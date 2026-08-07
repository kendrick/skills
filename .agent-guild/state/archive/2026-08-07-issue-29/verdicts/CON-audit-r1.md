---
task: CON-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: PASS
checked_at: 2026-08-07T17:12:59Z
---

Audit of the revised `.agent-guild/state/constitution.md` against
`.agent-guild/state/spec.md` (`kendrick/skills#29`). Round 1; the highest prior
audit is `CON-audit-r0.md`, a FAIL. That verdict was read, then set aside: every
line number, string, behavioral claim, and mutation result below was re-derived
from the working tree at `5f00eea` by running things here, not inherited from
the peer who wrote r0.

Baseline re-established before judging: `yq` at `/opt/homebrew/bin/yq`; all
three suites exit 0 unmutated (`inbox-to-memory-smoke` 0, `file-issue-smoke` 0,
`handoff-smoke` 0); repo tree clean before and after this audit.

The recipe was executed verbatim. It exits 0 and prints the count-1 case the
issue is about. C-6's copy-and-mutate method was executed too, both halves: a
copy of the repo runs green, and the zeroed-counts mutant applied to that copy
exits 1 naming the record assertion at `:1041`. Details under Verified by
execution.

## Per-clause results

| clause | result | severity | description | evidence |
| ------ | ------ | -------- | ----------- | -------- |
| C-1 | PASS | blocker | Premise re-confirmed independently: every nonzero path for `lint_failures`, `renames`, and `deletions` calls `fail`, so the record can only ever print those at zero and `links_checked` really is the only varying counter. The observed/derived split r0 asked for is now explicit and correct — count 1 is the only case in the tree, and I produced it. Derivation at 0 and 2 catches the hard-coded-singular fix. | `verify-migration.sh:85-88` (`fail` increments `failures`), `:113-125`, `:180`, `:184`; record gate `:204`; printf `:205-206`; recipe output below |
| C-2 | PASS | blocker | Still falsifiable, still scoped to the record alone, and the failing example is today's string verbatim. The clause text ("no directive addressed to the reader ... ends on its last factual sentence") is general, so naming the current sentence in the check adds a literal without narrowing the rubric to it. | `verify-migration.sh:205` ends `... 0 deletions. ... Paste this paragraph into the scope's patterns journal.` |
| C-3 | PASS | blocker | r0's hole is closed. The clause now constrains the instruction's own deixis ("it points **forward**, at the paragraph below it") and writes r0's exact minimum-diff failure in as the failing example, so the move-it-unchanged fix is now explicitly out. Stream, ordering, and failing-run absence all still pinned. | clause text; `verify-migration.sh:205-206`; combo case confirmed at `:1089-1127` |
| C-4 | PASS | blocker | Re-read fresh. Pair-every-removal is a real rubric; "assertion count over the record does not go down" is a new, checkable floor; both failing examples are constructible and `:1041` is where the clause says it is. | `tests/inbox-to-memory-smoke.sh:1041` (interior counts), `:1042` (paste sentence) |
| C-5 | PASS | blocker | `:1123` is now named alongside `:1046`, the general rule is stated over positive *and* negative needles, and each negative check gets its own falsification step. This also independently kills the vacuous-extraction escape from C-11 (a needle that can never match is exactly what C-5 forbids). | `tests/inbox-to-memory-smoke.sh:1046` (`grep -rlF "Paste this paragraph"`), `:1123` (`grep -F "Verified $v_combo against"`) |
| C-6 | PASS | blocker | Both r0 defects fixed, and I ran the fixed method rather than reasoning about it. The destructive `git checkout --` step is gone; copy-then-mutate works, and the required green baseline on the copy is real (I got it). The placement mutant is now twinned with the count mutant, which is what independently closes r0's missing-clause hole. The routing note names the write requirement and tells a read-only checker to return `blocked` rather than guess. | executed: copy green, count mutant exit 1 at `:1041`; `tests/inbox-to-memory-smoke.sh:8` (`BASH_SOURCE` repo-root resolution) confirmed |
| C-7 | PASS | blocker | Re-counted: `:193-199` is seven `echo` lines (scope, since, lint failures, links checked, renames, deletions, failures), so "seven" is now right. Both failing examples check out and both cited assertions exist. One wording tightening below, non-blocking. | `verify-migration.sh:193-199`; `tests/inbox-to-memory-smoke.sh:1033`, `:1160` |
| C-8 | PASS | blocker | Deterministic, runnable, correctly routed. Executed on the unmutated tree: 0, 0, 0. | `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh` |
| C-9 | PASS | blocker | The r0 contradiction with C-10 is gone — `inbox-to-memory/SKILL.md` is in the allowlist, so C-10's repair hatch is now legal. Command executed as written; it runs and reports correctly against a clean tree. | `python3 .agent-guild/scripts/check-diff-scope.py ... --ignore .agent-guild/` → `OK: 0 path(s) in scope`, exit 0 |
| C-10 | PASS | major | The false premise is corrected and I verified the corrected one is exhaustive: a repo-wide sweep of `*.md` finds exactly two sentences claiming a passing run ends by printing the paste-ready paragraph, and they are at the two cited lines. No third one is hiding. The no-unrelated-edits guard now covers both files. | `inbox-to-memory/references/migration.md:148`; `inbox-to-memory/SKILL.md:406`; grep sweep over `inbox-to-memory/`, `tests/`, `README.md` |
| C-11 | PASS | blocker | The clause that r0 said was missing, and it does its job. Traced below. Its two required assertions (line-isolated absence, whole-line instruction) each fail under the placement mutant, its "confirm load-bearing via the mutant" step is a real mutation test rather than an eyeball, and the `refute_output` warning heads off the negative assertion that can never fire. Two accuracy amendments below, neither blocking. | `tests/inbox-to-memory-smoke.sh:1123` (extraction idiom), `:49` (`require_line`, `grep -Fqx`), `:75` (`require_output`), `:39` (`refute_text`) |

**The r0 trace, re-run.** Walking the minimum-diff worker through C-1 to C-11:
split the printf, reword the instruction forward, update `:1041`'s count phrase,
repoint `:1046`'s needle, leave everything else. Under the r0 clause set that
worker passed everything and shipped a suite blind to a welded-on instruction.
Under this set it does not, and the property is caught twice over, which is why
I am comfortable calling this closed rather than merely addressed:

- C-11 structurally requires an assertion that *extracts* the record line from
  `$pass_out` and asserts the instruction's absence from that isolated line, plus
  a whole-line pin on the instruction. Both are read-only checkable. Weld the
  instruction back on and the isolated line now contains it (first fires) and no
  line equals the instruction exactly (second fires). The escapes I tried —
  extracting with a needle that never matches, writing the refutation over the
  whole capture, hiding it in a `grep && exit` that `set -e` neutralizes — are
  closed by C-5 (needles must be emittable), by C-11's own "absent from that
  isolated line, not from `pass_out`" wording, and by C-8 respectively.
- C-6's placement mutant catches the same blindness independently, by execution,
  and requires the failure to name a record assertion. Even if C-11's mutation
  half were skipped, C-6 alone fails a blind suite.

Two independent catches on the property the issue was filed about. That is the
r0 hole closed, not papered over.

**Nothing that passed in r0 broke.** C-1, C-2, C-4, C-7, and C-8 were each
re-derived from the tree rather than re-read against r0's notes. C-1's premise,
C-4's line citations, C-7's line range and count, and C-8's exit statuses were
all re-checked by hand or by running them. C-7's "six" → "seven" is now correct.

**Coverage.** All five acceptance criteria and the "Done when" line map to
clauses, and none is covered only in passing: criterion 1 → C-1; criterion 2 →
C-2, C-3, C-11; criterion 3 → C-4, C-5; criterion 4 → C-6; criterion 5 → C-8.
"Out of scope: the sweep's actual checks" → C-7, C-9, and the non-goals list. No
spec requirement is uncovered.

**Over-reach.** None that the spec forbids. C-11 asks for one or two new
assertions in `tests/inbox-to-memory-smoke.sh`, a file the spec already puts in
scope and already requires be updated in step; the spec's own "Why this shipped"
section is an argument for exactly this. It is above the spec's literal minimum
(which names only the zeroed-counts mutant) and that is the constitution's
prerogative where the risk is documented. C-9's allowlist growth to include
`SKILL.md` authorizes no new work — C-10 expects no doc change and permits only
a repair confined to a sentence a worker broke. Both are within the job's own
blast radius.

**Contradictions.** None found. C-3's ordering keeps both C-10 sentences true
(the run still ends with the paragraph). C-5's "repoint the stale needle" is not
C-4's "delete an assertion." C-11's strengthening of `:1042` is a move C-4
explicitly permits and its floor explicitly counts.

**Routing.** Correct. C-8 and C-9 are script invocations with real arguments and
route to `checker-deterministic`; the rest are rubrics marked
`checker-judgment`. No rubric masquerades as a script. C-6 now carries an
explicit writing-checker note with a `blocked` fallback. One routing amendment
on C-11 below.

**Protected content.** "None," still correctly argued, and the argument now
names C-11 alongside C-4 through C-6 as what protects assertion *strength* in
place of any literal. No dangling manifest reference to parse.

## Verified by execution

- The recipe at `constitution.md:34-47`, run verbatim from the repo root: exits
  0, prints `links checked: 1 (id fallback: 1)` and a record reading
  `... 0 lint failures, 1 links checked (1 by id fallback), 0 renames, 0
  deletions. ... Paste this paragraph into the scope's patterns journal.` That is
  the count-1 case the clause claims, observed, not derived. It writes only under
  its own `mktemp -d` and leaves the repo tree clean.
- C-6's method: `cp -R` of the repo to a temp dir, then
  `bash <copy>/tests/inbox-to-memory-smoke.sh` → exit 0 (green baseline on the
  copy, as C-6 requires before mutating). Count mutant applied to the copy's
  `verify-migration.sh:206` (arguments replaced with literal zeros) → exit 1 with
  `expected output not reported: 0 lint failures, 1 links checked (1 by id
  fallback), 0 renames, 0 deletions`. The failure names a record assertion, which
  is what C-6 demands.
- C-8's command: three suites, exits 0, 0, 0.
- C-9's command: runs, exit 0.

## Recommended amendments (non-blocking)

None of these lets a worker ship the filed defect with a green suite, which is
the bar for a blocker. All are cheap and worth folding in before dispatch.

- **C-11, routing.** Its check ends "confirm both are load-bearing via C-6's
  placement mutant," which is a write. C-6 has a routing note for that; C-11 has
  none, so a read-only checker or the courier hits the same wall r0 flagged on
  C-6 with no instruction on what to do. Give C-11 the same note, or state that
  its mutation half rides along with C-6's run and its structural half stands
  alone read-only. The structural half plus C-6 keep the property covered
  regardless, which is why this is an amendment and not a FAIL.
- **C-4 and C-7, `git diff --`.** Both checks read `git diff -- <path>`, which
  shows unstaged changes only. Workers here do not commit, but nothing stops one
  from running `git add`, and then both checks read an empty diff: C-4 has no
  removals to pair and C-7 has no hunks outside the record block. Two blocker
  clauses pass on nothing. `git diff HEAD -- <path>` fixes both and costs four
  characters.
- **C-11, helper inventory.** "the suite has `require_output`, file-based
  `refute_text`, and `refute_failure`" omits `require_line` at `:49`, which is an
  output-based `grep -Fqx` helper — precisely the tool C-11's own whole-line
  requirement asks for ("`grep -Fqx` or equivalent"). Name it, so a worker uses
  the existing helper instead of hand-rolling one against a clause note that
  reads as an exhaustive list. The `refute_output`-does-not-exist claim is true
  and worth keeping.
- **The recipe, stream separation.** It sends both streams to the terminal, so a
  checker running it verbatim cannot confirm C-3's "both go to stdout; neither
  moves to stderr." Add a redirected variant (`... --since "$SINCE" >out.txt
  2>err.txt`) or a line telling the checker to split the streams for C-3. C-3's
  failing example gestures at the redirect; the recipe should carry it.
- **Failing-run instruction absence, in the suite.** C-3 has the *checker*
  confirm a failing run prints neither line, but no clause has the *suite* assert
  it — `:1123` pins record absence only. r0 suggested pinning both; the revision
  kept the checker-level half. Worth making that a recorded decision rather than
  a silent drop: after this ships, a regression that printed the instruction on a
  failing run goes uncaught.
- **The record as a single physical line.** C-11's mechanism ("extract the record
  line") presumes the record stays one line, as it is today, while C-2 says
  "paragraph." A worker who hard-wraps the record while reworking the printf
  leaves C-11's prescribed assertion shape undefined. One sentence in C-2 or C-11
  pinning it closes that.
- **C-7 wording nit.** "every hunk lands in the record `printf` block or its
  comment" can be read as the single printf statement at `:205-206`, which C-3's
  mandated new instruction line is not. Say "the record block guarded by
  `failures -eq 0`, including the instruction line C-3 requires."
- **C-3 citation nit.** The combo case is `:1089-1127`, not `:1096-1127`;
  `:1096` is a `git rm` mid-setup. The record-absence check the clause points at
  is at `:1123` and is unambiguous either way.
