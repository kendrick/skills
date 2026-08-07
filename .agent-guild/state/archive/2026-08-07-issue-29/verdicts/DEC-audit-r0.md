---
task: DEC-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: PASS
checked_at: 2026-08-07T17:26:55Z
---

Audit of the decomposition — one task, `.agent-guild/state/tasks/T-001.md` —
against `.agent-guild/state/spec.md` (`kendrick/skills#29`) and the amended
`.agent-guild/state/constitution.md`. Round 0; no prior `DEC-audit-r*.md`
exists.

`CON-audit-r0.md` and `CON-audit-r1.md` were read for context on what the clause
set defends against, then set aside as evidence. Every line number, string, and
behavioral claim below was re-derived from the working tree at `5f00eea` by
running things here. Tree clean before and after; the only writes were under
`mktemp -d` and this file.

Both script invocations in `check_method` were executed as written, and so was
the constitution's passing-run recipe, including its split-stream form.

## Per-item results

| item | result | severity | description | evidence |
| ---- | ------ | -------- | ----------- | -------- |
| Coverage | PASS | blocker | All five acceptance criteria, the "Done when" line, and both "Out of scope" bullets map to cited clauses. Criterion 1 → C-1; criterion 2 → C-2, C-3, C-11; criterion 3 → C-4, C-5; criterion 4 → C-6; criterion 5 → C-8; out-of-scope → C-7, C-9. "Start here" and "Setup" both survive into the excerpt. Nothing in the spec maps to no task and no clause. | `spec.md:45-59`; `T-001.md:5`, `:44-100` |
| Clause citation honesty | PASS | blocker | All eleven cited, and none is decorative. With a single task, a clause left out of `clauses` is a clause nothing checks, so the burden runs the other way. The three that look like passengers are not: C-7 and C-9 fence a diff this worker is actively rewriting inside a script full of adjacent counter logic, and C-10 governs two doc sentences that C-3's ordering is *expected* to keep true — a conditional repair is still a real constraint, and the clause is where the worker learns the sentences exist. | `constitution.md:102-128`; `verify-migration.sh:193-209` |
| `check_method` completeness | PASS | blocker | Every one of the eleven clauses appears with a real check, and each entry is faithful to the clause it names — observed-vs-derived preserved on C-1, split-stream and forward-deixis on C-3, `git diff HEAD` (not bare `git diff`) on C-4 and C-7, both falsifications on C-5, copy-then-mutate with the never-`git checkout --` warning on C-6, three assertion shapes plus the mutation half on C-11. No entry is broader or narrower than its clause. | `T-001.md:9-35` against `constitution.md:59-137` |
| C-8 invocation runnable | PASS | blocker | Executed verbatim from the repo root. Three suites, exits 0, 0, 0. | `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh` → 0, 0, 0 |
| C-9 invocation runnable | PASS | blocker | Executed verbatim: exit 0, `OK: 0 path(s) in scope`. Also read the script: its path set is `git status --porcelain --untracked-files=all` unioned with `git diff --name-only`, so unlike the bare-`git diff` hazard `CON-audit-r1` fixed in C-4 and C-7, a worker who ran `git add` cannot hide from this one, and a brand-new file cannot either. | `check-diff-scope.py:86-104`, `:96` |
| The recipe the judgment clauses depend on | PASS | blocker | C-1, C-2, C-3, and C-10 all route through the constitution's recipe, so it has to work for four of the eleven entries to be executable. Run verbatim in split-stream form: exit 0, the count-1 case reproduced, and **stderr is 0 bytes** — so C-3's "nothing in `$S.err`" is satisfiable on today's tree rather than a demand no implementation could meet. Record is the last line of stdout. | recipe at `constitution.md:34-51`; output under Verified by execution |
| Routing, executor | PASS | major | `worker-craft` / `opus` is right by the work, not by default. The deliverable is a sentence a human pastes into a journal and a second sentence that has to read correctly from a new position — taste, judged on how it reads. The other half (three assertions in prescribed shapes) is subtle correctness work that no lower tier should be handed either, given #16's "implementation right, test vacuous" history. The two halves cannot be split (see `deps`), so the tier goes to the harder half. | `.agent-guild/CLAUDE.md` routing table; `T-001.md:6-7` |
| Routing, checker | PASS | blocker | `checker-judgment` / `opus` is correct and, importantly, *capable*. C-6 and C-11's mutation halves require writing a scratch copy; `checker-judgment` carries `Read, Bash, Write, Grep, Glob`, and `orchestrator-write-guard` no-ops inside subagents, so neither the `cp -R` nor the mutation is gated. A `checker-deterministic` here would have to return `blocked` on nine of eleven clauses. | plugin `agents/checker-judgment.md:5`; `hooks/orchestrator-write-guard.py:36-38`; `constitution.md:100`, `:137` |
| Spec excerpt, factual accuracy | PASS | blocker | Read cold as the worker, then every claim about the tree checked. All seven hold: record `printf` at `:205-206`, inside the `failures -eq 0` block opened at `:204`; interior counts at `:1041`; paste sentence at `:1042`; leak needle at `:1046`; failing-run absence needle at `:1123`; seven summary `echo`s at `:193-199`; two assertions reading that summary as machine output at `:1033` and `:1160`. The excerpt's premise that `lint failures`, `renames`, and `deletions` only ever print at zero was re-derived, not inherited: every nonzero path calls `fail`. Nothing in the excerpt is wrong about the tree. | `verify-migration.sh:113-119`, `:180-188`, `:193-209`; `tests/inbox-to-memory-smoke.sh:1033`, `:1041`, `:1042`, `:1046`, `:1123`, `:1160` |
| Spec excerpt, self-sufficiency | PASS | major | Workable cold. It states both defects, quotes the current output verbatim, settles the placement question the user ruled on, names the files and lines, and carries the `yq` prerequisite. What it leaves to the worker is craft, not guesswork: the instruction's new wording and the mechanism for count agreement, both bounded by C-3 and C-1. Three cheap tightenings below, none of which forces a worker to invent anything the constitution doesn't already supply. | `T-001.md:44-100` |
| `deps` | PASS | blocker | `[]`, trivially acyclic, no dangling reference. The one-task cut is judged separately below. | `T-001.md:39` |

## The one-task cut

The stated reasoning holds, and it holds for a stronger reason than the one
given.

The given reason is C-8: split the script edit from its assertions and the tree
is red in between. That is true but slightly soft — C-8 is checked on the final
tree, so a two-task chain could in principle cite C-8 only on the second task.
The harder constraint is identity of literals. The assertions C-11 requires pin
strings the worker *invents* while doing the script half: the instruction as a
whole line (`require_line`, `grep -Fqx`, so an exact match), the instruction's
absence from the extracted record line, and its absence from the combo run.
A second task would have to receive that exact text from the first, which means
the decomposition would be shipping the deliverable's content through the task
file. And C-6's two mutants and C-11's load-bearing half cannot run at all until
both halves exist, so a first task would have no way to verify itself and a
second would inherit blame for the first's wording.

The only separable-looking piece is C-10's doc repair, and it is conditional
work with an expected outcome of no change. A task that may correctly produce an
empty diff is not a task.

So: one dispatch, genuinely. No better cut exists, and the alternative buys
nothing while costing a hand-off of literal strings through orchestration state.

## Verified by execution

- C-8's command: `tests/inbox-to-memory-smoke.sh` 0, `tests/file-issue-smoke.sh`
  0, `tests/handoff-smoke.sh` 0.
- C-9's command, verbatim including `--ignore .agent-guild/`: exit 0,
  `OK: 0 path(s) in scope`.
- The constitution's recipe, split-stream form, run from the repo root: exit 0,
  stderr 0 bytes, stdout ending on

  ```
  Verified <scope> against <ref> on 2026-08-07: 0 lint failures, 1 links checked (1 by id fallback), 0 renames, 0 deletions. The link count covers every distinct wiki-link target the scope carried at that ref, resolved against the tree as it stands now. Paste this paragraph into the scope's patterns journal.
  ```

  That is the count-1 case and the instruction-inside-the-record defect, both
  observed. The record is one physical line and the last line of output.
- `git status --porcelain` empty before and after everything above.

## Recommended amendments (non-blocking)

None of these lets the worker ship the filed defect past a green check, which is
the bar for a blocker. The first two are worth folding into the excerpt before
dispatch; they cost a sentence each and each defuses a plausible wrongful FAIL
or miss.

- **The hoisted-helper trap, C-7 versus the count fix.** C-7's *text* forbids
  changing a counter's value; C-7's *check* is stricter — every hunk must land
  inside the `failures -eq 0` block or its comment. A worker who makes the count
  agree by computing a plural-noun variable next to the counters has violated
  nothing in C-7's text and everything in C-7's check, and eats a blocker FAIL
  for a correct implementation placed six lines too high. One line in the
  excerpt closes it: any helper the count agreement needs lives inside the
  `failures -eq 0` block, because C-7 confines every hunk there.
- **"Where" reads as the complete edit list.** The excerpt names four existing
  assertion sites (`:1041`, `:1042`, `:1046`, `:1123`) under a heading that
  scans as the inventory of what changes. C-11 requires assertions that do not
  exist yet, including a third one in the combo case. "Read C-11 before you
  touch the suite" points at it, and "Done when ... fails against a
  welded-instruction mutant" implies it, but neither says in the excerpt's own
  voice that new assertions are part of the deliverable. Add the words.
- **C-10's two sentences are invisible from the excerpt.** `migration.md:148`
  and `SKILL.md:406` appear nowhere in the task file; a worker meets them only
  by reading C-10. That is legitimate — the worker reads the whole constitution
  — but a one-clause pointer in "Out of scope" or "Done when" would stop a
  reword from silently falsifying a doc the worker never opened.
- **C-9's `--ignore .agent-guild/` is inert.** `check-diff-scope.py` matches
  `--ignore` by exact string equality (`:110`, `if path in ignored`); only the
  `allowed` arguments support the trailing-slash prefix form (`:146-147`). It is
  harmless here — `.agent-guild/state/*` and `__pycache__/` are both gitignored,
  so nothing under `.agent-guild/` reaches the check — but it reads as
  protection that is not there. Drop it, or pass `.agent-guild/` as an allowed
  dir if the protection is actually wanted.
- **C-2's entry presumes a run it doesn't commission.** The clause opens "run
  C-1's recipe, isolate the record paragraph"; the task's entry says "isolate
  the record paragraph from stdout," which implies a run without asking for one.
  Every other entry that needs the recipe names it. Four words.
- **Inherited clause-number collision.** C-4's clause text says "Every C-10
  assertion in `tests/inbox-to-memory-smoke.sh`" — that `C-10` is job #16's
  numbering, and this job has its own C-10 about docs. The task's `check_method`
  wisely drops the phrase, so the worker is safe; the checker reads clause text
  directly and is not. Worth a parenthetical in the constitution on the next
  edit, not a re-audit.
