---
name: jd-audit
description: "Audit a Johnny.Decimal system for drift by running its validator, then guide reconciliation of what it reports. Use when the user says \"clean up my vault\", \"is my system consistent\", \"something's off with my numbering\", \"audit my files\", \"check my index\", \"did I file this twice\", \"my JDex is out of date\", or \"why is this thing in two places\"—and for finding duplicate IDs, name collisions across substrates, broken cross-substrate links, or register-versus-folder mismatches. Reports and reconciles only: to file something, assign or mint an ID, or decide where a new thing goes, use jd-file instead."
argument-hint: '[check ID, group, or area to focus on | --only CHECK | --skip CHECK | --json]'
---

# jd-audit

`scripts/validate.py` establishes the ground truth for every run, and this skill spends its judgment strictly downstream of it—on what a finding means, which reconciliation the user should pick, and which ones have to reach the user before anything on disk is touched.

The division exists because a model reading a file tree for collisions produces confident opinions with nothing attached that says which of them are wrong: it misses the split that only surfaces when two labels normalize to the same string, invents a mismatch out of a folder it half-remembers, and reports both with identical certainty. Worse, it is unrepeatable—run it twice and get two different audits of an unchanged vault, with no way to tell which run was the honest one. So when a check misses something you can see with your own eyes, that is a defect in the script: fix it there and re-run.

Where a step names a shell command, treat it as the intent and use your native shell or file tools.

Resolve once per invocation:

- **ASK** — the text following the invocation. (Claude Code exposes this as `$ARGUMENTS`; on other agents it is the rest of the user's message.) It narrows the run to a check, a group, or an area. Empty means the full sweep.
- **VALIDATOR** — `scripts/validate.py`, resolved against this skill's own directory.
- **VAULT_ROOT** — pass as `--vault` only when the user names a path or the script cannot resolve one itself. The script does host lookup and discovery from the conventions block; a path supplied from memory is a path nobody checked.
- **CONVENTIONS** — `<VAULT_ROOT>/00-09 Admin & Meta/00 System/00.02 Vault Conventions.md`. Required whenever `--vault` is absent, unless the resolver ladder (`$JD_VAULT`, `obsidian.json`, carried probes in `scripts/resolve_vault.py`) settles a root first—the default path is computed from a root the script may not have yet.
- **Flags**, passed through: `--only CHECK` and `--skip CHECK` (both repeatable), `--host NAME`, `--json`.

## Step 1 — Orient

Establish that the three artifacts exist before anything walks the disk, because each one is the left-hand side of a whole check group and its absence changes what the run can claim:

| Artifact | Path under the vault | Absent means |
|---|---|---|
| register | `00-09 Admin & Meta/00 System/00.01 JDex.md` | the `drift-*` group has nothing to compare substrates against; say so, and report the substrates as unchecked rather than as clean |
| constitution | `00-09 Admin & Meta/00 System/00.00 Johnny Decimal Index.md` | the `triangle-*` group cannot run |
| conventions | `00-09 Admin & Meta/00 System/00.02 Vault Conventions.md` | nothing can run—this is exit `2` territory, not a degraded mode |

Translate ASK into flags rather than into intentions: "check my index" is `--only register-grammar --only register-duplicate-id --only register-bad-placement`, "my links are stale" is `--only link-broken --only link-unverifiable`.

Announce the run in one line before it starts—`Auditing <VAULT_ROOT>: all groups.` or `Auditing <VAULT_ROOT>: register group only.`—so the user can correct the scope before the walk spends anything on it.

**Done when:** the vault root and all three artifact paths have been stated with each marked present or absent, and the announced scope line names which checks will run.

## Step 2 — Run the Validator

```
scripts/validate.py [--vault VAULT_ROOT] [--only CHECK]... [--skip CHECK]...
```

| Exit | Meaning | What to do |
|---|---|---|
| 0 | no errors | continue to Step 3; warnings and info still get the full report |
| 1 | one or more errors | continue to Step 3; this is the expected first-run result on a drifted vault |
| 2 | fatal—unknown schema version, unreadable conventions, or the resolver ladder found no single vault root | report the script's own message verbatim and stop |

Exit `2` means the run has no ground truth to report. An unrecognized `schema_version` says the conventions block changed shape, and parsing it by hand to carry on anyway produces precisely the half-understood read the exit code exists to prevent. Repair the note or ask the user which vault they meant, then re-run.

Carry the findings forward exactly as printed. An audit whose report mixes script output with model impressions is one the reader has to re-verify by hand, which is the cost this design exists to remove.

**Done when:** the script exited `0` or `1` and its findings are in hand verbatim, or it exited `2` and its own message was reported verbatim with the run stopped there.

## Step 3 — Report

One shape, every run, so two audits a month apart are comparable:

1. **The count line**, as the script produced it—`3 errors, 2 warnings, 11 info, 2 suppressed by exception`.
2. **Errors**, grouped by check ID, each finding naming the concrete values in conflict and the tier its fix falls in.
3. **Warnings**, then **info**, in the same shape. Carry the info tier in full: `hygiene-empty` and `link-unverifiable` are the ones most likely to get quietly dropped to shorten the report, and dropping them makes the report claim a coverage it did not deliver.
4. **Suppressed**—the count, plus which exception absorbed each one. An accepted exception should stay visible without shouting.
5. **Clean and skipped**, listed separately by check ID, so the reader can tell a check that found nothing from a check nobody ran.

Look up each check in [references/findings-catalog.md](references/findings-catalog.md) as you write it up, and restate each finding in plainer language while keeping the script's own grouping, order, and severity.

**Done when:** the count line opens the report; every emitted finding appears under its check ID with its concrete values and its tier; every suppressed finding names the exception that absorbed it; and clean checks and skipped checks stand as two distinct lists.

## Step 4 — Reconcile

**The authority split, which decides every case below:** the register says what *should* exist; the substrates say what *does*. Neither one wins by default. When they disagree, report the disagreement and hand it to the user—a reconciliation nobody chose is indistinguishable from data loss that happened to typecheck.

Three tiers govern what you may propose:

| Tier | Covers | How to proceed |
|---|---|---|
| **Safe with confirmation** | additive, reversible corrections—adding a register entry for an ID that demonstrably exists in a substrate, adding a substrate to an entry's list when the walk found it there, recording an accepted exception | state the exact line you will write, take one confirmation, write it |
| **User decision** | the substance of most findings—which of two labels is right, which number survives, whether this disagreement is drift or a decision worth recording | present the candidates with the evidence behind each, recommend one, and wait |
| **Never automatic** | deleting a folder, retiring a category or ID, renaming anything, creating a category or an area, merging two IDs | write out the exact steps and hand them to the user to perform, whatever confirmation is on offer |

Renaming sits in the never tier because cross-substrate references in this system are absolute percent-encoded `file://` URLs with the path baked into them. Renaming a folder breaks every link pointing at the old name, and a broken `file://` link looks exactly like a working one until somebody clicks it—so the damage is both silent and delayed. Creating a category or an area is in the same tier for a different reason: it reshapes the system rather than filling it, and that is the user's call by definition.

`moc-stale` breaks the pattern above: the fix isn't a judgment call for the user—it's `jd-file`'s builder script, run again. That's still safe with confirmation rather than never automatic, because regeneration is idempotent and touches only the map's generated block. Unlike every other finding here, the reconciliation belongs to the sibling skill, not to the user's own decision.

Retirement is never a sweep, even inside a batch the operator has already agreed to. Agreeing to retire "the empty ones" approves the shape of the operation, not every folder caught in it—an empty category can be an abandoned reservation, or it can be a destination something else routes to, like an inbox that ambiguous items get parked in or a cold archive that dead content moves to, and the two look identical from a directory listing. Confirm each retirement on its own, with the reason it's safe stated for that specific folder, and check whether the conventions block, the constitution, or any skill's own steps name it as a destination before it goes.

Record an accepted disagreement in `[[exceptions]]` in the conventions note, where a suppression stays a decision on the record:

```toml
[[exceptions]]
check = "hygiene-category-file"
path = "10-19 Work/11 Clients/CLAUDE.md"
reason = "Governs every client ID beneath it, so category level is deliberate."
```

Suppression matches on the pair (`check`, `path`) by exact string equality, with no prefix matching and no normalization, so both fields have to carry the values the script itself emitted—a near-miss suppresses nothing while reading as though it did. `check` is the check ID verbatim. `path` is whatever that finding printed in its path field. `reason` states why this was accepted; "known issue" records nothing a future reader can act on.

**Done when:** every error and warning carries a named reconciliation and its tier, and each one is confirmed, deferred to the user, or written into `[[exceptions]]`; and any info-tier finding acted on rather than left—a retirement above all—carries that same per-item confirmation rather than riding along on a batch's approval.

## Step 5 — Apply and Re-Run

Apply only what the user confirmed, then run the same command again for fresh ground truth and show the new count line beside the old one. Re-running is what separates a fix from a claimed fix.

After reconciliation, offer to run `jd-file`'s `scripts/build_moc.py --vault VAULT_ROOT` over `[moc].categories` as routine maintenance—one confirmation for the whole regeneration, the same safe-with-confirmation tier `moc-stale` carries. The maps' cross-substrate cells are probes of trees this validator never walks. A folder created in the office tree since the last regeneration reads as a dash until the builder runs again, and nothing else refreshes it. The offer stands whether or not `moc-stale` fired—that check compares only ID sets and is deliberately blind to the cells this run exists to refresh. Regeneration stays the builder's job—the validator itself never writes a map it audits.

Every finding that disappeared must be explained by a change you made or an exception you wrote. One that vanished for neither reason means the walk saw something different this time—report that rather than banking it as progress.

**Done when:** the before and after count lines are both shown, every closed finding is accounted for, and everything still open is listed as an outstanding user decision.

## Further Reading

- [references/findings-catalog.md](references/findings-catalog.md) — read at Step 3 for each check that fired, and again at Step 4 before proposing any reconciliation
- [scripts/validate.py](scripts/validate.py) — read when a check's behavior is genuinely in question and the catalog does not settle it

## Sources

- Johnny.Decimal, the system this vault speaks a dialect of: https://johnnydecimal.com. The dialect itself lives in `00.02 Vault Conventions`, and where the two differ the conventions note wins.
- Prior art for walking a JD tree programmatically: `ngerakines/jd` at commit `b85e42e` (Apache-2.0), analyzed in [_docs/jd-ngerakines-plugin-report.md](../_docs/jd-ngerakines-plugin-report.md).
