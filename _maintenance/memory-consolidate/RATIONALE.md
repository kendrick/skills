# memory-consolidate—rationale

Evidence tiers: **[E]** measured or observed in a real run, **[P]** practitioner reasoning from prior art, **[C]** convention inherited from this repo or its neighbors.

## Where This Came From

Four sources:

- **Issue #195**, which asked for a report-only health pass over a scope's `_memory/` and set the acceptance criteria the smoke suite pins. Near-duplicate detection was in its first draft and left it on 2026-11-02 for kendrick/long-term-memory-kit#130.
- **#276, merged as #279**, which made a scope's `_memory/` a valid long-term-memory-kit Bank. Before it, `ltm doctor` couldn't read a scope.
- **The kit's `docs/doctor.md`**, which fixes the shape this skill consumes: `ltm doctor --bank <path> --json` prints an array of `{file, check, message, related_files}` objects, exits 0 whenever the checks ran, and exits 1 outside a Bank, on a bad `doctor:` block, or on an invalid `LTM_TODAY`. Its `stale-confirmed` dismissal paragraph is the source of the `ltm confirm`/`ltm deprecate` pointer in `SKILL.md`.
- **`inbox-to-memory`'s Phase 5** and the token grammar in `inbox-to-memory/references/machine-contracts.md`. The amend form `[memory candidate: update existing [[<file>|<label>]]] <claim>` is already registered there with its grep, and Phase 5 already resolves it.

## Decision Ledger

| # | Decision | Why | Tier |
|---|---|---|---|
| 1 | One stdlib script, `scripts/consolidate.py`, taking `--scope <root>` and an optional `--json <file>` | Turning a doctor array into lines is the same job every run, so a script does it the same way each time. Standard library only keeps the skill copy-in portable, per `AGENTS.md`. `--json` reads doctor output saved earlier, which lets the suite run without the kit and lets a user hand over a file made on another machine. `SKILL.md` keeps the judgment: when to run, how to present the report, and where the user goes next. | [C] |
| 2 | The report is a groomed note in drain form: frontmatter `schema: 2`, `date`, `type: report`, `unpromoted_candidates`, then one `[memory candidate: update existing [[<stem>\|<title>]]] <check>: <message>` line per finding, with a `related: [[<stem>]], ...` tail where doctor named related files | Every grep, the `unpromoted_candidates` count, and Phase 5 already read this token, so nothing downstream needs teaching. A new report format would need its own row in `machine-contracts.md` and its own handling in Phase 5. The title comes from the record's frontmatter `title`, else its stem, so the line shows the name the record gives itself. | [P] |
| 3 | Routing never names a check | `consolidate.py` turns every finding into a line the same way, whatever its `check`. A check the kit adds later, such as `near-duplicate` from long-term-memory-kit#130, comes through with no change here. The suite proves it with a stubbed `unseen-check` finding, which the report carries as a candidate line. | [P] |
| 4 | Resolution belongs to Phase 5, and this skill never writes a record | Phase 5 already has the per-candidate review, the approve, supersede, and dismiss paths, and the line rewrite that records each decision. A second resolver here would duplicate that and could drift from it. `consolidate.py` writes only the report path. The suite checks that `git status --porcelain _memory/` is empty after a run and that the report is the only new file. | [P] |
| 5 | Same scope, same `LTM_TODAY`, same bytes | The report holds no time of day, no run id, and no absolute path, and the date comes from `LTM_TODAY` where set. Doctor's thresholds count days from today, so the fixture's saved `doctor.json` reproduces byte for byte only with `LTM_TODAY=2026-10-01`. Unpinned, more fixture records age past a threshold (`RUN_DIR/fixture.txt` of issue-195). The suite runs the pass twice and compares the bytes with `cmp`. | [E] |
| 6 | Model-invocable, with a trigger-bearing description | A misfire writes one report file under `notes/reports/` and touches no record, so it costs little. The description names the triggers ("consolidate memory", "check memory health", "find stale records") and says the skill never writes records, naming `inbox-to-memory` for that. | [P] |
| 7 | Thresholds come from the scope's `memory-bank.yaml` `doctor:` block, and the skill passes none of its own | Doctor reads them there. A second set of thresholds in this skill would let the report and a direct `ltm doctor` run disagree about the same Bank. | [P] |
| 8 | Exit codes: 0 report written, 1 `ltm doctor` failed or couldn't run or its JSON isn't an array of `{file, check}` objects, 2 argparse usage error, 3 unreadable scope, unreadable `--json` file, or an `LTM_TODAY` not exactly `YYYY-MM-DD` | Follows the validator convention `check-territories.py` set, which `AGENTS.md` names for scripts that gate a run. A usage error exits 2 because argparse exits before the script's own code runs, as in `memory-index`. `ltm` missing from PATH exits 1, with doctor's other failures, since the input was fine and doctor couldn't run. On exit 1, stderr quotes doctor's output and no report is written. | [C] |
| 9 | Step 1 asks before a same-day rerun overwrites a report holding resolved lines | Same day means same path, and the script overwrites it. Phase 5 rewrites each line it resolves, so a silent rerun would throw away decisions already made. The script can't tell a resolved line from an unresolved one without learning Phase 5's grammar, so `SKILL.md` reads the old report and asks. | [P] |
| 10 | The suite stubs `ltm` with a PATH shim, and also runs the real `ltm` when one is on PATH | The shim makes every case run without the kit and lets the suite feed doctor a failure, malformed JSON, or an unseen check. The real run compares its report against the same hand-written expected bytes, so a `doctor.json` that drifts from what the kit prints fails the suite. | [E] |

## Deliberately Not Built

| Cut | Why |
|---|---|
| A list of known `ltm doctor` checks | Any list goes stale the day the kit adds a check, and a filter keyed on it would drop that check's findings without saying so (row 3). Pinned by a `refute_text` on `stale-confirmed`, `long-chain`, and `orphan` in `scripts/consolidate.py`. |
| A similarity search of its own | Near-duplicate detection moved to long-term-memory-kit#130 on 2026-11-02. When it lands as a doctor check, row 3 carries its findings in. Pinned by a `refute_text` on `near-duplicate` and `similarity` in `scripts/consolidate.py`, and on `near-duplicate` in `SKILL.md`. |
| Writing records | Resolution is Phase 5's (row 4), and the kit's `ltm confirm` and `ltm deprecate` stay commands the user runs. Pinned by a `refute_text` on `confirm` and `deprecate` in `scripts/consolidate.py`, and by the suite's `git status --porcelain _memory/` case. |

## Known Limitations

- A same-day rerun overwrites the report. The path carries only the date, so the script can't keep two runs from one day. Step 1 of `SKILL.md` asks first when the old report holds resolved lines (row 9). A user who skips the skill and runs the script directly gets no such check.
- A record title holding `|` or `]]` isn't escaped. It breaks the wikilink in that finding's line, and Phase 5 may misread the target.
- `consolidate.py` reads a title only from a single-line `title:` key. A title written as a YAML block scalar comes through as its first line, such as `>-`.
- `--json` doesn't check that the file came from this scope. Doctor output saved from another Bank still writes a report, and any record the scope doesn't hold gets its stem as its title.
