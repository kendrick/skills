# Substrate Selection

Read this at Step 4 when the target category holds nothing yet, when the thing plausibly belongs in more than one tree, or when its artifact type is not obviously covered by the map in `[substrate_selection]`.

"Which substrate" asks where a file is easiest to reach and hardest to lose. No tree is more official than another; they are joined by the JD folder name and differ only in what they hold and who can reach it.

## Precedent beats the type map

Read precedent by listing the category's existing IDs in each substrate and seeing where they cluster. Precedent belongs to the category, not to the artifact—a category whose IDs all live in the office tree takes the next one there even when the arriving thing is a note, because a category you can browse in one place is worth more than a category filed correctly in three.

## An empty category is a question, not a default

`[substrate_selection].when_category_empty` says ask. The first ID in a category sets the precedent every later ID inherits, so a silent default here is a decision made on the user's behalf that they will live inside for years.

Ask with the candidates named and the consequence of each stated: which tree the content syncs through, who else can reach it, and what the category will look like once ten IDs follow the same path. That is a question the user can answer quickly; "vault or office?" is not.

## Scope is a constraint, not a preference

Each `[[substrate]]` declares the areas or categories it carries. That declaration is what makes absence meaningful: an ID missing from a substrate outside its scope is missing by design, and the validator reports nothing. Ignore scope and every personal ID becomes a phantom gap in two trees.

So scope filters the candidates before the type map speaks. When the two disagree, scope wins and the type map was answering a question that was never open.

Create a folder only where the ID will hold content and the scope admits it. One added for symmetry is drift the moment it exists, and it reads to `jd-audit` exactly like a filing mistake, because that is what it is.

## IDs that span substrates

Two rules make spanning work:

**Spell the folder name byte-identically in every tree**—same words, same capitalization, same ampersands, same spacing. The name is the only join key, and a shortened one in a single tree breaks the join silently: every tree still looks fine on its own, and nothing surfaces until someone compares them deliberately. This is the most expensive mistake available at this step, so settle the name once, before creating anything.

**Split the content by artifact type.** A deck is an office-tree artifact whether it was written in week one or week forty. Splitting by project phase instead requires files to move as work progresses, which is the refiling the whole system exists to avoid.

The register entry lists every substrate that holds the ID. Listing a substrate that does not hold it, or holding it in one that is not listed, are both reportable drift—which is why the list is written in Step 5 from what will actually be created, not from what seems likely.

## Cross-substrate references

References between trees take the absolute percent-encoded form `[links]` describes. They encode one machine's mount points, so a link written on one host is unverifiable rather than broken on another, and `jd-audit` distinguishes the two.

Nothing in the vault's link maintenance reaches across substrate boundaries, so a folder renamed in one tree leaves live-looking links pointing nowhere. Treat every cross-substrate link as a commitment to the current name.

Build every path from the roots Step 1 resolved for this machine, rather than from one remembered off another host.

## Naming and ordering inside an ID

An address has exactly two numbers, category and item—area is a label for the ten categories it spans, not a third component. The depth invariant in `references/id-assignment.md` protects that count from below; this section is about what goes inside the ID once the count is settled.

Ordering that content is a separate question, and the system sanctions three answers, in the order to reach for them:

- **A name that already sorts** — no prefix needed, and the default whenever a name alone puts things in a useful order.
- **An ISO date prefix** (`2026-08-04 Something.md`) — for anything whose natural order is chronological.
- **A bare `10`, `20`, `30`…`90` prefix** — for whatever neither of the above orders the way a reader needs; the gaps leave room to insert later without renumbering what's already there.

The distinction worth holding onto: a prefix orders, it does not address, and it stays that way only while it stops short of repeating the ID. `01 Some Note.md` inside `80.01 Juno Beach 2026` is the blessed pattern—it sorts the folder and claims nothing more. `80.01.01 Some Note.md` in the same folder claims a third address segment the system never assigned, and the next reader will believe it.

Nest subfolders shallow where that's convenient. The system states it as a preference, not a ceiling the depth invariant enforces, so a client scope that runs many levels deep is a legitimate reading of that same preference, not a violation of it.

## Trees that are not filing targets

Content moves *out* of the legacy trees `[ignore].vault_top_level` names, during a migration the user drives. They predate this system, so their contents are not drift and their state is not this skill's problem.

Scopes listed in `[ignore].link_scan_skip` run under their own charter and their own internal structure. Respect the exception rather than normalizing it; each one exists because the user decided it should.
