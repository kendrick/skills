---
task: CON-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: FAIL
checked_at: 2026-08-07T15:51:48Z
---

Audit of `.agent-guild/state/constitution.md` against `.agent-guild/state/spec.md`
(`kendrick/skills#29`). Round 0; no prior `CON-audit-r*` exists in
`state/verdicts/`. Every line number, string, and behavioral claim below was
re-derived from the working tree at `5f00eea`, not taken from the clause text.
Baseline confirmed before judging: all three suites exit 0 today and `yq` is on
PATH at `/opt/homebrew/bin/yq`.

The two settled inputs (instruction before the record; the summary block's
`links checked: N (id fallback: M)` out of scope) are treated as fixed and are
not counted against any clause.

## Per-clause results

| clause | result | severity | description | evidence |
| ------ | ------ | -------- | ----------- | -------- |
| C-1 | PASS | blocker | Premise verified: `lint_failures`, `renames`, and `deletions` each call `fail`, so a nonzero value always suppresses the record — the record really can only print them at zero, and `links_checked` really is the only varying counter. Derivation at 0/1/2 catches the cheap wrong fix (hard-coded singular). One amendment needed: the "observed count-1 output from a real passing run" half names no way to produce that run. See Diagnosis item 6. | `verify-migration.sh:115,119,181,185` (every `fail` call); record gate at `:204`; printf at `:205-206` |
| C-2 | PASS | blocker | Falsifiable and correctly scoped to the record paragraph alone. Failing example is the string shipping today, verbatim. Same run-the-passing-case amendment as C-1. | `verify-migration.sh:205` ends `... 0 deletions. ... Paste this paragraph into the scope's patterns journal.` |
| C-3 | FAIL | blocker | Pins position and stream but not the instruction's own correctness. The minimum-diff fix — move the existing sentence above the record and change nothing else — satisfies C-1 through C-10 as written and ships `Paste this paragraph` printed *above* the paragraph it points at. Nothing in the constitution forbids that. | Diagnosis item 1 |
| C-4 | PASS | blocker | Sound as far as it goes: pair-every-removal is a real rubric, and both failing examples are constructible. Necessary but not sufficient — it constrains what may not shrink, never what must be added. Combined with item 2, an all-PASS suite can be blind to the defect this job fixes. | `tests/inbox-to-memory-smoke.sh:1041` (interior counts), `:1042` (paste sentence) both confirmed at the cited lines |
| C-5 | FAIL | blocker | Text says "every literal the suite searches for in the record's vicinity," but the check enumerates only `require_output` needles and the leak grep. It misses `:1123`, the failing-run absence check, which is a stale-needle hazard of exactly the shape C-5 exists to catch. | `tests/inbox-to-memory-smoke.sh:1123` greps `"Verified $v_combo against"`; leak needle at `:1046` confirmed |
| C-6 | FAIL | blocker | Two defects. The check's revert step destroys the worker's deliverable, and the clause covers only the counts half of the job. | Diagnosis items 2 and 3 |
| C-7 | PASS | blocker | Correctly scoped and falsifiable; the cited line range and both failing examples check out. Nit: `:193-199` is seven `echo` lines, not six. | `verify-migration.sh:193-199` (scope, since, lint failures, links checked, renames, deletions, failures); `tests/inbox-to-memory-smoke.sh:1033` and `:1160` both read the summary block as machine output, as the clause says |
| C-8 | PASS | blocker | Deterministic, runnable, correctly routed to a script invocation. Executed here: all three exit 0 on the unmutated tree, so the clause is falsifiable against a real green baseline rather than a hoped-for one. | `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh` → 0, 0, 0 |
| C-9 | FAIL | blocker | The check itself is correct and runnable, but the allowlist contradicts C-10 once C-10 is corrected: `inbox-to-memory/SKILL.md` also describes the record and is not in the allowed set. As written, a doc left false is the only legal outcome. | `check-diff-scope.py --help` confirms the `ALLOWED... --ignore` form; `inbox-to-memory/SKILL.md:406` |
| C-10 | FAIL | major | The clause's central factual premise is false. `migration.md:148` is not "the one such sentence today" — `SKILL.md:406` makes the same claim, and the check bounds the checker to `migration.md:146-148`, so the second sentence is never looked at. | `inbox-to-memory/SKILL.md:406`: "A passing run ends by printing one paragraph carrying the scope, the date, and the run's counts, for the user to paste into the scope's patterns journal." |
| (missing) | FAIL | blocker | No clause requires the suite to pin the property this job exists to establish. C-6 mutation-tests the counts; nothing mutation-tests placement. | Diagnosis item 2 |

Coverage against the spec: all five acceptance-criteria checkboxes and the
"Done when" line map to clauses. Criterion 1 → C-1. Criterion 2 → C-2 and C-3.
Criterion 3 → C-4 and C-5. Criterion 4 → C-6. Criterion 5 → C-8. "Done when"
→ C-1, C-2, C-6. No criterion is uncovered; the failures below are about
strength, not coverage.

Over-reach: none found. C-10's conditional doc obligation reads past the spec's
"only the emitted prose and the assertions pinning it change," but it fires only
when a worker's wording breaks a doc claim, which is a repair to the job's own
blast radius rather than new work. C-9's inclusion of `migration.md` is the same
minimal expansion and is fine.

Routing: correct throughout. C-8 and C-9 are script invocations with real
arguments and route to `checker-deterministic`; the rest are rubrics marked
`checker-judgment`. No rubric masquerades as a script. One caveat on C-6's
routing is in Diagnosis item 3.

Protected content: the "None" declaration is right and well-argued. The two
literals a manifest would guard are the job's deliverable, and pinning them
again is how #16 shipped the defect. No dangling manifest reference.

## Diagnosis

- **C-3** (blocker): the instruction's own wording is unconstrained, so the
  cheapest passing fix ships incoherent output.
  With the settled ordering, the sentence prints *before* the paragraph it
  refers to. Keep today's wording — `Paste this paragraph into the scope's
  patterns journal.` — and "this paragraph" now points backward at the summary
  block or at nothing. C-2 constrains only the record; C-3 constrains only
  position and stream; C-4 positively rewards leaving `:1042` untouched, since
  the string still appears in `pass_out` when both lines go to stdout. So the
  minimum-diff worker changes the printf split, changes nothing in the
  assertion, and passes every clause with wrong prose.
  Fix: extend C-3 (or add a clause) requiring the instruction line to read
  correctly from its new position — its deixis points forward at the paragraph
  below it. Failing example to write in: a run printing `Paste this paragraph
  into the scope's patterns journal.` on the line above the record.
  evidence: `verify-migration.sh:205`; `tests/inbox-to-memory-smoke.sh:1042`

- **(missing clause)** (blocker): nothing requires the suite to pin "the record
  carries no instruction." This is the #16 hole, still open.
  Trace the likely worker path through C-4, C-5, and C-6 together. The worker
  splits the printf, updates `:1041`'s interior-count phrase, repoints `:1046`'s
  leak needle at a record fragment, and leaves or lightly edits `:1042`. C-4 is
  satisfied (no removal without replacement, count did not drop). C-5 is
  satisfied (every needle is emittable). C-6 is satisfied (the zeroed-counts
  mutant still fails at the interior-count assertion, because the mutation
  touches only the record's printf arguments while the summary block keeps
  printing real counts — I confirmed that separation holds). And yet: put the
  instruction back inside the record paragraph and the suite still passes. Every
  surviving assertion is a substring search over the whole of `pass_out`, which
  cannot tell "instruction on its own line above the record" from "instruction
  welded onto the record's tail." The suite would not fail on the exact defect
  #29 was filed about. C-4, C-5, and C-6 gesture at the vacuity problem; on this
  property they do not close it.
  Fix: add a clause requiring assertions that isolate the record line from
  `$pass_out` (the suite's own `grep -F "Verified $v_pass against"` idiom at
  `:1123` is the model) and then assert the instruction sentence is *absent*
  from that isolated line, plus a `grep -Fqx` that the instruction stands on its
  own line, plus absence of the instruction on the failing combo run alongside
  the existing record-absence check at `:1123`. Note the suite has `refute_text`
  (file-based) and `refute_failure` but no `refute_output`; the clause should
  say the negative assertion is over the isolated record line, not over
  `pass_out` as a whole, or a worker will write a refutation that can never fire.
  evidence: `tests/inbox-to-memory-smoke.sh:1037,1041,1042,1046,1123`

- **C-6** (blocker): the mutation covers counts only; it needs a placement twin.
  C-6 proves the suite still discriminates a hard-coded *count*. Nothing proves
  it discriminates a mis-placed *instruction*, which is the other half of the
  spec's acceptance criteria and the half this job actually changes prose for.
  Fix: add a second mutant to C-6 (or to the clause added above): move the
  instruction back inside the record `printf`, run the suite, require nonzero
  exit naming a record assertion. Under the constitution as it stands today that
  mutant passes, which is the proof the clause set is incomplete.
  evidence: clause text at C-6; `verify-migration.sh:205-206`

- **C-6** (blocker): the check's revert step deletes the worker's fix.
  The check says "then `git checkout -- inbox-to-memory/scripts/verify-migration.sh`
  and confirm the suite is green again." Workers in this guild do not commit —
  the orchestrator commits at ship time, and C-9's own check reads
  `git status --porcelain` union `git diff --name-only`, which only sees an
  uncommitted tree. So at check time the worker's edit is unstaged, and
  `git checkout -- <path>` restores from the index, which still holds the HEAD
  version. The deliverable is destroyed. Worse, the failure mode is silent and
  self-incriminating: the checker then runs the suite against the original
  script plus the worker's new assertions, sees red, and reports the worker
  failed C-6 — a FAIL caused entirely by the check.
  I reproduced this in a throwaway repo: commit `original`, write `worker fix`
  unstaged, write `mutant`, `git checkout -- f.txt` → file reads `original`.
  Fix: replace the revert with a method that cannot touch the tree the worker
  built. Either mutate a copy (`cp -R` the repo to a temp dir and run
  `bash <copy>/tests/inbox-to-memory-smoke.sh`; the suite resolves its own
  repo root from `BASH_SOURCE` at `:8` and `cd`s there, so a copy runs against
  itself), or back the single file up by hand (`cp file file.bak` … `mv
  file.bak file`) and require the checker to verify byte-identity after
  restoring. The copy route is the one #16's T-003 checker used and is the safer
  default. This also resolves the routing question below.
  evidence: reproduced locally; `tests/inbox-to-memory-smoke.sh:8`;
  `.agent-guild/state/archive/2026-08-06/tasks/T-004.md:48` (the orchestrator
  commits, not the worker); `.agent-guild/state/archive/2026-08-06/tasks/T-003.md:89`
  ("in a copy of the repo")

- **C-6** (blocker, routing): a mutation check makes the checker an editor.
  The org chart says checkers never edit, and on a Codex host a checker is
  read-only and physically cannot perform C-6 as written; the courier's second
  opinion certainly cannot. As stated, C-6 is unexecutable by half the agents
  that may be asked to run it, which produces `blocked` verdicts rather than
  judgments. Mutating a scratch copy outside the repo keeps the deliverable
  untouched and makes the clause portable. If a copy is still considered an
  edit under the host's constraints, say so in the clause and route C-6
  explicitly to a writing in-family `checker-judgment`, so the routing is a
  decision rather than an accident.
  evidence: `.agent-guild/CLAUDE.md` org chart and the Codex read-only checker note

- **C-5** (blocker): the check's enumeration is narrower than the clause's text.
  The text says "every literal the suite searches for in the record's vicinity."
  The check lists `require_output` needles and the leak check's `grep -rlF`
  needle — and stops. It misses `:1123`, which greps the *failing* run's output
  for `"Verified $v_combo against"` to prove no record printed. If a worker
  changes the record's opening (say to `Migration verified: …`), that needle goes
  stale, the check passes vacuously, and a failing run that printed a record
  would sail through. That is the identical hazard C-5 names for `:1046`, one
  page down in the same file.
  Fix: name `:1123` in C-5's check alongside `:1046`, and state the general rule
  — every needle aimed at the record, positive or negative, must be a fragment
  the changed script can emit. Add the falsification step for the negative case:
  confirm the `:1123` check would still fire by feeding it output that does
  contain a record.
  evidence: `tests/inbox-to-memory-smoke.sh:1123`

- **C-10 and C-9** (major, contradiction): `migration.md:148` is not the only
  doc sentence describing the record.
  `inbox-to-memory/SKILL.md:406` makes the same claim: "A passing run ends by
  printing one paragraph carrying the scope, the date, and the run's counts, for
  the user to paste into the scope's patterns journal." C-10 asserts
  `migration.md:148` "is the one such sentence today," which is false, and its
  check bounds the checker to `migration.md:146-148`, so nobody ever reads the
  second one. Under the settled ordering both sentences most likely stay true —
  the record is still last — but the clause's escape hatch ("if a worker's
  wording breaks the sentence, the sentence gets fixed") is unavailable for
  `SKILL.md`, because C-9's allowlist does not include it. So if a worker does
  break `SKILL.md:406`, the constitution's only legal outcome is a false doc.
  Fix, both clauses together: extend C-10 to name `inbox-to-memory/SKILL.md:406`
  alongside `migration.md:148` and widen its check to read both against a real
  passing run, and add `inbox-to-memory/SKILL.md` to C-9's allowlist argument.
  Keep C-10's "no unrelated doc edits" guard on both files.
  evidence: `inbox-to-memory/SKILL.md:406`; `inbox-to-memory/references/migration.md:148`;
  C-9's check command

- **C-1, C-2, C-3** (amend while revising): three blocker clauses say "run the
  passing case" without naming a way to produce one.
  A passing run needs a migrated, committed scope with a resolvable wiki-link
  and `yq` on PATH. The suite builds one at `tests/inbox-to-memory-smoke.sh:1013-1026`
  and then swallows the output into `$pass_out`, printing it only on failure —
  so a checker following these clauses literally has no route to the stdout it
  is told to inspect. The predictable degradation is that the checker reads the
  `printf` and calls the derivation an observation, which is the check-layer
  version of the vacuity failure this constitution is built to prevent.
  Fix: name the route once, in C-1, and have C-2 and C-3 cite it. Either point at
  `tests/inbox-to-memory-smoke.sh:1013-1026` as the recipe to replay in a scratch
  directory, or require the worker to leave a runnable reproduction under
  `.agent-guild/state/` for the checker. Also worth stating in C-1 whether the
  checker must construct the 0-link and 2-link scopes or may derive those two
  from the `printf` — the clause currently reads as if all three are observed,
  and only count 1 exists anywhere in the tree.
  evidence: `tests/inbox-to-memory-smoke.sh:1013-1026`, `:1026` (`pass_out` capture)

- **C-7** (nit): "the six-line summary block at `verify-migration.sh:193-199`."
  That range is seven `echo` lines: scope, since, lint failures, links checked,
  renames, deletions, failures. The range is right and the clause is unambiguous
  in effect, but a checker counting lines against the text will hesitate. Say
  seven, or drop the count.
  evidence: `verify-migration.sh:193-199`
