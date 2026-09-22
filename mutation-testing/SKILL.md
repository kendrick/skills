---
name: mutation-testing
description: "A guard nobody has watched fail is not a guard. This measures which tests actually catch one, by breaking it. Use when a diff adds a rejection, a validation, an invariant, a limit, a permission or ownership check, a branch that refuses input, or a test pinning one of those, and before that work is called done. For a review of the whole diff use adversarial-review or code-review."
---

# mutation-testing

A guard nobody has watched fail is not a guard. A diff tells you the rejection is there; it cannot tell you whether anything would notice its absence. Two `code-review` passes across four subagents returned nothing that changed a line on a ticket whose entire content was a new rejection rule. One mutation run, on the same code, produced the sentence that mattered: hoisting a read out of its write transaction fails exactly one test and leaves 62 green, so a reasonable-looking refactor reintroduces the original defect with the suite still passing.

Every guard gets two mutations, because there are two questions and one mutation cannot answer both. The **plausible** mutation asks whether a reasonable refactor would slip past this suite, and its output is a measurement. The **adversarial** mutation asks whether the guard is watching the right quantity at all, and its output is a verdict.

This skill is model-invoked, the opposite call from `adversarial-review` and `work-issue`. The premise of the work is that nothing else in the toolkit asks for this measurement, so a missed trigger costs a guard its only check, while a misfire costs one mutation run and a restore.

A **mutation** here is a deliberate edit to working code, made to be reverted. `work-issue` uses the word for an edit that may have silently failed to apply; both senses want the change proved on disk before anything reads a result that depends on it.

Where a step names a shell command, treat it as the intent and use your native shell or file tools.

Resolve once per invocation:

- **DIFF** — what "the diff" means for this run, resolved before Step 1 and never re-resolved.

  Uncommitted work in the tree is the default and the common case, since the skill usually fires on a guard somebody just wrote. That is `git diff`, `git diff --cached`, **and every untracked file git will show you** — `git ls-files --others --exclude-standard`, read as wholly added. Ignored files stay out, deliberately and not by accident: the restore snapshot cannot see them either, so a guard in an ignored path could be measured and then not verified back. Where a guard really does live in an ignored file, say so and stop rather than measuring what you cannot restore. Leaving untracked files out is how the skill does nothing at all while reporting success: a new guard and its test in new files produce an empty `git diff`, Step 1 finds no guards, and the run finishes having tested the thing it was invoked for not at all.

  Invoked by name against work already on the branch, DIFF is `git diff <merge-base with the default branch>..HEAD`, and where the base is ambiguous, ask rather than guess. A run that picks a different base than the one the user meant reviews guards nobody asked about and misses the ones they did.

  An untracked path carries through the rest of the run like any other, with one difference worth knowing at Step 3: its backup is the only copy anywhere, since the index holds no version of it to fall back on, and a restore that loses it loses it for good.
- **GUARDS** — the guards DIFF adds, from Step 1. Each carries its file and lines, the quantity it watches, and the test that pins it.
- **SUITE_CMD** — the project's own test command, read off its manifest or config; ask where the project has none. Every count in the report comes from this one command, so a run that switches commands midway is a run whose rows cannot be compared.
- **BASELINE** — one green run of SUITE_CMD, its summary line saved verbatim, with `git status --porcelain -uall` saved beside it as the snapshot Step 3 restores against. A red baseline stops the run: a failure that was already there is indistinguishable from one a mutation caused, and every count downstream inherits the ambiguity. The tree does not have to be clean, and usually is not — this skill fires on a diff somebody is still working on, so the snapshot records the working tree as it stands rather than demanding a commit first. Step 4 re-takes BASELINE when the suite grows, and only there.

## Step 1 — Name the guards

Read DIFF for what it **adds**, not for which files it touches. A guard is added behavior that refuses, bounds, or asserts: a rejection, a validation, an invariant, a limit, a permission or ownership check, or a branch that turns input away.

A test that pins one of those is a **trigger, never a guard of its own**. It is why the skill fires and it is the thing a guard gets measured against, so it belongs in a guard's row as that guard's pinning test rather than in GUARDS as an entry.

Where the diff adds only such a test, against a guard that was already there, **the guard it pins goes into GUARDS** even though the diff did not add it. That is the one case where this skill reaches past what the diff added, and it is the point of the trigger: a new test claiming to cover an existing guard is exactly a claim worth measuring. Without it the trigger has no route to a measurement at all — no guard added, GUARDS empty, and the stop below fires every time the skill is invoked the way its own description advertises. Listing it as a guard makes Step 1 look for a test that pins the test, report it as untested, and Step 2 then either mutates the test instead of the code under review or skips it while a spurious untested-guard row sits in the report. A formatting change to a file full of guards adds none; a single line added to a controller may add one.

For each guard, write down three things: where it lives, **the quantity it watches**, and the test that pins it. The quantity is the load-bearing column, and Step 2's adversarial mutation is built entirely out of it. Name what the guard actually reads—the value in the variable it compares—rather than the outcome somebody intended it to protect.

A guard with no test is reported as such, in the report, before any mutation runs. There is nothing to measure there, and the absence is the finding.

**Stop the run where nothing will be mutated.** That is an empty GUARDS, and equally a GUARDS whose every entry is a guard with no pinning test, since those get no mutation either. Say what DIFF resolved to, how many files it covered, and which of the two cases this is — then stop, rather than continuing into a report with no measurement in it. A report with nothing in it is indistinguishable from a report of a run that measured something and found the suite adequate, and that is the one outcome this skill must never produce by accident. Nearly every defect found in this skill has been a different route to it: a diff that omitted untracked files, a fixture whose guards were already committed, a merge-base that resolved to the wrong place. The routes are not enumerable, so the stop lives here, where they all arrive.

**Done when:** every guard DIFF adds is listed with its quantity and its pinning test, and every guard with no test is named in the report ahead of the first mutation; or no guard was going to be mutated — GUARDS empty, or every entry unpinned — and the run stopped saying which and naming what DIFF resolved to.

## Step 2 — Write the mutations

Two per guard that Step 1 paired with a test, one per question. A guard Step 1 found no test for is already reported and gets no mutation: with nothing pinning it, its run comes back zero-failures, and zero failures is what this skill reads as a real gap. The two cases would be indistinguishable in the report.

**The plausible mutation** is the edit a person cleaning up this code would actually make, applied to the quantity the guard watches. Hoisting a read above the transaction that writes it is one. Caching a value the guard re-reads is another. Write the version a reviewer would approve without comment.

Reach for the plausible version rather than an arbitrary break, because an arbitrary break measures nothing. The first attempt in the run this skill came from mutated a read into a form that stalls under the test double, produced 21 failures, and said only that the test double was load-bearing. The hoisted read fails one test, and that one test is the answer.

**The adversarial mutation** makes the failure the guard exists to catch happen by a route the guard's proxy does not see. A guard rarely watches the thing it protects; it watches a stand-in, and the gap between the two is where it fails silently. In the reference case, a guard read the file count a formatter printed about itself and passed cleanly, while the tree-wide write it existed to catch had already happened. The plausible mutation could not reach that: a guard watching the wrong quantity survives every reasonable edit to the right one.

**Done when:** every guard with a pinning test carries one mutation of each kind, each written as a named-path edit a reviewer could read as a diff, and each tagged with the question it answers; and every guard without one carries no mutation and its Step 1 row instead.

## Step 3 — Run one at a time

Per mutation, in this order. The steps are named rather than numbered, because their numbers have shifted twice and every cross-reference to a number went stale silently.

**Refuse** — any path that is not a regular file, before anything is copied. A symlink stops the run, naming the path and saying no mutation was written through it.

A symlink cannot be handled safely here, and both obvious handlings are worse than refusing. Backing up the link (`cp -P`) captures none of the bytes a mutation writes, because writing through a link lands on the target: the target is never backed up, the restore puts the link back, and every check passes while the mutation stays on disk. Backing up the target instead (`cp` without `-P`) loses the link, so the restore writes a regular file where the link was, and again every check passes. Both were measured, one after the other, each as the repair for the one before. Row 28 settled the principle for ignored files and it holds here: stop rather than measure what the run cannot put back.

**Back up** — copy each path the mutation touches to a scratch location outside the repository, preserving mode (`cp -p`), at a destination that mirrors the path's full position in the repo rather than its basename alone. The backup is the only copy of the user's uncommitted work the run holds, and three details keep it that way:

- A backup left beside the file is untracked, so it lands in the collateral check and halts a valid run on its first mutation.
- Flattening to basenames collides. `app/storage.py` and `lib/storage.py` back up to one file; the second copy destroys the first; the restore then writes one file's contents into the other path; and both checks pass, because each path matches the single backup it was restored from and a tracked file's status stays ` M` whatever it now contains. Git holds no copy of what was lost.
- `cp` without `-p` sets a new file's mode through the umask, so the backup records a mode the source never had and the contents check compares against a fabricated authority. Restoring needs the same care: `cp` onto an existing file keeps the destination's mode, so remove the path first or set the mode explicitly, or the bytes come back and the mode does not.

**Prove** — apply the edit, then prove it landed against the backup: `cmp` reports the file and its backup as differing. That comparison is the proof, and it has no alternatives. `git diff -- <path>` cannot answer the question here, because the guard's own uncommitted change already makes that diff non-empty, so it reports success for a mutation that never applied. A grep for the inserted text fails the same way whenever that text already appears in the user's work. An edit that silently failed to apply leaves the suite green, and a green suite reads here as "no test catches this", the exact inverse of what happened.

**Measure** — run SUITE_CMD. Capture its summary line verbatim, and the names of the failing tests.

**Restore** — copy the backup back to its named path, one path at a time.

Never with `git checkout`. That restores from the index, which on the tree this skill runs on is the state *before* the guard existed, so it deletes the very work the run was called to measure: `git checkout -- guard.py`, where the guard is an uncommitted change to a tracked file, replaces it with the committed version and the user's edit is gone. A guard in a brand-new untracked file is safe from that particular command, which errors instead, so the tracked case is the one to picture.

Never by directory either. `git checkout -- app/storage/` reverted the new test alongside the mutation, and the suite came back green without it. That was caught on the test count rather than by noticing, so treat it as a near miss rather than a save.

**Check** — verify the restore two ways, because neither sees what the other does. [references/what-each-check-sees.md](references/what-each-check-sees.md) is the table of what every comparison here can and cannot see, per kind of path; read it before changing any of them.

- **Contents**, against the backup: every mutated path matches it in both contents and mode, `cmp` for the bytes and a direct comparison of the two files' modes. Compare against the backup rather than against HEAD — `git diff --summary` reports a mode change relative to the commit, so where the user's own uncommitted work is what carries the mode it prints nothing while the restored file's mode is wrong. Contents alone is not enough either: `cmp` passes on a file whose executable bit moved, and where that file was already modified before the run the collateral check passes too, so a mode-only restore failure clears both. `git status --porcelain` reports status codes rather than contents, so a tracked file the user had already modified reads ` M path` before the mutation and ` M path` again after a restore that silently failed. That file is the normal case here rather than an edge, since the guard under test is itself an uncommitted change.
- **Collateral**, against BASELINE's snapshot: `git status --porcelain -uall` matches it. This catches a restore that reverted something it should not have, which the contents check cannot see because the casualty is a path no mutation touched. `-uall` is load-bearing: without it git coalesces a wholly-untracked directory to a single `?? dir/` line, and a file deleted inside that directory leaves the snapshot byte-identical. It is the restore's near miss exactly. The casualty there is an uncommitted edit to a **tracked** file under the restored path, so its ` M path` line goes absent. For that mechanism specifically an untracked file is not the shape to look for, since `git checkout -- <dir>` restores tracked files from the index and leaves untracked ones where they are — but an untracked path can still be a casualty by other routes, a copy-back to the wrong destination or a cleanup that overreaches, and DIFF brings untracked files into scope, so `-uall` is what keeps those visible.

Either check failing stops the run and names the path.

**Done when:** every mutation was applied with its change proved against its backup, measured, and restored; every mutated path matches its backup in contents and in mode, and post-restore status equals the snapshot, for every one of them; or the run stopped, naming either the path that differs or the path it refused.

## Step 4 — Re-measure after the suite grows

Any edit to a test file after a measurement invalidates every count taken before it. One mutation in the reference run moved from 2 failures to 4 once a later test began exercising the same return value, and extrapolating from the earlier run would have put a wrong number in a pull request.

So before any count leaves this run—into a report, a pull-request description, a commit message, or a reply to a reviewer—re-take BASELINE and re-run every mutation through Step 3 against the suite as it now stands.

Re-take it in this order, because the order is what keeps Step 3's checks armed:

1. Confirm the Step 3 cycle that just finished ended with its checks passing, so every mutation is already restored. This is a fact about that finished cycle, never a check to run now: the new test file is itself a difference against the current snapshot, so the collateral check evaluated at this moment fails by construction. Skipping the confirmation bakes a live mutation into the new snapshot, and the collateral check then passes for the rest of the run with that mutation still on disk—the near miss it exists to catch, made permanent.
2. Run SUITE_CMD and save the new summary line. Red here stops the run for the same reason a red baseline does.
3. Save `git status --porcelain -uall` as the new snapshot, which now carries the grown suite.

Absorbing the new test file into the snapshot is the whole point: it is a deliberate edit, and the collateral check compares against a snapshot taken before it existed, so without this the re-measure halts on its first mutation at exactly the moment this step exists for.

**Done when:** every count in the report comes from a run against the suite as it stands at reporting time, BASELINE was re-taken from a fully restored tree, and no number has left the run ahead of that.

## Step 5 — Report

One row per mutation, carrying: the guard, which question it answers, the mutation in one line, the runner's summary line verbatim, the failing tests by name, how many passed, and the reading: `caught` or `slipped` for an adversarial mutation, `fails N, leaves M green` for a plausible one.

Where the runner does not report a passing count, write `passed: not reported by <runner>` and let the reading say `fails N` alone. `go test ./...` prints `ok example.test/count 0.392s` and no total, and that is the common case outside pytest-shaped runners. N is different: the runner names each failure, so counting the lines it printed is reading its output rather than reconstructing it, and where a runner prints no failures by name that count is unavailable too and says so. An absent number is a fact about the runner and reads as one; a number reconstructed by counting test functions in the source is a fabrication that reads exactly like a measurement, which is the one thing this skill exists not to produce.

Quote the runner's own summary line rather than a count assembled by hand. Runners disagree about what they report and about how they phrase it, and the line as printed is what a reader can check.

A `slipped` adversarial verdict splits in two, and the row says which.

Where the mutation changed behaviour a caller could observe and no test caught it, that is a defect in the guard rather than a measurement of the suite. It goes first, and it names the quantity the guard should have been watching instead.

Where the mutation changed nothing a caller could observe, no test could have caught it and the guard may be perfectly sound. That is an equivalent mutant: the row is unresolved, marked as awaiting a human ruling, and it is not reported as a defect. Where you cannot tell the two apart, say so on the row and leave it unresolved, because calling an equivalent mutant a defect sends somebody to repair a guard that works.

Close with the one sentence worth carrying into the pull-request description: the guard, the refactor that would slip past it, and the numbers.

**Done when:** the report is in the reply, every guard from Step 1 appears in it, every count traces to a row that names the run it came from, and every `slipped` row reads as a defect or as awaiting a ruling rather than as both.

## Further Reading

- [references/what-each-check-sees.md](references/what-each-check-sees.md) — read before changing any Step 3 comparison: what the proof, contents, mode and collateral checks each see and are blind to, per kind of path

## One at a time

One mutation, one working tree, in sequence. Restore is already the fragile step at concurrency one, and two mutations sharing a tree restore against the same snapshot and race over the same paths, which turns a fragile step into a correctness bug that reports a clean run. The only safe fan-out is a worktree per mutation. This skill builds none, and a run that wants one is a run that should wait.
