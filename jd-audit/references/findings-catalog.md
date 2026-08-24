# Findings catalog

Read this at Step 3 for each check that fired, and again at Step 4 before proposing a reconciliation.

The script's findings are the ground truth; this file supplies what each one means and what it costs to fix. One section per check ID: what the finding means in plain terms, what the plausible reconciliations are, and which fix tier it lands in. The check ID is the contract—the script emits it, this file is keyed on it, and an `[[exceptions]]` entry matches on it verbatim.

One behavior applies across every check. A register entry tagged `#conflict` is parsed normally, but findings about it are downgraded to `info` with a note that it is pending reconciliation—a seeded conflict is a decision already taken, not news.

| Check | Severity | Default tier | Catches in this vault |
|---|---|---|---|
| `register-grammar` | error | safe with confirmation, or user decision | — |
| `register-duplicate-id` | error | user decision | — |
| `register-bad-placement` | error | safe with confirmation | — |
| `structure-numbering` | error | never automatic | — |
| `structure-deep-numbering` | error | never automatic, or safe exception | `80.01.01`, `80.01.02` |
| `structure-stray-number` | error | never automatic | — |
| `drift-undocumented` | error | safe with confirmation, or user decision | Riverton Analytics on office, absent from the vault |
| `drift-orphaned` | error | safe with confirmation, or user decision | — |
| `drift-name-mismatch` | error | user decision, then never automatic | `11.03 Cobalt Freight` / `11.03 Cobalt`; `15.01`–`15.02` |
| `drift-split-name` | warn | never automatic | `13.02 Protogen` / `14.02 Protogen` |
| `triangle-constitution-folders` | warn | safe with confirmation, or never automatic | `13 UXD Practice` vs `13 Design & Dev` |
| `triangle-register-constitution` | warn | safe with confirmation | — |
| `hygiene-area-file` | error | user decision | — |
| `hygiene-category-file` | warn | safe with confirmation, or user decision | `11 Clients/CLAUDE.md` (already excepted) |
| `hygiene-empty` | info | never automatic | — |
| `link-broken` | error | safe with confirmation | — |
| `link-unverifiable` | info | no action, or safe conventions edit | — |
| `moc-stale` | warn | safe with confirmation | — |

## Register

### `register-grammar` — error

**Means.** A line in the register's entry region does not parse as an entry. The consequence is quieter than it looks: an unparseable line is an ID the drift group never compares against anything, so the register's real coverage is smaller than its line count suggests. Usual causes are hand-editing in a hurry—a curly quote where a backtick belongs, a hyphen where the grammar wants an em dash, a substrate bracket left unclosed.

**Reconcile by.** Repairing the line to the grammar without changing what it says, when the intent is unambiguous. When the line is garbled enough that its meaning is a guess, or it was never an entry at all (a stray note that drifted into the entry region), the user decides what it was.

**Tier.** Safe with confirmation for a mechanical repair—show the before and after line. User decision when the intent has to be inferred.

### `register-duplicate-id` — error

**Means.** Two entries claim the same AC.ID. One address, two things, and any lookup by number now returns whichever line was read first.

**Reconcile by.** Merging, when the two entries describe the same thing twice—that removes a duplicate rather than content. Otherwise the two are genuinely different things, one keeps the number, and the other needs a new one. Minting that number is filing, which belongs to `jd-file`, not here.

**Tier.** User decision. It escalates to never automatic the moment reconciling would renumber a folder that exists on disk.

### `register-bad-placement` — error

**Means.** An entry sits under a category heading its number does not belong to—`13.02` filed under `### 14`—or under no heading at all. Either the line is in the wrong section, or the number in the line is wrong, and those have very different consequences.

**Reconcile by.** Moving the line under the correct heading, which touches placement and leaves the entry's content alone. If instead the number is wrong, check the substrates before anything moves: a wrong number in the register usually means a real folder somewhere is the thing that needs deciding about.

**Tier.** Safe with confirmation to move the line. User decision to change the number, and never automatic if a folder already exists at either number.

## Structure

### `structure-numbering` — error

**Means.** An area, category, or ID folder name does not match its grammar pattern, or a category number falls outside its area's range, or an ID's prefix disagrees with the category it sits in. In practice this is a typo (`11.3 Cox` where the pattern wants `11.03 Cox`), a missing label, or a folder dragged into the wrong parent.

**Reconcile by.** Renaming to conform, moving to the correct parent, or—when the folder was never meant to be JD content—recording it in `[ignore]` or `[[exceptions]]`.

**Tier.** Never automatic. Every repair here is a rename or a move, and both break `file://` links pointing at the old path.

### `structure-deep-numbering` — error

**Means.** A fourth numbered tier: a name matching `AC.ID.NN`. Numbering in this system stops at AC.ID, and everything below an ID is unnumbered, free-form, and deliberately deep—client scopes run ten directories down through `_memory/`, `projects/`, and their own git repos. The invariant is "no fourth *numbered* tier", so the check keys on numbered names alone and stays silent on ordinary deep nesting however far down it runs.

In this vault it catches `80.01.01` and `80.01.02` under `80.01 Juno Beach 2026`, the only fourth-tier numbering that exists.

**Reconcile by.** Stripping the numeric prefixes and keeping the labels; promoting each sub-item to an ID of its own; or grandfathering the case in `[[exceptions]]` because the numbering is load-bearing for how that trip is organized. Grandfathering is a real answer here, so ask which the user wants rather than assuming this one needs repairing.

**Tier.** Never automatic for the rename or the promotion. Safe with confirmation for recording the exception, since that adds a decision and changes no files.

### `structure-stray-number` — error

**Means.** A JD-numbered name at the wrong level—an ID folder sitting directly under an area with no category between them, or a category-shaped folder inside an ID. Nearly always a drag-and-drop that landed one level off.

**Reconcile by.** Moving the folder under its correct parent, or renaming it if it was never meant to carry a number.

**Tier.** Never automatic.

## Drift

The high-value group. Every finding here is a register-versus-substrate disagreement, so the authority split in the skill body governs all of them.

### `drift-undocumented` — error

**Means.** An ID exists in a substrate that its register entry does not list, or has no register entry at all. The register under-describes reality, so anything consulting it to answer "where does this live" misses a folder that is really there.

Two sub-cases with different answers. The entry exists and simply omits a substrate—additive, low-stakes. Or there is no entry at all, which is the Riverton Analytics case in this vault: Riverton Analytics occupies `15.01` on the office tree and the register has nothing for it.

**Reconcile by.** Adding the substrate to an existing entry, when the walk proves the folder is there. Writing a whole new entry requires knowing what the ID is *for*, which is `jd-file`'s job—hand it over rather than inventing a purpose line. And check `drift-name-mismatch` for the same number first: Riverton Analytics is entangled with the `15.01`/`15.02` collision, so treating it as a simple missing entry would write down a number the user may be about to change.

**Tier.** Safe with confirmation to add a substrate to an existing entry. User decision, routed to `jd-file`, to author a new one.

### `drift-orphaned` — error

**Means.** A register entry lists a substrate that does not hold the ID. The register over-promises, which is the mirror image of `drift-undocumented`.

**Reconcile by.** First ruling out the third possibility: the folder is there under a different name, in which case `drift-name-mismatch` also fired and *that* is the real finding. While a name mismatch is reported anywhere nearby, treat an absence as unexplained rather than as a deletion. Once absence is confirmed, either drop the substrate from the entry's list, or create the folder—which is filing, and belongs to `jd-file`—or retire the ID.

**Tier.** Safe with confirmation to drop a substrate from a list once absence is confirmed. User decision to create or retire.

### `drift-name-mismatch` — error

**Means.** One AC.ID carries different labels across the register and the substrates. The join key between the three trees is the folder name, so a mismatch does not just look untidy—it severs the join, and every cross-substrate lookup for that ID silently returns less than it should.

Two shapes of this exist in the vault and they are not equally serious:

- `11.03` is `Cobalt Freight` in the vault and in the code tree, and `Cox` on the office tree. One label is short a word. A two-to-one split is evidence about which spelling is habitual, never authority—the office tree may carry the client's actual legal name, and the user is the one who knows.
- `15.01` and `15.02` are the harder shape. The vault has Nightlark Studio at `15.01` and Amber Fleet at `15.02`; the office tree has Riverton Analytics at `15.01` and Nightlark Studio at `15.02`. This is not a typo, it is Nightlark Studio holding two different numbers depending on which tree you open, with Riverton Analytics absent from the vault entirely. Any reference to "15.01" resolves to a different client depending on where it is read.

**Reconcile by.** Deciding the correct label—or, for the `15.01`/`15.02` shape, deciding which client owns which number across all three substrates—then updating the register and renaming the outliers. After any rename, re-run with `--only link-broken`: the rename is exactly what turns live `file://` links into dead ones, and that sweep is the only thing that will find them.

**Tier.** User decision to choose the label or the assignment. Never automatic for the rename that follows.

### `drift-split-name` — warn

**Means.** One normalized label appears under two or more distinct AC.IDs—one thing living under two numbers. Retrieval breaks immediately: the answer to "where is Protogen" becomes "which one", and neither the register nor a folder listing can tell you. It also compounds—every future filing that picks one of the two numbers deepens that pile, so the two halves diverge further the longer the split sits unreconciled. In this vault, `Protogen` occupies both `13.02` and `14.02`.

No number-joined check can see this. Both entries are individually well-formed, correctly placed, and consistent across substrates; the split is visible only by comparing names. Matching is exact after normalizing case and collapsing whitespace, because fuzzy matches here would train the user to skim the whole report.

**This is `jd-file`'s signature error path made deterministic.** A filing skill that fails to match an existing ID and mints a plausible-looking fresh one instead is precisely how a split gets born, which makes this check the backstop for the filing skill's own likeliest mistake. A split that has appeared since the last audit is worth reading as a filing incident—look at what was filed and when—not just as a folder to tidy.

**Reconcile by.** One of exactly two routes. Merge under a single ID: move the content, retire the losing number, and update the register and every reference into the retired tree. Or rename so the two are genuinely two things—`13.02 Protogen Design` and `14.02 Protogen Platform`—which is only honest if they really are distinct, and is otherwise a way of writing the split down permanently.

**Tier.** Never automatic. Merging moves content and retires a number, and a retired number does not come back cleanly; on top of that, every `file://` link into the losing tree dies with the rename. Warn rather than error only because recurring names are sometimes legitimate—an `Archive` ID in several areas is not a split—and those go in `[[exceptions]]` like any other accepted case. This check is the one place where `path` carries the normalized label instead of a filesystem path, so an exception here is keyed on the label exactly as the finding printed it.

## Triangle

### `triangle-constitution-folders` — warn

**Means.** A category listed in the constitution is missing from the substrates, or exists there under a different label. In this vault the constitution names `13 UXD Practice` while the folder is `13 Design & Dev`.

The damage is delayed rather than immediate. The constitution is what a person reads to decide where something goes, so a stale category name does not throw an error—it produces mis-filings weeks later, by a human following the document as written.

**Reconcile by.** Usually editing the constitution, because the folder is usually the newer truth: a practice gets renamed and the prose does not follow. That is a prose edit to one line. If the constitution is the correct one, the folder has to move instead.

**Tier.** Safe with confirmation to edit the constitution's category line. Never automatic to rename the folder.

### `triangle-register-constitution` — warn

**Means.** A register category heading has no matching constitution category, or the two labels differ. The register mirrors the constitution by design, and an unchecked mirror is just two copies drifting apart on their own schedules.

**Reconcile by.** Bringing the register heading in line—headings carry no content, so this is a cheap edit. First check whether `triangle-constitution-folders` fired for the same category: one rename typically trips both checks, and fixing them in the wrong order means fixing the register to match a constitution line that is itself about to change.

**Tier.** Safe with confirmation to edit a heading. User decision when the question is which of the three sources is authoritative.

## Hygiene

### `hygiene-area-file` — error

**Means.** A file sits directly in an area folder. It has no ID, so it has no address: nothing in the register can point at it, and no substrate join will ever find it. `[rules].files_at_area_level = "forbid"` says this level has no legitimate use.

**Reconcile by.** Filing it into an ID, which is `jd-file`'s job, or moving it out of the JD tree entirely when it is not JD content.

**Tier.** User decision. The move is a filing decision, and filing is the sibling skill's domain.

### `hygiene-category-file` — warn

**Means.** The same address problem one level down, but the category level has a legitimate use that the area level does not: a file that governs every ID beneath it rather than belonging to any one of them. `10-19 Work/11 Clients/CLAUDE.md` is exactly that—cross-substrate conventions for every client ID—and it is already recorded in `[[exceptions]]`.

**Reconcile by.** Recording the exception when the file genuinely governs the category, with a reason that says so. Otherwise filing it into an ID.

**Tier.** Safe with confirmation to record the exception. User decision to file it, routed to `jd-file`.

### `hygiene-empty` — info

**Means.** A category or ID folder holds no payload files. Nothing is wrong. An empty ID is a reservation—a number claimed before the work arrives—and this dialect explicitly allows gaps, so an empty folder is frequently the system working as intended. The finding exists so a reservation stays visible enough to be reviewed, not so it can be cleaned up.

Emptiness is evidence that a folder is unused; it is never evidence that it is unneeded. A folder can be empty because nothing has landed there yet, or because it is a destination something else routes to—an inbox that ambiguous items get parked in, a cold archive that dead content moves to—and a directory listing cannot tell those two cases apart. Before proposing retirement of any specific folder, check whether the conventions block, the constitution's routing or maintenance guidance, or a skill's own steps name it as a destination; a folder that turns up in any of those is load-bearing no matter how empty it looks.

Files named in `[rules].scaffold_names` don't count as payload. `jd-file` drops an `Overview.md` into every ID it mints, so without that key the check would go dark the moment scaffolding ships—every reservation would look occupied by its own furniture. One wrinkle is accepted on purpose. Once a human writes real content into a scaffold note, the ID is occupied in spirit, but the check still reports it. For an info-severity finding whose tier is never automatic, a mild false positive beats a silent false negative.

**Reconcile by.** Leaving it. If a reservation is genuinely abandoned, retiring it is a deletion and a renumbering, and it should be raised as one—on its own, with the reason it's safe stated for that specific folder, never bundled with the rest of the info list just because they're all empty.

**Tier.** Never automatic. Empty IDs come off one at a time, each as its own user decision with its own reason—agreeing to retire "the empty ones" approves the shape of a sweep, not every folder caught inside it, so a bulk sweep of the info list is the single most destructive action this catalog can lead to, and the finding carries no evidence that anything is wrong.

## Links

### `link-broken` — error

**Means.** A `file://` target that falls under one of *this* host's roots and does not exist. It is an error because a dead link is visually identical to a live one until somebody clicks it, so nothing surfaces it except a check like this one. Almost always the downstream damage of a rename.

**Reconcile by.** Repointing the link when the new location is unambiguous—that corrects a pointer and moves nothing. When the target is genuinely gone, what to do with the referring note is the user's call.

**Tier.** Safe with confirmation to repoint an unambiguous link. A cluster of these appearing right after a reconciliation is the rename that was just performed, which is why Step 5 re-runs rather than declaring the work done.

### `link-unverifiable` — info

**Means.** The target falls under a root belonging to another host, or under no configured root at all. This is information about *this machine*, not a defect in the link.

**Info is the ceiling for this check.** Absolute `file://` URLs encode one machine's mount points—the office tree sits under one sync client on one machine and somewhere else entirely on another—so a link written on a different host cannot be checked from here, and calling that "broken" would be a claim the run has no evidence for. The practical argument is just as strong: these are numerous, and burying the real `link-broken` findings under a wall of unverifiable ones teaches the user to skim past the whole report, which costs far more than the links do.

The message distinguishes two sub-cases in report text only, with no new severity:

- The same path translated onto this host's root for that substrate **exists**. The link is fine and merely spelled for another machine. Nothing to do.
- The translated equivalent is **also missing**. That is stronger evidence of a genuinely dead link than "unverifiable here", and it is worth checking on the owning host—but this run still cannot prove it, so the severity does not move.

A target matching no configured root usually means a root is missing from `[hosts.*]` rather than that the link is wrong.

**Reconcile by.** Doing nothing in the first sub-case. Noting the second for the next audit run on the machine that owns the root. When a whole class of these turns out to be noise from a missing root, adding that root to the conventions block clears them all at once.

**Tier.** No action for the link itself. Safe with confirmation for a conventions edit that adds a missing root.

## Maps

### `moc-stale` — warn

**Means.** For a category `[moc].categories` names, the map's table and its folders disagree on which IDs exist. Nobody validates the table against the folders by eye, so a missing row doesn't read as "the table is stale"—it reads as "this client has no office documents." A wrong map is worse than no map: one is silently believed, the other visibly asks to be checked.

The check compares only the set of IDs the table lists against the set the folders hold. It deliberately ignores link text and status values, cosmetic differences that don't change whether the map is still telling the truth. Matching on those too would make it cry wolf over an ordinary rename or status flip.

**Reconcile by.** Regenerating, never hand-editing. Run `jd-file`'s `scripts/build_moc.py --vault VAULT_ROOT` and the table matches the folders again. Editing between the markers by hand is wasted work—the next regeneration discards it. Editing outside them is exactly what that space is for. Worth running even when this check stayed quiet—the cross-substrate cells are probes of trees the validator never walks, and only regeneration refreshes them. `jd-audit` Step 5 offers exactly that.

**Tier.** Safe with confirmation. Regeneration is idempotent and touches only the block between the markers. Unlike every other finding in this catalog, the fix here isn't a judgment call for the user—it's `jd-file`'s builder, run again.
