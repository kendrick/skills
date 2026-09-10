# jira-refine fixtures

What each file plants, and why. Read `jira-refine/references/staging-format.md`,
`tracker-contract.md`, and `ticket-template.md` first — every claim below is a
claim about the grammar and contract those files define.

## Transcripts: `refinement.vtt`, `refinement.srt`, `refinement.txt`

One session, encoded three ways — same speakers, same words, same clock
times, only the container format differs (VTT cues, SRT cues, plain-text
`[HH:MM:SS] Name: text` lines). Feeding any one of the three to `segment.py`
with `jira-refine.toml` and `--session-date 2026-09-07 --json` produces the
same four segment keys, in the same order, with the same word counts,
`revisited`, and `long` flags:

- `PROJ-412` — opened with "PROJ dash four twelve" (a number-word run behind
  the literal word "dash"). The happy-path ticket: empty description in
  `issues.json`, so the apply path can write to it cleanly.
- `PROJ-413` — opened with "PROJ 413" (bare digits, no dash). The conflict
  path: `issues.json` seeds it with a human-written description, so applying
  against it has to refuse rather than clobber.
- `PLAT-77` — opened with "platform seventy seven" (a number-word form, no
  dash), then reopened a few turns later with "back to platform seventy
  seven" — a revisit, so `revisited: 1` on this entry.
- `PROJ-455` — opened with "PROJ four fifty five" (another number-word
  form). Runs for roughly sixteen minutes against a session median near
  100 seconds, so `segment.py`'s `long_factor` (2x) flags it `long: true`.
  This is the conspicuously-long segment.

`PROJ-398` is mentioned mid-turn inside PROJ-412's segment ("proj three
ninety eight lands," seven words into the turn, past the six-word boundary
window) and never opens a segment of its own — it shows up only in
`PROJ-412`'s `mentions` and in the "mentioned in passing" list. It's the same
key `issues.json` seeds as an existing issue, so a later wave's dependency
link has something real to resolve against.

The transcript also carries the moment a later wave hands to `file-issue`: at
00:03:00, Dan says the retry-backoff work on the export job has no ticket
yet. No key is spoken, because none exists — that's the point. It's dialogue
text only; `segment.py` does nothing special with it, and nothing here
depends on it being segmented.

## `jira-refine.toml`

The test config: two projects (`PROJ`, `PLAT`) with the spoken aliases the
transcripts use, the `rest` transport, and `fields.goal` set to a
real-looking custom field id (`customfield_10057`) so a run against this
config exercises the Goal-applied path instead of always taking the
description-block fallback the shipped example's empty `goal` would force.
`site` expands `${JIRA_REFINE_TEST_SITE}`, per tracker-contract.md's Auth
rule, so a test points it at a fake without editing the file — see "Transport
fakes" below for what that variable, and the fakes on the other end of it,
expect.

It also declares one `[extra_fields.team]` table — `customfield_10001` (Jira
Cloud's Advanced Roadmaps Team field) under the jira-cli name `Team`, with the
value `team-a`. That makes a create run against this config exercise the
extra-field path on both transports instead of the empty-table case the shipped
example gives, which is the difference between testing the fix for the
invisible-ticket bug and testing the code around it.

## Transport fakes: `fake-jira-rest.py`, `fake-jira`

Two stand-ins for the two transports `jira-apply.py` supports, both seeded
from `issues.json`. Four environment variables drive them:

| Variable | Read by | Holds |
|---|---|---|
| `FAKE_JIRA_LOG` | both | Path to a log file. Each mutating write (`PUT`/`POST` under REST, an editing subprocess call under the CLI fake) appends one JSON line here; a `GET` (or `jira issue view`) never logs. Compare this file's line count before and after a second run over the same input to prove the idempotency rules hold: a clean second run appends nothing. |
| `FAKE_JIRA_SEED` | `fake-jira` only | Path to the seed state, shaped like `issues.json`. |
| `FAKE_JIRA_STATE` | `fake-jira` only | Path to the mutable state file the CLI fake reads and rewrites on every invocation — it has to persist across processes, since `JiraCliTransport` shells out fresh each time, unlike the REST fake's single long-lived server process. |
| `FAKE_JIRA_CUSTOM_FIELDS` | `fake-jira` only | A JSON object mapping a custom field's display name to its field id, e.g. `{"Goal": "customfield_10057", "Team": "customfield_10001"}`. `fake-jira` uses it so a `--custom NAME=VALUE` write lands under the id and can be read back by id, the way real Jira behaves. A name absent from the map falls back to being stored under the literal name. The smoke test builds it from the config's `[fields]` pair **and** every `[extra_fields.*]` table, so adding a field to the config never leaves its write key and its read key on two different names. |

`fake-jira-rest.py` takes `--port N --seed PATH` on its command line rather
than an env var for its seed, and serves the REST endpoints on that port for
`site = "${JIRA_REFINE_TEST_SITE}"` to point at.

`fake-jira` has no file extension and carries the executable bit, but putting
this fixtures directory on `PATH` does not make it resolve as `jira` —
`shutil.which` (and `JiraCliTransport.__init__`, which looks the binary up
the same way) matches on filename, and the file is named `fake-jira`. What
the design enables instead is symlinking the fixture into a scratch directory
under the name `jira`, then putting that directory on `PATH`, the way
`tests/jira-refine-smoke.sh` does:

```
mkdir -p "$tmp/bin"
ln -s "$fixtures/fake-jira" "$tmp/bin/jira"
export PATH="$tmp/bin:$PATH"
```

It also runs directly as `python3 fake-jira KEY ...` for a test that would
rather not touch `PATH`.

## `staging-good.md`

Hand-authored, and deliberately independent of the transcripts above — it
represents a fuller refinement session than the fixture transcripts bother
to encode, so its keys, wording, and timestamps don't need to (and don't)
match `refinement.{vtt,srt,txt}`. Its only job is to be a staging file that
`check-staging.py validate` accepts outright:

```
$ python3 jira-refine/scripts/check-staging.py validate tests/fixtures/jira-refine/staging-good.md
OK: 5 entries
```

Five entries, three statuses:

- `approved`: `PROJ-412` (matches the seeded empty issue), `PROJ-413`
  (matches the seeded human-written issue, so applying it should conflict),
  and `PROJ-398` (matches the seeded existing issue, and is `PROJ-412`'s
  anchored Dependency — the apply path has a real link to resolve).
- `staged`: `PLAT-77` — a fresh, unreviewed skeleton in `segment.py`'s own
  output shape (every content section empty, all five `not discussed`
  lines), with `revisited: 1` to exercise that field outside the
  transcripts too.
- `skipped`: `PLAT-14` — reviewed and declined.

`entries --status approved` on this file emits exactly the three approved
keys above, in order, as the JSON lines `tracker-contract.md` specifies —
the input `jira-apply.py update` expects on stdin.

## `staging-bad.md`

Fails `check-staging.py validate` with exactly six problems on stderr, exit
1 — one per planted defect, each a distinct grammar rule, spread across the
frontmatter and two entries so no defect's failure can cascade into another:

```
$ python3 jira-refine/scripts/check-staging.py validate tests/fixtures/jira-refine/staging-bad.md
check-staging: frontmatter: schema is '2', expected '1'
check-staging: frontmatter: generated '2026-08-30 16:45:00' is not YYYY-MM-DDTHH:MM:SS
check-staging: entry PROJ-500: status 'pending' is not one of ['staged', 'approved', 'skipped', 'applied', 'conflict']
check-staging: entry PROJ-500: Acceptance criteria line has no valid anchor: '- [ ] Ship the retry button'
check-staging: entry PROJ-501: Dependencies references its own key
check-staging: entry PROJ-501: Goal has both content and a not-discussed line
```

The six, for whoever writes the smoke test:

1. **Frontmatter, wrong schema.** `schema: 2` instead of `1`.
2. **Frontmatter, malformed `generated`.** A space instead of `T` between
   date and time.
3. **`PROJ-500`, illegal status.** `status: pending`, not one of the five
   legal values.
4. **`PROJ-500`, unanchored Acceptance criteria.** `- [ ] Ship the retry
   button` carries no trailing `(raw: "..." HH:MM:SS)` at all.
5. **`PROJ-501`, self-referential Dependency.** Its Dependencies section
   lists `PROJ-501` — an entry can't depend on itself.
6. **`PROJ-501`, Goal with both content and a not-discussed marker.** The
   Goal section holds a real anchored line, and Open questions *also* carries
   `- not discussed: goal` — a section is either filled or marked empty,
   never both.

## `issues.json`

The seed state both transport fakes load, one issue per key as the Jira REST
v2 API returns it:

- `PROJ-412` — `description: null`. The happy path: an apply run against
  this entry has an empty field to write into.
- `PROJ-413` — `description: "A human wrote this by hand."`. The conflict
  path: an apply run has to detect this text is not one of its own
  `jira-refine` blocks and refuse to overwrite it without `on_conflict` set.
- `PROJ-398` — `description: null`, no relation to the other two beyond
  being on the tracker. Exists so `PROJ-412`'s Dependency on it, and
  `staging-good.md`'s own `PROJ-398` entry, resolve against a real issue
  instead of reporting `missing-issue`.

This is the interface both fixture-owning tasks in this wave build against —
the fake transports read exactly this shape, keyed by issue key.
