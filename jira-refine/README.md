# jira-refine

Turns a recorded backlog-refinement transcript into staged Jira tickets, then pushes only the ones you approve.

## Why This Exists

A refinement call is an input nobody controlled: people talk over each other, decide half a thing out loud, and move on to the next ticket before anyone writes down what they agreed. Typing that up by hand means either skipping detail to keep pace with the room or falling behind and reconstructing it from memory afterward. Neither produces a description a stranger can act on six weeks later.

The template this skill fills is a fixed set of slots, and a slot the room never reached gets a `- not discussed: <section>` line instead of a guess. An invented acceptance criterion costs the tech lead their trust in every other line in the file, and that trust is the only reason running this is worth it. So the skill never writes to Jira from a transcript directly. It stages first, in a file the transcript alone produced, and applies only what a person marked `approved` in an editor afterward—an edit made between those two steps counts exactly as much as one made by the model.

## How It Works

Stage mode reads a transcript—VTT, SRT, or plain `[HH:MM:SS] Speaker: text`—and segments it by the project keys spoken aloud, using the aliases your config lists for how your room actually says them ("the plat board," "platform dash ninety one"). Each segment becomes one entry in a `.refine.md` staging file, with a fixed seven-field template filled from what was actually said. Every acceptance criterion, dependency, and goal line ends in a `(raw: "four to six verbatim words" HH:MM:SS)` anchor quoted straight from that entry's own excerpt, so a validator can check the claim against the transcript rather than trusting the fill. A dependency is a key from the entry's own mentions or an explicit blocked-by statement—a key said in passing while discussing something else doesn't become one, because each dependency turns into a real Jira link. A goal only lands where a product owner named one out loud; inferring it from the acceptance criteria is exactly the failure this rule exists to block.

Stage mode ends by validating the file and stopping. Nothing has been pushed anywhere—the file is now the human's review artifact, and the user flips each entry's status to `approved` or `skipped` before anything downstream touches it.

Apply mode reads that staging file back from disk, never from what the conversation remembers writing, and validates it again in case it was hand-edited since. It previews every write in a dry run—one plan line per approved entry, showing what would change—and asks for confirmation before pushing anything for real; no flag skips that ask. Afterward it reconciles: each entry's status becomes `applied` or `conflict` based on what the tracker actually reported, and a hand-deleted sentinel on a previously-applied ticket produces a conflict by design, since the sentinel is the only record that a push already happened.

`jira-apply.py` is the one file in the skill that knows Jira exists, over either its REST API or the `jira` CLI. Everything upstream of it—segmenting, filling, validating—is tracker-agnostic. And where the room named a piece of work with no ticket for it, the skill drafts it in `file-issue`'s task shape and says plainly that filing it means carrying the draft into Jira by hand: `file-issue` only creates GitHub issues today, not Jira ones.

## Install

```bash
npx skills add kendrick/skills --skill jira-refine
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/jira-refine ~/.claude/skills/jira-refine
```

Needs Python 3.11 or newer (for `tomllib`) and either network reach to Jira Cloud or the `jira` CLI on `PATH`.

## Use

It only runs when you ask for it by name—see the Gotchas for why.

```
> /jira-refine transcripts/2026-09-07-refinement.vtt
> /jira-refine transcripts/session.txt --session-date 2026-09-07
> /jira-refine --apply transcripts/session.refine.md
> /jira-refine --apply transcripts/session.refine.md --dry-run
```

Staging needs a transcript path; applying needs the staging file it produced. `--session-date` overrides the date read from the filename, and lands in the batch label and every Provenance block the run writes. `--dry-run` on apply previews the writes without pushing them.

## What's Here

```
jira-refine/
├── SKILL.md                      # the skill—stage: segment, fill, summarize, validate; apply: validate, preflight, dry run, push, reconcile
├── assets/
│   └── jira-refine.example.toml    # every config key with its default
├── references/
│   ├── ticket-template.md          # the seven-field template and what counts as stated
│   ├── staging-format.md           # the staging file's grammar, checked by check-staging.py
│   └── tracker-contract.md         # entry and report shapes, exit codes, the eight idempotency rules
└── scripts/
    ├── segment.py                  # stage: transcript to staging skeleton
    ├── check-staging.py            # the validation gate, and the entry source for apply
    └── jira-apply.py                # the only file here that talks to a tracker
```

## Gotchas

- **Every design choice here is reasoned, not measured.** The ledger's rows carry `[P]` or `[C]` until a live run bumps one to `[E]`, and that run is tracked in `EVALS.md`, not yet done.
- **It won't fire on its own.** A misfire here writes into a client's tracker, which costs somebody's team a real conversation; a missed trigger costs you one typed word. Type its name.
- **Number words only go up to 9999.** A key spoken as a larger number won't parse. Say the digits instead, or spell the key.
- **The jira-cli transport is the thinner path.** It can't discover custom fields at all, its undocumented `--custom` flag on edit means Goal may still fall back to the description block even with `goal_cli_name` set, and its flags are pinned by the test fixture rather than by any particular `jira` release.
- **Deleting the sentinel doesn't undo anything.** It marks the next apply a conflict rather than a clean rewrite, because that block is the only record a push already happened.
- **A board filter can hide a ticket you just created.** If your board's filter tests a Team field, a ticket created without one is real, correct, reported `applied`, and nowhere in the backlog. Declare that field under `[extra_fields]` so every `create` carries it. Nothing guesses it for you: on a project shared by several teams, a guess files one team's work onto another team's board.
- **An epic-link Goal needs its own config entry.** The skill assumes Goal is a custom field; nothing detects the epic-link case automatically.
- **Jira's description cap is unhandled.** Past roughly 32,767 characters, you get whatever error the API returns, nothing friendlier.
- **Refining the same ticket in two sessions conflicts by design.** The two sources don't match, and the skill won't guess which one wins.
- **A bad transcript stays bad.** Diarization errors carry straight through into the quoted anchors.
- **Filing a gap ticket is still manual.** `file-issue` writes only to GitHub today, so a Jira gap drafted here is something you carry over by hand, not a one-line handoff—that lands once a follow-up gives `file-issue` a Jira path.

## Maintainers

The decision ledger lives in [`_maintenance/jira-refine/`](../_maintenance/jira-refine/). Every contested choice has a row in [RATIONALE.md](../_maintenance/jira-refine/RATIONALE.md), including the twelve things deliberately left out. [EVALS.md](../_maintenance/jira-refine/EVALS.md) carries the live procedure for whether a run actually holds up end to end.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).
