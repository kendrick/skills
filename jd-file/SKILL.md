---
name: jd-file
description: Give an incoming thing its AC.ID number, put it in the right tree, and write its register line in one motion. Use when the user says "where should I file this", "what number goes here", "give this an ID", "does this get a number", "add a client", "add a project", "organize this", "put this in my vault", "I don't know where this lives", or "should this be a new category"—and when a PDF, deck, transcript, note, or repo arrives with no obvious home. Use it before creating any folder inside a numbered tree, because a number on disk that nothing recorded is indistinguishable from drift. Not for grooming a project or client inbox into memory records, which is inbox-to-memory; not for checking the whole system for consistency or reconciling the register against the folders, which is jd-audit.
---

# jd-file

Filing and recording are one motion, not two. The tempting split—give it a number now, update the index later—produces the exact rot an index-first system exists to prevent. The thing sits on disk, nothing knows about it, and the next person to file something similar reads the register, finds no match, and mints a second number for the same subject. Now one subject holds two IDs, both defensible, and the only way to discover it is to compare labels across three trees by hand. So the register line gets written before the folder gets created, and an ID missing from the register has not been assigned yet.

Where a step names a shell command, treat it as the intent and use your native shell or file tools.

Resolve once per invocation:

- **VAULT** — the vault root, resolved fresh in Step 1 on every invocation.
- **CONVENTIONS** — `00.02 Vault Conventions`, the grammar this skill and `jd-audit` both read. Its first fenced `toml` block is the configuration. Every rule below names a key in that block instead of repeating its value, because a value copied into prose is a value that will eventually disagree with the script reading the block.
- **REGISTER** — `00.01 JDex`, at `[register].path`. The master record: one line per ID, carrying its purpose clause and the substrates that hold it.
- **CONSTITUTION** — `00.00 Johnny Decimal Index`, at `[constitution].path`. Why the system is shaped the way it is, at category granularity. It owns the classification framework Step 2 runs on.
- **THING** — what is being filed, and where it sits right now. Say what it is out loud before deciding anything: half of all "where does this go" questions are really "what is this", and answering the second one first usually settles the first.

<!-- BEGIN SHARED POLICY — the ask/act ladder and the confidence gate. Written to be self-contained: if this body outgrows its budget, lift this section into references/ whole rather than paraphrasing it. jd-audit states its own fix tiers in its own words for its own domain; this is not a shared include. -->

## Asking and Acting

| Action | Tier |
|---|---|
| Filing into an existing ID that clearly matches | Act, then report what you did and where. |
| Several items at once | Propose the whole batch as one table and take a single confirmation. |
| A new ID inside an existing category | Confirm before creating it. |
| A new category, or a new area | Never without explicit approval. |

Filing fills the system, a new ID extends it, and a new category reshapes it: the tier tracks how much of the system an action changes, not risk of loss, since nothing here deletes anything. Reshaping is the user's call because they carry the consequences for years; the constitution's own success test is that notes rarely need to move.

Run the confidence gate on the classification first, then let the ladder decide how to ask:

- Would you bet money on it? Act.
- Would you want a second opinion? Recommend one destination, name the runner-up, and confirm.
- Are you guessing? Put two or three candidates in front of the user with the reasoning behind each, and let them pick.

When you ask, be specific. "Where should this go?" hands the work straight back. "This looks like `32.02 Vehicles`, a new ID for vehicle ownership and coverage records—create it?" is a question that closes in one word.

**Report and stop.** The register says what should exist; the folders say what does. When the two disagree, name the disagreement, hand it to the user as a finding for `jd-audit`, and leave both sides as they stand. Creating, renaming, or deleting to make them agree destroys the evidence of how they diverged, and reconciliation is `jd-audit`'s job, not a chore to absorb mid-filing.

<!-- END SHARED POLICY -->

## Step 1 — Orient Before Any Mutation

Nothing carries over between invocations. The vault is hand-edited in Obsidian, on more than one machine, through a sync client; state remembered from an earlier run is a claim about a tree that has since changed underneath you.

Work in order:

1. **Resolve VAULT.** Look up the current hostname in `[hosts]`. No entry means probing `[discovery]` in the order given: exactly one hit is a confirmation, and several hits or none is a question for the user rather than a guess.
2. **Load the conventions block.** Check `schema_version` before reading any other key. An unrecognized version stops the run—a half-understood grammar does not fail loudly, it files things in the wrong place with total confidence.
3. **Load REGISTER and CONSTITUTION.**
4. **Snapshot the target category across all three substrates**, resolving each one's root and walking it according to its declared `shape`. Honour each substrate's `scope`: an ID outside a substrate's scope is absent by design, and reading that absence as a gap is how a filer starts creating folders nobody wanted.

Keep the register and the folders as two separate observations all the way through. Merging them into one picture is precisely how a tool silently "fixes" a disagreement it was supposed to report; once merged, the conflict is unrecoverable. If the two disagree about the category you are about to file into, report and stop.

**Done when:** VAULT is named, the schema version is accepted, and you can state the target category's contents twice—once from the register, once from the folders of every in-scope substrate—and say whether the two agree.

## Step 2 — Classify

Use the constitution's decision framework rather than inventing one, because it encodes choices the user already made and would have to re-litigate otherwise:

1. **Clearly one category?** Place it there.
2. **Plausible in several?** Tag it and leave it in the inbox. Forced filing is the failure this whole system is built to avoid: a note buried under a number that felt right once is harder to recover than a note that never left the inbox.
3. **Temporary or scratch?** The inbox.
4. **Genuinely dead?** The cold archive. Completion is not death—a finished project keeps its ID and changes its status metadata, and the constitution is explicit that project completion must never trigger refiling.

Then run the confidence gate from **Asking and Acting**. A classification you would not bet money on is a candidate list, not a destination.

**Done when:** the thing has one named destination category and the confidence tier it was settled at, or an explicit decision to leave it in the inbox along with the tags that will make it findable there.

## Step 3 — Decide the ID

Three outcomes, in ascending cost: an existing ID absorbs it, a new ID joins an existing category, or a new category gets created. Default hard toward the first. An ID minted for a single document is an ID that sits near-empty for years and then competes with the one the subject actually needed.

Read [references/id-assignment.md](references/id-assignment.md) before minting anything—it carries the expansion test, how to find the next free number without pattern-matching, the `[rules].meta_slot_item` reservation, and the tests that separate a genuinely new category from a subtype of an existing one.

Mint only a number confirmed absent in both the register and every in-scope substrate. Checked against one source alone, a number already taken in the other still reads as free—and that gap between the two is exactly the drift this step must not add to.

**Done when:** a specific AC.ID and label are named, the number is confirmed absent from the register and from every in-scope substrate, and the ladder tier for creating it has been declared out loud.

## Step 4 — Pick the Substrate

Precedent decides first: whatever the target category already does, do. `[substrate_selection].follow_category_precedent` says so, and consistency inside a category beats a rule imported from outside it—one deck in the vault beside nine in the office tree is worse than either arrangement applied uniformly.

Read [references/substrate-selection.md](references/substrate-selection.md) when the category is empty, when the thing plausibly spans substrates, or when its artifact type is not obviously covered by the map in `[substrate_selection]`.

An ID living in more than one substrate is normal, not duplication—a client is notes in the vault, decks in the office tree, and repos in code. The folder name is the join key across all of them, so it is decided once, here, and spelled identically everywhere.

**Done when:** the category's precedent has been read off its existing IDs (or, for an empty category, the user has chosen), every substrate that will hold this ID is named, each one's `scope` admits it, and a single folder name is settled that will be spelled byte-identically in all of them.

## Step 5 — Write the Register Entry, Then Create the Thing

The register line comes first: the ID exists the moment it is recorded, so anything created ahead of the line is unrecorded by definition.

Write one line matching `[register].entry`, under the `###` category heading that matches its category, under the `##` area heading that matches its area. If the category has no heading yet, add one mirroring the constitution's label exactly—the register mirrors the constitution, and a mirror nobody checks is just two copies drifting. If the register is missing lines for IDs the folders already hold, report and stop on those: they belong to `jd-audit`, and this is not the moment to backfill them.

The **purpose clause** states what the ID is for—the sentence a future filer reads to decide whether the next arrival belongs here. Write it to outlive every file underneath it, as a rule admitting a class of thing rather than an account of today's contents, which are stale within a month.

Then create the folder in each listed substrate, with the identical name, and put the thing inside. Notes a person writes by hand inside an ID are Title Case with no number, since the folder already carries the number; notes another skill manages keep their generated names untouched. `[naming]` is the authority on both. Cross-substrate references take the absolute percent-encoded form `[links]` describes, and they break silently on rename—one more reason the name was settled in Step 4.

In the vault substrate only, create `Overview.md` inside the new ID folder from [assets/overview.template.md](assets/overview.template.md), filling the placeholders from the ID just minted. Numbering stops at the ID, so this note is what a reader orients by in the depth below it, and it gets created in the same motion as the ID itself—an overview left for a human to add later is the give-it-a-number-now, record-it-later split all over again. `Overview.md` is skill-managed, so it keeps its generated name; the Title Case rule above is for hand-authored notes. Never copy the purpose clause into it—the note's own callout says why. On machines without Dataview, the Rollups section renders as visible query text. That is deliberate: the same file syncs to every machine, and everything above that section is plain markdown. Skip the note in the office and code trees, where its queries mean nothing.

Filing into an ID that already holds an `Overview.md` appends one line to its `## Log`: `- **YYYY-MM-DD** — filed <filename>`. Append only—never rewrite existing lines, never touch other sections. The Log records what this skill did, not what the ID contains. An inventory would go stale the first time a human adds a file by hand—the register anti-pattern one level down.

When the category is one `[moc].categories` names, run `scripts/build_moc.py --vault VAULT` right after creating the folder—minting the ID is what makes the map stale. The map is generated, so it's safe to rewrite—there's no confirmation tier here. Regenerating touches only the block between the markers, leaving the prose around it untouched. Contrast the register above, written by hand before the folder exists.

Obsidian syntax, frontmatter mechanics, and vault CLI usage belong to `obsidian-markdown`, `obsidian-bases`, and `obsidian-cli`. Invoke them.

**Done when:** the register line exists, matches `[register].entry`, sits under the correct headings, and its purpose clause would settle the next arrival without naming any current file; every substrate folder listed on that line exists with the identical name; the thing is inside one of them; a newly minted ID's vault folder holds an `Overview.md` built from the template; and, for a category `[moc].categories` names, its map table includes the new ID.

## Anti-Patterns

| Anti-pattern | Instead |
|---|---|
| Minting a number that looks plausible without reading the folders | Mint from the union of the register and every in-scope substrate. A number taken on looks alone surfaces months later as two IDs answering to one name. |
| Creating a category when an ID would do | Mint the ID. Categories are the stable layer, and one created for a single subject is a permanent structural change bought to dodge a two-minute naming decision. |
| Adding a fourth numbered tier | Use a named subfolder. Numbering stops at AC.ID, and depth *below* an ID is unnumbered, free-form, and deliberately deep—client scopes run ten directories down. Read the invariant as "no fourth numbered tier"; it says nothing about nesting. |
| A register entry that inventories what is filed inside the ID | Write the purpose clause Step 5 defines. Contents turn over and a list of them is stale within the month, while the question the entry has to answer—does the next thing belong here—outlives every file under it. |
| Proposing a standard-zero management item | Treat an `AC.00` as ordinary content where one exists and expect none where it doesn't (`[rules].standard_zeros`): `00.00` is vault-wide meta, `15.00` is an ordinary ID, and a category without one is complete. |
| Filing into the legacy trees at the vault root | File into the numbered tree. `[ignore].vault_top_level` names the legacy trees; they predate the system, so they are neither drift nor destinations. |
| Renumbering an existing ID to make room | Take the next free number and leave the gap. Gaps are free; absolute `file://` links encode the old name and die without a sound. |

## Worked Example — A Car Insurance Renewal Lands

**Orient.** The hostname resolves VAULT from `[hosts]`; `schema_version = 1` is recognized. The constitution describes `32 Property & Records` as property and legal records—HOA documents, deeds, surveys, insurance, warranties. Snapshot category 32: the vault holds `32.01 HOA` and nothing else. The office substrate's scope is area 10-19 and the code substrate's is category 11, so neither carries area 30-39 at all; their silence is by design, not absence. The register's account of category 32 matches the folders.

**Classify.** Insurance is named in the category's own description, so this is rule 1—clearly one category. Money-bet confidence.

**Decide the ID.** `32.01 HOA` is about the homeowners association, so no existing ID absorbs a vehicle policy; expansion fails. A new `33 Vehicles` category fails too—32 is already the home for property and legal records, and splitting records by subject buys maintenance the constitution explicitly refuses. So: a new ID inside 32. `32.01` is taken and nothing argues for a gap, making `32.02` the next free number. Label it `Vehicles`, not `Car Insurance`—the next arrivals are a title, a registration renewal, a service record, and an ID named after the document that happened to arrive first gets re-minted within the year. Minting a new ID inside an existing category is the confirm-first tier, so state the number and its purpose and wait.

**Pick the substrate.** Personal content, and the office and code substrates carry only area 10-19 and category 11 respectively. The vault is the only tree whose scope admits this ID, and `[substrate_selection]` routes notes there regardless. One substrate: vault.

**Result.** The folder:

```
<VAULT>/30-39 Home & House/32 Property & Records/32.02 Vehicles/
```

The note inside it, hand-authored and so Title Case with no number: `Auto Insurance.md`. Beside it, the scaffolded `Overview.md`, its Log opening with `- **2026-08-23** — created`. The PDF goes to that ID's own `_attachments/` folder, per the constitution's attachment rule for ID-specific files.

The register entry, written before any of that exists, under `## 30-39 Home & House` → `### 32 Property & Records`:

```
- `32.02 Vehicles` — Vehicle ownership and coverage records: policies, titles, registrations, service history. [vault]
```

## Further Reading

- [references/id-assignment.md](references/id-assignment.md) — read at Step 3, before minting any number, and before ever proposing a new category
- [references/substrate-selection.md](references/substrate-selection.md) — read at Step 4 when the category is empty, when a thing spans substrates, or when its artifact type is not obviously mapped

## Sources

- `00.00 Johnny Decimal Index` in the vault — the constitution: the classification framework in Step 2, the item-creation test, the attachment rule, and the stability philosophy the ladder defends.
- [johnnydecimal.com](https://johnnydecimal.com) — the underlying system. Free to use; its documentation prose is not, so every rule here is written from the vault's own dialect.
- `_docs/jd-ngerakines-plugin-report.md` — analysis of the Apache-2.0 prior art at `ngerakines/jd` (commit `b85e42e`), from which structural ideas were adapted.
