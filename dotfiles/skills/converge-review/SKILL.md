---
name: converge-review
description:
  Orchestrate an independent multi-reviewer loop over the current changes using
  open-code-review, ponytail-review, superpowers requesting-code-review, and
  mattpocock code-review, gated by the project's own executed checks and fixing
  between rounds until the fixes verify clean. Manual only: invoke with
  /converge-review.
disable-model-invocation: true
---

# Converge Review

You are the orchestrator. You do not review. Subagents review independently,
executed checks supply ground truth, and you fix and verify until both agree.

Same-family reviewers share blind spots, so four seats are not four independent
votes. Fresh full re-reviews of a nondeterministic reviewer find something new
every round. The loop therefore converges on evidence: one broad review, then
scoped verification of the fixes.

## Seats

| Seat                                 | Role        | Hunts                                        |
| ------------------------------------ | ----------- | -------------------------------------------- |
| `open-code-review:delegate-review`   | correctness | bugs, security, error handling, concurrency  |
| `superpowers:requesting-code-review` | correctness | bugs, plan alignment, tests, production risk |
| `ponytail:ponytail-review`           | advisory    | over-engineering only                        |
| `mattpocock-skills:code-review`      | advisory    | spec compliance, documented standards only   |

Advisory findings may be accepted and fixed, but never block convergence. If a
reviewer from another model family is available (e.g. a `codex` CLI), give it
one correctness seat — diversity buys more than seat count.

## Loop

1. **Pin the inputs.** Choose the base once. Write the whole change, including
   uncommitted and untracked files, to one patch file outside the repo
   (`git diff <base>`, plus `git diff --no-index /dev/null <file>` per untracked
   file). Record the spec or plan path, or the literal "no spec". Every dispatch
   reviews that patch file — the seats otherwise disagree on what a diff is
   (workspace, `BASE..HEAD`, merge-base).
2. **Run the gate.** Discover the project's own checks — CI workflows, task
   runner, build, tests, linters, type checker — and run them. A failure is a
   finding with ground truth behind it. No runnable checks means the review is
   unanchored; say so in the deliverable.
3. **Round 1: full review.** Dispatch all four seats in parallel — one Agent
   call each, in a single message. Each gets the patch path, the spec or "no
   spec", the override block below, and the instruction to invoke exactly its
   one skill. Keep them blind: never pass one seat's findings to another.
4. **Merge.** Deduplicate by `file:line` + claim. Normalise severity to Critical
   / Important / Minor. Record for each finding: seats that raised it, severity,
   and verdict — fix, reject with a reason, or defer with a `ponytail:` comment.
   Agreement between correlated seats is weak evidence, not authority.
5. **Fix.** Before fixing an accepted Critical or Important finding, make it
   **red**: a test, or failing that a repro command, that fails on the pinned
   code. The fix turns it green and the test stays in the suite, so the fix
   keeps a guard. A claim you cannot make red keeps its severity, is marked
   unverified, and is deferred with the exact check that would settle it (live
   hardware, external system). Reproducibility is evidence, not impact. Apply
   the smallest change that turns red to green; every changed line is the next
   round's review surface. Never fix by adding an abstraction a reviewer merely
   speculated about. Re-run the gate.
6. **Rounds 2+: scoped re-review.** Write the fix diff (the head the last review
   saw → now) to a patch file. Dispatch fresh agents on the correctness seats
   only, each with the fix patch and the accepted findings, unattributed. Each
   verdicts every finding addressed or not, and reports new breakage inside the
   fix diff only. Issues in code the fix did not touch go to the ledger as
   non-blocking, not into the loop. Fresh agents every round — one that saw
   round N will rubber-stamp round N+1.

## Override block

Paste into every dispatch verbatim. The seats' own instructions conflict with
this loop (auto-fixing, asking the user, spawning reviewers); this block wins.

> Report only. Do not edit files or apply fixes. Do not ask the user anything;
> if an input is missing, state your assumption and continue. Do not spawn
> agents or invoke any other review skill or command; review directly. Review
> only the given patch file, reading surrounding source for context. For each
> finding give file:line, severity (Critical / Important / Minor), the claim,
> and the evidence. For Critical or Important, include a command or test that
> fails on the patched code when you can; otherwise say the claim is reasoned.
> Report spec gaps and breaches of documented standards; leave generic code
> smells out. List every file in the patch you did not review, and why.

## Rejections

Every rejection is a ledger entry with its reason; silent discards are
forbidden. Rejecting a Critical or Important finding from a correctness seat
needs evidence — a source citation or a gate result. Without it, dispatch one
fresh verifier agent with only that finding and the patch, and follow its
verdict.

## Convergence

Converged when all hold:

- The gate passes, or its failures pre-exist on the base and are listed.
- A scoped re-review verdicts every accepted Critical and Important finding
  addressed.
- That re-review reports no new breakage in the fix diff.

Cap: three fix rounds — gains saturate around there, and later rounds trade
churn for regressions. The last round is always a re-review, never a fix:
unreviewed fixes are how regressions land. Hitting the cap is not convergence.
Say so explicitly and list what is still open.

## Rules

- Never review the diff yourself, in any round. If you catch yourself reading
  code to form an opinion, dispatch instead.
- Never let a reviewer edit files. Reviewers report; you apply.
- Never claim convergence you have not observed. A round or gate run that
  errored out is a failure, not a clean result.

## Deliverable

- A findings table — seat(s), file:line, severity, verdict, the red test behind
  each accepted Critical or Important fix, and the evidence behind each
  rejection.
- Gate results from the first and last run.
- Coverage — files any seat skipped and why, and axes that did not run (no spec,
  no standards docs, no runnable checks).
- Round count, what converged, and what remains open and why.
