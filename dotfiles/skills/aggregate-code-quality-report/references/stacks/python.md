# Stack profile: Python

Detect: the repository root has `pyproject.toml`, `setup.py`, `setup.cfg`, or
`requirements*.txt`, or 10 or more tracked `.py` files.

Tools, in tab order:

- Skylos: security, path handling, resource management, dead code, dependencies.
- PySCN: complexity, duplication, maintainability, architecture.
- Slop Detector: broad density, inflation, churn, coverage, dependency sanity.

Production targets: inspect the repository layout. For Skylos, use the existing
subset of `src`, `scripts`, and `profiles` as the production surface. Record the
actual target list. Do not silently replace missing production targets with a
whole-repository scan.

## Skylos

Run the equivalent of:

```bash
uv run skylos --trace -a src backend python \
  --no-upload \
  --format json \
  --output .scanner-report-artifacts/skylos.json \
  --limit 1000
```

Adapt only for production targets that do not exist or for the executable
bootstrap method. Capture stdout and stderr. Never enable uploads or
external-LLM analysis.

## PySCN

Run:

```bash
uv run --with pyscn pyscn analyze --html --no-open src/
```

If `src/` does not exist, record the scanner as unavailable for the requested
production target rather than substituting an unrelated tree without disclosure.

Locate the report created by this exact run under
`.pyscn/reports/analyze_*.html`; do not select an older report. Copy it to
`.scanner-report-artifacts/pyscn.html` and record its original path. Capture
terminal output. Use an HTML parser where practical to extract scores,
complexity, duplication, clone groups, hotspots, and architecture observations.

## Slop Detector

Run:

```bash
uv run --with ai-slop-detector slop-detector src/ \
  --json \
  --no-history \
  > .scanner-report-artifacts/slop-detector.json
```

Capture stderr separately. If `src/` is absent, disclose the limitation rather
than silently changing scope. Confirm JSON parseability before using project
status, file counts, deficit scores, hotspot priorities, logic density,
dependency usage, coverage/churn context, or warning details.

## Provenance

shortcut: these commands moved here from the old workflow and have not run
since. They lack the version rule, exit-status meaning and success check the
template asks for; the first run against a Python repository writes them to
`.scanner-report-artifacts/proposed-stacks/python.feedback.md` (workflow section
9).
