# memory-consolidate

## Why This Exists

Over months a memory bank decays: records go stale, a decision gets superseded four times over, and a record nobody links to sits there unread. [long-term-memory-kit](https://github.com/kendrick/long-term-memory-kit)'s `ltm doctor` already finds all three, but its output is a JSON array you read once and lose. This skill writes those findings into a note that `inbox-to-memory` can drain. That way each finding gets the same review a memory candidate from a meeting gets, and the note keeps a record of what you decided.

## How It Works

`scripts/consolidate.py --scope <scope-root>` runs `ltm doctor --bank <scope-root> --json` and writes `<scope-root>/notes/reports/YYYY-MM-DD-consolidation.md`. Each doctor finding becomes one line, in doctor's order:

```
[memory candidate: update existing [[prefixed-entity-invoice-numbers-Mc7InvNum4|Prefixed entity invoice numbers]]] long-chain: Supersession chain holds 4 Records (threshold 3) related: [[per-entity-invoice-sequences-Mc6InvNum3]], [[per-region-invoice-sequences-Mc5InvNum2]], [[sequential-invoice-numbers-Mc4InvNum1]]
```

That prefix is the update-existing token `inbox-to-memory` already greps for. The report's `unpromoted_candidates` frontmatter counts the lines. When you approve a line, Phase 5 amends the record, adds the report's `id` to the record's `source_refs`, and rewrites the line to `[[<record>|memory — updated]]`. A line you don't approve keeps its prefix and its place in the count. A bank with no findings gets a report that says `No findings.` and a count of 0.

The script holds no list of check names. Every finding becomes a line the same way, so a check the kit adds later shows up in the report with no change here. Thresholds come from the `doctor:` block in the scope's `memory-bank.yaml`, which is where doctor reads them, and the skill sets none of its own.

The skill writes the report file and never creates or edits a record. A same-day rerun writes the same path, and with `LTM_TODAY` pinned it writes identical bytes, since the report carries no time of day and no absolute path. Its `id` is hashed from the date for the same reason. A line Phase 5 resolved starts with `[[`, and the script won't overwrite a report that holds one. It exits 1 and leaves the file alone. The skill then shows you the resolved lines and reruns with `--force` only if you say yes.

To fix a `stale-confirmed` finding, run `ltm confirm <id>` when the record still holds, or `ltm deprecate <id>` when it doesn't. Neither needs a hand edit.

`--json <file>` reads doctor output you saved earlier instead of running `ltm`. The script exits 0 when it wrote the report. It exits 1 when `ltm doctor` failed, couldn't run, or printed something other than an array of findings. It also exits 1 when it refused to overwrite a report, and then stderr starts with `consolidate: refusing to overwrite`. It exits 3 for a scope that isn't a readable directory, an unreadable `--json` file, or an `LTM_TODAY` that isn't `YYYY-MM-DD`. Without `--scope`, argparse prints a usage error and exits 2. `--force` turns off the refusal and changes nothing else about the run.

## Install

```bash
npx skills add kendrick/skills --skill memory-consolidate
```

To install by hand, clone the collection and copy this directory in:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/memory-consolidate ~/.claude/skills/memory-consolidate
```

It needs Python 3 and `ltm` from [long-term-memory-kit](https://github.com/kendrick/long-term-memory-kit) on your `PATH`, and a scope whose `_memory/` is a valid bank, as `inbox-to-memory` scaffolds it. The script uses only the standard library. Without `ltm`, run `ltm doctor --json` somewhere it is installed and pass the saved file with `--json`.

## Use

```
> consolidate memory
> check memory health
> what's gone stale in _memory
```

Then resolve the report through `inbox-to-memory`:

```
> resolve today's consolidation report with inbox-to-memory
```

## Known Limitations

- A same-day rerun with `--force` overwrites that day's report and every line Phase 5 resolved in it. The script also refuses a report it can't read, because it can't tell whether that report holds a resolved line.
- A line you decline has no way to say so. Phase 5 dismisses only contradiction flags, so a declined finding stays in that report's `unpromoted_candidates` count until a later report replaces the report.
- A record title containing `|` or `]]` goes into the wikilink unescaped, which breaks that link.
- The skill finds what `ltm doctor` finds and nothing more. Near-duplicate records are out of scope until the kit adds a check for them (kendrick/long-term-memory-kit#130).

The decision ledger behind these choices is [`_maintenance/memory-consolidate/RATIONALE.md`](../_maintenance/memory-consolidate/RATIONALE.md).
