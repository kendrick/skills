# Brief: T-001

**Task:** T-001 — Fix the migration record's prose and strengthen the assertions that pin it

## Constitution clauses

### C-1: The link counter agrees with its noun

- **text**: In the record paragraph, the link count and the noun after it agree at every count the paragraph can print: `1 link checked` at one, `0 links checked` at zero, `2 links checked` at two and above. The other counters in the paragraph (`lint failures`, `renames`, `deletions`) are only ever printed at zero, because any nonzero value calls `fail` and a failing run prints no record; they are not required to change.
- **check**: checker-judgment: run the recipe above and read the count-1 case off real stdout — that one is observed, not derived. Then read the record `printf` in `inbox-to-memory/scripts/verify-migration.sh` and derive its exact output at `links_checked` of 0 and 2; deriving those two is sufficient, since no scope in the tree produces them. All three must agree.
- **severity**: blocker
- **failing example**: A run that checked one link prints `1 links checked (1 by id fallback)`. Also failing: a fix that hard-codes the singular, so a run checking two links prints `2 link checked`.

### C-2: The pasteable record carries no instruction to paste it

- **text**: The record paragraph — the text a reader is told to paste — contains no directive addressed to the reader. It ends on its last factual sentence about the run. Paste it into a patterns journal and the journal entry contains the record and nothing else.
- **check**: checker-judgment: run C-1's recipe, isolate the record paragraph from the rest of stdout, and confirm it contains no imperative sentence directed at the reader; the sentence `Paste this paragraph into the scope's patterns journal.` must not appear inside it. The record stays a single physical line, as it is today — C-11's assertions extract it as one, so hard-wrapping it leaves their prescribed shape undefined.
- **severity**: blocker
- **failing example**: The paragraph still ends `... 0 deletions. The link count covers every distinct wiki-link target the scope carried at that ref, resolved against the tree as it stands now. Paste this paragraph into the scope's patterns journal.`

### C-3: The instruction is printed before the record, on its own line, and reads correctly from there

- **text**: A passing run prints the paste instruction on its own line, then a blank line, then the record paragraph — so the record is the last thing the run prints and the instruction is not adjacent text a careless selection sweeps up. Both go to stdout; neither moves to stderr. The instruction's own wording has to work from its new position: whatever it points at, it points **forward**, at the paragraph below it. A failing run still prints neither line.
- **check**: checker-judgment: run C-1's recipe in its split-stream form and confirm both lines land in `$S.out` with nothing in `$S.err`, in the order instruction, blank line, record, end of output; then read the instruction as a reader would, with only the lines above it visible, and confirm its reference resolves to the paragraph that follows. Separately confirm both lines are absent from a failing run (the suite's combo case at `tests/inbox-to-memory-smoke.sh:1089-1127` is the model).
- **severity**: blocker
- **failing example**: Today's sentence is moved above the record unchanged, so the run prints `Paste this paragraph into the scope's patterns journal.` on the line above the paragraph — "this paragraph" now points backward at the summary block or at nothing. Also failing: the instruction goes to stderr, so `verify-migration.sh scope --since ref > out.txt` drops it and the suite's `$( )` capture stops seeing it.

### C-4: The pinning assertions are updated in step, never deleted or loosened

- **text**: Every assertion in `tests/inbox-to-memory-smoke.sh` that pinned an old string pins an equally specific new one. (The suite labels the section "C-10" — that is job #16's clause numbering baked into a comment, unrelated to *this* constitution's C-10 about docs.) No assertion is deleted, commented out, or weakened to a shorter substring that a wrong record would also satisfy. Assertion count over the record does not go down.
- **check**: checker-judgment: read `git diff HEAD -- tests/inbox-to-memory-smoke.sh` (`HEAD`, not a bare `git diff` — a worker who ran `git add` would otherwise leave this clause reading an empty diff and passing on nothing) and pair every removed assertion with its replacement; a removal with no replacement, or a replacement matching a strictly larger set of outputs than the string it replaced, fails.
- **severity**: blocker
- **failing example**: `require_output "$pass_out" "0 lint failures, 1 links checked (1 by id fallback), 0 renames, 0 deletions"` is replaced by `require_output "$pass_out" "Verified"`, which any record satisfies. Also failing: the interior-count assertion at `:1041` is dropped because the new wording made it awkward.

### C-5: No assertion is left hunting for a string the script cannot emit

- **text**: Every needle the suite aims at the record — positive or negative — is a fragment the changed script can actually emit. A negative assertion whose needle went stale is worse than a missing one: it passes forever and reads later as coverage. Two needles are known to be at risk, and both must be re-derived rather than assumed: the record-leak check at `:1046`, which greps the scope for `Paste this paragraph`, and the failing-run absence check at `:1123`, which greps a failing run's output for `Verified $v_combo against` to prove no record printed.
- **check**: checker-judgment: for every needle the suite aims at the record, confirm the changed `verify-migration.sh` can emit it. Then falsify each of the two negative checks: confirm `:1046` still fires by planting a file containing the record's text under the scope, and confirm `:1123` still fires by feeding it output that does contain a record.
- **severity**: blocker
- **failing example**: The script now prints `Paste the paragraph below into the scope's patterns journal.` while `:1046` still greps for `Paste this paragraph` — the check passes on every run, including one where the whole record was written into `patterns-journal/`. Also failing: the record's opening changes to `Migration verified: ...` while `:1123` still greps for `Verified $v_combo against`, so a failing run that wrongly printed a record would sail through.

### C-6: The suite still discriminates, on both counts and placement

- **text**: The assertions detect both defects this job fixes. **Count mutant**: hard-coding the record's count arguments to zeros, on a run that really checked one link, makes the suite fail. **Placement mutant**: moving the instruction sentence back inside the record `printf`, so it ships welded to the paragraph's tail, also makes the suite fail. Both must fail on a record assertion, not incidentally somewhere else.
- **check**: checker-judgment: copy the repo to a temp directory outside it, confirm `bash <copy>/tests/inbox-to-memory-smoke.sh` is green there first (a red baseline makes every later result meaningless), then apply each mutant to the copy in turn and require nonzero exit with the failure naming a record assertion. The suite resolves its own repo root from `BASH_SOURCE` at `:8` and `cd`s there, so a copy runs against itself. **Never mutate the repo itself and never revert with `git checkout -- <path>`**: workers here do not commit, so their fix is unstaged, and restoring from the index would silently destroy the deliverable and then blame the worker for the resulting red suite.
- **severity**: blocker
- **failing example**: The placement mutant passes, because every surviving assertion is a substring search over the whole of `pass_out` and cannot tell the two layouts apart. Also failing: the count mutant passes because the assertions only pin the record's opening and closing and never its interior counts.
- **routing note**: this check writes — to a scratch copy, never to the repo — so it needs a checker that can write. Route it to a writing in-family `checker-judgment`. A read-only checker or the courier should return `blocked` on C-6 rather than guessing, and say so.

### C-7: The sweep's behavior is untouched

- **text**: Only emitted prose and the assertions pinning it change. Link resolution, the id fallback, the lint invocation and how its exit status is read, rename and deletion handling, every counter's value, the exit status, the record's gate on `failures -eq 0`, and the seven summary `echo` lines at `verify-migration.sh:193-199` all ship unchanged. The script still writes nothing and leaves the scope byte-identical.
- **check**: checker-judgment: read `git diff HEAD -- inbox-to-memory/scripts/verify-migration.sh` (`HEAD`, so a staged change cannot hide from this clause) and confirm every hunk lands inside the record block guarded by `failures -eq 0` — including the instruction line C-3 requires, which is new output that block did not previously have — or in its comment. Any hunk touching the sweeps, the counters, the summary `echo`s, or the exit path fails. One narrow exception, so a correct fix is not failed on placement: a variable computed **solely** to word the record — a plural noun, say — may sit just above the block if it is read nowhere else. Confirm that by reading its only use; a helper the sweeps also consume is not this.
- **severity**: blocker
- **failing example**: The worker makes the counter agree by changing how `links_checked` is incremented. Also failing: `echo "links checked: $links_checked (id fallback: $links_fallback)"` is reworded to agree, breaking the assertions at `:1033` and `:1160` that read it as machine output.

### C-8: All three suites exit 0

- **text**: `tests/inbox-to-memory-smoke.sh`, `tests/file-issue-smoke.sh`, and `tests/handoff-smoke.sh` each exit 0 on an unmutated tree.
- **check**: `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh`
- **severity**: blocker
- **failing example**: The record wording changes but `:1042`'s assertion does not, so the inbox-to-memory suite exits 1 on a string that no longer prints.

### C-9: The diff stays inside the job's paths

- **text**: The change touches `inbox-to-memory/scripts/verify-migration.sh`, `tests/inbox-to-memory-smoke.sh`, and — only where C-10 requires it — `inbox-to-memory/references/migration.md` and `inbox-to-memory/SKILL.md`. Nothing else.
- **check**: `python3 .agent-guild/scripts/check-diff-scope.py inbox-to-memory/scripts/verify-migration.sh tests/inbox-to-memory-smoke.sh inbox-to-memory/references/migration.md inbox-to-memory/SKILL.md` — no `--ignore` for guild state: `check-diff-scope.py:111` already hardcodes `.agent-guild/state/` as in scope, and `--ignore` matches by exact string equality anyway, so `--ignore .agent-guild/` would be inert. Better absent than advertising protection it does not provide.
- **severity**: blocker
- **failing example**: `lint-scope.sh` is edited in passing to make an unrelated message read better.

### C-10: The docs still describe what the script prints

- **text**: Prose in the repo describing the record stays true of the changed output. There are two such sentences, and both are in scope: `inbox-to-memory/references/migration.md:148` and `inbox-to-memory/SKILL.md:406`, which both say a passing run *ends* by printing the paragraph, ready to paste. C-3's ordering should keep both true, so the expected outcome is no doc change — but if a worker's wording breaks either sentence, that sentence gets fixed rather than left wrong. No other doc edits, and no unrelated improvements to the sections they sit in.
- **check**: checker-judgment: read both sentences against a real passing run's stdout from C-1's recipe and confirm each claim in each still holds; if either file was edited, confirm the edit was forced by a broken claim and is confined to the sentence that broke.
- **severity**: major
- **failing example**: The instruction is printed after the record, so the run no longer ends with the paragraph, and both sentences still say it does. Also failing: the worker rewrites `migration.md`'s whole Verification section while it is in there.

### C-11: The suite pins the separation, not just the strings

- **text**: The suite asserts the property this job establishes — that the instruction is *outside* the record — in a way that can actually fail. Substring searches over the whole of `$pass_out` cannot do this: `require_output` greps the entire capture, so it matches identically whether the instruction stands on its own line or is welded to the record's tail. Three assertions are required. The suite must isolate the record line from `$pass_out` and assert the instruction sentence is **absent from that isolated line**; it must pin the instruction as a whole line of its own; and it must assert the instruction is absent from the failing combo run's output, alongside the record-absence check already at `:1123`. Without that third one, a later regression that printed the instruction on a failing run goes uncaught — C-3 has a checker confirm it once, which is not the same as the suite holding it.
- **check**: checker-judgment: confirm one assertion extracts the record line from `$pass_out` (the suite's own `grep -F` idiom at `:1123` is the model) and asserts the instruction's absence from that extracted line; confirm a second pins the instruction as a whole line; and confirm a third pins its absence from the combo run. Then confirm the first two are load-bearing via C-6's placement mutant — an assertion that survives the mutant is not pinning the separation.
- **severity**: blocker
- **failing example**: The worker updates `:1041`'s count phrase, repoints `:1046`'s leak needle, and leaves `:1042` as a whole-capture `require_output` for the instruction sentence. Every other clause passes, and the suite still goes green with the instruction welded back onto the record.
- **helper note**: use `require_line` at `tests/inbox-to-memory-smoke.sh:49` for the whole-line pin — it is `grep -Fqx` over a captured output and is exactly the tool this clause asks for. There is genuinely no `refute_output` helper (the suite has output-based `require_output` and `require_line`, and file-based `require_text`/`refute_text`, plus `refute_failure`), so both negative assertions have to be written against the extracted line by hand. Written any other way, they cannot fire.
- **routing note**: the structural half — reading the three assertions — is read-only and stands alone. The load-bearing half is a mutation and rides along with C-6's run on the same scratch copy; do not mutate the repo for it. A read-only checker or the courier should judge the structural half and say plainly that it did not run the mutation, rather than implying it did.

## Spec excerpt

From `kendrick/skills#29`. A passing `verify-migration.sh` run ends by printing one
paragraph for the user to paste into the scope's patterns journal. Two things about
that paragraph are wrong.

Today, on a run that checked exactly one link, it prints:

```text
Verified <scope> against <ref> on <date>: 0 lint failures, 1 links checked (1 by id fallback), 0 renames, 0 deletions. The link count covers every distinct wiki-link target the scope carried at that ref, resolved against the tree as it stands now. Paste this paragraph into the scope's patterns journal.
```

1. `1 links checked` is ungrammatical at count 1. It is the only counter that shows the
   problem: `lint failures`, `renames`, and `deletions` each call `fail` when nonzero, and
   a failing run prints no record at all, so those three are only ever printed at zero.
2. The closing sentence is an instruction to the reader, and it sits inside the thing the
   reader is told to paste. Follow it literally and the journal entry ends with a
   direction to paste it into the journal.

**What to build.** The count agrees with its noun at every value it can print, and the
paste instruction moves out of the record. The user settled the placement: the
instruction goes on its own stdout line **before** the record, with a blank line between,
so the record is the last thing the run prints. Reword it so it reads correctly from
there — printed above the paragraph, a sentence saying "this paragraph" points backward
at nothing.

**Where.** The record `printf` at `inbox-to-memory/scripts/verify-migration.sh:205-206`,
inside the `failures -eq 0` block, and the assertions in
`tests/inbox-to-memory-smoke.sh` that pin it: the interior counts at `:1041`, the paste
sentence at `:1042`, the record-leak needle at `:1046`, and the failing-run absence
needle at `:1123`.

Those four existing sites are not the whole edit. **C-11 requires assertions that do not
exist yet** — three of them, one of which goes in the failing combo case. Writing new
assertions is part of this deliverable, not optional hardening.

Keep whatever the count agreement needs *inside* the `failures -eq 0` block. A plural-noun
variable hoisted up next to the counters is a perfectly reasonable-looking way to do it
and will fail C-7, whose check confines every hunk to that block. The clause carries a
narrow exception for a variable read nowhere else, but inside the block needs no
exception.

Two doc sentences describe this output and are expected to stay true rather than change:
`inbox-to-memory/references/migration.md:148` and `inbox-to-memory/SKILL.md:406` both say
a passing run *ends* by printing the paragraph, ready to paste. Printing the instruction
first keeps both true. Read them before you settle the wording — C-10 governs them, and a
reword that quietly falsifies a doc you never opened is the failure mode here.

**Why it shipped, and what that means for you.** A checker caught both defects during the
guild run for `#16` and deliberately did not fail them: both strings were pinned verbatim
by assertions that a separate clause forbade touching, so the only route to fixing the
prose ran through a protected assertion. That block is lifted. Changing the assertions
and the template together is the point of this task, not a side effect of it.

That history is also the warning. `#16`'s retrospective found that every real defect in
that run was "implementation right, test vacuous," and this task edits assertions on
purpose. The constitution weights that risk heavily — C-4, C-5, C-6, and C-11 exist for
it. In particular: every assertion over the record today is a substring search across the
whole captured output, which cannot tell an instruction on its own line from one welded
back onto the record's tail. Read C-11 before you touch the suite.

**Out of scope.** The sweep's actual checks — link resolution, the id fallback, the lint
pass-through, rename and deletion handling, every counter's computed value, and the exit
status all stay exactly as they are. The seven summary `echo` lines at `:193-199` stay
too: `links checked: N (id fallback: M)` is a label and a value, not a sentence, and the
user ruled it out of scope. Two assertions read it as machine output. Do not add a
`refute_output` helper to the suite; the idioms already in the file are enough.

**Done when** a passing run's pasteable paragraph reads correctly at count 1 and carries
no instruction to paste it, the suite still fails against both a zeroed-counts mutant and
a welded-instruction mutant, and all three suites under `tests/` exit 0.

`yq` must be on PATH; the scripts refuse without it.
