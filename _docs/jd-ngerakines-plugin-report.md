# ngerakines/jd Plugin Analysis Report

> Exploration report from a read-only agent, captured verbatim on 2026-08-22 during planning for the JD skill set. Companion to `jd-vault-system-report.md` and `jd-repo-house-style-report.md`. The clone analyzed here lived in session scratchpad (ephemeral); the commit SHA below is the durable pointer. This is the input the JD skills' SOURCES.md and RATIONALE decision ledgers trace back to. The source repository is licensed Apache-2.0, copyright Nick Gerakines, and passages quoted in this report are reproduced under that license with file and line citations.

Cloned and read every file (17.7k words total, all Markdown/JSON — zero executable code).

Source: `https://github.com/ngerakines/jd` — single commit at HEAD: `b85e42e Add jd-next-action skill for "what do I need to do next?" reports (#4)`. Plugin version `1.2.0`.

---

## 1. INVENTORY

Full tree (excluding `.git`) — 21 files, 372K, **no scripts of any kind** (only `.md`, `.json`, and two identical `LICENSE` files):

```
/.claude-plugin/marketplace.json         13 lines   (marketplace "jd-plugins", owner Nick Gerakines)
/README.md                               46
/LICENSE                                201        (Apache-2.0, verbatim, unfilled appendix)
/jd/.claude-plugin/plugin.json            8         (name "jd", version 1.2.0)
/jd/README.md                           138
/jd/LICENSE                             201        (byte-identical to root LICENSE)
/jd/commands/
    jdex-audit.md                        49
    manage-tasks.md                      58
    next-action.md                       61
    process-inbox.md                     47
    setup-system.md                      41
    sub-index.md                         45
/jd/skills/
    jd-inbox-processor/SKILL.md         443   (2481 words)
      references/jd-system-rules.md     211   ( 986 words)
      references/classification-heuristics.md 175 (1080 words)
    jd-jdex-audit/SKILL.md              203   ( 854 words)
    jd-next-action/SKILL.md             512   (2624 words)
    jd-sub-index/SKILL.md               218   ( 874 words)
    jd-system-setup/SKILL.md            265   ( 990 words)
    jd-task-manager/SKILL.md            878   (4475 words)
      references/jdtodo-spec.md         546   (3347 words)
```

**Skills (6):** `jd-inbox-processor`, `jd-jdex-audit`, `jd-next-action`, `jd-sub-index`, `jd-system-setup`, `jd-task-manager`.
**Commands (6):** `/jd:process-inbox`, `/jd:jdex-audit`, `/jd:setup-system`, `/jd:sub-index`, `/jd:manage-tasks`, `/jd:next-action`.
**Agents: none.** No `agents/`, no hooks, no MCP config, no settings.

Command frontmatter is uniform: `description`, `argument-hint`, `allowed-tools: [Read, Glob, Grep, Bash, Write]` — except `next-action.md`, which correctly drops `Write` (read-only skill).

Skill frontmatter carries only `name` + a long `description` stuffed with trigger phrases. No `allowed-tools`, no `license`, no `version` on skills.

---

## 2. ARCHITECTURE

Decomposition is **by verb over a folder tree**, not by domain layer:

| Skill | Job | Writes? |
|---|---|---|
| `jd-system-setup` | Create the system from scratch: root, area folders, category folders, standard zeros, initial `00.00 JDex.md`, `00.02 Tasks.md`, `00.03 Processing log.md`. Ships 3 canned templates (Personal / Work / Child). | Yes (creates) |
| `jd-inbox-processor` | The centerpiece. Orient → discover inbox → read item → classify down Area→Category→ID → confidence-gate → rename with date prefix → move → extract tasks → append processing log → JDex maintenance. | Yes (moves) |
| `jd-task-manager` | Full CRUD over `jdtodo.txt` (todo/done/someday), incl. recurrence math, dependency graphs, weekly review mode, legacy `.md`→`.txt` migration. Largest body at 878 lines. | Yes |
| `jd-next-action` | Read-only aggregator: parses `todo.txt`, counts inbox and needs-review, buckets 1–8 (overdue → coming up), emits a dashboard. Explicitly forbidden from writing. | No |
| `jd-jdex-audit` | Three-way compare of JDex vs. filesystem: orphaned entries, undocumented folders, name mismatches; plus +SUB index check; optional JDex regeneration. | Yes (with consent) |
| `jd-sub-index` | Maintains `AC.ID+NNNN` / `AC.ID+CODE` index files, assigns next sequential +SUB, updates JDex. | Yes |

Reference files are used as progressive disclosure: `jd-system-rules.md` (spec restatement) and `classification-heuristics.md` (decision framework) hang off the inbox processor; `jdtodo-spec.md` (a full standalone format spec, v0.1.0) hangs off the task manager. `jd-next-action` cross-reads the task-manager reference via relative path — `/jd/skills/jd-next-action/SKILL.md:25`:

> ``For task parsing rules, read `../jd-task-manager/references/jdtodo-spec.md` ``

That `../` traversal across skill directories is fragile if skills are ever installed independently.

### Overlaps / copy-paste

**a) The orientation block is copy-pasted three times.** `jd-inbox-processor/SKILL.md:28-70`, `jd-task-manager/SKILL.md:28-82`, and `jd-next-action/SKILL.md:30-70` all carry identical §1.1 "Locate the JD Root" / §1.2 "Identify Systems" / §1.3 "Load Each System's JDex" text. Diffing inbox vs. task-manager shows only 5 hunks of drift — the "process my inbox" vs "show my tasks" example, one reflowed sentence, and the divergent JDex-missing consequence. `jd-jdex-audit/SKILL.md:19-33` and `jd-system-setup/SKILL.md:44-49` carry shortened variants of the same root list. The three iCloud/Documents/JD paths appear in all six skills plus `jd/README.md:110-114`.

**b) The actionability filter is duplicated verbatim** between `jd-task-manager/SKILL.md:180-190` and `jd-next-action/SKILL.md:92-102` (and again in the latter's Quick Reference at lines 502-512) — seven bullet conditions, three copies.

**c) Standard zeros tables appear four times** with *inconsistent* content: `jd-inbox-processor/SKILL.md:429-443`, `references/jd-system-rules.md:76-87`, `jd-system-setup/SKILL.md:102-120`, and `jd-task-manager/SKILL.md:851-878`. Setup writes `00.02 Tasks.md` (a file), while task-manager expects `00.02 Tasks/todo.txt` (a directory) and has to define a whole legacy-migration path (§10.2) to reconcile the plugin against its own setup skill.

**d) +SUB explanation duplicated** between `jd-sub-index/SKILL.md:21-53` and `references/jd-system-rules.md:96-135`, including the same `+REDD`/`+OAKS`/`+RIVR` and `+0001 weather-api` examples.

---

## 3. THE INBOX PROCESSOR — ASK/ACT POLICY (§8.1)

Verbatim, `jd/skills/jd-inbox-processor/SKILL.md:333-345`, section **"## 8. Interaction Principles" → "### 8.1 When to Ask vs. When to Act"**:

> ## 8. Interaction Principles
>
> ### 8.1 When to Ask vs. When to Act
>
> - **Act without asking**: Filing an item to a clearly matching existing ID with
>   proper date-prefix naming. This is routine and unambiguous.
> - **State and confirm in batch**: When processing multiple items, you can
>   propose a batch of filings and let the user approve them all at once rather
>   than one at a time. Present a table: item → proposed destination.
> - **Ask before acting**: Creating new IDs, creating new +SUB entries, archiving
>   or deleting items, moving items between systems, any classification with
>   medium or low confidence.
> - **Always ask**: Creating new categories or areas. These are structural changes.

The same policy is restated as a rule list at `jd-inbox-processor/SKILL.md:184-200` (§3.4 "Creating New IDs"):

> 1. **Never create a new area or category without explicit user approval.** These
>    are structural decisions that affect the whole system. Flag the need and ask.
> 2. **New IDs within an existing category are lower-stakes.** You may propose a
>    new ID, but always confirm with the user before creating it.

And restated a third time in the heuristics reference, `jd-inbox-processor/references/classification-heuristics.md:84-90`:

> ### Pattern: Item has no matching category
>
> Example: User starts a new hobby that doesn't fit any existing category.
>
> Resolution: **Do not create a new category.** This is a structural change that
> affects the system's architecture. Move the item to `00.08 Someday` or
> `00.04 Needs review` and flag it for the user to decide where it belongs.

The parallel policy for tasks lives at `jd-task-manager/SKILL.md:703-713` (§9.1, same heading name):

> - **Act without asking**: Listing tasks, showing filtered views, resolving
>   dependency graphs, enriching JD code references. These are read-only and
>   safe.
> - **Confirm before acting**: Completing tasks, cancelling tasks, moving tasks
>   between files (todo.txt ↔ done.txt ↔ someday.txt), modifying tasks the user
>   has specifically identified. Present the change and get a "yes."
> - **Always ask**: Deleting task lines (prefer moving to done.txt — never
>   truly delete without explicit user confirmation), modifying tasks that the
>   user hasn't specifically identified, creating task files or directories.

And for the auditor, `jd-jdex-audit/SKILL.md:153-176` (§5 "Offer Fixes") uses a three-tier "Safe Fixes (do automatically with confirmation)" / "Requires User Decision" / "**Never Do Automatically**" split — the never-tier being delete folders, rename folders, create new areas or categories.

---

## 4. CONFIDENCE GATING

Verbatim, `jd/skills/jd-inbox-processor/SKILL.md:166-182`, section **"### 3.3 Confidence Assessment"**:

> ### 3.3 Confidence Assessment
>
> After classification, assess your confidence:
>
> - **High confidence** (clear match, unambiguous): Proceed to filing.
> - **Medium confidence** (reasonable match, but another location is plausible):
>   State your recommendation and the alternative, then ask the user to confirm.
> - **Low confidence** (genuinely unclear): Present the top 2–3 candidate
>   locations with brief reasoning, and ask the user to choose.
>
> The threshold: if you'd bet money on the classification, it's high confidence.
> If you'd want a second opinion, it's medium. If you're guessing, it's low.
>
> When asking the user, be specific. Not "where should this go?" but rather:
>
> > This looks like a health insurance claim. I'd file it at **P10.34.01**
> > (Health insurance). Does that sound right, or does it belong somewhere else?

The betting-money line is the load-bearing calibration device and appears **only once** in the repo. It is backed by worked examples in `jd-inbox-processor/references/classification-heuristics.md:136-162` ("## Confidence Calibration" → "### High Confidence (act without asking)" / "### Medium Confidence (recommend and confirm)" / "### Low Confidence (present options and ask)"), e.g.:

> ### Low Confidence (present options and ask)
>
> - A cryptic filename with no readable content
> - An item whose subject matter doesn't match any existing area
> - Content that spans multiple domains with no clear primary focus
> - Anything in a language or notation you don't fully understand

Compressed restatement in the command layer, `jd/commands/process-inbox.md:30-34`:

> ## Classification Confidence
>
> - **High confidence**: File without asking.
> - **Medium confidence**: Recommend a destination and ask the user to confirm.
> - **Low confidence**: Present 2–3 candidate locations and ask the user to choose.

The task manager has a structurally similar but unnamed gate at `jd-task-manager/SKILL.md:415-422` (§5.1): one match → confirm; multiple → present candidates; none → say so.

---

## 5. ORIENTATION PHASE

Verbatim, `jd/skills/jd-inbox-processor/SKILL.md:28-72`, section **"## 1. Orientation: Discover the JD Environment"**:

> ## 1. Orientation: Discover the JD Environment
>
> Before touching any files, build a mental map of the user's JD setup.
>
> ### 1.1 Locate the JD Root
>
> The JD root folder is wherever the user's systems live. Common locations:
>
> - `~/Library/Mobile Documents/com~apple~CloudDocs/JD/` (iCloud Drive)
> - `~/Documents/JD/`
> - `~/JD/`
> - A project-specific folder the user designates
>
> If you don't know the root, ask the user. If the user says "process my inbox"
> without further context, check the most common locations above. If you find
> exactly one, confirm it. If you find multiple or none, ask.
>
> ### 1.2 Identify Systems
>
> List the top-level folders under the JD root. Each folder whose name matches
> the pattern `[A-Z][0-9][0-9] *` is a JD system (e.g., `P10 Personal`,
> `W20 Work`, `C40 Citywide`).
>
> If the user has a single system (no SYS prefix), that's fine — treat the
> entire JD root as one system.
>
> ### 1.3 Load Each System's JDex
>
> For every system you'll process, read the JDex file at:
>
> ```
> SYS/00-09 */00 */00.00 *JDex*
> ```
>
> The JDex is the authoritative index of every area, category, and ID. It is
> your primary classification reference. If the JDex is missing or empty for a
> system, fall back to reading the folder structure directly — but flag this to
> the user as something that should be fixed.
>
> ### 1.4 Snapshot the Folder Structure
>
> For each system, list the area folders, category folders, and ID folders to
> depth 3. This gives you the physical layout to validate against the JDex and
> to discover any folders not yet in the index.

Three properties worth stealing: (a) "Before touching any files" as a hard precondition; (b) the *exactly-one-else-ask* disambiguation rule; (c) index and disk are loaded as **two separate observations** so they can be compared rather than conflated.

`jd-jdex-audit/SKILL.md:19-52` runs the same three steps under "## 1. Locate the System" with an explicit parse step: "Parse it into a structured list of areas, categories, and IDs. Each entry should capture: The AC.ID (or SYS.AC.ID) address / The description/name / Any +SUB entries."

---

## 6. REFUSE TO AUTO-REPAIR

The core statement, `jd/skills/jd-inbox-processor/SKILL.md:382-384`, section **"## 9. Error Handling"**:

> - **JDex/folder mismatch**: If the JDex says an ID exists but the folder
>   doesn't (or vice versa), flag the inconsistency. Don't silently create or
>   delete anything to "fix" it — the user decides.

The authority split that makes this coherent, `jd-inbox-processor/references/jd-system-rules.md:168-170` ("## The JDex"):

> When classifying inbox items, **always consult the JDex first**, then validate
> against the folder structure. If they disagree, the JDex is authoritative for
> what *should* exist; the filesystem is authoritative for what *does* exist.

The audit skill's version, `jd-jdex-audit/SKILL.md:161-175` (§5):

> ### Requires User Decision
>
> - **Orphaned JDex entries**: Ask whether to create the missing folder or
>   remove the JDex entry.
> - **Name mismatches**: Ask which name is correct (JDex or folder) and
>   update the other.
>
> ### Never Do Automatically
>
> - **Delete folders**: Even if they appear orphaned, never delete without
>   explicit user confirmation.
> - **Rename folders**: Name changes can break references. Always confirm first.
> - **Create new areas or categories**: These are structural decisions.

And the regeneration guard, `jd-jdex-audit/SKILL.md:190-191`:

> **Warning**: Regeneration loses any JDex entries that don't have corresponding
> folders. Always confirm before proceeding.

Related non-repair stances: `jd-task-manager/SKILL.md:794-800` on circular `dep:` chains — "Suggest removing one of the dependencies to break the cycle. / Do not modify anything automatically."; `jd-task-manager/SKILL.md:781` — "Rename `00.02 Tasks.md` to `00.02 Tasks.md.bak` (do not delete)."; `jd-next-action/SKILL.md:470-473` — unparseable task lines get a `[parse error]` flag and are surfaced, never skipped.

---

## 7. VALIDATION / SCRIPTS

**There are zero scripts.** No `scripts/`, no `.py`, `.sh`, `.js`, `.ts`, no `Makefile`, no CI workflow, no tests. Every fenced code block in the repo is either a folder-layout illustration, a Markdown output template, or a format example — nothing is executed. All "validation" is prose instructions for the model to perform with Read/Glob/Grep/Bash.

The closest things to deterministic specifications, all prose-embedded:

- **One regex, stated twice**, `jd-task-manager/SKILL.md:135-137` and `references/jdtodo-spec.md:83-85`:
  > ```
  > \+([A-Z]\d{2}\.)?\d{2}\.\d{2}(\+[A-Za-z0-9]+)?
  > ```
- **One ABNF-style grammar**, `references/jdtodo-spec.md:450-467` (`logical-line = task-body [" --- " note-body]` …). Written for a parser that does not exist; the model is the parser.
- **Audit checks (prose, `jd-jdex-audit/SKILL.md:56-101`):** orphaned JDex entries (index→disk), undocumented folders (disk→index), name mismatches + malformed `AC.ID Description` names, and +SUB index vs. +SUB folders. Output is a fixed Markdown report skeleton with a summary count table (`jd-jdex-audit/SKILL.md:108-149`).
- **Actionability predicate** (7 boolean conditions) and **bucketing algorithm** (8 ordered buckets, first-match-wins, with a 3-key sort) in `jd-next-action/SKILL.md:92-205` — genuinely algorithmic, entirely unenforced.
- **Recurrence date math** (strict vs. non-strict, gap preservation between `t:` and `due:`) in `jd-task-manager/SKILL.md:464-500` — arithmetic the model must do by hand, with no test fixtures.

Notably, the JD structural invariants that *could* be mechanically checked — max 10 areas, max 10 categories/area, `.01`–`.99` ID range, no files at area/category level, unique `id:` per file — are asserted in prose (`references/jd-system-rules.md:18-44`, `jd-task-manager/SKILL.md:803-809`) and never verified.

---

## 8. WEAKNESSES

**Spec restatement.** `references/jd-system-rules.md` is 211 lines of Johnny.Decimal spec paraphrase — hierarchy, AC.ID decoding, SYS prefixes, "2,600 possible system codes", +SUB, standard zeros, plus a "## Core Philosophy" section (lines 195-212) that quotes JD doctrine ("Decide and document", "The goal is to reduce mental burden. It is not to use up all the numbers."). Roughly 40% of the file is teaching the spec rather than instructing behavior, and it duplicates material already in `jd-inbox-processor/SKILL.md:411-443`, `jd-sub-index/SKILL.md:21-53`, and `jd/README.md:122-134`. `jdtodo-spec.md` similarly restates todo.txt (§1.1–1.4 are pure todo.txt) before adding anything new, and includes a client-compatibility matrix (§11.2, naming Sleek/topydo/SimpleTask/SwiftoDo) that is pure reference trivia for an agent that will never use those clients.

**Oversized bodies.** `jd-task-manager/SKILL.md` at 878 lines / 4,475 words is far past comfortable always-loaded skill size, and it *still* defers to a 546-line reference — meaning a single "mark that done" can pull ~1,400 lines into context. `jd-next-action/SKILL.md` (512 lines) spends §4.1–4.12 hand-drawing twelve Markdown output templates that differ only in column headers, then repeats the bucket table and actionability list again as "Quick Reference" (lines 489-513). The inbox processor's §10 summary template and two Quick Reference sections are similarly redundant with §5's log format. Compression targets: one shared orientation reference, one shared actionability predicate, one output-format section instead of twelve.

**The jdtodo.txt task layer is a second product bolted on.** It invents a *new file format* (v0.1.0, dated February 2026, `~` cancellation marker, ` --- ` note separator, `\` continuation, `before:`/`after:`, `id:`/`dep:`/`sup:`) with no reference implementation, no validator, and no ecosystem support — the spec's own §11.2 admits `before:`, `after:`, `~`, ` --- `, and `\` are supported by *no* existing client. The plugin also contradicts itself: `jd-system-setup/SKILL.md:110` creates `00.02 Tasks.md` while `jd-task-manager/SKILL.md:71-81` wants `00.02 Tasks/todo.txt`, forcing a legacy-migration section (§10.2) to fix a mess the same plugin creates. And `jd-inbox-processor` §4.2 writes tasks in Markdown-checkbox format, requiring `jd-task-manager/SKILL.md:673-684` (§8.3 "Task Extraction Compatibility") to referee the conflict at runtime. Three formats, two skills, one directory. Meanwhile `jd/README.md` never documents `/jd:next-action` or `jd-next-action` at all — the tables at lines 13-31 list only 5 commands and 5 skills; the newest feature is undocumented outside `plugin.json`.

**Assumptions that break for an Obsidian-primary system.** The whole design assumes *folders are the system and the index is a mirror*:

- Every locator is a filesystem glob — `SYS/00-09 */00 */00.00 *JDex*` (repeated in 4 skills) and `SYS/00-09 */00 */00.01 Inbox/`. An Obsidian vault where each ID is a **note** (`11.23 Furnace maintenance.md`) with frontmatter, and where the "inbox" is a tag, folder-free query, or Bases view, matches none of these patterns.
- "Filing" is defined as **moving a file** (`jd-inbox-processor/SKILL.md:214`, "Move the file from the inbox to the destination ID folder"). In an Obsidian-primary system, filing is more often *linking* — adding `[[11.23 Furnace maintenance]]`, setting a property, or writing into an existing note. The plugin has no concept of a note-to-note relation; its only cross-reference mechanism is a `_reference.md` stub file (`references/jd-system-rules.md:174-187`) rather than wikilinks.
- The JDex is treated as a **single flat Markdown file** at `00.00 JDex.md` (`references/jd-system-rules.md:159-160`), authoritative and hand-maintained. If the index is instead many notes — one per ID, with frontmatter `id: 11.23` — then "read the JDex file" fails, the audit's index→disk diff has no left-hand side, and `jd-jdex-audit`'s regeneration (§6) would flatten a graph into a list.
- `references/jd-system-rules.md:207-208` — "**Nothing in area or category folders.** All files live in ID folders" — is unenforceable and arguably wrong in a vault where MOC/index notes legitimately sit at the category level.
- Date-prefix renaming (`YYYY-MM-DD Description.ext`, stated in 3 places) **breaks wikilinks**. Renaming `Untitled.md` → `2026-02-08 Buyer meeting notes Red Door.md` (`classification-heuristics.md:132`) silently orphans every `[[Untitled]]` reference; nothing in the plugin updates inbound links or even warns about them.
- No awareness of `.obsidian/`, attachment folders, templates, dataview/Bases queries, or aliases. The `00.01 Inbox/` folder scan would also happily walk hidden plugin directories.
- Multi-system is modeled as sibling top-level `[A-Z][0-9][0-9] ` folders under one root — which for a vault means either multiple vaults (the JDex globs then break) or an odd second-level nesting.

**Smaller issues.** The `../jd-task-manager/references/jdtodo-spec.md` cross-skill relative read (`jd-next-action/SKILL.md:25`) couples two skills at the filesystem level. `allowed-tools` grants `Bash` to five write-capable commands with no constraint on what Bash may do — the "never delete" invariants are prose-only and structurally unenforced. Root discovery hardcodes three macOS/iCloud paths with no config file, no env var, and no persistence: every invocation re-asks or re-guesses. §8.3 "Learning from User Decisions" (`jd-inbox-processor/SKILL.md:361-368`) explicitly scopes learning to "within the same session" — corrections are never written anywhere, so the same misfiling recurs next week.

---

## 9. LICENSING

**Apache License 2.0**, stock and unmodified. Two byte-identical copies (verified with `diff`): `/LICENSE` and `/jd/LICENSE`, 201 lines each — the canonical Apache-2.0 text including the boilerplate appendix, which is **left unfilled**:

> ```
>    Copyright [yyyy] [name of copyright owner]
>
>    Licensed under the Apache License, Version 2.0 (the "License");
> ```

There is no `NOTICE` file, no year, no named copyright holder in the license itself, and no per-file license headers. Authorship appears only in metadata: `.claude-plugin/marketplace.json` (`"owner": {"name": "Nick Gerakines"}`) and `jd/.claude-plugin/plugin.json` (`"author": {"name": "Nick Gerakines"}`). Both READMEs close with "Apache License 2.0. See [LICENSE](LICENSE)." (`README.md:44-46`, `jd/README.md:136-138`).

Third-party attribution is handled in prose, not in a NOTICE file — `jd/skills/jd-task-manager/references/jdtodo-spec.md:544-546`:

> ## Acknowledgments
>
> This specification builds on the [todo.txt format](https://github.com/todotxt/todo.txt) created by Gina Trapani, the [Johnny.Decimal system](https://johnnydecimal.com/) created by Johnny Noble, and de facto community extensions pioneered by [topydo](https://github.com/topydo/topydo), [SimpleTask](https://github.com/mpcjanssen/simpletask-android), [Sleek](https://github.com/ransome1/sleek), and [SwiftoDo](https://swiftodoapp.com/).

Johnny.Decimal itself is credited via links to `johnnydecimal.com` in both READMEs and the spec, with no statement about the JD system's own licensing/trademark posture — worth noting, since the plugin restates a substantial amount of JD's documented conventions in `references/jd-system-rules.md`. For reuse: Apache-2.0 permits derivation with attribution and a change notice; if you lift `jd-system-rules.md` or `jdtodo-spec.md` you inherit both the Apache obligations and this unresolved question about the underlying JD material.
