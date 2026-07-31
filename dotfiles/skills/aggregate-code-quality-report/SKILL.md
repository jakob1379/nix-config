---
name: aggregate-code-quality-report
description:
  Generate a fresh, source-validated, offline aggregate code-quality report for
  a repository using Skylos, PySCN, AI Slop Detector, Desloppify, and Ponytail
  Audit. Use when the user asks for an aggregate scanner report, a clean
  code-health baseline, a multi-scanner technical-debt report, or the exact
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
3. Execute the referenced workflow in order. Continue past unavailable scanners
   and make every limitation prominent.
4. Invoke `$ponytail:ponytail-audit ultra` for the simplification lane. If that
   skill is unavailable, perform the compatible manual audit defined in the
   reference and disclose the fallback.
5. Keep source inspection read-only. Allow only Git update operations authorized
   by the workflow plus scanner state and report artifacts.
6. Generate the detailed offline report at `scanner-aggregate-report.html` and
   fresh supporting evidence under `.scanner-report-artifacts/`.
7. Validate all machine-readable artifacts, HTML structure, accessibility
   wiring, revision references, redactions, and final repository status before
   reporting completion.

## Integrity rules

- Never average, normalize, or directly compare incompatible scanner scores.
- Never promote a scanner finding without checking current source and reachable
  callers.
- Keep Ponytail simplification findings separate from operational severity
  unless independent evidence establishes actual risk.
- Never claim latest `main`, successful review, browser validation, or tool
  coverage unless it actually succeeded.
- Never fix, resolve, skip, or mark scanner findings complete during this
  observational task.
- Never commit, push, open a PR, upload source/scanner data, or discard
  unrelated work.

## Deliverables

Return only a concise handoff in chat. Put commands, evidence, tool details,
reconciled findings, limitations, and raw-source summaries in the HTML report
and supporting artifact directory.
