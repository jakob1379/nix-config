# Stack profile: Shell

Detect: a tracked `.sh` or `.bash` file, or a tracked extensionless file whose
first line is a `sh` or `bash` shebang.

Tools, in tab order:

- ShellCheck: shell correctness, quoting, portability, and common pitfalls.
- ysap-lint: the preferred bash style, from the ysap style guide
  (https://style.ysap.sh/).

Production targets: build the file list from `git ls-files` with the `Detect:`
predicate, excluding vendored paths, and write it to
`.scanner-report-artifacts/shell-files.txt`. Pass files explicitly; ysap-lint's
own directory walk does not skip `node_modules/`. Split the list:

- **Bash files**: `.bash`, a bash shebang, or `.sh` without a non-bash shebang.
  Both tools run on these.
- **POSIX sh files**: a `#!/bin/sh` or `#!/usr/bin/env sh` shebang. Only
  ShellCheck runs on these; the ysap rules assume bash.

## ShellCheck

Version rule: `nix run nixpkgs#shellcheck -- --version`; record it.

Run:

```bash
nix run nixpkgs#shellcheck -- --format=json1 --external-sources <files> \
  > .scanner-report-artifacts/shellcheck.json \
  2> .scanner-report-artifacts/shellcheck-stderr.txt
```

ShellCheck applies the repository's `.shellcheckrc` when present; record it.
Never pass `--format=diff` or apply its suggested fixes.

Exit status: 0 means clean; 1 means comments were found and is not a failure;
anything else, for example 2 for a missing file, is a failure. Success check:
`shellcheck.json` parses and has a `comments` array.

Extract: counts by `level` (`error`, `warning`, `info`, `style`) and by `code`,
and the files with the most comments. Each comment has `file`, `line`, `column`,
`level`, `code`, and `message`.

Triage:

- `error` and `warning`: validate every one under section 6 of the workflow.
  Unquoted expansions (SC2086) reaching `rm`, `eval`, a command position, or a
  path are candidates for High when the input is untrusted.
- `info` and `style`: Low unless corroborated.

## ysap-lint

Version rule: `github:jakob1379/ysap-lint`, the user's own linter. Record the
resolved revision:

```bash
nix flake metadata github:jakob1379/ysap-lint --json
```

and read `locked.rev`.

Run on the bash files only:

```bash
nix run github:jakob1379/ysap-lint -- check <bash files> \
  > .scanner-report-artifacts/ysap-lint.txt \
  2> .scanner-report-artifacts/ysap-lint-stderr.txt
```

Output is one `file:line:col: CODE message` per issue, then `Found N issues.`.
There is no JSON mode; parse the lines.

Exit status: 0 means clean; 1 means issues were found and is not a failure; 2
means at least one file could not be read, so the result is partial. List the
unreadable files from stderr in the limitations.

Extract: counts by code and the files with the most issues.

Triage:

- This is the preferred bash style. Judge bash style against ysap, not against
  other style guides.
- `YS403` (unchecked `cd`), `YS405` (`eval`), `YS501` (unquoted expansion), and
  `YS206` (parsing `ls`) can be correctness bugs: validate under section 6.
- All other codes are the style backlog: Low, reported as counts per code with
  example locations, not one row per issue.

Overlap: SC2006 = YS203, SC2086 = YS501, SC2164 = YS403, SC2012 = YS206. The
same rule at the same `file:line` from both tools is one finding. Two linters
flagging one rule is a single signal, not corroboration.

Known noise: tree-sitter-bash cannot parse some valid bash (`exec {fd}<>file`,
`${x//a/\&b}`, `$(((x == 1)) && ...)`), and ysap-lint reports nothing on those
lines. A deliberate `#!/bin/bash` triggers `YS402`; classify it as noise when
the repository uses that shebang consistently.

Provenance: added 2026-11-23, tested with ShellCheck 0.11.0 and ysap-lint
`5105b5e` on a sample script.
