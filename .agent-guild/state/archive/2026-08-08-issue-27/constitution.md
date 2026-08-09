# Constitution: inbox-to-memory — `last_confirmed` write-through on confirmation (#27)

When an inbox file confirms a claim an `accepted` memory record already makes, the skill stamps that record's `last_confirmed` date without stopping for approval. That is one sanctioned hole in the rule that nothing in `_memory/` gets written without per-item sign-off, and the job is as much about naming the hole honestly as about cutting it.

Four things the issue left open were settled with the user before this document was drafted, and every clause below assumes them:

1. **A script does the writing.** Detecting a confirmation is judgment and stays in SKILL.md; writing the date is mechanical and moves into `inbox-to-memory/scripts/stamp-confirmed.sh`. That split is what makes the issue's seventh acceptance criterion — "the smoke test asserts that a run over the mixed fixture leaves v1 records untouched" — a real assertion instead of a prose grep. The v1 skip is then enforced by code, not by an agent remembering.
2. **The date is the confirming note's, and it never moves backwards.** `migration.md:37` already argues that any later date "would assert a review that never happened"; the same argument forbids stamping today onto a confirmation someone made in February. The monotonic guard is the other half: draining a backlog of old transcripts must not age a record that was confirmed last week.
3. **No new token.** The phase 6 report and the record's own date are the trace. A `[confirms accepted: ...]` flag would need a grammar row, a lint check, and a ruling on whether it counts as an unpromoted candidate — and it would look like something waiting for sign-off, which is the one thing this write is not.
4. **The eval suite is in scope.** Deciding that an input confirms a record rather than merely mentioning it is judgment, and judgment is what `EVALS.md` exists to grade.

Everything below is measured against the shipped tree, not against a worker's account of it.

**Revision r6.** Seven audits ran and the first seven failed this document, each finding something the last one's fix opened; r7 passed it. The clause bodies carry their own `revised in rN` markers and some lag a round or two behind; where a marker and this section disagree, trust this section.

The last three rounds all landed on the same clause, C-13's placement harness, and all three findings were invisible to reading — each was caught by an auditor building a conforming stamper and running the checks against real synthetic artifacts. r4: C-18's `^stamped: ` count also matched the closing summary line, so no implementation could satisfy it. r5: the harness searched for literal script paths, but this suite invokes every script through a bound variable, so the set it called "every invocation" held one variable assignment and no invocations. r6: pinning the variable name narrowed that without closing it, because the binding line alone still satisfied both bounds — so a section with no invocations at all, C-13's own first failing example, went green. The binding and the uses are now two sets, found two ways, both required to exist and both bounded.

That is the recurring shape worth naming: a check whose pass string prints for a reason other than the property it names. It has now appeared six times, four of them in code I wrote to catch it.

The earlier rounds: r1's blocker came from r0 pinning the stamp *per input*, which left "confirmed twice in one run is stamped once" unenforced; r2 answered that by making the stamper **batch-scoped** — one invocation per run, taking repeatable `--note` groups — and that in turn silently redefined monotonicity, because a record can now be named by two groups whose dates straddle its current value. C-3 and C-5 said different things about that case and neither check reached it. The script contract below now states the resolution as one two-stage rule so the clauses cannot drift apart again.

r2's other blocker was in my own check code: `open(p, "w").write(… open(p).read() …)` truncates the file before reading it, so two checks mutated their fixture to zero bytes and printed their pass strings on the wreckage. That is the third time a check has passed for a reason other than the property it names. Every mutation in this document now reads first and writes second, the form C-4 always had.

Clause numbering is unchanged; revised clauses are marked.

**Verification runs on an uncommitted tree.** C-12 and C-16 both establish scope by comparing the working tree against the job's base commit, `f027515c9f5487acd4b8d0be973af0e5bc9017d0`. Committing *this job's* work before the checks run makes a blocker and a major clause vacuous at the same moment. C-16 asserts `HEAD` is still the base for that reason.

The base moved once, mid-job, and this is the record of it. It was `924f81f` when the constitution was written and passed audit. The user then commissioned an unrelated retrofit of the `## Courier comparison` sections in `.agent-guild/state/archive/*/tasks/` and committed it as `f027515`, which is now `HEAD` and is pushed. Both clauses were repointed rather than left pinned to a commit that is no longer the tip. This is safe to do here and would not be safe in general: the retrofit touched only files under `.agent-guild/state/archive/`, and none of the four files C-12 reads differs between the two commits — verified by comparing `git show 924f81f:<f>` against `git show f027515:<f>` for all four. Nothing this job produces is committed.

## Reading this

Nobody reads a 600-line constitution end to end, and the r3 audit was right to call that a finding rather than a style note. A worker or checker holds a task file naming two or three clauses. So: **read the script contract below, then only your clauses.** The contract is the one section everything depends on, and skipping it is how the r2 draft ended up with two clauses contradicting each other.

| | Clause | Severity |
| --- | --- | --- |
| **The script** | C-1 interface, happy path, bad input · C-2 v1 never written · C-3 never backwards · C-4 `accepted` only · C-5 stamped once per run · C-6 key insertion and the budget · C-7 nothing else changes · C-18 every branch at once | blocker, except C-4 and C-18 major |
| **The prose** | C-8 phase 2.5 detection · C-9 phase 6 report · C-10 the operating rule · C-11 the prose census · C-12 no new token | blocker, except C-11 and C-12 major |
| **Tests and wiring** | C-13 the smoke section · C-14 the eval scenario · C-15 stale cross-references · C-16 suites and diff scope · C-17 the skill calls it | blocker, except C-14 major and C-15 minor |

## Baseline

Recorded from the tree at `924f81f`, clean, by running each check named here. Corrections from both audits are folded in.

- `yq` is at `/opt/homebrew/bin/yq` and `nanoid` at `~/.nvm/versions/node/v24.18.0/bin/nanoid`. The lint aborts with exit 2 without `yq`.
- All three suites exit 0: `tests/inbox-to-memory-smoke.sh`, `tests/file-issue-smoke.sh`, `tests/handoff-smoke.sh`.
- `tests/inbox-to-memory-smoke.sh` is 1309 lines. **Its whole-fixture hash guard is a pair, not a point:** the snapshot is taken at `:586` and compared at `:1299`, inside the commented block at `:1296-1302`, and it covers `tests/fixtures/inbox-to-memory`. Only writes happening *between* those two lines are caught — a section above `:586` is baked into the baseline and one below `:1299` is invisible to it. That is what C-13 turns on.
- The migrator's wiring precedent, which C-17 mirrors, is at `tests/inbox-to-memory-smoke.sh:596-602`: `require_text inbox-to-memory/SKILL.md "scripts/migrate-scope.sh"` sits at **`:600`**. (r1 cited `:599`; r0 and r2 both had it right.)
- **The only `bash` here is 3.2.57**, Apple's, so no associative arrays, no `${var^^}`, no `mapfile`. That matters for exactly one thing in this job: the keyed max-date dedupe in stage 1 of the resolution rule is the obvious job for an associative array and cannot use one. Parallel indexed arrays or a sorted stream will do it; a `declare -A` in the shipped script will not run.
- The `mixed/` fixture already holds every half of the test. `_memory/context/atlas-region-topology-mPmy8XBe5H.md` is `schema: 2`, `status: accepted`, `last_confirmed: 2026-02-10`, with `date:` at `:7`, `last_confirmed:` at `:8`, `source_refs:` at `:9` and no `effective_from`/`effective_to`. `_memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md` carries no `schema` key, is `status: accepted`, and has no `last_confirmed`. Notes run from `2025-12-02` to `2026-02-17`, so one fixture supplies a forward stamp, a backward one, an exactly-equal one, two distinct dates for the cross-input dedupe, and a v1 record that must come out byte-identical.
- **Two shipped fixtures are already `schema: 2`, `status: accepted`, and missing `last_confirmed`**: `evals/unacknowledged-tension/_memory/context/bexley-dock-capacity-MH-2ub4mwK.md` and `.../decisions/bexley-pilots-first-LvJedcverX.md`. They are the only two in the tree. C-6 still constructs its own input — a check that pins its own input cannot be broken by someone editing a fixture for an unrelated scenario — but the shape is shipped, not hypothetical. No fixture anywhere is non-`accepted` while carrying the key, so C-4 genuinely has to build one.
- **The frontmatter budget bites, but only with a comment in the block.** `last_confirmed` is itself one of the 18 keys a full record carries, so a record missing it carries at most 17 and closes on line 19; inserting the key closes on 20 and lints clean. Overflow needs a **comment line inside the block**, which is ordinary rather than exotic: five of the six templates in `assets/records/` carry four such comments (`journal-entry.template.md` carries two). Verified — a 17-key record with one frontmatter comment closes on 20 at `failures: 0`, and inserting `last_confirmed` closes on 21 at `frontmatter-budget: closing --- on line 21, past the 20-line budget`, `failures: 1`. C-6's recipe is that run.
- **Two pre-existing prose defects sit in the blast radius.** `_maintenance/inbox-to-memory/eval-scope.sh:6` cites `tests/inbox-to-memory-smoke.sh:1226` for the never-migrate-a-fixture rule, which lives at `:1296`; the citation is already wrong and this job moves the target further. `_maintenance/inbox-to-memory/EVALS.md:9` says "Four" fixtures and becomes five. Both are in scope. A third, `tests/fixtures/inbox-to-memory/README.md:3` saying "Three scopes" above four bullets, is unrelated and is a non-goal.
- **In the agent's own shell, several commands are not what they look like.** `grep` and `find` are Claude Code shell functions — `grep` execs `ugrep` and its output order is not stable across runs; `find` with compound predicates is shadowed by RTK, so use `rtk proxy find …` for `-exec` and `-not`. `cat` is aliased to `ccat`, so checks use `/bin/cat`. `stat` is **not** shadowed. None of this reaches a script run under `bash`, only a checker running commands directly, so every check below either avoids the wrappers or sorts before comparing.

## The script contract

Clauses C-1 through C-7 all describe `inbox-to-memory/scripts/stamp-confirmed.sh`. Its interface is pinned here because SKILL.md, the smoke test, and the eval scenario all have to agree on it:

```
bash inbox-to-memory/scripts/stamp-confirmed.sh <scope-root> [--dry-run] \
  --note <note-path> <record-path>... \
  [--note <note-path> <record-path>...]...
```

**It is called once per run, not once per input.** Each `--note` group is one confirming input and the records phase 2.5 judged it confirms; a run over an inbox of six files makes one invocation carrying up to six groups. That is what makes the issue's "a record confirmed twice in one run is stamped once" a property of the script rather than a property of how the caller happens to loop, and it is why the write count does not depend on the order the inbox was processed in.

`--note` names a groomed note; the script reads its `date:`. **Note paths and record paths follow the same rule**: absolute, or relative to the scope root. `--dry-run`, if given, sits between `<scope-root>` and the first `--note`; it is the only argument that may. An invocation with no `--note` group, or a `--note` group with no record paths after it, is a usage error — see C-1. Every outcome prints one line per distinct record, and the run ends with a count:

```
stamped: <record-path> <old-or-none> -> <new>
skipped: <record-path> (<reason>)
stamped: N  skipped: N
```

**Lines come out sorted by resolved record path, never in argument order.** A worker holding only C-1 and C-6 would otherwise never meet this rule, and encounter order is the obvious thing to write. C-5 is where it is falsified; the reason it is a contract rule rather than a C-5 detail is that the phase 6 report reads off this output, and a report that reshuffles between two runs over the same inbox is a report nobody can diff.

Taking `--note` rather than `--date` is what puts "the date comes from the confirming input" in code instead of in prose.

**Resolution is two stages, in this order, and both C-3 and C-5 describe the same rule from different sides.** Getting the order wrong is how the r2 draft ended up with two clauses contradicting each other on a case neither check reached.

1. **Resolve.** Collapse the groups to one candidate per distinct record. A record named by more than one group takes the **latest** of those groups' note dates. Nothing has been compared to the record's own state yet, and nothing has been written.
2. **Decide, once per resolved record.** Exactly one branch fires, and each produces exactly one output line. In order:

   | Branch | Outcome | Clause |
   | --- | --- | --- |
   | no `schema` key | skip, v1 | C-2 |
   | `status` is not `accepted` | skip, status | C-4 |
   | has `last_confirmed`, candidate is later | **stamp** | C-3 |
   | has `last_confirmed`, candidate is earlier or equal | skip, not later | C-3 |
   | no `last_confirmed`, insertion fits the 20-line budget | **stamp**, inserting the key | C-6 |
   | no `last_confirmed`, insertion overruns the budget | skip, budget | C-6 |

   The missing-key rows are the ones the r2 draft's one-sentence version of this rule left out, which is how C-6's subject came to be governed by a rule that never mentioned it.

So the record named by a 2025-12-02 group and a 2026-02-17 group, currently sitting at 2026-02-10, resolves to 2026-02-17 and is stamped once. It is **not** skipped for the older group and stamped for the newer one; the older group never reaches stage 2 as a candidate of its own. C-3's monotonic rule applies to the resolved candidate, never to a raw group date.

**It writes by default.** No `--apply`. The migrator dry-runs first because a migration is a batch a human approves; this write is the one the user has agreed in advance never to be asked about, and a confirmation prompt in front of it is exactly what the issue is removing. `--dry-run` exists for inspection and for the tests, and prints the same lines while writing nothing.

## Clauses

### C-1: the stamper exists, moves a v2 accepted record forward, and refuses bad input whole

*(revised in r2: adds the `--dry-run` and closing-count assertions the r1 audit found unexercised, and pins what a bad `--note` does.)*

- **text**: `inbox-to-memory/scripts/stamp-confirmed.sh` exists, is executable via `bash`, and honors the interface above. Given a scope root and one or more `--note` groups, it sets `last_confirmed` on each named `schema: 2`, `status: accepted` record to its group's note `date`, prints one `stamped:` line per record naming the old and new values, closes with `stamped: N  skipped: N`, and exits 0. `--dry-run` prints byte-identical output and writes nothing.

  Input validation is all-or-nothing and covers notes as well as records. The script writes nothing, names what failed, and exits nonzero when: any named record or `--note` path does not exist or does not parse; **no `--note` group is given at all**; or **a `--note` group is followed by no record paths**. A missing note is a usage error, never a silent skip — otherwise a typo in a note path is indistinguishable from a record that was correctly left alone. An empty group is the same: a note that confirmed nothing has no business being passed, and accepting it would let a caller that found no confirmations still make a call, which C-17 forbids.
- **check**:

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  N=notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md
  R=_memory/context/atlas-region-topology-mPmy8XBe5H.md
  before="$(shasum "$S/$R" | cut -d' ' -f1)"
  dry="$(bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" --dry-run --note "$N" "$R")"
  [ "$before" = "$(shasum "$S/$R" | cut -d' ' -f1)" ] && echo "dry-run wrote nothing" || echo "DRY RUN WROTE"
  printf '%s\n' "$dry" | /usr/bin/grep -q '^stamped: .*2026-02-10 -> 2026-02-17' \
    && echo "dry-run reported the stamp" || echo "DRY RUN SAID NOTHING"
  wet="$(bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" --note "$N" "$R")"; echo "exit=$?"
  [ "$dry" = "$wet" ] && echo "dry and wet output identical" || { echo "OUTPUT DIFFERS"; diff <(echo "$dry") <(echo "$wet"); }
  printf '%s\n' "$wet"
  /usr/bin/grep '^last_confirmed:' "$S/$R"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" --note "$N" _memory/context/no-such-record-AAAAAAAAAA.md; echo "bad-record exit=$?"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" --note notes/no-such-note.md "$R"; echo "bad-note exit=$?"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" "$R"; echo "no-group exit=$?"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" --note "$N"; echo "empty-group exit=$?"
  rm -rf "$S"
  ```

  The wet run prints a `stamped:` line carrying `2026-02-10 -> 2026-02-17`, a closing `stamped: 1  skipped: 0`, and `exit=0`; the record then reads `last_confirmed: 2026-02-17`. All four malformed invocations print a nonzero exit and name what failed. `dry-run wrote nothing`, `dry-run reported the stamp`, and `dry and wet output identical` must all three print — the middle one is not redundant, because a stamper that prints nothing at all satisfies "wrote nothing" and "identical" together.
- **severity**: blocker
- **failing example**: a script that takes `--date` instead of reading the note, so the rule that the date comes from the confirming input lives in prose nothing checks. Also failing: a script that stamps the first two records it was handed and then dies on the third, leaving the scope half written; and one that treats an unreadable `--note` as a group producing zero stamps, so a path typo reports the same clean "nothing to do" as a genuinely unconfirmed run.

### C-2: a v1 record is never written

- **text**: A record carrying no `schema` key is never modified by the stamper under any invocation. It is reported as skipped with a reason naming its generation, and the file is byte-identical afterwards. This holds whether it is named alone or alongside records that do get stamped.
- **check**:

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  V1="$S/_memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md"
  before="$(shasum "$V1" | cut -d' ' -f1)"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" \
    --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md \
    _memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md \
    _memory/context/atlas-region-topology-mPmy8XBe5H.md; echo "exit=$?"
  after="$(shasum "$V1" | cut -d' ' -f1)"
  [ "$before" = "$after" ] && echo "v1 untouched" || echo "V1 RECORD WAS WRITTEN"
  rm -rf "$S"
  ```

  Must print `v1 untouched`, `exit=0`, a `skipped:` line naming the v1 record and its reason, and a `stamped:` line for the v2 one in the same run.
- **severity**: blocker
- **failing example**: the stamper appends `last_confirmed: 2026-02-17` to the freeze-window record. It is now a v1 file carrying a v2-only key, invisible to `grep -l '^schema: 2'` and to every generation-aware query, and the compatibility guarantee the `mixed/` fixture exists to protect is gone.

### C-3: the stamp never moves backwards

*(revised in r3: stated against the **resolved candidate date** of stage 2, not against a raw group date. The r2 wording said an older group meant "not written, skipped, byte-identical," which contradicted C-5's "takes the latest of the group dates" whenever two groups straddled the record's current value.)*

- **text**: When a record's resolved candidate date — the latest note date among the groups naming it, per stage 1 of the resolution rule — is earlier than or equal to its existing `last_confirmed`, the record is not written. It is reported as skipped with a reason naming both dates, and the file is byte-identical afterwards. An individual group whose date loses at stage 1 produces no skip line of its own; it produced no candidate.
- **check**: each invocation below carries a single group, so the resolved candidate is that group's date and the two stages collapse. The straddle case, where they do not, is C-5's.

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  R="$S/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
  before="$(shasum "$R" | cut -d' ' -f1)"
  for n in 2025-12-02-atlas-steerco-ZGulgExW0q.md 2026-02-10-atlas-runbook-review-j5jLCGc5il.md; do
    bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" --note "notes/$n" \
      _memory/context/atlas-region-topology-mPmy8XBe5H.md; echo "exit=$?"
  done
  [ "$before" = "$(shasum "$R" | cut -d' ' -f1)" ] && echo "held" || echo "MOVED"
  rm -rf "$S"
  ```

  The record holds at `last_confirmed: 2026-02-10`. The first note is older and the second is exactly equal, and both print a `skipped:` line, a closing `stamped: 0  skipped: 1`, and `exit=0`; the run prints `held`. The exit assertion is not decoration — without it a stamper that dies before writing also prints `held`.
- **severity**: blocker
- **failing example**: draining a folder of transcripts from last autumn walks a record confirmed in February back to November. The field exists so stale records are visible, and it has just been made to lie in the one direction that matters.

### C-4: only `accepted` records are stamped

- **text**: A record whose `status` is anything other than `accepted` is never written, and is reported as skipped with a reason naming its status. This matches phase 2.5's existing rule that only `accepted` records produce flags: a `proposed` record has not been agreed to, so confirming it asserts nothing, and a `superseded` one is already known to be wrong.
- **check**:

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  R="$S/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
  python3 - "$R" <<'PY'
  import sys; p = sys.argv[1]; t = open(p).read()
  open(p, "w").write(t.replace("status: accepted", "status: proposed", 1))
  PY
  before="$(shasum "$R" | cut -d' ' -f1)"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" \
    --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md \
    _memory/context/atlas-region-topology-mPmy8XBe5H.md; echo "exit=$?"
  [ "$before" = "$(shasum "$R" | cut -d' ' -f1)" ] && echo "held" || echo "STAMPED A PROPOSED RECORD"
  rm -rf "$S"
  ```

  Must print a `skipped:` line naming `proposed`, then `held`, at `exit=0`.
- **severity**: major
- **failing example**: a proposed Rule nobody has agreed to comes out of a run carrying a fresh `last_confirmed`, which reads as "reviewed and still true" for a claim that was never accepted in the first place.

### C-5: a record confirmed twice in one run is stamped once, whichever order the inputs came in

*(revised in r3 on two counts: the r2 check truncated the record it was testing to zero bytes and then printed its pass strings against the wreckage, and case 2 is now stated against stage 1 of the resolution rule so it and C-3 describe one rule rather than two.)*

- **text**: Within one invocation, each distinct record is resolved to one candidate at stage 1, written at most once, and named at most once in the output. The closing count reflects distinct records, not arguments. Four ways the same record can be named twice all collapse to one decision:

  1. Twice inside one `--note` group.
  2. Once each in two groups, both later than the record's current `last_confirmed` — the issue's "confirmed twice in one run" case. It takes the **latest** of the two dates.
  3. Once each in two groups whose dates **straddle** the record's current value. Stage 1 resolves to the later date, so the record is stamped once and the older group produces nothing — not a skip line, not a write. This is the case C-3 and C-5 disagreed about in r2.
  4. Once by an absolute path and once by a path relative to the scope root.

  **Output order is stable and does not track argument order.** Lines are emitted sorted by resolved record path, so a run's output is byte-identical however the groups and records were arranged on the command line. Emitting in argument order would satisfy every other sentence in this clause and still make the phase 6 report shuffle between two runs over the same inbox, which is the thing order-independence is for.
- **check**: note the mutation form — read first, write second. The r2 draft inlined `open(p).read()` inside `open(p, "w").write(…)`, which truncates before it reads and leaves an empty file that then classifies as v1; every assertion below passed on that, `order-independent` included.

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  R=_memory/context/atlas-region-topology-mPmy8XBe5H.md
  A=notes/2026-02-10-atlas-runbook-review-j5jLCGc5il.md   # equal to the record's date
  B=notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md
  C=notes/2025-12-02-atlas-steerco-ZGulgExW0q.md          # older than it
  python3 - "$S/$R" <<'PY'
  import re, sys
  p = sys.argv[1]
  t = open(p).read()
  open(p, "w").write(re.sub(r"^last_confirmed:.*$", "last_confirmed: 2026-01-20", t, count=1, flags=re.M))
  PY
  [ -s "$S/$R" ] && echo "fixture intact" || echo "FIXTURE TRUNCATED — THE CHECK IS VOID"
  cp -R "$S" "$S.b"
  # case 2, both groups later than 2026-01-20, and order-independence at arity 2.
  # V1 rides along in both runs so the comparison spans more than one output line —
  # at arity 1 an argument-ordered implementation is indistinguishable from a sorted one.
  V1=_memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md
  ab="$(bash inbox-to-memory/scripts/stamp-confirmed.sh "$S"   --note "$A" "$R" --note "$B" "$V1" "$R")"
  ba="$(bash inbox-to-memory/scripts/stamp-confirmed.sh "$S.b" --note "$B" "$V1" "$R" --note "$A" "$R")"
  printf '%s\n' "$ab"
  [ "$ab" = "$ba" ] && echo "order-independent" || { echo "ORDER DEPENDENT"; diff <(echo "$ab") <(echo "$ba"); }
  printf '%s\n' "$ab" | /usr/bin/grep -c '^stamped: .*atlas-region-topology'
  /usr/bin/grep '^last_confirmed:' "$S/$R"
  # case 3, the straddle: 2025-12-02 and 2026-02-17 against a record at 2026-02-10
  S3="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S3/"
  st="$(bash inbox-to-memory/scripts/stamp-confirmed.sh "$S3" --note "$C" "$R" --note "$B" "$R")"
  printf '%s\n' "$st"
  printf '%s\n' "$st" | /usr/bin/grep -c 'atlas-region-topology'
  # cases 1 and 4, one group, two spellings of one path
  S2="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S2/"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S2" --note "$B" "$R" "$R" "$S2/$R" \
    | /usr/bin/grep -c '^stamped: .*atlas-region-topology'
  rm -rf "$S" "$S.b" "$S2" "$S3"
  ```

  `fixture intact` and `order-independent` must both print. The order-independence comparison runs at arity 2 on purpose: the two invocations name the same two records with the groups and the record arguments rearranged, so an implementation emitting in argument order prints `stamped` then `skipped` in one and `skipped` then `stamped` in the other, while a sorted one prints the same two lines twice. At arity 1 the two are indistinguishable, which is how r2's version of this check passed a stamper that had no stable order at all.

  All three `grep -c` results must be `1` — including the straddle, where the single line must be a `stamped:` reading `2026-02-10 -> 2026-02-17` and **not** a `skipped:` for the December group. The straddle and single-group runs close at `stamped: 1  skipped: 0`, the arity-2 runs at `stamped: 1  skipped: 1`, and the case-2 record ends at `last_confirmed: 2026-02-17`, the later of the two dates rather than the last one processed. The two path spellings differ by more than a prefix: `mktemp -d` returns `/var/folders/…` while the real path is `/private/var/folders/…`, so a dedupe built on string equality fails case 4 and one built on `realpath` passes it. Do the max-date keying without `declare -A`; the only bash here is 3.2.57.
- **severity**: blocker
- **failing example**: two inbox files in one run both confirm the freeze-window record. Processed oldest-first the run writes it twice and the phase 6 report names it twice; processed newest-first the second write is refused and the report names it once. Same inbox, same records, two different reports depending on directory order. The straddle variant is subtler and just as wrong: one `stamped:` line and one `skipped: … (2025-12-02 is not later than 2026-02-10)` for a single record, so the report says the run both did and did not update it.

### C-6: a missing key is inserted in contract position, or refused

*(revised in r2, and again in r3. The r1 recipe passed a nonexistent `--note` and so never reached the budget path at all, yet still printed its pass string; the r2 insertion half then truncated its fixture to zero bytes with the same inlined-`open` bug as C-5, so `sed -n '1,20p'` printed nothing and the lint reported `failures: 0` on an empty file.)*

- **text**: A `schema: 2`, `status: accepted` record with no `last_confirmed` gains it, positioned per the record key order in `machine-contracts.md` — after `effective_to` and before `source_refs` — so the scope still passes `frontmatter-key-order`. When inserting the line would push the closing `---` past line 20, the record is not written; it is reported as skipped with a reason naming the budget, because a stamp that turns a clean record into a `frontmatter-budget` failure has done more harm than the missing field did.
- **check**: insertion first, against the real fixture:

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  R="$S/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
  python3 - "$R" <<'PY'
  import re, sys
  p = sys.argv[1]
  t = open(p).read()
  open(p, "w").write(re.sub(r"^last_confirmed:.*\n", "", t, count=1, flags=re.M))
  PY
  [ -s "$R" ] && /usr/bin/grep -q '^schema: 2' "$R" \
    && [ "$(/usr/bin/grep -c '^last_confirmed:' "$R")" = 0 ] \
    && echo "fixture is v2, nonempty, and has no last_confirmed" \
    || echo "FIXTURE NOT IN THE STATE THIS CHECK NEEDS — THE CHECK IS VOID"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" \
    --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md \
    _memory/context/atlas-region-topology-mPmy8XBe5H.md; echo "exit=$?"
  /usr/bin/sed -n '1,20p' "$R"
  bash inbox-to-memory/scripts/lint-scope.sh "$S" | /usr/bin/grep -E '^(failures|FAIL)'
  rm -rf "$S"
  ```

  `fixture is v2, nonempty, and has no last_confirmed` must print first, and all three predicates are load-bearing. The r2 version of this block emptied the file, which then classified as v1 and was skipped, and every assertion after it passed on nothing — so `-s` and `schema: 2` went in. The third predicate is the one r3 added: the **unmutated** fixture already carries `last_confirmed` at `:8`, directly after `date:` and before `source_refs:`, which is exactly where this clause asks the *inserted* key to land. Without asserting the key is gone before the run, a neutered mutation leaves the original line in place and every pass condition prints from a run that inserted nothing.

  Then the record gains `last_confirmed: 2026-02-17` directly after `date:` (it carries neither `effective_from` nor `effective_to`) and directly before `source_refs:`, at `exit=0`, and the lint reports `failures: 0`.

  Then the budget refusal, on a scope built for it — **with a real note in it**, so the run reaches the budget path rather than dying on a usage error and printing the pass string for the wrong reason. A record carrying the maximum 17 keys plus one frontmatter comment line closes on exactly line 20, which is where the shipped `assets/records/` templates live:

  ```bash
  S="$(mktemp -d)"; mkdir -p "$S/_memory/context" "$S/notes" "$S/_inbox"
  /bin/cat > "$S/notes/2026-06-01-budget-probe-BBBBBBBBBB.md" <<'EOF'
  ---
  id: BBBBBBBBBB
  date: 2026-06-01
  type: working-session
  tags: [probe]
  topics: [probe]
  ---

  ## Notable Quotes

  ## Raw Content

  Probe.
  EOF
  R="$S/_memory/context/budget-probe-AAAAAAAAAA.md"
  /bin/cat > "$R" <<'EOF'
  ---
  schema: 2
  body_schema: 1
  id: AAAAAAAAAA
  memory_type: Context
  title: 'Probe'
  status: accepted
  date: 2026-01-01
  effective_from: 2026-01-01
  effective_to: 2026-12-31
  # a commented-out key, as the shipped record templates carry
  source_refs: [BBBBBBBBBB]
  applies_to: [probe]
  owners: [Nobody]
  tags: [probe]
  related: []
  exception_to: []
  supersedes: []
  superseded_by: []
  ---

  # Probe
  EOF
  bash inbox-to-memory/scripts/lint-scope.sh "$S" | /usr/bin/grep '^failures:'   # failures: 0
  before="$(shasum "$R" | cut -d' ' -f1)"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" \
    --note notes/2026-06-01-budget-probe-BBBBBBBBBB.md \
    _memory/context/budget-probe-AAAAAAAAAA.md; echo "exit=$?"
  [ "$before" = "$(shasum "$R" | cut -d' ' -f1)" ] && echo "held" || echo "OVERFLOWED"
  rm -rf "$S"
  ```

  The run must exit 0, print a `skipped:` line naming the budget, and print `held`. Because the note is real and dated later than the record, every other reason to skip is excluded — the record is v2, `accepted`, and has no `last_confirmed` at all — so `held` can only mean the budget path fired. Sanity: inserting the line by hand instead closes the block on 21 and the lint reports `frontmatter-budget: closing --- on line 21, past the 20-line budget`, `failures: 1`, which is the outcome the skip exists to avoid.
- **severity**: blocker
- **failing example**: the key is appended at the end of the block. `frontmatter-key-order` now fails on a record the run just touched, and phase 6's lint goes red on a scope that was clean before the skill ran. The budget half fails when the stamper writes the probe record above and hands the user a `frontmatter-budget` failure in exchange for a metadata update nobody asked to be asked about.

### C-7: the stamp changes nothing else, and the scope still lints clean

- **text**: A stamped record differs from its prior self in exactly one line, the `last_confirmed` value (or one inserted line, per C-6). Body bytes, every other frontmatter key, quoting style, and the trailing newline are unchanged. After any stamping run, `lint-scope.sh` over the scope reports the same failure count it reported before.
- **check**:

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  before="$(bash inbox-to-memory/scripts/lint-scope.sh "$S" | /usr/bin/grep '^failures:')"
  cp -R "$S" "$S.orig"
  bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" \
    --note notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md \
    _memory/context/atlas-region-topology-mPmy8XBe5H.md \
    _memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md >/dev/null
  diff -r "$S.orig" "$S"
  after="$(bash inbox-to-memory/scripts/lint-scope.sh "$S" | /usr/bin/grep '^failures:')"
  echo "before=$before after=$after"
  rm -rf "$S" "$S.orig"
  ```

  The `diff -r` output must be exactly one changed file and, within it, one changed line pair — the old and new `last_confirmed`. `before` and `after` must both read `failures: 0`.
- **severity**: blocker
- **failing example**: the script round-trips the frontmatter through `yq`, so `title: 'Billing region and deployment region are not the same boundary'` comes back double-quoted and `related: [clarifies::G2k65qG3Nc]` comes back in block style. The record now fails `frontmatter-single-line`, and every unrelated line in it shows up in the user's `git diff`.

### C-8: phase 2.5 detects confirmation in the same pass, inside the same budget

- **text**: `SKILL.md`'s phase 2.5 says that the pass detecting contradictions also detects confirmations — an input restating a claim an `accepted` record already makes — and that both come out of the same five-body-read budget. The budget sentence at `SKILL.md:67` still binds and is not weakened, duplicated, or given a second allowance for confirmations. The section says which records are eligible (`accepted` only, matching the existing rule) and that the resulting stamp does not pass through phase 5. Where the write happens is C-17's business, not this clause's.
- **check**: `checker-judgment`: read `SKILL.md`'s phase 2.5 end to end. Does it state that confirmation detection rides the contradiction pass, that eligibility is `status: accepted`, and that the five-read budget covers both without being raised? Would an agent following only this section know to stamp without asking? A section that adds confirmation detection as a separate numbered step with its own reads fails.
- **severity**: blocker
- **failing example**: phase 2.5 gains "then, in a second pass, read each accepted record again and decide whether the input confirms it." The read budget has silently doubled, and the sentence at `:67` insisting it binds is now the least true sentence in the file.

### C-9: phase 6 names every record the run touched, and every one it declined to

- **text**: `SKILL.md`'s phase 6 requires the verify report to name every record whose `last_confirmed` was stamped, and every record the **stamper** declined to write along with the reason — that is, the records phase 2.5 judged confirmed and handed to the script, which it then skipped on one of the four skip branches in the stage-2 table: v1, non-`accepted`, not-later, or over budget. Records merely read at phase 2.5 and not judged confirmed are outside this list; they were never candidates for a write. Naming the stamps alone is not enough: a skipped v1 record is the one a user would otherwise have no way to notice was left behind, and a silent skip is indistinguishable from a record nobody confirmed.
- **check**: `checker-judgment`: read phase 6. Does it require both lists by name, and is the skipped list required rather than optional? Is the skipped list scoped to what the stamper declined, so a reader cannot mistake it for an inventory of everything phase 2.5 opened? Does it read as a report of writes the user did not approve individually, which is what makes the report load-bearing rather than decorative? A phase 6 that says "mention any records that were updated" fails on vagueness.
- **severity**: blocker
- **failing example**: phase 6 gains one bullet, "note any `last_confirmed` updates." A run stamps four records and skips six, the report says "some records were updated," and the one durable trace of an ungated write is a sentence with no nouns in it.

### C-10: the operating rules name the exception, and its reasoning

- **text**: `SKILL.md`'s Operating Rules carries a rule naming the `last_confirmed` write-through as the sole sanctioned exception to the per-item sign-off gate on `_memory/`, with the issue's reasoning: it is metadata rather than content, and gating it would put an obviously-yes prompt in front of every input, which trains rubber-stamping and devalues the gate protecting the writes that need protecting. The rule reads as a bounded exception rather than a loosening — it says what is still gated.
- **check**: `checker-judgment`: read the Operating Rules list whole. Is the exception stated as sole, scoped to the sign-off rule, and reasoned rather than asserted? Critically: the list already ends with "This is the one sanctioned exception to preserving raw content exactly as captured" for VTT collapsing (`SKILL.md:459`). Two rules each claiming to be "the one sanctioned exception" to different rules must not read as a contradiction — check that each names the rule it excepts, closely enough that a reader is never left counting exceptions.
- **severity**: blocker
- **failing example**: a bullet reading "**`last_confirmed` is written without sign-off.** This is the one sanctioned exception." It sits four lines below the VTT bullet making the identical claim, gives no reason, and does not say that record creation is still gated — so the honest reading is that the sign-off rule now has a hole of unknown size.

### C-11: no surviving prose gives a complete-sounding account that omits the write-through

*(revised in r2: adds the one document the r1 audit found the census could legitimately skip past — the `_memory/` conventions file that ships into every scaffolded scope.)*

- **text**: After this job, no passage in the skill's own prose leaves a reader with what reads as a full account of when the skill writes into `_memory/`, or of how `last_confirmed` comes to hold its value, while omitting the write-through. Two documents carry a named obligation on top of the census:

  - **`references/machine-contracts.md`** states the key's lifecycle in one place: the migrator initializes it to the record's own date, the write-through advances it and never retreats, and a record with no `schema` key never gains it — which follows from that document's own generation table, whose first row puts a v1 file outside the frontmatter contract entirely.
  - **`assets/claude-md/_memory.template.md`** accounts for the write-through *somewhere in the document*. This is the agent-facing conventions file that ships into every scaffolded `_memory/`, it lists `last_confirmed` as required frontmatter at `:21` with no account of how the value is ever set, and it is the document an agent working in a user's scope actually reads. Its passage at `:65` is pre-ruled below as passing on its own terms; that pre-ruling is about the sentence, not about the file, and the file still owes the reader an account.
- **check**: `checker-judgment`, with the sweep re-derived rather than taken from the list below.

  **The discriminating test, in two questions.** Both must be answered for each hit, and they are ordered:

  1. *Would a user who has read only this passage be surprised to find `git status` showing modified files under `_memory/` after a run in which they approved nothing?* If yes, the passage is incomplete and must carry the exception or be narrowed until it stops making the claim.
  2. *Is this passage its document's only account of what the skill does to `_memory/` on its own?* If yes, it carries the burden even when question 1 is arguable.

  Literal truth is **not** the test. The write-through creates no record and promotes nothing, so nearly every candidate passage stays literally true; a test built on truth passes all of them and the clause checks nothing.

  **Two boundary cases are pre-ruled here, so two checkers converge rather than re-litigating them.** `README.md:74` ("Nothing is ever promoted to memory automatically. Every record requires your explicit per-candidate approval…") **fails** as shipped: it is the README's only statement about automatic writes to memory, it sits in a list of operational caveats a user reads as exhaustive, and question 1 answers yes. `assets/claude-md/_memory.template.md:65` ("Only create record files in `_memory/` after the user reviews…") **passes** unchanged: it is step 2 of a numbered "How Records Get Created" procedure, plainly about creation, and no reader takes it as an inventory of every write. The document-level obligation above is what keeps that second ruling from emptying the file of any mention at all.

  **Then question the category.** The sweep below searches for passages about approval and about `last_confirmed`. A passage describing the write surface in neither vocabulary will not appear in it, and the #32 job's enumeration moved from four to eight precisely because three sweeps in a row inherited one predicate.

  ```bash
  /usr/bin/grep -rniE "sign-?off|auto-promote|automatic|per-candidate|approval|last_confirmed" \
    inbox-to-memory/ _maintenance/inbox-to-memory/
  ```

  Twelve locations were candidates at `924f81f`, and this is a floor rather than a boundary: `SKILL.md:26`, `:138`, `:168`, `:361`, `:455`; `README.md:74`; `assets/claude-md/_memory.template.md:21`, `:65`, `client.template.md:71`, `project.template.md:55`; `references/migration.md:37`; `references/retrieval-funnel.md:40`. A verdict reporting exactly these twelve without having re-derived them has not run the check. One known hit sits outside C-16's allowlist — `scripts/migrate-scope.sh:348-349`, carrying the same reasoning as `migration.md:37` — and the last non-goal governs it: surface it, do not fix it.
- **severity**: major
- **failing example**: `README.md:74` ships unchanged. A user reads the bullet as the whole story, runs the skill, and finds `git status` holding modifications to three records they were never asked about. Also failing: every prose file is corrected except `_memory.template.md`, so the conventions doc sitting inside the very directory being written to is the one place that never mentions the write.

### C-12: no new token, and the registered inventory is unchanged

*(revised in r2: compares against the job's base commit rather than `HEAD`, which goes vacuous the moment the work is committed.)*

- **text**: This job registers no new inline token. The set of token shapes registered across the four places that enumerate them — `SKILL.md`'s candidate-flag block, the grammar table and token-field list in `machine-contracts.md`, `assets/note.template.md`, and `REGISTERED_TOKENS` in `lint-scope.sh` — is identical before and after. The trace of a confirmation is the phase 6 report and the record's own date, not a flag in the note.
- **check**: diff the inventory, extracted from all four files at once, between the base commit and the working tree. This runs clean today and was verified against a synthetic `[confirms accepted:` line, which the pattern does catch:

  ```bash
  BASE=f027515c9f5487acd4b8d0be973af0e5bc9017d0
  inv() {
    for f in inbox-to-memory/SKILL.md inbox-to-memory/references/machine-contracts.md \
             inbox-to-memory/assets/note.template.md inbox-to-memory/scripts/lint-scope.sh; do
      if [ -n "$1" ]; then git show "$1:$f"; else /bin/cat "$f"; fi
    done | /usr/bin/grep -ohE '\[[a-z][a-z0-9 -]*(:|\])' | sort -u
  }
  diff <(inv "$BASE") <(inv); echo "inventory exit=$?"
  ```

  Must print no diff and `inventory exit=0`. The extraction picks up a little stable noise from `lint-scope.sh`'s regex character classes (`[a-z]`, `[a-z0-9-]`); that is fine, because the assertion is a set difference and identical noise cancels on both sides. Use `/bin/cat` — `cat` is aliased to `ccat` in the agent shell. Residual and accepted: a capitalized or underscored token shape falls outside the character class, so C-8's and C-10's judgment rubrics remain the backstop for a token dressed up to evade this.
- **severity**: major
- **failing example**: a `[confirms accepted: [[<record>|<label>]]]` row lands in the grammar table and `lint-scope.sh` grows a `confirmation-fields` check. The job has quietly doubled, and the note now carries a flag that looks like it is waiting for a sign-off that by design will never come.

### C-13: the smoke test proves it, on copies, inside the guard

*(revised in r2 on three counts the r1 audit raised: the placement check was bounded on one side only, the restore assertion could not fail against an untracked file, and the saboteur discarded so much of the interface that a red suite proved nothing in particular.)*

- **text**: `tests/inbox-to-memory-smoke.sh` gains a section for the write-through that runs the real script and asserts, at minimum: a run over a copy of the `mixed/` fixture leaves the v1 record byte-identical while the v2 record moves to the note's date (the issue's seventh criterion); the backward and equal-date holds; the cross-group dedupe of C-5 case 2, which is the issue's "confirmed twice in one run"; the `status` gate; and key insertion at contract position with the lint still clean. Every case works on a copy under `mktemp -d` and registers it for cleanup.

  **The section lands between the guard's snapshot and its comparison** — after `:586`, before `:1299` — so the guard actually covers it. Above the snapshot it is baked into the baseline; below the comparison it is invisible. The guard's comment says "a migration test"; it now also covers stamping tests and must say so.

  The section opens with a banner comment reading exactly `# last_confirmed write-through (#27)`, in the style of `# v1 link checking (#32)` at `:1227`. That banner is the placement anchor, and it exists because a bare search for `stamp-confirmed` cannot serve as one: it also matches C-17's `require_text` wiring assertion, which legitimately belongs beside the existing `scripts/lint-scope.sh` assertion at `:300`, and it matches the guard message once the worker reworks it to mention stamping — as this clause instructs. Both would read as the section being out of place.

  **The section binds the script to `stamper` and invokes through it**, matching the suite's house style: `lint=` at `:11`, `vtt=` at `:522`, `migrator=` at `:588`, `verify=` at `:970`. The binding sits inside the section, below the banner. This is pinned rather than left to taste because the placement check has to find the invocations, and in this file there is nothing else to find — `grep -n 'migrate-scope\.sh'` over all 1309 lines returns two hits, the binding and C-17's `require_text`, and not one invocation. A check searching for literal paths would measure a variable assignment or nothing at all.

  Invoke `$stamper` on a plain line, or capture it into a variable as the suite already does at `out="$(bash "$migrator" …)"`. Never inside an `echo` or a `require_text`, both of which the placement check excludes — an invocation wrapped in one is invisible to the bounds and can sit outside the guard while the section reads as if it were inside. (Recorded as a minor by the r7 audit, with this sentence as the prescribed close; `echo "$(…)"` appears nowhere in the suite today.)
- **check**: four parts.

  ```bash
  bash tests/inbox-to-memory-smoke.sh; echo "suite exit=$?"
  # placement: bounded on both sides, anchored on the guard's own code rather than its prose
  snap=$(/usr/bin/grep -n 'fixtures_before=' tests/inbox-to-memory-smoke.sh | head -1 | cut -d: -f1)
  cmp=$(/usr/bin/grep -n '"\$fixtures_before"' tests/inbox-to-memory-smoke.sh | tail -1 | cut -d: -f1)
  ban=$(/usr/bin/grep -n '^# last_confirmed write-through (#27)$' tests/inbox-to-memory-smoke.sh | cut -d: -f1)
  # The binding and the uses are two sets, found two ways, and both must exist
  # and both must sit in bounds. Folding them into one set is what let the
  # binding alone satisfy both bounds while the real invocations sat outside.
  bind=$(/usr/bin/grep -n '^stamper=.*stamp-confirmed\.sh' tests/inbox-to-memory-smoke.sh | cut -d: -f1)
  uses=$(/usr/bin/grep -nE '\$\{?stamper\}?' tests/inbox-to-memory-smoke.sh \
          | /usr/bin/grep -v 'require_text' | /usr/bin/grep -v '^[0-9]*:#' \
          | /usr/bin/grep -v 'echo ' | cut -d: -f1)
  first=$(printf '%s\n' "$uses" | sort -n | head -1)
  last=$(printf '%s\n' "$uses" | sort -n | tail -1)
  echo "snap=$snap banner=$ban bind=$bind first-use=$first last-use=$last cmp=$cmp"
  [ -n "$ban" ] && [ -n "$bind" ] && [ -n "$first" ] \
    && [ "$snap" -lt "$ban" ] && [ "$ban" -lt "$bind" ] && [ "$bind" -le "$first" ] \
    && [ "$last" -lt "$cmp" ] \
    && echo "inside the guard" || echo "OUTSIDE THE GUARD"
  ```

  `inside the guard` must print. An empty `$ban`, `$bind`, or `$first` is a failure, not a pass — and the third is the one that matters most: a section that binds `stamper` and never uses it has no invocations, which is C-13's first failing example, and an earlier draft of this check passed it because the binding line alone satisfied both bounds. The bounds are the assignment and the last use of `fixtures_before`, never the failure message, since the clause instructs the worker to reword that message and anchoring on it would lose the anchor by obeying the clause. The invocation set excludes `require_text` lines, comment lines, and `echo` lines for the reason given above: C-17's wiring assertion sits legitimately beside the `scripts/lint-scope.sh` one at `:300`, and the guard's failure message — which this clause tells the worker to reword to mention stamping — is an `echo`. Both name the script without being part of the section, and counting either turns a correct artifact into a false FAIL on a blocker clause.

  The pattern matching `$stamper` as well as the literal path is what makes the bounds measure anything. Searching for the literal alone, against the house style this clause requires, finds the binding and nothing else — so a correct section whose binding sits beside `migrator=` at `:588`, exactly where the Baseline points, would be FAILed for being outside the guard, while a section that binds inside the guard and appends every real invocation after the comparison would pass. That second artifact is this clause's own failing example, green-lit by its own check.

  Then `checker-judgment`: read the new section. Is every assertion run against a real invocation of `stamp-confirmed.sh` rather than a `require_text` against SKILL.md, and does each case build and register its own scope?

  Then falsify the headline assertion. The saboteur **delegates to the real script and then additionally stamps the v1 records it was handed**, so it is the real behavior in every respect except the one being falsified — a red suite therefore means the suite asserts the v1 hold, not merely that it noticed the output format changed:

  ```bash
  B="$(mktemp -d)"; SCS=inbox-to-memory/scripts/stamp-confirmed.sh
  cp "$SCS" "$B/real.sh"; orig="$(shasum "$SCS" | cut -d' ' -f1)"
  /bin/cat > "$SCS" <<'EOF'
  #!/usr/bin/env bash
  # SABOTEUR. Real behavior, plus it stamps v1 records too. Narrow on purpose:
  # everything except the v1 hold is delegated, so a green suite means the v1
  # hold is untested rather than that the output shape changed.
  set -euo pipefail
  bash "$SABOTEUR_REAL" "$@"
  root="$1"; shift; want=0; d=""
  for a in "$@"; do
    case "$a" in
      --dry-run) ;;
      --note) want=1 ;;
      *) if [ "$want" = 1 ]; then
           d="$(/usr/bin/grep -m1 '^date:' "$root/$a" | /usr/bin/sed 's/^date: *//')"; want=0
         else
           f="$a"; [ -f "$f" ] || f="$root/$a"
           /usr/bin/grep -q '^schema:' "$f" ||
             /usr/bin/sed -i '' "s|^source_refs:|last_confirmed: $d\\
  source_refs:|" "$f"
         fi ;;
    esac
  done
  EOF
  SABOTEUR_REAL="$B/real.sh" bash tests/inbox-to-memory-smoke.sh >/dev/null 2>&1; echo "sabotaged exit=$?"
  cp "$B/real.sh" "$SCS"; rm -rf "$B"
  [ "$orig" = "$(shasum "$SCS" | cut -d' ' -f1)" ] && echo "restored" || echo "SABOTEUR STILL INSTALLED"
  git status --porcelain tests/fixtures/ | head; echo "fixture damage above, if any"
  ```

  `sabotaged exit=` must be nonzero — a suite that stays green against a stamper with no v1 guard is testing nothing. `restored` must print; comparing shasums is the point, because `git diff` is empty for an untracked file and the stamper is untracked in this job, which is how r1's version of this step managed never to fail. The `git status` line must be empty: a sabotaged run can trip the fixture guard by writing to a checked-in fixture, and leaving that damage behind would fail C-16 later for the wrong reason. Restore with `git checkout -- tests/fixtures/` if it is not.
- **severity**: blocker
- **failing example**: the new section is six `require_text` calls against `SKILL.md` confirming it contains the words "V1 records are skipped entirely." The suite is green, the seventh acceptance criterion is checked off, and nothing has been tested — the exact outcome choosing a script over prose was meant to prevent. Equally failing: a real section, correctly written, appended at `:1310` where the fixture guard cannot see it.

### C-14: the eval suite grades the judgment half, negative case included

*(revised in r2: the r1 clause required two of EVALS.md's three enumerations to be updated and missed the Grading table, which is the same stale-enumeration defect that made the `:9` fixture count a required fix.)*

- **text**: `_maintenance/inbox-to-memory/EVALS.md` gains a scenario for the write-through, backed by a new fixture at `tests/fixtures/inbox-to-memory/evals/confirmation-writethrough/`. That path is pinned; every reference to it uses that exact name.

  The fixture holds an `accepted` v2 record the transcript genuinely confirms, an `accepted` v1 record it also confirms, an `accepted` v2 record that is read at phase 2.5 and neither confirmed nor contradicted, and a `proposed` record the transcript confirms. The scenario's pass table is binary per row and covers the stamp, the v1 hold, the two negative cases, and the absence of any per-record prompt. It carries a "without the skill" baseline paragraph like the four scenarios before it.

  **All four of the document's enumerations move together**: the fixture count at `:9` from "Four" to five, the fixture list under it, the Grading table at `:123-128` which names scenarios 1 through 4 by row, and the closing sentence at `:130` ("The delta is widest on 1 and 4") if the new scenario changes what is true of the set.
- **check**: `checker-judgment`: read the scenario against the four already there. Is every row settleable by looking at the staged copy, with no row needing an argument? Does the negative case have teeth — is the unconfirmed record close enough to the transcript's subject that a model stamping everything it read would actually stamp it? Then verify mechanically:

  ```bash
  staged="$(bash _maintenance/inbox-to-memory/eval-scope.sh confirmation-writethrough)"
  bash inbox-to-memory/scripts/lint-scope.sh "$staged" | /usr/bin/grep -E '^(failures|v1 files|v2 files)'
  /usr/bin/grep -H '^status:\|^schema:\|^last_confirmed:' "$staged"/_memory/*/*.md
  rm -rf "$staged"
  # every enumeration moved
  /usr/bin/grep -c '^Four, all under' _maintenance/inbox-to-memory/EVALS.md    # 0
  /usr/bin/grep -c '^Five, all under' _maintenance/inbox-to-memory/EVALS.md    # 1
  /usr/bin/grep -c 'confirmation-writethrough' _maintenance/inbox-to-memory/EVALS.md
  /usr/bin/grep -c '^| [0-9]\.' _maintenance/inbox-to-memory/EVALS.md          # 5
  ```

  The staged scope must report `failures: 0`, and the four records must be present with the statuses and generations the clause names. The fixture-count sentence must have moved from `Four, all under` to `Five, all under` — anchored to the start of `:9` on purpose, because `Four` also appears at `:12` in "Four prior notes" about the `unacknowledged-tension` fixture, which is a fact about that fixture and must not change. The Grading table must hold five numbered rows.
- **severity**: major
- **failing example**: the fixture holds one accepted v2 record and one accepted v1 record, and the scenario grades two rows. Every model passes, including one that stamps every record it opened, because nothing in the fixture can distinguish "confirmed this" from "read this." Also failing: a fifth scenario written well, with a Grading table that still stops at four — a document whose own summary table has quietly become an incomplete census of itself.

### C-15: no cross-reference this job invalidates is left pointing at the wrong place

- **text**: Every line-number cross-reference that this job's edits move is either corrected or rewritten to point at something stable. `_maintenance/inbox-to-memory/eval-scope.sh:6` cites `tests/inbox-to-memory-smoke.sh:1226` for the never-migrate-a-fixture rule; the rule is at `:1296` today, so the citation is already wrong and the new section moves it again. Fix it, and prefer a form that does not rot — the rule's comment text is greppable and its line number is not.
- **check**:

  ```bash
  /usr/bin/grep -rnoE 'inbox-to-memory-smoke\.sh:[0-9]+' _maintenance/ inbox-to-memory/ tests/
  ```

  For each hit, open the cited line in the shipped tree and confirm it says what the citing comment claims. A hit that no longer resolves is a failure; zero hits is a pass, since the citation was rewritten to a stable form.
- **severity**: minor
- **failing example**: the comment still reads `tests/inbox-to-memory-smoke.sh:1226`, which now lands in the middle of the new write-through section — a pointer that resolves to a real line saying something else entirely, which is worse than one that resolves to nothing.

### C-16: the suites stay green, the diff stays in scope, and the tree is still uncommitted

*(revised in r2: asserts `HEAD` is still the base commit, since `check-diff-scope.py` reads a committed tree as an empty diff and passes on anything.)*

- **text**: All three test suites exit 0 against the shipped tree, and the working tree's diff touches nothing outside the job's surface. The job's work is uncommitted when this runs.
- **check**:

  ```bash
  bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh; echo "suites exit=$?"
  [ "$(git rev-parse HEAD)" = "f027515c9f5487acd4b8d0be973af0e5bc9017d0" ] \
    && echo "HEAD is the base" || echo "HEAD MOVED — THIS CHECK AND C-12 ARE BOTH VACUOUS"
  .agent-guild/scripts/check-diff-scope.py \
    inbox-to-memory/SKILL.md \
    inbox-to-memory/README.md \
    inbox-to-memory/references/ \
    inbox-to-memory/assets/ \
    inbox-to-memory/scripts/stamp-confirmed.sh \
    tests/inbox-to-memory-smoke.sh \
    tests/fixtures/inbox-to-memory/evals/ \
    _maintenance/inbox-to-memory/EVALS.md \
    _maintenance/inbox-to-memory/eval-scope.sh \
    .agent-guild/; echo "scope exit=$?"
  ```

  All three must pass, and `HEAD is the base` must print. Note that `inbox-to-memory/scripts/lint-scope.sh` is deliberately absent from the allowlist — the stamper is the only script this job adds, and naming it by filename rather than admitting `scripts/` is the second lock on the no-lint-changes non-goal.
- **severity**: blocker
- **failing example**: the run is green but `git status` also shows `tests/fixtures/inbox-to-memory/mixed/_memory/context/atlas-region-topology-mPmy8XBe5H.md` modified — a test forgot to copy and stamped the checked-in fixture, which every later run then reads as the expected state. Or: the worker commits first, `check-diff-scope.py` reports `OK: 0 path(s) in scope` against an empty diff, and the clause passes without having looked at anything.

### C-17: the skill calls the stamper, once per run, at the one point that admits it

*(revised in r2 and again in r3. r1 found "after the note exists, before phase 5" left the end of phase 4 equally admissible; r2 claimed batch scope forced the answer; r3's audit showed it does not, because SKILL.md's phases each loop the queue separately, so the close of phase 3 works for a batch call too. The pin below is now stated as the convention it is.)*

- **text**: `SKILL.md` shows the stamper's invocation in its own `<skill-path>` convention — `bash <skill-path>/scripts/stamp-confirmed.sh <scope-root> --note …`, matching how it shows `lint-scope.sh` at `:175`, `migrate-scope.sh` at `:347`, and `verify-migration.sh` at `:399`. The bare string `scripts/stamp-confirmed.sh` therefore appears in the file, which is what the smoke suite pins, mirroring `tests/inbox-to-memory-smoke.sh:600`.

  Three things about the call are required, and only the first two are derived:

  1. **One call for the whole queue, never one per input.** This *is* forced: the script takes every `--note` group in a single invocation, and C-5's dedupe is defined over that invocation. A per-input loop cannot satisfy "confirmed twice in one run is stamped once." SKILL.md says so and says why.
  2. **The call is made only when phase 2.5 found at least one confirmation.** Also forced: C-1 makes an invocation with no `--note` group, or a group with no records, a usage error. Most runs confirm nothing, and those runs make no call at all. SKILL.md says this explicitly rather than leaving a reader to infer it from the exit code.
  3. **The call sits immediately after phase 4 and before phase 5.** This is a **convention, not a derivation**, and SKILL.md must not dress it up as one. The close of phase 3 and the close of phase 4 both satisfy every constraint the script imposes — phase 4 only disposes sources and opens no gate. The constitution picks the later so that two agents converge and the report reads in phase order. A worker who invents a load-bearing reason for the boundary has written something false; the honest sentence names phase 4 and says the choice is a convention, with the batch rule in (1) as the part that actually matters.
- **check**: deterministic first:

  ```bash
  /usr/bin/grep -n 'scripts/stamp-confirmed.sh' inbox-to-memory/SKILL.md
  /usr/bin/grep -n 'require_text inbox-to-memory/SKILL.md "scripts/stamp-confirmed.sh"' tests/inbox-to-memory-smoke.sh
  ```

  Both must return at least one hit. Then `checker-judgment`: read phases 2.5 through 6 in sequence. Is it unambiguous that the stamp is one call for the whole queue rather than one per input, and that a run finding no confirmations makes no call? Is the phase-4 boundary presented as a convention rather than justified by an argument that does not survive reading phase 4? A SKILL.md that mentions the script only inside phase 6's verify list fails — that puts the write after the gate it exists to bypass. One that shows it inside the per-input loop fails against the script's own interface. One that claims the boundary is forced fails for asserting something untrue about the document it is part of.
- **severity**: blocker
- **failing example**: SKILL.md's phase 2.5 gains a fine paragraph about detecting confirmations, phase 6 gains a reporting bullet, `stamp-confirmed.sh` ships and passes C-1 through C-7, and the string `stamp-confirmed` appears nowhere in SKILL.md. Every other clause is green and the feature does not exist, because nothing ever calls the script. Also failing: SKILL.md puts the call at the end of the per-input loop, so an inbox of six files makes six invocations and the issue's sixth acceptance criterion quietly stops holding — the exact defect the r1 audit filed.

### C-18: the resolution rule itself is exercised, every branch

*(new in r3. The r3 audit's structural finding: at 567 lines nobody reads this document whole, and the passage most likely skimmed is the two-stage rule — which is exactly the rule that exists to stop C-1, C-3, C-5, C-6, and C-9 from drifting apart. It was prose governing five clauses and falsifiable through none of them. Now it has its own harness.)*

- **text**: One invocation exercises four of stage 2's six branches at once — the v1 skip, the non-`accepted` skip, a stamp onto an existing key, and a stamp that inserts a missing one — plus a record named by two groups, and produces exactly one output line per distinct record with the counts adding up. Four records, four lines. The remaining two branches, earlier-or-equal and over-budget, need their own scopes and stay with C-3 and C-6.

  This clause asserts nothing C-2 through C-6 do not each assert individually. What it adds is that they hold *simultaneously, in one run*, which is the only condition under which the resolution rule is a rule rather than five separate behaviors that happen to agree when tested apart.
- **check**: build a scope carrying one record per branch and stamp them all at once.

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  B=notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md
  C=notes/2025-12-02-atlas-steerco-ZGulgExW0q.md
  V2="$S/_memory/context/atlas-region-topology-mPmy8XBe5H.md"
  mk() {  # $1 dest slug, $2 python edit applied to a copy of the v2 record
    cp "$V2" "$S/_memory/context/$1.md"
    python3 - "$S/_memory/context/$1.md" "$2" <<'PY'
  import re, sys
  p, mode = sys.argv[1], sys.argv[2]
  t = open(p).read()
  if mode == "proposed":  t = t.replace("status: accepted", "status: proposed", 1)
  if mode == "nokey":     t = re.sub(r"^last_confirmed:.*\n", "", t, count=1, flags=re.M)
  open(p, "w").write(t)
  PY
  }
  mk r-proposed proposed          # branch 2
  mk r-nokey    nokey             # branch 5
  cp -R "$S" "$S.snap"
  out="$(bash inbox-to-memory/scripts/stamp-confirmed.sh "$S" \
    --note "$B" \
      _memory/context/atlas-region-topology-mPmy8XBe5H.md \
      _memory/decisions/freeze-window-owned-by-ops-ocPwdpeY0a.md \
      _memory/context/r-proposed.md \
      _memory/context/r-nokey.md \
    --note "$C" \
      _memory/context/atlas-region-topology-mPmy8XBe5H.md)"; echo "exit=$?"
  printf '%s\n' "$out"
  # Anchor on the path, not the bare verb: the closing summary line also begins
  # `stamped:`, so `^stamped: ` counts 3 against a correct stamper and no
  # implementation can satisfy both this clause and the contract.
  printf '%s\n' "$out" | /usr/bin/grep -c '^stamped: _memory/'   # 2
  printf '%s\n' "$out" | /usr/bin/grep -c '^skipped: _memory/'   # 2
  # The insertion is the branch that distinguishes this clause from C-2..C-6 run
  # apart, so assert the record state and not only the counts.
  printf '%s\n' "$out" | /usr/bin/grep -q '^stamped: .*r-nokey.* none -> 2026-02-17' \
    && echo "insert reported as an insert" || echo "INSERT REPORTED AS AN UPDATE"
  /usr/bin/grep -c '^last_confirmed: 2026-02-17' "$S/_memory/context/r-nokey.md"   # 1
  diff -r "$S.snap/_memory/context/r-proposed.md" "$S/_memory/context/r-proposed.md" \
    && echo "proposed record untouched"
  bash inbox-to-memory/scripts/lint-scope.sh "$S" | /usr/bin/grep '^failures:'
  rm -rf "$S" "$S.snap"
  ```

  Four distinct records, four output lines, no more: two `stamped:` (the v2 record resolving to `2026-02-17` despite also being named by the December group, and the missing-key record gaining it), two `skipped:` (the v1 record, the proposed one). The closing line reads `stamped: 2  skipped: 2`, `exit=0`, and the scope still lints at `failures: 0`. `insert reported as an insert` and `proposed record untouched` must both print, and `r-nokey.md` must hold exactly one `last_confirmed: 2026-02-17`.

  The record-state assertions are the point of the clause and not belt-and-braces. A stamper that leaks per-record state across loop iterations — the natural bash-3.2 parallel-array bug — passes C-1 through C-7 verbatim, and produces counts and a closing line byte-identical to a correct run here. The only distinguishing byte is whether the insert line reads `none -> 2026-02-17` or `2026-02-10 -> 2026-02-17`. A version of this check that asserted only counts would have shipped that bug.

  The over-budget and earlier-or-equal branches are covered by C-6 and C-3 on their own scopes; this run must not accidentally produce either, and a `skipped: _memory/` count above 2 means it did.
- **severity**: major
- **failing example**: a stamper that handles each branch correctly in isolation but resolves groups per-record inside the per-record loop, so the December group re-decides the v2 record after the February one already stamped it and the run emits five lines for four records. Every one of C-2 through C-6 passes on its own scope; the report the user reads is still wrong.

## Protected content

Nothing in this job ships verbatim author words. No manifest.

## Non-goals

- **A lint check on `last_confirmed`.** No date-format, not-in-the-future, and not-before-`date` validation. The stamper is the only writer this job adds, C-7 holds it to leaving the scope lint-clean, and a new lint check would fire on records the skill never touched.
- **A `[confirms accepted: ...]` token.** Settled with the user and locked by C-12.
- **Backfilling `last_confirmed` across a scope.** The stamper writes only the records it is handed.
- **Migrating v1 records so they can be stamped.** V1 records are skipped, permanently and by design; migrate mode already exists for anyone who wants the field.
- **`tests/fixtures/inbox-to-memory/README.md:3`, which says "Three scopes" above four bullets.** A real defect, unrelated to this change, and predating it. File it; do not fix it here.
- **Any change to `lint-scope.sh`, `migrate-scope.sh`, `verify-migration.sh`, or `collapse-vtt.sh`.** If the job appears to need one — and C-11's census does reach `migrate-scope.sh:348-349` — that is a finding to surface, not a task to do.
