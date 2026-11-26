# Skill roster

Every installed skill that improves security, design, or quality, and how this
report uses it. The report's Overview lists each row's status: `used`,
`fallback`, `not applicable: <predicate>`, or `missing`.

## Loading a skill

`<name>` below is the skill's name without its plugin prefix: `ponytail-audit`
for `ponytail:ponytail-audit`.

A row marked `(built-in)` is never read from disk: when the host does not offer
it, mark it `missing`. For every other row, look beside this skill first. When
`<the directory you loaded this skill from>/../<name>/SKILL.md` exists, read
that file and follow only the steps named here: it is the copy pinned with this
skill, as in the `agent-skills` package. Use the path you were given, not its
resolved target.

Otherwise invoke the skill by name. When it is marked
`disable-model-invocation`, absent from the host's skill list, or installed for
another agent, read its `SKILL.md` instead and follow only the steps named here:

```bash
find -L ~/.claude/skills ~/.agents/skills -path '*/<name>/SKILL.md' | head -1
```

If it is not installed, use the fallback in its lane section and mark it
`missing` or `fallback`. Every skill runs under this report's rules: read-only
on source, offline report, no fixes, no commits, no files in the repository
outside `.scanner-report-artifacts/`, the report, and the scanner state of lanes
5.2 and 5.3 (`.desloppify/`, `graphify-out/`). Where a skill's own steps write
files anywhere else, open a browser, ask the user, or apply fixes, skip those
steps.

## Predicates

- **UI**: tracked `.html`, `.jsx`, `.tsx`, `.vue`, `.svelte`, `.astro`, or
  server templates (`.jinja`, `.j2`, `.hbs`, `.erb`, `.ejs`).
- **Web UI**: UI, plus CSS or a browser framework (`.css`, `.scss`, Tailwind,
  React, Vue, Svelte, Astro).
- **Motion**: UI source containing `transition`, `animation`, `@keyframes`,
  `requestAnimationFrame`, or a dependency on `motion`, `framer-motion`,
  `react-spring`, `gsap`, `@react-spring/*`, `react-native-reanimated`.
- **Gestures**: Motion, plus drag, swipe, or pointer-tracking code, or a
  dependency on `vaul`, `@use-gesture/*`, `react-native-gesture-handler`.
- **Expo**: a `package.json` depends on `expo` or `react-native`.
- **Sonner**: a `package.json` depends on `sonner`.
- **Swift**: a tracked `.swift` file.
- **Branch delta**: the current branch has commits not in `origin/main`.

## Lanes and roles

| Skill                                             | Area             | Role                                                | When         |
| ------------------------------------------------- | ---------------- | --------------------------------------------------- | ------------ |
| `desloppify`                                      | quality          | lane 5.2                                            | always       |
| `graphify`                                        | design           | lane 5.3                                            | always       |
| `mattpocock-skills:codebase-design`               | design           | vocabulary for 5.3 and 5.7                          | always       |
| `mattpocock-skills:improve-codebase-architecture` | design           | lane 5.7, step 1 only                               | always       |
| `mattpocock-skills:domain-modeling`               | design           | 5.7 reads `GLOSSARY.md` and ADRs; never writes      | always       |
| `ponytail:ponytail-audit`                         | security/quality | lane 5.4                                            | always       |
| `ponytail:ponytail-debt`                          | quality          | lane 5.5                                            | always       |
| `open-code-review:delegate-review`                | security/quality | lane 5.8 rules; branch-delta seat in 5.9            | always       |
| `mattpocock-skills:code-review`                   | quality          | lane 5.8 Standards axis; branch-delta seat in 5.9   | always       |
| `security-review` (built-in)                      | security         | branch-delta seat in 5.9                            | Branch delta |
| `code-review` (built-in)                          | security/quality | branch-delta seat in 5.9, level `medium`            | Branch delta |
| `ponytail:ponytail-review`                        | quality          | branch-delta seat in 5.9                            | Branch delta |
| `superpowers:requesting-code-review`              | quality          | branch-delta seat in 5.9                            | Branch delta |
| `converge-review`                                 | quality          | 5.9 seat isolation and merge rules, no fix loop     | Branch delta |
| `design:accessibility-review`                     | design           | lane 5.6                                            | UI           |
| `design:design-system`                            | design           | lane 5.10                                           | UI           |
| `design:ux-copy`                                  | design           | lane 5.10                                           | UI           |
| `frontend-design`                                 | design           | lane 5.10 rubric                                    | UI           |
| `emil-design-eng`                                 | design           | lane 5.10 rubric                                    | UI           |
| `apple-design`                                    | design           | lane 5.10 rubric                                    | UI           |
| `mobile-native`                                   | design           | lane 5.10 rubric                                    | Web UI       |
| `ask-sonner`                                      | design           | lane 5.10 rubric for toast usage                    | Sonner       |
| `improve-animations`                              | design           | lane 5.11 driver                                    | Motion       |
| `review-animations`                               | design           | lane 5.11 rubric                                    | Motion       |
| `animation-performance`                           | design/quality   | lane 5.11 rubric                                    | Motion       |
| `remove-animations`                               | design           | lane 5.11 criteria only; its edits are skipped      | Motion       |
| `find-animation-opportunities`                    | design           | lane 5.11, advisory                                 | Motion       |
| `gestures`                                        | design           | lane 5.11 rubric                                    | Gestures     |
| `animate-expo`                                    | design           | lane 5.11 rubric for React Native motion            | Expo         |
| `write-swift`                                     | security/quality | lane 5.12 rubric                                    | Swift        |
| `superpowers:dispatching-parallel-agents`         | process          | section 5: run independent lanes in parallel        | always       |
| `superpowers:receiving-code-review`               | process          | section 6: verify every finding before accepting it | always       |
| `superpowers:verification-before-completion`      | process          | section 8: evidence before any completion claim     | always       |
| `unslop`                                          | quality          | section 7: prose pass on report text                | always       |
| `dataviz`                                         | design           | section 7: any chart, as inline SVG                 | always       |

## Installed but excluded

List these in the Overview's skill coverage as `excluded: <reason>`.

- Apply fixes or edit code: `simplify`, `open-code-review:review`, `break-ui`.
- Build, fix, or plan workflows: `superpowers:test-driven-development`,
  `mattpocock-skills:tdd`, `superpowers:systematic-debugging`,
  `mattpocock-skills:diagnosing-bugs`, `superpowers:writing-plans`,
  `superpowers:executing-plans`, `superpowers:subagent-driven-development`,
  `superpowers:brainstorming`, `animate`, `choreograph`.
- Interactive or routing only: `mattpocock-skills:grilling`,
  `mattpocock-skills:grill-me`, `mattpocock-skills:grill-with-docs`, `ask-emil`,
  `pick-ui-library`, `animation-vocabulary`, `learn-taste`.
- Need a rendered UI, screenshots, or design files: `design:design-critique`,
  `design:design-handoff`.
- Write docs: `openwiki`.
- Publishing contract conflicts with an offline local report: `artifact-design`.
