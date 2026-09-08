# jira-refine—evals

The smoke test (`bash tests/jira-refine-smoke.sh`) pins the scripts against fixtures: `segment.py` against three transcript encodings, `check-staging.py` against a hand-authored good and bad staging file, `jira-apply.py` against two fake transports seeded from `tests/fixtures/jira-refine/issues.json`. It proves the scripts parse correctly and that the fakes agree with the idempotency rules. It says nothing about whether a filled-in entry is faithful to what a room actually said, whether a real Jira Cloud instance accepts what the write layer sends, or whether jira-cli's argument forms still match a real release. Those questions need a live run, and this file is the procedure for that.

**Scenarios are unrun until somebody runs them.** This file names the setup and the pass condition; it records no result until a human has actually executed one.

## What the Fixtures Already Cover

`tests/fixtures/jira-refine/README.md` lays out the transcript trio, the two transport fakes, and the good and bad staging files. None of that substitutes for the scenarios below—the fakes prove the scripts speak the contract correctly, not that a real tracker or a real recording behaves the way the contract assumes. A scenario below that needs a live Jira project says so, and every one of them needs a sandbox project, never a client's live board.

## Scenarios and Pass Conditions

### 1. A Real Transcript Through Stage Mode, Checked for Faithfulness

**Setup:** a recording of an actual backlog-refinement session (not a fixture), plus a config naming its real projects and spoken aliases.

**Commands:**

```
jira-refine/scripts/segment.py SESSION.vtt --config jira-refine.toml --session-date YYYY-MM-DD > SESSION.refine.md
jira-refine/scripts/check-staging.py validate SESSION.refine.md
```

Fill each entry by hand from Step 2 of `SKILL.md`, then re-run `validate`.

**Pass condition:** for every entry, every Acceptance criteria, Dependencies, and Goal line's `(raw: "…")` snippet is a phrase someone in the room actually said. Check this by reading the excerpt yourself rather than trusting the anchor regex, which only confirms the snippet appears in the excerpt, not that the excerpt supports the claim built on it. A line whose snippet is real but whose claim overreaches it (for example, quoting "fifty thousand rows" to support "must complete in under a minute") fails this scenario even though `validate` passes it clean.

### 2. A Topic the Room Never Reached Stays Empty

**Setup:** the same real session as Scenario 1, or any recording where a template section, say Out of scope, genuinely never comes up.

**Commands:** same staging run as Scenario 1, then read the entry's Out of scope section and its Open questions section.

**Pass condition:** Out of scope is empty and Open questions carries `- not discussed: out of scope`, with no sentence in Out of scope that sounds plausible but traces to nothing said. Fails if a filled-looking line appears in a section the transcript never touches, even one that would be a reasonable guess.

### 3. A Circular Segment Gets Caught in the Summary

**Setup:** a real session containing a segment that reopens a question more than once without resolving it. `segment.py` already reports this key's `revisited` count above zero.

**Commands:** the Step 3 draft of Summary's Spike candidates, by hand, per `SKILL.md`.

**Pass condition:** the entry is flagged `circular` with two anchors that both show the same question being reopened, not just a segment that is merely `long` or `revisited` for unrelated reasons. `long` and `revisited` are arithmetic segment.py already computed; `circular` is the one judgment call a human adds on top, and this scenario is where a reviewer checks that the call was actually made rather than copied from the `revisited` flag.

### 4. Goal-Field Discovery Before the First Real Apply

**Setup:** a sandbox project whose config has no `fields.goal` set yet, and a Jira admin who knows which custom field holds the team's Goal (or is willing to look it up).

**Commands:**

```
jira-refine/scripts/jira-apply.py fields --name goal --config jira-refine.toml
```

**Pass condition:** the command prints candidate field ids and names without writing to the config or the tracker, and one of the printed candidates is confirmed by the admin as the real Goal field. Fails if the command writes anything, or if the printed list omits the field a human already knows is correct.

### 5. Apply Dry Run Against a Sandbox Project

**Setup:** the sandbox project from Scenario 4, config now carrying the confirmed Goal field id, and a staging file with at least one entry `status: approved` against a real (sandbox) issue key.

**Commands:**

```
jira-refine/scripts/jira-apply.py get PROJ-1 --config jira-refine.toml
jira-refine/scripts/check-staging.py entries STAGING --status approved \
  | jira-refine/scripts/jira-apply.py update --config jira-refine.toml --dry-run
```

**Pass condition:** `get` returns the sandbox issue, the dry run's stderr plan lines correctly describe what a real run would do against that issue's actual current state (an empty description plans `applied`, a non-empty one plans `conflict` unless `on_conflict` is set), and the sandbox issue is unchanged afterward. Fails if the plan disagrees with the issue as it actually stands, or if anything on the sandbox project changed.

### 6. A Second Apply Proves Zero Writes on a Live Tracker

**Setup:** immediately after a real (non-dry-run) apply against the sandbox project from Scenario 5 has succeeded.

**Commands:**

```
jira-refine/scripts/check-staging.py entries STAGING --status approved \
  | jira-refine/scripts/jira-apply.py update --config jira-refine.toml --report second-run.jsonl
```

**Pass condition:** every entry reports `already-present` on description, links, label, and goal; `writes` is `0` for every entry; and the exit code is `0`. This is idempotency rule 8, checked against a real tracker rather than the fixture fakes. It fails if the sandbox issue's description, links, labels, or Goal field changed at all, or if any entry's `writes` is nonzero.

### 7. A Conflict on a Genuinely Human-Written Description, Resolved by `on_conflict`

**Setup:** a sandbox issue whose description a person actually typed by hand (not a jira-refine block from a prior run), and a staging entry approved against that key.

**Commands:**

```
jira-refine/scripts/check-staging.py entries STAGING --status approved \
  | jira-refine/scripts/jira-apply.py update --config jira-refine.toml --dry-run
```

Confirm the plan reports `conflict` on that entry. Then set `on_conflict: append` on the entry, flip it back to `status: approved`, and rerun without `--dry-run`.

**Pass condition:** the first dry run reports `conflict` and performs zero writes; the sandbox issue's human-written text is completely intact after the second run, with the jira-refine block appended below it rather than replacing any of it. Repeat with `on_conflict: replace` on a second sandbox issue and confirm the human text is gone and only the new block remains. Fails if either mode alters the human text in a way its own contract doesn't describe (append changing a byte of the original, or replace leaving stray fragments behind).

### 8. The jira-cli Transport Against a Real Release

**Setup:** a sandbox project, a real `jira` CLI binary installed and authenticated against it (per `RATIONALE.md`'s Known Limitations, its argument forms are pinned only by the fixture's fake, never verified against an actual release), and `fields.goal_cli_name` set in config alongside `fields.goal`.

**Commands:**

```
jira-refine/scripts/jira-apply.py get PROJ-1 --config jira-refine.toml --transport jira-cli
jira-refine/scripts/check-staging.py entries STAGING --status approved \
  | jira-refine/scripts/jira-apply.py update --config jira-refine.toml --transport jira-cli --dry-run
```

Then run it for real, and run it a second time.

**Pass condition:** `get`, `update_description`, `add_labels`, `create_link`, and the `--custom`-based `set_field` for Goal each produce the outcome `tracker-contract.md`'s Operations table claims for jira-cli, and the second run reports zero writes exactly as in Scenario 6. Check Goal specifically: `--custom` on edit is undocumented per the Known Limitations, so this scenario either confirms it works as assumed or confirms the fallback to the description block fires cleanly instead. It fails if any of the five operations errors out, silently no-ops, or if Goal reports `applied` on the second run instead of `already-present`.

### 9. A Hand-Deleted Sentinel Reports a Conflict, Not a Silent Rewrite

**Setup:** a sandbox issue already carrying a jira-refine block from a prior successful apply (Scenario 5 or 6's issue works). By hand, delete the `h6. jira-refine begin … h6. jira-refine end` block from the issue's description, leaving the rest of the description (if any) untouched.

**Commands:** the same update pipeline as Scenario 6, against that entry.

**Pass condition:** the run reports `conflict` on that entry rather than writing a fresh block as if nothing were there. Per `RATIONALE.md`'s Known Limitations, this is the correct outcome, not a bug, because the block was the only record that a push had already happened. Fails if the run instead writes silently and reports `applied`.

### 10. The Same Ticket Refined in Two Separate Sessions Conflicts by Design

**Setup:** a sandbox issue already carrying an applied jira-refine block from session A's `source`. Stage and approve a second entry for the same key from a different transcript, session B.

**Commands:** the update pipeline, pointed at session B's staging entries.

**Pass condition:** the run reports `conflict` on that entry, because the existing block's `source` doesn't match session B's. Per idempotency rule 3, this is deliberate, not a defect, and this scenario exists so nobody "fixes" it later. Fails if the run overwrites session A's block without `on_conflict` set.

## What These Evals Do Not Cover

Whether a gap ticket drafted in Step 3 actually reads well once a human files it in Jira by hand. `file-issue` has no Jira create path yet, so that step's output is a draft, not something a script can grade. Number-word parsing outside English 0–9999 and diarization errors in a real transcript's speaker labels are also out of scope: both are named as unmeasured in `RATIONALE.md`'s Known Limitations, and neither has a scenario here because neither has a proposed fix to validate. Treat them as open risks to watch for while running the scenarios above, not as separate scenarios of their own.
