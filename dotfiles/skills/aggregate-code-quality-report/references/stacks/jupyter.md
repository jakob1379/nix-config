# Stack profile: Jupyter notebooks

Detect: 10 or more tracked `.ipynb` files outside vendored paths.

Tools, in tab order:

- Ruff: Python correctness (Pyflakes), syntax errors and lint rules on the code
  cells of notebooks, read natively from the `.ipynb` JSON.

Production targets: every tracked `.ipynb` from `git ls-files '*.ipynb'`,
excluding vendored paths. Write the list to
`.scanner-report-artifacts/notebook-files.txt` and pass the files explicitly, so
Ruff does not walk untracked or ignored notebooks.

## Ruff

Version rule: run the newest release, `uvx ruff@<version>`, with the version
resolved by `uvx ruff@latest --version` just before the run. Record the resolved
version.

Run:

```bash
uvx ruff@<version> check --no-fix --no-cache --isolated \
  --output-format json $(cat .scanner-report-artifacts/notebook-files.txt) \
  > .scanner-report-artifacts/ruff-notebooks.json \
  2> .scanner-report-artifacts/ruff-notebooks.stderr
```

`--isolated` ignores the repository's Ruff configuration, so every repository is
judged by the same rules; run a second pass without it when the repository
configures Ruff and its own policy matters. `--no-cache` keeps `.ruff_cache/`
out of the scanned tree.

Never: `--fix`, `--unsafe-fixes`, `--add-noqa`, `ruff format` without `--check`,
`--watch`.

Exit status: 0 means no findings; 1 means findings were reported (not a
failure); 2 means Ruff itself failed (bad arguments, unreadable file).

Success check: the stdout file parses as a JSON array, and every element has
`code`, `filename`, `cell` and `location.row`. An exit status of 2 or a non-JSON
stdout is a failed run.

Extract: count by `code`; for each finding the notebook, `cell` (1-based code
cell index) and `location.row` (line inside that cell), and the `message`.
Report locations as `<notebook>#cell<n>:<row>`.

Triage: validate every `F` (Pyflakes: undefined names, unused imports and
variables) and every `invalid-syntax`/`E9` finding against the cell source; an
undefined name can be defined in an earlier cell that Ruff did see, so check
cell order. Treat `UP`, `I`, `PIE`, `SIM`, `FURB`, `PLC`, `PLR` and `RUF` as Low
style. `W605` (invalid escape sequence) is Low unless the string is not meant
for LaTeX.

Known noise: with `--isolated`, Ruff's default rule set includes the pyupgrade
(`UP031`, `UP032`), isort (`I001`) and Ruff (`RUF059`) rules, which made up most
of the trial's results on teaching notebooks. Matplotlib labels written as
non-raw strings (`'$\phi$'`) raise `W605`. Shell and magic lines (`!pip`,
`%matplotlib`) are skipped by Ruff and raise nothing.

Provenance: proposed 2026-11-26 from jakob1379/AMAS@e43b48e with Ruff 0.17.6 (10
notebooks, exit 1, 67 results, none of them `F821` or syntax errors).
Unverified: exit status 2, notebooks with non-Python kernels (Ruff skips them),
and a repository with its own `[tool.ruff]` configuration.
