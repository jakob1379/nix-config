# Stack profile: JavaScript / TypeScript

Detect: a tracked `package.json` outside vendored paths, or 10 or more tracked
`.js`, `.jsx`, `.mjs`, `.cjs`, `.ts`, `.tsx`, `.mts`, or `.cts` files.

Tools, in tab order:

- Biome: JS/TS correctness, suspicious patterns, a small security rule set,
  complexity, and style.

Production targets: the whole repository, filtered by the repository's
`.gitignore` through Biome's VCS integration. Record whether a Biome
configuration was used.

## Biome

Version rule: if any tracked `package.json` declares `@biomejs/biome`, use the
version the lockfile resolves it to, or the declared version when no lockfile
pins it, so the repository's own `biome.json` schema parses. Otherwise use the
current release. Record the resolved version from `--version` either way.

Configuration: if `biome.json` or `biome.jsonc` exists, Biome applies it; record
its path. Without one, Biome runs its recommended defaults; state in the tab
that findings reflect Biome defaults, not the project's chosen rules. If the
project lints with ESLint instead, record that, and classify default-rule style
diagnostics that contradict the project's conventions as noise.

Run, without installing project dependencies. Redirect stdout rather than using
`--reporter-file`, which Biome 1.x lacks. When the repository has no root
`.gitignore`, leave out the three `--vcs-*` flags and say in the tab that VCS
filtering was off: with them, Biome exits 1 with `couldn't find an ignore file`
and writes nothing. Before Biome 1.9.0, replace `--max-diagnostics=none` with
`--max-diagnostics=65535`: those releases reject `none`, take no larger number,
and otherwise stop at 20 diagnostics.

```bash
npx --yes @biomejs/biome@<version> lint \
  --vcs-enabled=true \
  --vcs-client-kind=git \
  --vcs-use-ignore-file=true \
  --max-diagnostics=none \
  --reporter=json \
  . \
  > .scanner-report-artifacts/biome-report.json \
  2> .scanner-report-artifacts/biome-stderr.txt
```

Never pass `--write`, `--fix`, `--unsafe`, or `--suppress`, and never run
`biome check --write` or `biome format --write`.

Exit status: 0 means no error-level diagnostics; 1 also covers "diagnostics
found" and is not a tool failure by itself. Success check: the run succeeded
only if `.scanner-report-artifacts/biome-report.json` parses and has a `summary`
object. Otherwise report the lane as failed with stderr, typically a
configuration or version mismatch.

Extract: `summary.errors`, `summary.warnings`, `summary.infos`, diagnostic
counts by `category`, and the files with the most diagnostics. Each diagnostic
has `severity`, `message`, `category`, and `location.path` with
`location.start.line`. Before Biome 2.4.0 the shape differs: the text is in
`description`, the path in `location.path.file`, and the line is 1 plus the
newlines before byte offset `location.span[0]` of `location.sourceCode`; when
`span` is null, report the finding without a line. Before 2.3.0 there is no
`summary.infos`; count the diagnostics whose `severity` is `information`.

Triage:

- `lint/security/*` and `lint/correctness/*`: validate every one under section 6
  of the workflow.
- `lint/suspicious/*`: validate a representative sample.
- `lint/complexity/*`, `lint/style/*`, `lint/a11y/*`, `lint/nursery/*`: Low
  unless corroborated. Route `lint/a11y/*` to the Accessibility lane as
  corroboration when that lane is active.
