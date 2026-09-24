# The merge test

One procedure, run with zero or more branches, that builds a scratch tree, merges into it in merge order, verifies, and removes it on every route out, a conflict or a red suite included. `SKILL.md` reads this file at four trigger points:

- **Baseline**, Step 4, with no branches, before any lane is dispatched.
- **Contract change**, Step 5, over every lane branch with commits, when a returned lane's `files_changed` has a path under CONTRACT_PATHS or its `contract_changed` names any path.
- **Before publish**, Step 6, over the full merge set in `order.md` order, once every unheld lane has returned, and again from Step 7 when `origin/DEFAULT` has moved past the newest green run's `base:`.
- **HEAD moved**, Step 8, re-run once more before the final report, if any lane's HEAD differs from the SHA the newest recorded run merged.

## Why a linked worktree, never `cp -R` or `git archive`

Both alternatives are trapped by #109's reproducer, filed on PR #121's deferred-findings queue as rows 4 and 5.

`cp -R` keeps the copy's `.git` as a plain file pointing at the original tree's gitdir. #109's own reproducer staged into the issue worktree's real index while believing itself sandboxed, because a copy made this way shares an index with the tree it was copied from rather than owning one.

`git archive` leaves no `.git` at all. `divvy-up/scripts/check-waves.py`'s `repo_root_for` treats `os.path.exists(node/.git)` as marking a root, so a tree with no `.git` reads as no root, and every on-disk check `check-waves.py` runs over it is silently skipped rather than failed.

`git worktree add --detach` dodges both. The tree it makes has its own gitdir and index under `<COMMON>/worktrees/`, so nothing staged inside it touches ROOT's index, and it carries its own `.git` file, so `repo_root_for` sees a real root and runs its checks against it.

## Procedure

1. **Clear the ground.** MERGE_TREE must not already exist. If it does, `git worktree remove --force MERGE_TREE`, then `git worktree prune`.
2. **Build the tree.** `git -C ROOT fetch origin DEFAULT`, then `git -C ROOT worktree add --detach MERGE_TREE origin/DEFAULT`. Record `base: origin/<DEFAULT> <sha>` from `git -C MERGE_TREE rev-parse HEAD`. Step 7 compares that SHA with a fresh fetch before any lane publishes, because every lane's rebase lands on whatever `origin/DEFAULT` is by then, and a run over an older base tested a different tree.
3. **Merge in order.** For each branch in `order.md` order that has commits: record `issue-N <sha>`, then `git -C MERGE_TREE merge --no-ff --no-edit issue-N`. Sequential, never octopus, so a conflict names one pair rather than an N-way tangle, and the order is the order the human will merge in by hand. On conflict, record `conflict: issue-N after issue-M — <paths from git diff --name-only --diff-filter=U>`, run `git -C MERGE_TREE merge --abort`, and go to step 7.
4. **Verify.** INSTALL_CMD, then VERIFY_CMD, saving the tail of its output.
5. **Check for a dirty tree.** `git -C MERGE_TREE diff --stat HEAD`. Non-empty is `dirty after verify:` and red. Checked this way, never with `git status`: a status read of a copied tree once reported clean over an index that had already been staged into, the same #109 hazard step 1 exists to keep out of MERGE_TREE itself.
6. **Record the run.** Write `WAVE_DIR/merge-test/<k>.md`: the `base:` line, every merged SHA in order, any conflict or dirty-tree line, and VERIFY_CMD's saved tail.
7. **Tear down.** `git worktree remove --force MERGE_TREE`, on every route out: a clean pass, a conflict, or a red suite alike.

## Reading the result

- **Red baseline.** DEFAULT was already red before any lane touched it. A later run red at the same failures is inherited, not caused by a lane.
- **Conflict.** A lane wrote outside the footprint it declared; its own `divvy-up` gate should have caught this, and resolving it is a judgment call no unattended run makes.
- **Red after a green baseline, no conflict.** The cross-lane coupling the footprint proof cannot see: read the failing output against `coupling.md` and correct whichever row called the pair `independent`.
- **Green, and step 5's diff empty.** The sentence the final report quotes.
