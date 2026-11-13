---
name: progress-party
description:
  Live party progress bar for running subagents; the glory scales with progress.
disable-model-invocation: true
argument-hint: "[which subagents to track]"
---

# Progress party

You classify; `render.py` (next to this file) does the arithmetic and the glory.
Never compute a percentage or pick a tier yourself.

## 1. Roster

The **roster** is the list of units to track:

- With arguments: the subagents they name.
- Without: every subagent, background task and delegate launched for the request
  the user made before typing this command, finished ones included. Units
  launched for earlier requests stay off.

Per unit, record a `label` (≤ 32 chars, what the unit does, never its id) and
its source, read with the matching tool:

| Source           | Read with                                        |
| ---------------- | ------------------------------------------------ |
| output file      | `Read` / `tail`                                  |
| delegate task id | its status tool (T3 Code: `task_status`)         |
| thread id        | its thread-read tool (T3 Code: `t3_thread_read`) |

Done when every unit has a label and a source. The roster only grows: a unit
launched later is appended, a finished unit stays.

## 2. Snapshot

Read every unit's source now. The source's content decides the state, never a
notification alone. Give each unit exactly one state; the first matching rule
wins:

1. `failed`: ended with an error, was cancelled or killed, or its final report
   says it could not do its task.
2. `done`: ended with a final report. Bad news the unit was asked to find
   (failing tests, bugs, findings) still counts as `done`.
3. `queued`: its status says it is waiting to start (queued, pending).
4. `running`: launched, not ended.

Per unit also set:

- `detail`, ≤ 40 chars:
  - `failed`: the cause.
  - `done`: the result.
  - `running`: the last line that states a count, a percentage or a step,
    shortened; `started` when there is none.
  - `queued`: `queued`.
- `frac`: `running` units only, and only when the last such line states `k` of a
  total `n` (`3 of 7`, `3/7`, `step 2 of 5`) or a percentage (`60%`,
  `about 60%`). Write `k/n` or the percentage as a fraction rounded to 2
  decimals (`0.43`, `0.4`, `0.6`). A number without a total (`step 2`,
  `processed 38 files`) gives no frac.

Write `party/state.json` in the scratchpad:

```json
{
  "title": "Auth review",
  "units": [
    {
      "label": "Security review",
      "state": "running",
      "detail": "3/7 files reviewed",
      "frac": 0.43
    }
  ]
}
```

`title` is ≤ 40 chars naming the overall work. Done when every roster unit has a
state and a detail read from its source in this snapshot.

## 3. Render

```sh
python3 <skill dir>/render.py <scratchpad>/party/state.json <scratchpad>/party/party.html
```

It prints a summary JSON with `pct`, `tier`, `headline` and `ascii`. Show the
page with an inline-HTML render tool, passing the file's contents (T3 Code:
`html_render`, `title` from state.json, height 720). With no such tool, print
`ascii` in a code block.

Your reply text is one line: on the first render, `pct` and the four state
counts from the summary; after that, the units whose state changed.

## 4. Monitor

After the first render, start one `Monitor` that runs `tail -F` on the output
files of the units still `running` or `queued`. Restart it on the new file set
whenever the roster grows, and when it times out while units are still open.

On every event (a Monitor line, or a completion notification), run Snapshot
again; units without an output file are re-read with their status tool then.
Render only when `state.json` changed. Between events, end your turn; the events
wake you.

Monitoring ends when one of these is true, after a final render:

- Every unit is `done` or `failed`.
- The only open units have no output file. Say which ones, and that
  `/progress-party` again picks them up.

Then stop the Monitor (`TaskStop`) and say monitoring has ended.
