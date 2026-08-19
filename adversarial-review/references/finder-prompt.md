# Finder prompt

Read this at Step 3, once, then instantiate one prompt per territory.

## Dispatching

Use general-purpose subagents. Stake-neutral matters here: a review of this repo's own contracts must not be run by this repo's own auditor or checker agents, because an agent with a stake in the standard being reviewed is grading its own homework. A general-purpose agent has no such stake.

Dispatch every territory in the same turn so they run concurrently. They share no state and must not—the confidence mechanism in this design is verification, not agreement, and finders who can see each other's work produce correlated findings that look like agreement.

Model per the territory's `model_tier` from the scope contract.

If a finder returns something that does not parse as the contract below, re-prompt it once with the contract restated. Still unparseable, mark the territory failed in the run notes rather than hand-editing its output into shape—a finding you had to repair is a finding you partly authored. A failed territory reports as UNREVIEWED in the final report.

## Template

Substitute the five placeholders. Everything else goes across verbatim.

```
You are reviewing one territory of a code diff, adversarially.

The diff under review:

    {{DIFF_CMD}}

Your territory—review only these paths, and nothing else in the diff:

{{TERRITORY_ENTRIES}}

What to be suspicious of in this territory, and what to hunt:

{{CLASSES_AND_HUNT_ITEMS}}

Out of scope. These are settled. Reporting one is a false positive, no matter
how wrong it looks to you:

{{OUT_OF_SCOPE}}

{{PRIOR_ROUNDS}}

Two rules govern everything you report:

1. Verify against code. A comment, a docstring, a commit message, a variable
   name, and a test name are all claims about the code, not evidence of it.
   Where a comment says the tenant filter is applied, your job is to find the
   line that applies it. When the code and the comment disagree, you have
   found something.

2. Every finding needs a reproduction command someone else could run without
   your reasoning: a test invocation, a grep, a script. Someone who does not
   trust you, and cannot see how you reached this, will run that command and
   decide whether you were right. Write the command for that reader.

Rank your findings by how much they matter, most first.

Severity is two values. `blocking` means this should not merge. `advisory`
means it should be fixed but need not gate the merge. Use `blocking` where you
mean it—an inflated severity spends someone's time writing a failing test
for something that did not need one.

Finding nothing is a complete and legitimate report. An empty findings array
is a real answer, and manufacturing a finding to look thorough corrupts the
one thing this process is for.

Your final message is exactly one fenced json block and nothing else—no
preamble, no summary paragraph, no closing assessment. This shape:

```json
{
  "territory": "{{TERRITORY_NAME}}",
  "works": "one line on what in this territory is genuinely sound",
  "findings": [
    {
      "file": "path/to/file.py",
      "quoted_evidence": "the exact code this is about, copied verbatim",
      "claim": "one falsifiable statement of what is wrong and why",
      "proposed_fix": "the concrete change",
      "proposed_repro": "a single read-only or test-runner command",
      "claimed_severity": "blocking"
    }
  ]
}
```
```

## Placeholders

- `{{DIFF_CMD}}` — the scope contract's `diff_cmd`, verbatim. It names the pinned merge-base SHA, so every territory reviews the same code.
- `{{TERRITORY_ENTRIES}}` — this territory's `entries`, one per line.
- `{{CLASSES_AND_HUNT_ITEMS}}` — for each class in this territory, its name and its hunt items from [trigger-table.md](trigger-table.md).
- `{{OUT_OF_SCOPE}}` — the scope contract's `out_of_scope` list, verbatim and complete. Every finder gets the whole list, including items about territories they do not own; a shortened list per territory is how a settled decision gets re-litigated by the one finder who was not told.
- `{{PRIOR_ROUNDS}}` — empty in round 1. Afterward: what previous rounds found in this territory, which of those fixes landed, and which fixes introduced new blockers. That last part is the reason the round loop exists, and a finder who knows it hunts the fix rather than re-hunting the original.
- `{{TERRITORY_NAME}}` — this territory's name, so the returned JSON identifies itself.

## Why the output is only JSON

The orchestrator copies fields straight from this block into `ledger.py` flags. No parsing step, no interpretation, nothing that could drift between what the finder meant and what the ledger records. A prose summary alongside the JSON reintroduces exactly that gap, which is why the template asks for the block alone.
