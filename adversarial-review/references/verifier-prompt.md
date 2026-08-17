# Verifier prompt

Read this at Step 5, once, then instantiate.

## Why a separate agent

A verifier that shares context with the finder is the same mistake as running several review personas in one window: the reasoning that produced the claim is sitting right there, and agreeing with it is the path of least resistance. So the verifier is a fresh subagent that never saw the finder's work.

It receives exactly five fields per finding—`id`, `file`, `quoted_evidence`, `claim`, `proposed_repro`—and no others. In particular it never receives `proposed_fix`, which is the finder's reasoning in disguise: a proposed fix tells you what the finder believed the bug was, and a verifier who reads it inherits the belief it was supposed to test independently.

Batch one territory-round's findings into one verifier at Depth 0 and 1. At Depth 2, dispatch one verifier per finding—more independence, more cost, worth it when the diff is high-stakes.

Model: opus at Depth 1 and 2. Verification is the judgment-heavy half of this process, and it is the wrong place to save money.

## Template

```
You are checking whether a claim about code is actually true. You did not
write this claim and you have no stake in it.

Your job is to make each claim fall over. Run the command, read the code, and
look for the reason it is wrong: the guard elsewhere that already handles this,
the caller that never passes that value, the test that already covers it.
REPRODUCED is the verdict you failed to avoid, not the one you are aiming for.

For each finding below, land on exactly one of three states.

REPRODUCED—you ran something and watched the claim be true. Record the exact
command and its actual output. Paste what the terminal printed; a summary of
output you did not capture is the failure mode this entire process exists to
prevent.

NOT_REPRODUCED—you have counter-evidence. The command ran clean, or the code
does something other than what the claim says. Record what you found. Closing a
finding is a claim too, and it carries the same evidence bar as making one.

UNVERIFIABLE—you could not check it. Record why: a missing fixture, an
environment you cannot reach, a claim too vague to test, a repro command that
would change state. This is an honest answer and it is better than a guess in
either direction.

Command safety: run read-only commands and test runners only—grep, cat, git
log, pytest, go test, npm test and their like. Where a proposed repro would
write, migrate, deploy, send a request that changes something, or touch
anything outside this repo, do not run it. Mark that finding UNVERIFIABLE with
the reason "unsafe repro" and say what it would have done. You may substitute a
safe command that tests the same claim, and where you do, record the command
you actually ran rather than the one you were given.

Findings to check:

{{LEDGER_RECORDS}}

Your final message is exactly one fenced json block and nothing else:

```json
{
  "events": [
    {
      "finding_id": "F-r1-money-01",
      "disposition": "REPRODUCED",
      "repro_command": "the command you actually ran",
      "observed_output": "what it actually printed",
      "counter_evidence": null,
      "reason": null
    }
  ]
}
```

Every key is present on every event. Fill the ones your verdict earns and leave
the rest null—REPRODUCED needs `repro_command` and `observed_output`,
NOT_REPRODUCED needs `counter_evidence`, UNVERIFIABLE needs `reason`. A value
invented to fill a field is indistinguishable from a real one later, which is
why null is the right answer where nothing was observed.
```

## Placeholder

- `{{LEDGER_RECORDS}}` — a JSON array of the findings to check, each carrying `id`, `file`, `quoted_evidence`, `claim`, and `proposed_repro`. Build it by selecting those five keys explicitly. Selecting explicitly rather than deleting `proposed_fix` from a full record means a later field added to the finding schema cannot leak into the verifier by default.

## Recording the result

Each returned event maps field-for-field onto `ledger.py append-event`, plus an `--actor` naming this verifier (`verifier-r<round>-<territory>`). The actor field is what makes the isolation auditable after the fact: a verification event whose actor is the finder is the failure this gate exists to catch.

`ledger.py` enforces the evidence rules, so a REPRODUCED event with no observed output is rejected at the append rather than discovered later.
