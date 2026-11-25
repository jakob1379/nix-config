# Stack profile: <Stack name>

Detect: <observable predicate over tracked files, e.g. "10 or more tracked `.go`
files, or a tracked `go.mod`">

Tools, in tab order:

- <Tool>: <one line: what it is good at>.

Production targets: <which paths the tools scan and how to record them>.

## <Tool>

Version rule: <pinned version or how to resolve one; record the resolved
version>.

Run:

```bash
<exact ephemeral command; machine-readable output written under
.scanner-report-artifacts/>
```

Never: <autofix, write, upload, or external-LLM flags to avoid>.

Exit status: <what each exit code means; which ones are "findings present"
rather than failure>.

Success check: <the artifact property proving the run worked>.

Extract: <metrics and fields to pull from the output>.

Triage: <which rule categories to validate every time, sample, or treat as Low>.

Known noise: <false-positive patterns seen in trials>.

Provenance: proposed <YYYY-MM-DD> from <repository>@<short SHA> with <tool>
<version>. Unverified: <what the trial did not exercise>.
