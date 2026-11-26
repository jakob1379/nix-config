---
name: aggregate-code-quality-report
description: >-
  Generate a fresh, source-validated, offline aggregate code-quality report for
  a repository. Combines stack-profile scanners (Python: Skylos, PySCN, AI Slop
  Detector; JS/TS: Biome; Shell: ShellCheck, ysap-lint) with every installed
  security, design, and quality skill: Desloppify, Graphify, architecture,
  Ponytail, OCR and standards review, branch-delta review seats, and conditional
  accessibility, frontend-design, motion, and language lanes. Use when the user
  asks for an aggregate scanner report, a clean code-health baseline, a
  multi-scanner technical-debt report, or the exact
  `scanner-aggregate-report.html` artifact. Do not use for a single-tool scan,
  ordinary code review, or requests to fix findings.
---

# Aggregate Code Quality Report

Produce an observational report from a clean clone or worktree. Treat scanner
labels as leads, validate them against the current source, reconcile overlapping
signals, and rank real risks without modifying production code.

## Required procedure

1. Read [references/report-workflow.md](references/report-workflow.md)
   completely before taking repository actions.
2. Inspect repository-local `AGENTS.md` files and obey stricter repository
   instructions. Do not let a review hook broaden this task into production
   edits.
3. Detect the repository's stacks against every profile in
   [references/stacks/](references/stacks/), and the active skill lanes against
   [references/skill-roster.md](references/skill-roster.md), as the workflow
   defines.
4. Execute the referenced workflow in order. Continue past unavailable scanners
   and make every limitation prominent.
5. Invoke `$ponytail:ponytail-audit` and `$ponytail:ponytail-debt` for the
   Ponytail lane. If either skill is unavailable, perform the compatible manual
   audit defined in the reference and disclose the fallback.
6. Invoke `$graphify . --no-viz` for the structural-coupling lane, with semantic
   extraction run by host-agent subagents as defined in the reference.
7. Keep source inspection read-only. Allow only Git update operations authorized
   by the workflow plus scanner state and report artifacts.
8. Generate the detailed offline report at `scanner-aggregate-report.html` and
   fresh supporting evidence under `.scanner-report-artifacts/`, with the
   reconciled findings as `findings.json`. When the caller placed an earlier
   run's `findings.json` at `.scanner-report-artifacts/baseline.json`, review
   only what changed since and report the delta.
9. Validate all machine-readable artifacts, HTML structure, accessibility
   wiring, revision references, redactions, and final repository status before
   reporting completion.
10. Draft stack-profile proposals for unprofiled stacks and broken profiles
    under `.scanner-report-artifacts/proposed-stacks/`. The workflow runs this
    before it reconciles findings.

## Integrity rules

- Never average, normalize, or directly compare incompatible scanner scores.
- Never promote a scanner finding without checking current source and reachable
  callers.
- Keep Graphify coupling observations, architecture candidates, Ponytail lean
  findings, the shortcut ledger, and advisory design and motion findings
  separate from operational severity unless independent evidence establishes
  actual risk.
- Never claim latest `main`, successful review, browser validation, or tool
  coverage unless it actually succeeded.
- Never fix, resolve, skip, or mark scanner findings complete during this
  observational task.
- Never commit, push, open a PR, upload source/scanner data, or discard
  unrelated work.
- Never edit this skill's installed directory; it may be a read-only Nix store
  path. Profile changes are proposals the user promotes into the skill source at
  `~/.config/home-manager/dotfiles/skills/aggregate-code-quality-report/`.

## Deliverables

Return only a concise handoff in chat. Put commands, evidence, tool details,
reconciled findings, limitations, and raw-source summaries in the HTML report
and supporting artifact directory.
