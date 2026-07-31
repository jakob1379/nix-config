# Aggregate code-quality report workflow

## Contents

1. Scope and outputs
2. Establish the revision
3. Bootstrap artifact storage
4. Run the scanners
5. Validate and reconcile findings
6. Generate the HTML report
7. Validate the result
8. Return the handoff

## 1. Scope and outputs

Assume:

- Execution starts at the repository root in a clean clone or clean worktree.
- No previous scanner artifacts, `.pyscn/`, `.desloppify/`, or HTML report
  exist.
- `git`, `uv`, and network access for installing scanner packages are available.
- Production source must remain unchanged. Scanner state and report artifacts
  are allowed.
- No commit, push, PR, upload, or source/scanner-data transmission is allowed.
- Unrelated changes must be preserved if the environment is unexpectedly dirty.

Create:

- A standalone static report at `scanner-aggregate-report.html`.
- Fresh supporting artifacts under `.scanner-report-artifacts/`.
- An offline-useful HTML document with no external runtime dependencies.
- Separate lanes for Skylos, PySCN, AI Slop Detector, Desloppify, and Ponytail
  Audit ultra.

Apply this rule throughout: scanner labels are leads, not conclusions. Validate
findings against current source, reconcile overlapping signals, and rank risks
by real urgency and impact.

## 2. Establish the revision

1. Run `git status --short --branch`.
2. Preserve all tracked and untracked user changes. Never delete, reset, or
   overwrite them.
3. Run `git fetch --prune origin`.
4. Update against `origin/main`:
   - On `main`, use a fast-forward-only update.
   - On another branch, rebase it onto `origin/main`.
   - If `origin/main` is absent or local changes prevent the update, report the
     exact limitation and continue without destructive cleanup. Do not silently
     substitute another default branch.
5. Record the repository name, current branch, current commit SHA, `origin/main`
   SHA when present, ahead/behind counts, and UTC generation timestamp.
6. Run `git status --short --branch` again.

Do not claim coverage of latest `main` unless the update succeeded.

## 3. Bootstrap artifact storage

Create `.scanner-report-artifacts/`. Do not assume previous output exists.
Remove or replace only artifacts proven to belong to the current report run;
never delete user-owned or historical files merely because their names look
related.

For every tool, record:

- Installed version.
- Full command line.
- Exit status.
- Complete human-readable stdout and stderr in separate artifact files where
  practical.
- Bootstrap failure, if any.

If a tool is unavailable, try an ephemeral `uv run --with ...` or
`uvx --from ...` invocation. If installation still fails, continue and show the
failure prominently.

Before scanning, inspect the repository layout. For Skylos, use the existing
subset of `src`, `scripts`, and `profiles` as the production surface. Record the
actual target list. Do not silently replace missing production targets with a
whole-repository scan.

## 4. Run the scanners

### 4.1 Skylos

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

### 4.2 PySCN

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

### 4.3 AI Slop Detector

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

### 4.4 Desloppify

Check availability:

```bash
command -v desloppify
```

If unavailable, use the supported `uvx` or `uv` bootstrap path and record it.
Then run, capturing complete output for every command:

```bash
desloppify scan --path .
desloppify status
desloppify next
```

Follow `desloppify next` exactly. If it requests subjective review, run:

```bash
desloppify review --run-batches --runner codex --parallel --scan-after-import
desloppify status
desloppify next
```

Do not ask review or triage prompts to spawn child agents; the first-class batch
runner owns isolation and parallelism. Retry only failed packet slices using the
immutable packet and `--only-batches` when needed.

This task is observational. Do not fix, resolve, skip, or mark findings
complete.

Report separately, when available:

- Overall score.
- Strict score.
- Objective/mechanical score.
- Verified score.
- Subjective review status.
- Open findings by tier.
- Wontfix debt.
- Whether unreviewed subjective dimensions depress the score.

Explain that Desloppify's scoring model is incompatible with other scanner
scores; never compare its strict score directly without that qualification.

### 4.5 Ponytail Audit ultra

Invoke `$ponytail:ponytail-audit ultra` as a read-only whole-repository
over-engineering audit. If the named skill is unavailable, perform the same
audit manually and disclose the fallback.

Inspect the production codebase for:

- Dead code and unused flexibility.
- Dependencies replaceable by the standard library.
- Code replaceable by native platform features.
- Single-implementation interfaces or factories.
- Delegating-only wrappers.
- Unused configurability.
- Duplicate abstractions.
- Forwarding-only files or layers.
- Hand-rolled standard-library behavior.
- Large implementations that can preserve behavior with substantially less code.

Rank the largest credible reduction first. Use exactly these tags:

```text
delete:
stdlib:
native:
yagni:
shrink:
```

Format every finding as:

```text
<tag> <what to cut>. <replacement>. [path]
```

End with:

```text
net: -<N> lines, -<M> deps possible.
```

If nothing can credibly be cut, use `Lean already. Ship.` Do not treat this lane
as a correctness, security, or performance scanner. Keep it separate and do not
assign operational severity unless independent validated evidence establishes
actual risk.

## 5. Validate and reconcile findings

Read current source before ranking any finding.

For every proposed High finding:

- Open the reported source and relevant callers.
- Identify the trust boundary and reachable execution path.
- Determine whether input is trusted, authenticated, constrained, or
  operator-controlled.
- Check whether the scanner misunderstood framework behavior.
- Record current paths and line numbers.
- Assign high, medium, or low confidence.
- Require a plausible trigger and impact; do not promote hypothetical danger.

Validate representative Medium findings similarly. Mark unsupported claims as
noise, false positives, or `needs evidence`.

Use these severities:

- **High:** Plausibly exploitable security boundary; credential or
  sensitive-data exposure; arbitrary file read/write, command execution, or
  destructive action reachable from insufficiently trusted input; data
  corruption/loss; a production correctness defect likely to break a critical
  workflow; or an immediate release/operational blocker.
- **Medium:** A real reliability, maintainability, resource-leak, duplication,
  or complexity problem with meaningful future cost; a security concern limited
  to trusted operator input; a defect needing unusual conditions or having
  contained impact; or a cross-module contract weakness worth scheduling.
- **Low:** Style, clarity, modest duplication, test gaps, timeouts, annotations,
  speculative maintainability, tool-only signals without demonstrated runtime
  impact, scanner noise, semantic-clone noise, literals, generated/config code,
  or low-confidence claims.

For every aggregate finding include:

- Severity and concise title.
- Impact and evidence.
- Affected source locations.
- Trigger or reachability.
- Confidence.
- Reporting tools.
- Tool agreement or disagreement.
- Recommended next action.
- Classification: `confirmed`, `corroborated`, `tool-only`, `false positive`, or
  `noise`.

Never average tool scores. Compare the tools by purpose:

- Skylos: security, path handling, resource management, dead code, dependencies.
- PySCN: complexity, duplication, maintainability, architecture.
- Slop Detector: broad density, inflation, churn, coverage, dependency sanity.
- Desloppify: mechanical and subjective health backlog plus execution state.
- Ponytail Audit: deletion, simplification, YAGNI, stdlib/native replacement.

## 6. Generate the HTML report

Create `scanner-aggregate-report.html` as one self-contained HTML document with
inline CSS and minimal inline JavaScript. Do not use external fonts, scripts,
CDNs, images, or runtime requests. Keep content readable when JavaScript fails.

Create these tabs:

- Overview
- Priority Matrix
- Tool Comparison
- Skylos
- PySCN
- Slop Detector
- Desloppify
- Ponytail Audit
- Raw Sources

### Overview

Show repository, branch, commit, `origin/main`, ahead/behind, timestamp, tool
statuses and versions, validated High/Medium/Low counts, top actions,
limitations, failures, and whether a previous baseline existed.

If no earlier report or scanner artifacts existed, state exactly:

```text
Baseline delta: unavailable; this is a fresh clean-environment baseline.
```

Never invent a post-rebase delta.

### Priority Matrix

Order High, Medium, then Low. Separate confirmed findings from noise. Show
impact, confidence, source locations, tools, and next action. Never reinterpret
maintenance scores as security severity.

### Tool Comparison

Explain each tool's scope and blind spots, corroboration, and apparent
contradictions. Do not average or fake-normalize scores.

### Tool tabs

For every tool include exact command, version, run status, key metrics, detailed
findings, source-validation notes, known false positives or limitations, and
artifact path.

Keep Ponytail as a separate simplification backlog ordered by credible deletion,
ending with the line/dependency estimate.

### Raw Sources

Include commands, versions, artifact paths, exit statuses or failure summaries,
concise raw excerpts, redaction notes, and Git revision metadata. Do not embed
huge JSON documents; name or link local artifact paths and summarize relevant
evidence.

### Accessible tab behavior

- Use stable button IDs.
- Use `role="tablist"`, `role="tab"`, and `role="tabpanel"`.
- Pair `aria-controls`, `aria-labelledby`, and `aria-selected` correctly.
- Support Left, Right, Home, and End keyboard navigation.
- Avoid clipped or overlapping text at desktop and mobile widths.
- Keep all content readable if JavaScript fails.

## 7. Validate the result

Run all applicable checks:

1. Parse every generated JSON artifact.
2. Parse `scanner-aggregate-report.html` with Python's standard-library
   `html.parser`.
3. Verify all tab IDs, panel IDs, `aria-controls`, and `aria-labelledby` values
   are unique and paired.
4. Search for stale SHAs, old dates, removed paths, placeholder scores, `TODO`,
   `TBD`, and sample data.
5. Confirm every required tab exists.
6. Confirm source locations refer to the current commit.
7. Confirm no secret, token, credential, or sensitive environment value appears.
8. Confirm the report has no external network dependency.
9. If browser preview is available, smoke-test all tabs, keyboard navigation,
   desktop layout, mobile layout, and clipping/overlap. Do not claim browser
   validation when unavailable.
10. Run `git status --short --branch`.

## 8. Return the handoff

Return a concise summary containing:

- Whether update/rebase onto `origin/main` succeeded.
- Current branch, commit, and ahead/behind counts.
- A link to `scanner-aggregate-report.html`.
- High/Medium/Low counts.
- The most important validated findings.
- Successful and failed tools.
- Whether this is a fresh baseline.
- Validation performed.
- Browser-preview limitations.
- Generated files shown by final Git status.

Do not dump every scanner finding into chat; the HTML report is the detailed
artifact.
