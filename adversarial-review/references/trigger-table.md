# Trigger table and territory derivation

Read this at Step 2, and again whenever you want to add a row.

The table turns "what does this diff touch" into "what should someone be suspicious of." Personas were the obvious alternative and they lose: a Security Auditor persona reviews an authz change and a money change with the same posture, while a suspicion class carries the actual question worth asking. What follows is derived from the diff, so the roster changes with the code rather than being fixed in advance.

## The table

Rows are ordered. That order is the tiebreak when a file matches more than one row, which is what makes derivation reproducible.

**Match signals as whole words or identifiers, case-insensitively—never as bare substrings.** A signal ending in `_` is a prefix (`max_` matches `max_retries`). A unit suffix matches against the number in front of it (`12px` matches `px`), because a whole-word `px` finds `const px` and never finds `padding: 12px`, which is the one place a unit mismatch lives. The unit suffixes are `px`, `rem`, `em`, `ms`, `bytes`, and `kb`, in whichever row they sit. Each matches only straight after a digit: `500ms` and `10kb` match, while `500 ms` and `ms = 3` do not. Only added and removed lines count: a signal sitting in unchanged context never matches. Substring matching quietly wrecks derivation: `index` inside `page_index` files a paging helper as a schema change, `rate` inside `generate` makes every function a money change, and a territory built on those is hunting the wrong thing with a straight face.

[`scripts/match-triggers.py`](../scripts/match-triggers.py) implements these rules. It reads the signals out of this table at run time, and the unit suffixes out of the sentence that begins "The unit suffixes are", and prints `<n> <name>` for each row a diff on stdin matches, in table order. It is the one matcher every run shares, so two runs on the same diff classify it the same way. A grep hand-built from this paragraph each run has to get every rule right on its own, and the table's signals carry punctuation that a regex reads as syntax (#114).

| # | Row | Diff signals (match the hunks, not the file) | Suspicion class | Hunt items |
|---|---|---|---|---|
| 1 | money | `Decimal`, `float(`, `round(`, `* 100`, `/ 100`, `cents`, `amount`, `price`, `total`, `subtotal`, `discount`, `tax`, `rate`, `currency`, `qty`, `quantity`, unit names (`ms`, `bytes`, `kb`) | Arithmetic correctness | Rounding applied per item then summed, instead of summed then rounded. Sign handling on refunds, credits, reversals. Float where the domain is exact. Accumulation across repeated edits — apply the same operation twice and see whether the value drifts. Unit conversion at a boundary where one side changed. |
| 2 | authz | `tenant`, `org_id`, `account_id`, `user_id`, `WHERE`, `filter(`, `.query(`, `raw(`, `execute(`, `is_admin`, `role`, `permission`, `can_`, `authorize`, `current_user` | Tenancy and authorization | Can row A reach row B: trace the query from parameter to predicate and check the tenant filter is in the SQL rather than in a comment. Inheritance *claimed* but not *enforced* — a parent's permission asserted in a docstring while the child query omits it. Filters applied after a `LIMIT`. Admin bypass paths that skip the same check. |
| 3 | state | `status`, `state`, `phase`, `enum`, `transition`, `flag`, `sentinel`, `is_`, `has_`, `pending`, `complete`, `lock`, `acquire`, `release`, `PAUSED`, `retry` | Gate and state transition | Trace the **next** transition by reading the implementation, never the docstring. Prove both paths: the set and the clear. A gate with no clear path is a latch. Concurrent entry — two callers reaching the transition at once. What the state is after a mid-sequence failure. |
| 4 | schema | `ALTER TABLE`, `CREATE TABLE`, `migration`, `NOT NULL`, `DEFAULT`, `CHECK (`, `UNIQUE`, `FOREIGN KEY`, `CASCADE`, `backfill`, `deleted_at`, `soft_delete`, `index` | Migration and schema | The constraint claimed in a comment versus the constraint in the DDL. Backfill against rows that already violate the new constraint. Soft-deleted rows in a uniqueness check. Whether the migration is reversible and whether the down path was tested. Column added `NOT NULL` with no default on a non-empty table. |
| 5 | budget | `limit`, `max_`, `quota`, `budget`, `counter`, `remaining`, `throttle`, `rate_limit`, `timeout`, `retries`, `depth`, `cap` | Counter and limit | The path where the limit is exhausted **mid-flight** rather than at entry. Off-by-one at the boundary — is the limit inclusive. Whether the counter resets, and what resets it. What a caller sees on exhaustion: an error, a silent truncation, or a hang. Concurrent decrement. |
| 6 | representation | `hex`, `rgb`, `srgb`, `oklch`, `alpha`, `opacity`, `composite`, `blend`, `px`, `rem`, `em`, `toFixed`, `round(`, `serialize`, `deserialize`, `stringify`, `parse(`, `schemaVersion`, `migrate`, `adapter`, `getComputedStyle`, `getImageData`, `toDataURL` | Representation boundary | A value asserted in the producer's units and consumed in another's—assert it where it lands, never where it was made. Precision that survives the computation and dies in the serialized form. A shape change with no version change beside it. The same value stored twice with nothing enforcing agreement. A type that admits values its consumer rejects. An assertion that recomputes the implementation rather than observing the result. |
| 7 | general | any changed file (this row always matches) | Test coverage | Do the tests exercise the changed path, or route around it — a test that mocks the function under review proves the mock works. A test asserting the shape of a result and never its value. A changed behavior whose test changed alongside it in the same direction, so both could be wrong together. |

Row 7 matching everything is deliberate: every territory carries the coverage lens, because "was this actually exercised" is the one question that applies to every kind of change. It is named `general` rather than `tests` because it also becomes the owning territory for any file that matched nothing else, and those are rarely test files. A changed test file, meanwhile, usually matches the row its subject matches and lands with the code it covers—which is what you want, since one finder then sees both the change and the test that is supposed to catch it.

## Deriving territories

The output is a set of territories where each changed file has exactly one owner and each territory carries every lens its files earned. Ownership must be disjoint or `check-territories.py validate` fails the run; lenses layer freely, because a file that is both money and authz should lose neither.

1. **Classify each file.** Run `git diff <merge_base_sha>..HEAD -- <file> | adversarial-review/scripts/match-triggers.py rows` for each changed file. The rows it prints, plus row 7, are that file's class set. Row 7 names no signal, so the script never prints it, and every file gets it by this rule, including a file the script printed nothing for. A non-zero exit stops the run: 1 means this table no longer parses, 3 a usage error or unreadable input.
2. **Assign an owner.** Each file goes to a territory named after its **first** matching row. First-match by table order is the whole determinism mechanism: the same diff yields the same assignment on any run, on any machine, by any model.
3. **Union the lenses.** A territory's `classes` is the union of its member files' class sets. So the money territory reviewing a file that also matched authz hunts the authz items too — on that file, in that territory, by that one finder.
4. **Write the derivation record.** One entry per file naming its `matched_rows` and its `territory`. This is what a later reader (or a re-run) checks the assignment against.
5. **Set entries.** A territory's `entries` are the literal paths of its member files. Not globs: `check-territories.py` rejects `*` and `?` outright, because a pattern that owns nothing is indistinguishable from a territory nobody is reviewing. Directory prefixes ending in `/` are legal and useful for a hand-written amendment; derivation itself emits file paths, which makes disjointness structural rather than merely checked.
6. **Cap the roster.** Depth 0 allows 2 territories, Depth 1 allows 4, Depth 2 allows 6. Over the cap, merge the lowest-priority territories (highest row number) into their nearest neighbor and union the lenses — a merged territory reviews more with one finder, which costs attention but never coverage.

## Model tier

Set each territory's `model_tier` from its highest-priority class, then let depth modulate it:

| Classes present | Base tier |
|---|---|
| money, authz, state | opus |
| schema, budget, representation | sonnet |
| tests alone | haiku |

Depth 0 caps every territory at sonnet. Depth 2 raises money, authz, and state to opus and leaves the rest. The reason for tiering at all is that a full opus fan-out is genuinely expensive, and a docs-and-types diff does not earn one.

## Adding a row

Extend the table rather than hardcoding a territory for a specific repo. A new row needs three things, and the third is the one people skip:

1. **Signals a changed line can match.** "Touches the payment flow" is not a signal; `stripe`, `charge(`, `refund` are. Write each one in backticks in the signals cell: `match-triggers.py` takes the backticked strings as the row's signals and ignores the prose around them. Keep the `| # | Row |` header and the separator row as they are, since the script finds the table by them and exits 1 when it cannot. Add a new unit signal to the "The unit suffixes are" sentence as well, in backticks and ahead of its period. The script exits 1 when that sentence is gone.
2. **A suspicion class** naming what goes wrong in this domain, not the domain itself. "Caching" is a domain; "a cache whose invalidation path is never taken" is a class.
3. **Hunt items that name evidence.** Each item should suggest what a finder would quote. An item nobody can produce evidence for generates UNVERIFIABLE findings, and a territory full of those is dead weight the calibration signal will eventually flag.

Insert a new row by priority, not at the end: row order decides ownership on files that match several rows, so placing a row changes derivation for existing diffs. That is a deliberate act, and it belongs in the RATIONALE ledger.
