# jd-audit

## Why This Exists

The obvious way to check whether a Johnny.Decimal vault has drifted is to have an agent read the folders and the register and eyeball whether they match. That's exactly the task a language model is worst at doing consistently, run to run—it's a diff, and a diff wants a diff tool, not a fresh act of judgment every time someone asks. The actual comparison in jd-audit is `scripts/validate.py`, a standard-library Python script that parses `00.02 Vault Conventions.md` once and treats it as the schema for every check that follows, so "does this folder name match the grammar" is a regex match, not a vibe that can come out differently next week.

The register says what should exist; the substrates say what does. When the two disagree, the honest move is to say so and stop—a validator that also picked which side to fix would be quietly rewriting your own history. jd-audit's job is the half of the story a script can't tell on its own: presenting the findings so you can act on them, then walking you through the actual reconciliation decision—was this ID renamed, does the office copy need to catch up, is this a real split or a name that legitimately recurs—because that judgment is yours, not the validator's.

## How It Works

Running the skill runs `scripts/validate.py` against the vault, reading the same `00.02 Vault Conventions.md` block `jd-file` reads, so the two skills can never disagree about what the rules are. The script checks the register's own grammar and placement, the physical folder structure at every level, drift between the register and each substrate—honoring what each substrate is even in scope for, since an ID outside a substrate's scope is absent by design and not a fault—the three-way mirror between the constitution, the register, and the substrates, basic hygiene like a file sitting where only folders belong, and cross-substrate links, checked against every known machine's roots so a link built on another laptop reads as unverifiable here rather than broken.

Each finding's severity tracks how much judgment it still needs. A register entry and a substrate disagreeing about whether an ID exists is unambiguous, so it's an error. A name recurring under two different IDs might be a real split, or might be a name that's legitimately repeated—an "Archive" folder can exist under more than one area on purpose—so it's a warning that asks for a call instead of declaring a fault. An absolute link this host can't verify might just belong to a different machine's mount point, which is normal, so it's informational only.

The written report leads with a one-line count, groups errors before warnings before info, and closes by naming every check that ran clean—because a report that only shows problems can't tell you "nothing's wrong" apart from "nobody looked."

## Install

```bash
npx skills add kendrick/skills --skill jd-audit
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/jd-audit ~/.claude/skills/jd-audit
```

Needs Python 3.11 or later on the machine running it—`scripts/validate.py` is standard-library only, no install step of its own beyond that.

## Use

```
> audit the vault
> check the JDex against what's actually on disk
> is anything drifted between vault and office
> --only drift-name-mismatch audit the 15 category
> run the validator and walk me through what it finds
```

## What's Here

```
jd-audit/
├── SKILL.md                     # orient, run the validator, report, reconcile, apply and re-run
├── scripts/
│   └── validate.py              # stdlib-only checker; 00.02 Vault Conventions.md is its schema
└── references/
    └── findings-catalog.md      # what each check means and how to reconcile it
```

## Gotchas

- Never repairs anything on its own. A finding is a report, not a fix; every reconciliation decision—rename, backfill, accept—is yours to make.
- Standard library only, no network calls. `scripts/validate.py` runs headless off a filesystem scan and one TOML block, so it works the same on a plane as it does at a desk.
- A fourth numbered tier gets flagged (`structure-deep-numbering`); ordinary unnumbered nesting below an ID—client memory folders, nested git repos ten levels down—doesn't, and won't, because that depth is how this vault's client scopes actually work.
- Split names are warnings, not errors. Two IDs sharing one normalized label get surfaced for a decision, since some recurring names are legitimate.
- An unreadable or version-mismatched conventions note stops the run instead of falling back to a best guess—a half-understood config file is more dangerous than a script that refuses to start.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).

The decision ledger lives in [`_maintenance/jd-audit/RATIONALE.md`](../_maintenance/jd-audit/RATIONALE.md); attribution for the Johnny.Decimal system and the prior art this skill set draws structure from is in [`_maintenance/jd/SOURCES.md`](../_maintenance/jd/SOURCES.md).
