---
name: converge-review
description:
  Orchestrate an independent multi-reviewer loop over the current changes using
  open-code-review, ponytail-review, superpowers requesting-code-review, and
  mattpocock code-review, fixing between rounds until the reviewers converge.
  Use when the user asks for a converged review, a multi-reviewer review, a
  review loop, "review until settled", or invokes /converge-review. Do not use
  for a single-pass review or when only one reviewer was requested.
---

# Converge Review

You are the orchestrator. You do not review. Subagents review independently; you
fix and re-dispatch until they stop finding things.

## Loop

1. **Fix the scope.** Establish the diff once (`git diff <base>...HEAD` or the
   working tree) and reuse the identical scope for every round. State the base
   in every dispatch so reviewers see the same code.
2. **Dispatch all four reviewers in parallel** — one Agent call per reviewer,
   all in a single message. Each agent gets: the scope, the round number, and
   the instruction to invoke exactly one skill:
   - `open-code-review:delegate-review`
   - `ponytail:ponytail-review`
   - `superpowers:requesting-code-review`
   - `mattpocock-skills:code-review`
3. **Keep them blind.** Never pass one reviewer's findings to another, in any
   round. Independent signal is the only reason to run four of them.
4. **Merge.** Deduplicate by `file:line` + claim. Record for each finding: which
   reviewers raised it, severity, and your verdict — fix, reject with a reason,
   or defer with a `ponytail:` comment.
5. **Fix.** Apply accepted fixes yourself. Reject freely: agreement across
   reviewers is evidence, not authority, and a finding you can disprove against
   the source is noise. Never fix by adding an abstraction a reviewer merely
   speculated about.
6. **Re-dispatch** a fresh set of agents on the updated diff. Fresh context, no
   history — an agent that saw round N will rubber-stamp round N+1.

## Convergence

Stop when either holds:

- A full round produces no new accepted finding (repeats of things you already
  rejected with a stated reason do not count as new), or
- Round 4 completes.

Hitting the round cap is not convergence. Say so explicitly and list what is
still open.

## Rules

- Never review the diff yourself, in any round. If you catch yourself reading
  code to form an opinion, dispatch instead.
- Never let a reviewer edit files. Reviewers report; you apply.
- Never re-dispatch a reviewer that returned an empty round unless the diff
  changed since.
- Never claim convergence you have not observed. A round that errored out is a
  failed round, not a clean one.

## Deliverable

A table of findings — reviewer(s), file:line, verdict — plus the round count,
what converged, and what remains open and why.
