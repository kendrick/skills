Finish migration with a Tier 2 sidecar and a verification sweep

Tier 1 gave a v1 scope everything a script can derive from the file itself. `summary` and `entities` are the two keys it couldn't: they are a reading of the note rather than a fact about it, and a generated summary nobody sourced is worse than an absent one, because the skill later greps that key as fact.

So generation stays with the model, enforcement stays in the script, and a file sits between them. `--tier2-extract <dir>` writes each v1 note's extracted sections plus a proposals skeleton and touches nothing in the scope. The agent fills in summary and entities from that extract and nothing else. `--tier2 <file> --apply` merges them into the Tier 1 rewrite, refusing any entity that doesn't appear in that note's own extract (`tier2-entity-unsourced`) and any summary spanning lines (`tier2-summary-multiline`), and leaving the note byte-identical when it refuses rather than half-written. The extract stops at `## Raw Content` using the same extraction the derived counts already use, so there is no second copy of that rule to drift and quietly widen what Tier 2 gets to read.

Tier 2 is gated on its own. A plain `--apply` writes neither key, approval is per file or one batch, and a note the proposals file omits comes out identical to a Tier-1-only apply. Rejecting a proposal is an absence, not a rollback.

`verify-migration.sh <scope> --since <ref>` is the closing sweep. It's a separate script because it has to work on a migration someone committed last week, and it reads git history rather than `git status`, which reports a clean tree for exactly that case. It lints the scope off the lint's exit status instead of its output, so an aborting lint can't pass for a clean one. It checks every wiki-link target the scope carried at the ref, by name and then by nanoid, and says how many took the fallback. Anything with a file status other than `M` fails. The sweep reports and never repairs: it prints every failure rather than the first, changes nothing on disk, and on a passing run ends with one paragraph for the user to paste into the patterns journal—stdout only, never written anywhere.

The docs now describe both halves. `references/migration.md` no longer claims Tier 2 is unimplemented, and the smoke test pins the flags and the new script by name in SKILL.md, plus the extract stopping at the fence, both refusals leaving the note untouched, the subset and batch applies, the committed rename that porcelain would miss, and a record whose counts match the run that printed them.

Closes #16
