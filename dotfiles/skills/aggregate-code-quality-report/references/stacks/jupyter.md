# Stack profile: Jupyter notebooks

Detect: 10 or more tracked `.ipynb` files outside vendored and generated paths.

Tools, in tab order:

- Ruff: Python correctness (Pyflakes), syntax errors and lint rules on the code
  cells of notebooks, read natively from the `.ipynb` JSON.

Production targets: every tracked `.ipynb`, excluding the vendored and generated
paths from the workflow's stack detection. Write the list NUL-delimited and pass
the files explicitly, so Ruff does not walk untracked or ignored notebooks and
paths with spaces or glob characters stay whole:

```bash
git ls-files -z -- '*.ipynb' \
  ':(exclude,glob)**/node_modules/**' ':(exclude,glob)**/vendor/**' \
  ':(exclude,glob)**/third_party/**' ':(exclude,glob)**/dist/**' \
  ':(exclude,glob)**/build/**' ':(exclude,glob)**/*.min.*' \
  > .scanner-report-artifacts/notebook-files.txt
```

Coverage: Ruff skips a notebook whose `metadata.language_info.name`, or without
it `metadata.kernelspec.language`, is not `python`; a notebook with neither is
read as Python. List the skipped notebooks as uncovered in the report. Call the
stack clean only when every notebook was analyzed; when some were skipped, say
the result covers only the analyzed ones.

## Ruff

Version rule: use the Ruff the repository pins, from its lockfile (`uv.lock`,
`pylock.toml`, `requirements*.txt`) or its declared dependencies; with no pin,
use the newest release. Record the version the run reports.

Environment: run inside the repository's own Python environment with
`uv run --no-sync`, so a Ruff already installed in its `.venv` is the one that
runs and `uv.lock` is never written. When the repository has a `flake.nix` with
a dev shell, prefix the `uv run` line with
`nix develop --no-update-lock-file -c` so it gets the repository's Python and
`uv` without writing `flake.lock`; if `nix develop` fails, run without it and
record the failure. In a Python project without a `.venv`, `uv run` creates an
empty one: delete it afterwards.

Run, with `ruff==<pinned>` in place of `ruff` when the repository pins one:

```bash
mapfile -d '' -t notebooks < .scanner-report-artifacts/notebook-files.txt
uv run --no-sync --with ruff ruff check --no-fix --no-cache \
  --isolated --output-format json \
  --output-file .scanner-report-artifacts/ruff-notebooks.json \
  -- "${notebooks[@]}" 2> .scanner-report-artifacts/ruff-notebooks.stderr
```

`--isolated` ignores the repository's Ruff configuration, so every repository is
judged by the same rules; run a second pass without it when the repository
configures Ruff and its own policy matters. `--no-cache` keeps `.ruff_cache/`
out of the scanned tree. `--output-file` keeps anything a dev shell's
`shellHook` prints out of the JSON.

Never: `--fix`, `--unsafe-fixes`, `--add-noqa`, `ruff format` without `--check`,
`--watch`.

Exit status: 0 means no findings; 1 means findings were reported (not a
failure); 2 means Ruff itself failed (bad arguments, unreadable file).

Success check: the output file parses as a JSON array, and every element has
`code`, `filename`, `cell` and `location.row`. An exit status of 2 or a non-JSON
output file is a failed run.

Extract: count by `code`; for each finding the notebook, `cell` (1-based index
over all of the notebook's cells, Markdown included) and `location.row` (line
inside that cell), and the `message`. Report locations as
`<notebook>#cell<n>:<row>`.

Triage: validate every `F` (Pyflakes: undefined names, unused imports and
variables) and every `invalid-syntax`/`E9` finding against the cell source; an
undefined name can be defined in an earlier cell that Ruff did see, so check
cell order. Validate the same way every `RUF008` (mutable dataclass default, a
`ValueError` when the cell runs), `RUF009` (call in a dataclass default) and
`RUF016` (indexing with a non-integer key, a `TypeError`), and any other finding
whose message describes a runtime error. Treat `UP`, `I`, `PIE`, `SIM`, `FURB`,
`PLC` and `PLR` as Low style. For any other `RUF` code, read the rule's
documentation and treat it as Low only when the rule is about style. `W605`
(invalid escape sequence) is Low unless the string is not meant for LaTeX.

Known noise: with `--isolated`, Ruff's default rule set includes the pyupgrade
(`UP031`, `UP032`), isort (`I001`) and Ruff (`RUF059`) rules, which made up most
of the trial's results on teaching notebooks. Matplotlib labels written as
non-raw strings (`'$\phi$'`) raise `W605`. Shell and magic lines (`!pip`,
`%matplotlib`) are skipped by Ruff and raise nothing. Outside a Python project
`uv run` warns on stderr that `--no-sync` has no effect. A dev shell's
`shellHook` can install git hooks under `.git/hooks`; record any it adds.

Provenance: proposed 2026-11-26 from jakob1379/AMAS@e43b48e with Ruff 0.17.6 (10
notebooks, exit 1, 67 results, none of them `F821` or syntax errors). The
`uv run` command, the NUL-delimited list, the `cell` numbering and the skipped R
notebooks were checked on 2026-11-26 with Ruff 0.17.6.
`nix develop --no-update-lock-file -c` was checked on jakob1379/nix-config,
where its dev shell supplied `uv` and Python and installed a `pre-push` hook.
Unverified: exit status 2, a repository that pins Ruff, Ruff run inside a dev
shell, and a repository with its own `[tool.ruff]` configuration.
