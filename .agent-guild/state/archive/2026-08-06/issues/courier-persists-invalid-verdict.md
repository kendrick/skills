Surfaced by a live guild run of `kendrick/skills#16` on a Claude host. A courier persisted a verdict file that is not valid JSON. `validate-verdict.py` rejects it, so nothing downstream can read it — but it sits at the canonical lane-suffixed stem, where a later reader takes it for a recorded second opinion.

The courier contract already says what should have happened: retry the lane once, and after a second invalid response emit a schema-conforming `blocked` verdict carrying the raw response as evidence, never repairing vendor JSON. Instead the raw response went straight to disk unvalidated.

## Steps to Reproduce

1. Run a codex crossing whose vendor response embeds unescaped double quotes inside a JSON string value. In the observed case the vendor wrote an `evidence` field containing `sections "An aborting lint still fails verification" and "One planted lint defect."`, so the string terminated early.
2. Let the courier persist its verdict.
3. Validate the artifact it wrote:

   ```bash
   python3 .agent-guild/scripts/validate-verdict.py \
     .agent-guild/state/verdicts/T-003-sonnet-r0-codex.json
   ```

## Observed vs. Expected

**Observed:** exit 1, `malformed JSON: Expecting ',' delimiter: line 1 column 446 (char 445)`. The file is 3647 bytes of unparseable text at the canonical stem, with a rendered `.md` sibling beside it. No `blocked` verdict was emitted and the lane was not retried.

**Expected:** the courier validates before persisting. A response that fails validation twice becomes a schema-conforming `blocked` verdict whose evidence carries the raw text, and the stem holds a file every reader can parse.

## Error Output

```
validate-verdict: .agent-guild/state/verdicts/T-003-sonnet-r0-codex.json: malformed JSON: Expecting ',' delimiter: line 1 column 446 (char 445)
```

## Why it matters

An unparseable verdict is worse than an absent one. An absence is visible — the #34 comparison records it and moves on. This file exists, sits where a valid verdict goes, and only fails when something tries to read it. In this run the task's `## Courier comparison` was written on findings recovered from it by tolerant read, which means a human decided to parse by eye what a validator had already rejected.

It also cannot be cleaned up by the orchestrator without crossing a line: repairing a verdict you also commissioned makes you the author of your own check. So a malformed verdict is stuck on disk until someone rules on it by hand.

Related but distinct: #84 covers the lane's missing script, divergent timeout handling, and unreliable ledger fields. This is specifically the validate-before-persist gap, which a shared `codex-courier.py` would be the natural place to close.

## Acceptance Criteria

- [ ] No path writes a verdict to the lane-suffixed stem without it passing `validate-verdict.py` first.
- [ ] A vendor response that fails validation is retried once on the same fixed lane.
- [ ] A second failure produces a schema-conforming `blocked` verdict carrying the raw response as evidence, and the raw text is preserved somewhere inspectable.
- [ ] Vendor JSON is never repaired, reformatted, or re-serialized on the way to disk.
- [ ] A test drives a deliberately malformed vendor response through the courier path and asserts a `blocked` verdict lands rather than the malformed text.

## For a Coding Agent

- **Verify with:** `python3 hooks/test_hooks.py`
- **Setup:** stdlib only. `scripts/validate-verdict.py` is the existing validator, and it already enforces the two semantic rules the schema can't express.
- **Start here:** `scripts/claude-courier.py` handles the Codex→claude direction and is the model to mirror; `agents/checker-courier.md` steps 4 and 5 carry the retry-then-blocked contract that was not followed; `schemas/verdict.schema.json` is what conformance means.
- **Done when:** a malformed vendor response cannot reach the verdict stem, and the failure is recorded as a `blocked` second opinion instead.
- **Out of scope:** timeout policy and ledger field correctness, both tracked in #84.
