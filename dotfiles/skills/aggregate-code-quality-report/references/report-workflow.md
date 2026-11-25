# Aggregate code-quality report workflow

## Contents

1. Scope and outputs
2. Establish the revision
3. Bootstrap artifact storage
4. Detect stacks and lanes
5. Run the lanes
6. Validate and reconcile findings
7. Generate the HTML report
8. Validate the result
9. Propose stack-profile updates
10. Return the handoff

## 1. Scope and outputs

Assume:

- Execution starts at the repository root in a clean clone or clean worktree.
- No previous scanner artifacts, `.pyscn/`, `.desloppify/`, `graphify-out/`, or
  HTML report exist. The one exception is a baseline the caller placed at
  `.scanner-report-artifacts/baseline.json`: the `findings.json` of an earlier
  run on this repository (section 2).
- `git`, `uv`, `npx`, and network access for installing scanner packages are
  available, plus `nix` for the Shell profile.
- Production source must remain unchanged. Scanner state and report artifacts
  are allowed.
- No commit, push, PR, upload, or source/scanner-data transmission is allowed.
- Unrelated changes must be preserved if the environment is unexpectedly dirty.

Create:

- A standalone static report at `scanner-aggregate-report.html`.
- Fresh supporting artifacts under `.scanner-report-artifacts/`, including the
  reconciled findings as `findings.json` (section 6).
- An offline-useful HTML document with no external runtime dependencies.
- One lane per active tool, chosen in section 4.

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
7. If `.scanner-report-artifacts/baseline.json` exists, read its `repo` and
   `commit`. The baseline is usable when git does not track the file, its `repo`
   is this repository, and `git merge-base --is-ancestor <baseline commit> HEAD`
   succeeds. Then write
   `git diff --name-only --no-renames <baseline commit> HEAD` to
   `.scanner-report-artifacts/changed-files.txt`, so a renamed file lists both
   its old and its new path; this is an incremental run. Otherwise this is a
   full run: say why in the Overview and ignore the baseline. A branch that step
   4 rebased has usually lost the baseline commit as an ancestor, so expect a
   full run there.

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

If a tool is unavailable, try an ephemeral `uv run --with ...`,
`uvx --from ...`, `npx --yes <pkg>@<version>`, or `nix run nixpkgs#<pkg>`
invocation. If installation still fails, continue and show the failure
prominently.

## 4. Detect stacks and lanes

List tracked files with `git ls-files`. Exclude vendored and generated paths
(`node_modules/`, `vendor/`, `third_party/`, `dist/`, `build/`, `*.min.*`,
lockfiles) from every count below. Record the counts per file extension in
`.scanner-report-artifacts/stacks.json`.

Read every file in [stacks/](stacks/) except `_template.md`. Each profile starts
with a `Detect:` line. A profile is **active** when its `Detect:` predicate
holds. Run every tool of every active profile (section 5.1).

A stack is **unprofiled** when its source extensions account for 10 or more
tracked files and no profile's `Detect:` predicate covers them. Ignore
documentation, data and config formats (`.md`, `.txt`, `.json`, `.yaml`, `.yml`,
`.toml`, `.lock`, `.csv`, images). Record each unprofiled stack; section 9
handles it.

A stack is **under threshold** when it has tracked source files but too few to
activate its profile or count as unprofiled. Record its file count; the Tool
Comparison names it as covered only by the always-on lanes.

Read [skill-roster.md](skill-roster.md). Its predicates decide which skill lanes
(5.2 to 5.12) and which conditional skills inside them are active.

Record every lane and every roster skill as `active` or
`not applicable: <reason>`.

## 5. Run the lanes

Follow `superpowers:dispatching-parallel-agents`: lanes 5.1 to 5.12 are
independent, so run them as parallel subagents when the host supports it. Give
each subagent the repository root, its lane section verbatim, the roster rules
for loading skills, this skill's directory (the roster looks beside it), its
artifact paths, and the read-only rule. Collect each lane's output into
`.scanner-report-artifacts/` before section 6.

Scope every whole-tree review (5.4, 5.7, 5.8, 5.10, 5.11, 5.12) to production
source: skip tests, fixtures, generated code, vendored code, and docs unless the
lane says otherwise. Record the file list each lane reviewed.

On an incremental run, 5.1 to 5.3 and 5.5 still run on the whole tree: their
output is not per file. 5.9 reviews the branch's own changes and ignores the
baseline. Each other lane (5.4, 5.6 to 5.8, 5.10 to 5.12) reads only the
production files in `changed-files.txt`, plus the callers it needs to judge
them, but only when the baseline's `lanes_done` names it. A lane the baseline
did not finish reads the whole tree. So does a conditional skill inside a lane
(5.10 to 5.12) that the baseline's `lanes_done` does not name, even when the
lane has no changed files. When a lane the baseline finished has no changed
files and no such skill ran in it, record it as
`not applicable: unchanged since <baseline commit>`; a lane where one ran is
active. A request for a full review overrides this and makes the run a full run.

### 5.1 Stack-profile lanes

For each active profile, run its tools exactly as the profile defines: version
rule, production targets, command, exit-status meaning, success check, and
extraction. A profile tool whose command fails because the tool changed (renamed
flag, changed output format) is a broken profile: record the error, try the
documented replacement if one is evident from `--help`, and note it for
section 9.

### 5.2 Desloppify

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

Do not run subjective review. When `desloppify next` requests it, stop there and
report the subjective dimensions as unreviewed.

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

### 5.3 Graphify

Invoke `$graphify . --no-viz` to build a structural knowledge graph of the
repository. If the named skill is unavailable, bootstrap with
`uvx --from graphifyy graphify` and follow the same pipeline, disclosing the
fallback.

Run both extraction passes and keep the LLM inside the host session:

- Unset `GEMINI_API_KEY` and `GOOGLE_API_KEY` for every graphify command so no
  source is sent to an external LLM.
- Run AST extraction for code and semantic extraction for docs, papers, and
  images with the skill's `general-purpose` subagents. Record the subagent
  count, chunk count, failed or missing chunks, and token totals.
- If semantic extraction fails for more than half the chunks, report the lane as
  AST-only and disclose which files are not represented.
- Do not run `graphify hook install`, `graphify claude install`, `--watch`,
  `--mcp`, Neo4j/FalkorDB pushes, or any step that edits repository files
  outside `graphify-out/`.

Copy `graphify-out/graph.json` and `graphify-out/GRAPH_REPORT.md` to
`.scanner-report-artifacts/graphify/`. Extract node/edge/community counts, god
nodes, low-cohesion communities, and surprising cross-community connections.
Count edges by `EXTRACTED`, `INFERRED`, and `AMBIGUOUS` and report them
separately; label every LLM-derived edge as such in the report.

When `mattpocock-skills:codebase-design` is available, load it and describe god
nodes, low-cohesion communities and bridges in its vocabulary (module,
interface, depth, seam, shallow, leverage, locality). It supplies vocabulary
only; it adds no findings.

Treat `INFERRED` and `AMBIGUOUS` edges as weaker than `EXTRACTED` edges; never
let them alone corroborate another tool. Treat god nodes and surprising
connections as coupling leads, not defects. Validate each against current source
before it corroborates a profile-tool architecture finding or a Ponytail
finding. Keep this lane separate and do not assign operational severity unless
independent validated evidence establishes actual risk.

### 5.4 Ponytail Audit

Invoke `$ponytail:ponytail-audit` on the whole repository. It is read-only and
takes no level argument. If the skill is unavailable, perform the same audit
manually from its definition (map first; look for bug, risk, scale, missing
test, speed, lean; a concrete case per finding) and disclose the fallback.

Save its full output to `.scanner-report-artifacts/ponytail-audit.md`. The
output contains:

- `What this repo does:` and the load it assumed.
- Up to 20 findings grouped **Must fix**, **Should fix**, **Nice to have**, each
  with file:lines and the bullets What this is, Problem, Fix, If we skip it.
- `Verdict:`, `Lean: -N lines, -M dependencies possible.`, and `Not checked:`.

Split the findings by kind:

- **Bug, risk, scale, missing test, speed** findings are candidate findings.
  They enter section 6 with reporting tool `Ponytail Audit` and are validated
  and severity-ranked like any scanner finding. Ponytail's grouping is not the
  report's severity.
- **Lean** findings (delete, reuse, stdlib, native, yagni, merge, split) form
  the simplification backlog. Keep it in the Ponytail tab, ordered by credible
  deletion, ending with the `Lean:` line. Assign no operational severity unless
  independent validated evidence establishes actual risk.

Copy `Not checked:` verbatim into the report's limitations.

### 5.5 Ponytail Debt

Invoke `$ponytail:ponytail-debt`. If the skill is unavailable, run its grep
manually and disclose the fallback:

```bash
git grep -nE '(#|//|/[*]) ?(shortcut|ponytail):'
```

Save the ledger to `.scanner-report-artifacts/ponytail-debt.md`. Report the
marker count, the `no-trigger` count, and the ledger grouped by file.

Ponytail Audit treats a marked shortcut as a decision, not a finding. Promote a
ledger row to a candidate finding only when the load assumed in 5.4 already
crosses the ceiling the comment names; validate it in section 6.

### 5.6 Accessibility (conditional)

Run only when the roster's UI predicate holds.

Invoke `design:accessibility-review` against the repository's UI source:
templates, components, and static HTML. If the skill is unavailable, audit the
same WCAG 2.1 AA criteria manually and disclose the fallback.

This is a static source audit. Do not install dependencies or start the app to
render it. Report which criteria were checked from source (alt text, labels,
semantic structure, ARIA wiring, keyboard handlers) and which stay unverified
without rendering (contrast, focus visibility and order, target size). Never
claim a rendered check that did not run.

Accessibility defects are Medium at most unless they block a critical workflow
for assistive-technology users; then they are High.

### 5.7 Architecture

Read `mattpocock-skills:improve-codebase-architecture` and run its step 1
(Explore) only, with `mattpocock-skills:codebase-design` loaded for vocabulary.
Read `GLOSSARY.md` and `docs/adr/` when they exist and never write to them. Skip
its step 2 (its HTML report loads CDNs) and step 3 (interactive, edits glossary
and ADRs).

Save the candidates to `.scanner-report-artifacts/architecture.md`. Each
candidate has files, problem, solution, benefits in locality and leverage, the
deletion-test result, and a strength of `Strong`, `Worth exploring`, or
`Speculative`. Cross-reference each candidate with Graphify god nodes and
low-cohesion communities from 5.3, and state where they agree or disagree.

Candidates are advisory and get no operational severity unless independent
validated evidence establishes actual risk.

### 5.8 Whole-tree code review

Two read-only reviews over the production source.

**OCR rules.** Run `ocr delegate rule <files>` on the production file list
(`ocr delegate preview` needs a commit range, so skip it). Review each file's
full contents against its rule groups, focusing on correctness, security,
performance, error handling, and concurrency. Never run `ocr review` or apply
fixes. Fallback when `ocr` is missing: review the same files for the same focus
areas and disclose it. Save to `.scanner-report-artifacts/ocr-review.md`.

**Standards.** Read `mattpocock-skills:code-review` and run only its Standards
axis against the whole tree instead of a diff: find the repo's documented
standards (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/`) and apply them
plus the skill's smell baseline. A documented standard overrides the baseline.
Baseline smells are judgement calls. Skip the Spec axis; a whole repository has
no single spec. Save to `.scanner-report-artifacts/standards-review.md`.

Both feed section 6 as candidate findings.

### 5.9 Branch delta (conditional)

Run only when the roster's Branch delta predicate holds. Review
`origin/main...HEAD` with these seats, each in its own subagent, blind to the
others, all reviewing the same patch file written outside the repository:

- `security-review` (built-in).
- `code-review` (built-in) at level `medium`, passed explicitly: with no level
  it reuses the last one typed. Never `max` or `ultra`.
- `open-code-review:delegate-review` with `--from origin/main --to HEAD`.
- `ponytail:ponytail-review`.
- `superpowers:requesting-code-review`.
- `mattpocock-skills:code-review` with fixed point `origin/main`.

Merge as `converge-review` does: deduplicate by `file:line` plus claim, and
record which seats raised each finding. Run no fix loop. Seats that cannot load
are listed as `missing`. Save to `.scanner-report-artifacts/branch-delta.md`.
Findings feed section 6.

### 5.10 Frontend design (conditional)

Run only when the roster's UI predicate holds. Review the UI source with:

- `design:design-system`: hardcoded colors, spacing, and type values; token and
  naming inconsistencies across components.
- `design:ux-copy`: error messages, empty states, button labels, confirmations.
- `frontend-design`: whether the visual direction is consistent or reads as
  templated defaults.
- `emil-design-eng` and `apple-design`: interaction polish, press and hover
  states, popover origin, tooltip timing, reduced motion, typography.
- `mobile-native`, when the Web UI predicate holds: mobile CSS and meta-tag
  defects.
- `ask-sonner`, when the Sonner predicate holds: toast setup and usage.

Static source review only. Save to
`.scanner-report-artifacts/frontend-design.md` grouped by skill. Findings are
advisory unless they break a user workflow, such as a mobile input that zooms
the page on focus or an error state with no message; those enter section 6.

### 5.11 Motion (conditional)

Run only when the roster's Motion predicate holds.

Use `improve-animations` as the driver: its survey and prioritized audit, read
only. Write its implementation plans to `.scanner-report-artifacts/motion/`,
never to the repository. Apply as rubrics:

- `review-animations`: craft bar for existing motion.
- `animation-performance`: non-composited properties, main-thread animation,
  layout thrash.
- `remove-animations`: its criteria for motion that should not exist. Skip its
  edits.
- `find-animation-opportunities`: places that should animate. Advisory only.
- `gestures`, when the Gestures predicate holds.
- `animate-expo`, when the Expo predicate holds.

Missing `prefers-reduced-motion` handling and frame-dropping animation on a
critical path enter section 6. The rest stays in the Motion tab as advisory.

### 5.12 Language rubrics (conditional)

Review production code with the language skill whose predicate holds:

- `write-swift` (Swift): data-race safety, concurrency, retain cycles, API
  design.

Findings enter section 6. Add a rubric here when a new language skill is
installed.

## 6. Validate and reconcile findings

Follow `superpowers:receiving-code-review`: every lane and scanner finding is
unverified review feedback. Verify it against the code before accepting it, and
reject it with a reason when it is wrong.

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
- An id that survives edits: `<category>:<path>:<anchor>`. The category is one
  of `security`, `correctness`, `data-loss`, `reliability`, `performance`,
  `complexity`, `duplication`, `dead-code`, `test-gap`, `accessibility`,
  `design`, `architecture`, `style`, `shortcut`. The path is the finding's main
  file, relative to the repository root. The anchor is the enclosing function,
  class or top-level key, or the tool's rule id when there is none. The anchor
  may itself hold colons (`Foo::bar`); the first two colons split the id. Never
  put a line number in an id. Two findings with the same id are one finding, so
  when two different defects would share one, add a word to the anchor that
  tells them apart. When a defect matches a baseline finding in the same file,
  reuse the baseline's id.

Write every finding to `.scanner-report-artifacts/findings.json`, including the
ones classified as a false positive or noise, so a later run does not validate
them again:

```json
{
  "repo": "<owner/name>",
  "commit": "<current commit SHA>",
  "generated": "<UTC timestamp>",
  "baseline": "<baseline commit, or null on a full run>",
  "lanes_done": ["5.4", "5.7", "5.10", "5.10:mobile-native"],
  "findings": [
    {
      "id": "<category>:<path>:<anchor>",
      "status": "new | open | fixed | dismissed",
      "severity": "High | Medium | Low | Advisory",
      "title": "<concise title>",
      "path": "<main file>",
      "line": 0,
      "classification": "<as above>",
      "lanes": ["<each reporting tool or lane>"]
    }
  ]
}
```

`lanes_done` lists the lanes among 5.4, 5.6 to 5.8 and 5.10 to 5.12 whose review
is complete for this commit, and each conditional skill that ran inside one as
`<lane>:<skill>` (`5.10:mobile-native`): each one that finished in this run,
plus each one the baseline finished that had no changed files. Leave out a lane
that failed, was skipped, or stopped early.

A false positive or noise has status `dismissed`, on every kind of run and
whatever the rules below would otherwise give it. Drop a `dismissed` finding
whose file no longer exists. Graphify coupling observations, architecture
candidates, the lean backlog, the shortcut ledger and advisory design and motion
findings have severity `Advisory`, since they carry no operational severity; the
delta counts them like any other finding. On a full run every other status is
`new`. On an incremental run:

- A baseline finding whose file is not in `changed-files.txt` carries over
  unchanged with status `open`, unless a whole-tree tool in this run no longer
  reports it; then check the source and mark it `fixed` or keep it.
- A baseline finding whose file changed is validated again: `open` when it still
  holds, `fixed` when it does not. A baseline finding already `fixed` is
  dropped.
- A finding whose id is not in the baseline is `new`.
- A `dismissed` baseline finding whose file is unchanged stays `dismissed`
  without another look.

Never average tool scores. Compare the tools by purpose. Each stack profile
states its tools' purposes; the always-on and conditional lanes are:

- Desloppify: mechanical and subjective health backlog plus execution state.
- Graphify: structural coupling, god nodes, module communities, cross-module
  bridges.
- Ponytail Audit: bugs, security and data-loss risk, scale, untested risky
  logic, slow paths, and deletion/simplification.
- Ponytail Debt: deliberate, marked shortcuts and whether each names an upgrade
  trigger.
- Accessibility: WCAG 2.1 AA issues visible in UI source.
- Architecture: deepening opportunities.
- Whole-tree code review: per-language OCR rules and documented-standards
  conformance.
- Branch delta: independent review seats on the current branch's changes.
- Frontend design: design-system consistency, UX copy, interaction polish.
- Motion: animation craft, performance, and reduced-motion handling.
- Language rubrics: language-specific correctness and safety.

Several review lanes are model-driven. Two of them agreeing is weaker evidence
than a deterministic tool plus a model, and never sufficient alone for High.

## 7. Generate the HTML report

Create `scanner-aggregate-report.html` as one self-contained HTML document with
inline CSS and minimal inline JavaScript. Do not use external fonts, scripts,
CDNs, images, or runtime requests. Keep content readable when JavaScript fails.

Run the report's prose (summaries, explanations, recommendations) through
`unslop`; leave quoted evidence, commands, and code untouched. Draw any chart
following `dataviz`, as inline SVG with no library.

Create these tabs, in order, skipping inactive conditional lanes:

1. Overview
2. Priority Matrix
3. Tool Comparison
4. One tab per active stack-profile tool, in profile order.
5. Desloppify
6. Graphify
7. Architecture
8. Ponytail (Audit and Debt sections)
9. Code Review (OCR rules and Standards sections)
10. Branch Delta
11. Accessibility
12. Frontend Design
13. Motion
14. Language Rubrics
15. Raw Sources

### Overview

Show repository, branch, commit, `origin/main`, ahead/behind, timestamp,
detected stacks with active profiles, every lane with its status (`active`,
`failed`, or `not applicable: <reason>`) and tool version, unprofiled stacks,
validated High/Medium/Low counts, top actions, limitations, failures, and
whether a previous baseline existed.

Include a skill coverage table: every skill in
[skill-roster.md](skill-roster.md), including the excluded list, with its status
(`used`, `fallback`, `not applicable: <predicate>`, `missing`, or
`excluded: <reason>`).

On a full run with no baseline, state exactly:

```text
Baseline delta: unavailable; this is a fresh clean-environment baseline.
```

On a full run that refused a baseline, state the reason instead:

```text
Baseline delta: unavailable; the baseline was not usable: <reason>.
```

On a full run that was asked for although a baseline was usable, state:

```text
Baseline delta: unavailable; a full review was requested, so the baseline at <baseline commit> was ignored.
```

On an incremental run, state the counts from `findings.json` instead, and mark
each finding's status wherever the report lists it:

```text
Baseline delta against <baseline commit>: <n> new, <n> still open, <n> fixed.
```

Never invent a delta the baseline does not support.

### Priority Matrix

Order High, Medium, then Low. Separate confirmed findings from noise. Show
impact, confidence, source locations, tools, and next action. Never reinterpret
maintenance scores as security severity.

### Tool Comparison

Explain each active tool's scope and blind spots, corroboration, and apparent
contradictions. Name the coverage gap for every unprofiled and under-threshold
stack. Do not average or fake-normalize scores.

### Tool tabs

For every tool include exact command, version, run status, key metrics, detailed
findings, source-validation notes, known false positives or limitations, and
artifact path.

The Ponytail tab holds the simplification backlog ordered by credible deletion,
ending with the `Lean:` line, then the shortcut ledger with its counts. Audit
findings promoted into section 6 appear in the Priority Matrix and are
cross-referenced here.

### Raw Sources

Include commands, versions, artifact paths, exit statuses or failure summaries,
concise raw excerpts, redaction notes, Git revision metadata, stack-detection
counts, and the paths of any proposed stack profiles. Do not embed huge JSON
documents; name or link local artifact paths and summarize relevant evidence.

### Accessible tab behavior

- Use stable button IDs.
- Use `role="tablist"`, `role="tab"`, and `role="tabpanel"`.
- Pair `aria-controls`, `aria-labelledby`, and `aria-selected` correctly.
- Support Left, Right, Home, and End keyboard navigation.
- Avoid clipped or overlapping text at desktop and mobile widths.
- Keep all content readable if JavaScript fails.

## 8. Validate the result

Follow `superpowers:verification-before-completion`: run each check, read its
output, and quote the evidence before claiming it passed.

Run all applicable checks:

1. Parse every generated JSON artifact. In `findings.json`, confirm every id is
   unique, has a category, a path and an anchor, and holds no line number, and
   that the report's High/Medium/Low counts match its `new` and `open` findings.
2. Parse `scanner-aggregate-report.html` with Python's standard-library
   `html.parser`.
3. Verify all tab IDs, panel IDs, `aria-controls`, and `aria-labelledby` values
   are unique and paired.
4. Search for stale SHAs (the baseline commit in the delta line is not one), old
   dates, removed paths, placeholder scores, `TODO`, `TBD`, and sample data.
5. Confirm a tab exists for every active lane, the Overview lists every inactive
   lane with its reason, and the skill coverage table has a row for every roster
   skill.
6. Confirm source locations refer to the current commit.
7. Confirm no secret, token, credential, or sensitive environment value appears.
8. Confirm the report has no external network dependency.
9. If browser preview is available, smoke-test all tabs, keyboard navigation,
   desktop layout, mobile layout, and clipping/overlap. Do not claim browser
   validation when unavailable.
10. Run `git status --short --branch`.

## 9. Propose stack-profile updates

The installed skill may be read-only. Never edit it. Write proposals under
`.scanner-report-artifacts/proposed-stacks/` for the user to promote.

For each unprofiled stack:

1. Pick one established, read-only analyzer from that ecosystem's standard
   toolchain: a linter or static analyzer with a machine-readable output mode
   and no upload, autofix, or external-LLM behavior.
2. Trial it ephemerally (section 3 bootstrap paths) on the stack's files,
   capturing version, command, exit status, and output under
   `.scanner-report-artifacts/candidates/<stack>/`.
3. Report its output in Raw Sources as `candidate lane, unvalidated`. Its
   findings reach the Priority Matrix only after source validation under section
   6, like any other finding.
4. Write `proposed-stacks/<stack>.md` by filling
   [stacks/_template.md](stacks/_template.md) with what this trial observed: the
   `Detect:` predicate, exact command, exit-status meaning, success check,
   extraction, and the noise you saw. Record what the trial left unverified.

For each broken profile (section 5.1), write
`proposed-stacks/<stack>.feedback.md` with the failing command, the error, the
tool version, and the corrected command if one ran successfully. Write one too
for an active profile whose Provenance carries a `shortcut:` note, giving the
values this run observed for the fields the note says are missing.

If the trial failed or no suitable analyzer exists, still write the proposal
with the failure recorded.

## 10. Return the handoff

Return a concise summary containing:

- Whether update/rebase onto `origin/main` succeeded.
- Current branch, commit, and ahead/behind counts.
- A link to `scanner-aggregate-report.html`.
- High/Medium/Low counts.
- The most important validated findings.
- Detected stacks, active lanes, and successful and failed tools.
- Whether this is a full or an incremental run, with the delta counts, and the
  path of `findings.json` to hand the next run as its baseline.
- Validation performed.
- Browser-preview limitations.
- Proposed stack profiles, each with its path and the promote step: copy it to
  `~/.config/home-manager/dotfiles/skills/aggregate-code-quality-report/references/stacks/`
  and rebuild home-manager.
- Generated files shown by final Git status.

Do not dump every scanner finding into chat; the HTML report is the detailed
artifact.
