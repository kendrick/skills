# jd-file

## Why This Exists

Ask an agent to "just file this" and the obvious approach is to move the item and stop—the folder holds it now, done. But nothing else in the system learns what happened: the one document that's supposed to answer "what's in here and why" stays exactly as stale as it was, and the next filing decision has to guess blind instead of consulting a record. jd-file treats the register as the real answer to that question, not a chore attached to it, so writing the `00.01 JDex.md` line happens inside the filing action itself, never as a follow-up step someone forgets.

The opposite failure runs the other direction: an agent confident enough to invent a category the moment nothing existing quite fits. A Johnny.Decimal system's shape—its areas, its categories—is a decision a person made on purpose, and reshaping it silently is a different kind of mistake than misfiling one item. jd-file earns the right to act by scaling its caution to the stakes: a clean match to an existing ID gets filed without a question, several items at once get proposed as one table and take one confirmation, a new ID inside a category that already exists gets a confirm, and a new area or category never happens without you saying so first.

## How It Works

Every run starts by reading `00.02 Vault Conventions.md`, the TOML block that carries this vault's roots, grammar, and rules. jd-file never hardcodes a path or a pattern that already lives there, because a rule stated twice is a rule that can quietly drift from itself. It then reads `00.01 JDex.md`, the register, for what already exists before touching anything, so a filing decision gets made against the actual index instead of a guess.

Classification follows precedent first: whatever a category already does for its substrate—the Obsidian vault, the office tree, or a client repo—is the answer, because consistency inside a category beats a rule imported from outside it. Where the call is clean, jd-file bets on it and files. Where it would want a second opinion, it names the pick and the runner-up and asks you to confirm. Where it's genuinely guessing, it lays out two or three candidates with its reasoning and lets you choose—and it never phrases the question as "where should this go," because a specific ID with a stated purpose is one you can actually answer.

Filing writes the register line as part of the same action, not a separate step after it. If the register already disagrees with what's on disk—an ID it lists that no substrate actually holds, say—jd-file reports the conflict and stops rather than picking a side to fix, because that call belongs to you.

## Install

```bash
npx skills add kendrick/skills --skill jd-file
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/jd-file ~/.claude/skills/jd-file
```

Needs `00.02 Vault Conventions.md` to already exist in the target vault—this skill reads that file for every path and pattern it uses, and has nothing to fall back on without it.

## Use

```
> file this PDF, it's the new dental insurance card
> where should the Amber Fleet SOW go
> I started keeping a woodworking log, help me set it up
> file these three photos from the Cobalt Freight walkthrough
```

## What's Here

```
jd-file/
├── SKILL.md                          # orient, classify, decide the ID, pick the substrate, write the register line, then file
├── assets/
│   ├── overview.template.md          # scaffolded as Overview.md inside every newly minted vault ID
│   └── moc-rollups.md                # Dataview block a category map carries outside its generated markers
├── references/
│   ├── id-assignment.md              # minting a number without proposing a category
│   └── substrate-selection.md        # which of the three trees a thing belongs in
└── scripts/
    └── build_moc.py                  # regenerates a category map's table between its markers
```

## Gotchas

- Personal tooling, not general-purpose: it reads one vault's `00.02 Vault Conventions.md` for its roots, grammar, and rules, and has no default behavior without one.
- Never creates a category or an area on its own initiative, no matter how confident the classification—that decision is reserved for you, every time.
- Refuses to auto-repair. When the register and the substrates disagree about what exists, jd-file reports the conflict and stops; it never guesses which side is stale.
- No fourth numbered tier, not "nothing nested below an ID." Depth below an ID—client memory folders, nested git repos, whatever a scope needs—is normal and expected; jd-file only pushes back on a folder that tries to number itself `AC.ID.NN`.
- Doesn't propose `AC.00` management items. This vault's dialect doesn't use standard zeros, so jd-file won't invent one to be tidy.
- The Rollups sections in scaffolded notes need Obsidian's Dataview plugin. On a machine without it they render as visible query text—ugly, not broken—while everything above them is plain markdown and works everywhere.
- `obsidian-markdown`, `obsidian-bases`, and `obsidian-cli`, which Step 5 invokes for Obsidian mechanics, are external skills installed from [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills), not part of this repo.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..).

The decision ledger lives in [`_maintenance/jd-file/RATIONALE.md`](../_maintenance/jd-file/RATIONALE.md); attribution for the Johnny.Decimal system and the prior art this skill set draws structure from is in [`_maintenance/jd/SOURCES.md`](../_maintenance/jd/SOURCES.md).
