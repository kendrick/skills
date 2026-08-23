# JD Skill Set Sources

Shared by `jd-file` and `jd-audit`. Every rule either skill states, and every check `scripts/validate.py` runs, was written from this vault's own scanned structure—not copied from anything below. This file exists so a later reader can trace where an idea came from, not where a sentence did.

## Johnny.Decimal

The Johnny.Decimal system itself is free to use. Its documentation prose at [johnnydecimal.com](https://johnnydecimal.com) is licensed CC BY-NC-SA, which permits reading and citing it but not lifting its wording—and this skill set doesn't. Every rule embedded in `jd-file`, `jd-audit`, and the vault's own `00.02 Vault Conventions.md` was written from scratch against how this vault actually works, with zero sentences traceable back to the site's prose.

The topics below informed the design. Each was read on the date listed, so a later reader can diff the live site against what's recorded here instead of re-deriving the reasoning from nothing.

| Topic | Consulted |
| --- | --- |
| The `AC.ID` address scheme | 2026-08-22 |
| Areas grouping categories in tens | 2026-08-22 |
| One thing, one place | 2026-08-22 |
| The index as the system's master record | 2026-08-22 |

## `ngerakines/jd`

Structural ideas, not prose, are adapted from [`ngerakines/jd`](https://github.com/ngerakines/jd) at commit `b85e42e`, licensed Apache-2.0, copyright Nick Gerakines. The ideas carried forward:

- **The ask/act ladder.** Routine filing acts on its own; a batch gets one confirmation for the whole table; a new ID inside an existing category gets a confirm; a new area or category always asks first.
- **Three-tier confidence gating.** Would you bet money on it, would you want a second opinion, or are you genuinely guessing—and the rule that follows from it: when asking, name the specific candidate, never "where should this go?"
- **The orientation-before-mutation phase.** Load the register and the actual folder structure as two separate observations before classifying anything, so they can be compared instead of quietly conflated.
- **The refusal to auto-repair.** The register is authoritative for what should exist; the substrates are authoritative for what does. When they disagree, report it and stop.

The full analysis this skill set was built against—inventory, architecture, the ask/act and confidence-gating passages quoted verbatim with line citations, and where the prior art's assumptions break for an Obsidian-primary vault—is [`_docs/jd-ngerakines-plugin-report.md`](../../_docs/jd-ngerakines-plugin-report.md).
