---
name: memory-consolidate
description: "Run `ltm doctor` over a memory scope's `_memory/` and write its findings as a report of memory candidates for review. Use when the user says \"consolidate memory\", \"check memory health\", \"find stale records\", or \"what's gone stale in _memory\", or after a batch of records lands and the bank wants a health pass. Writes one report note and never writes or edits records: to resolve what it finds, use inbox-to-memory's Phase 5."
argument-hint: '<scope-root>'
---

# memory-consolidate

`ltm doctor` already knows what a sick bank looks like: stale records, long supersession chains, orphans, and whatever checks the kit adds later. This skill turns its findings into a note that `inbox-to-memory` can drain, so a finding gets the same per-candidate review a groomed note's candidates get. `scripts/consolidate.py` does the mechanical part; this file decides when to run it, what to show the user, and where the user goes next.

The report is a proposal list. This skill writes the report file and nothing else, and every change to a record happens later, through Phase 5, on the user's say-so.

Resolve once per invocation:

- **SCRIPT**: `scripts/consolidate.py`, resolved against this skill's own directory. Run it with `python3`.
- **SCOPE_ROOT**: the directory holding the scope's `_memory/` and `memory-bank.yaml`. Take it from the user, or from the working directory when that directory holds both. Ask when neither does.
- **REPORT**: `SCOPE_ROOT/notes/reports/YYYY-MM-DD-consolidation.md`, dated from `LTM_TODAY` when that variable is set, else today.

| Exit | Meaning |
|---|---|
| 0 | the report was written |
| 1 | `ltm doctor` failed, couldn't run (`ltm` not on PATH), or printed something other than an array of `{file, check}` objects; stderr quotes it |
| 2 | usage error from argparse, such as a missing `--scope` |
| 3 | SCOPE_ROOT isn't a readable directory, the `--json` file is unreadable, or `LTM_TODAY` isn't exactly `YYYY-MM-DD` |

On any nonzero exit, report stderr verbatim and stop. The skill never falls back to reading records itself, since a report that doctor didn't produce can't be traced to a doctor finding.

## Step 1 — Check the Day's Report

The script overwrites REPORT whenever it runs, and the same day maps to the same path. When REPORT already exists, read it. A line Phase 5 has resolved starts with `[[`, because approving a candidate rewrites its prefix to a wiki link, and a rerun would throw that work away. Show the user which lines are resolved and run Step 2 only on a yes.

**Done when:** REPORT doesn't exist, or it holds no resolved line, or the user confirmed the overwrite, or declined it and the skill stopped.

## Step 2 — Run the Pass

```
python3 SCRIPT --scope SCOPE_ROOT
```

The script runs `ltm doctor --bank SCOPE_ROOT --json` and writes REPORT. Doctor reads its thresholds from the scope's `memory-bank.yaml` `doctor:` block, so to change what counts as stale or orphaned, the user edits that block. The skill passes no thresholds of its own.

`--json <file>` reads doctor output saved earlier instead of running `ltm`. Use it when the user hands you a saved `ltm doctor --json` file, or when `ltm` isn't on PATH and they can produce that file elsewhere.

**Done when:** the script exited 0 and REPORT exists, or it exited nonzero and its stderr was reported verbatim.

## Step 3 — Present the Report

Read REPORT and show the user every candidate line, in the order the file holds them. Each line is one doctor finding:

```
[memory candidate: update existing [[<record stem>|<record title>]]] <check>: <message> related: [[<stem>]], ...
```

The `related:` tail appears only when doctor named related files, such as the other records in a chain. Present each line's check name and message as doctor wrote them. A check name you don't recognize is a finding like any other, so show it with the rest; the kit adds checks over time and the report carries them unchanged.

Give the count from REPORT's `unpromoted_candidates` frontmatter. When it is 0, tell the user doctor found nothing and stop here.

**Done when:** the user has seen every candidate line in REPORT and the count, or has been told the bank is clean.

## Step 4 — Hand Off to Phase 5

Stop after presenting. Resolving a finding is `inbox-to-memory`'s job: point the user to its Phase 5 (Propose and Crystallize), which treats REPORT like any groomed note. Approving a line takes Phase 5's update-existing path: it amends the target record, adds REPORT's `id` to that record's `source_refs`, and rewrites the line to `[[<target>|memory — updated]]`, so the report doubles as the record of what was approved. A line the user doesn't approve keeps its candidate prefix and stays counted in `unpromoted_candidates`.

For a `stale-confirmed` finding, the usual fix is a command rather than an edit. A record's id is the nanoid that ends its stem. Have the user re-read the record (`ltm show <id>`), then:

- `ltm confirm <id>` when it is still true, which sets `last_confirmed` to today.
- `ltm deprecate <id>` when it no longer holds, which sets its `status` to `deprecated`.

For any other check, the kit's `docs/doctor.md` gives a dismissal paragraph per check.

**Done when:** the user has been pointed to Phase 5 for the report, and given the `ltm confirm`/`ltm deprecate` commands for each `stale-confirmed` line, if any, with no record touched by this skill.
