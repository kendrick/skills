# What Each Check Sees

Read this before changing anything in Step 3, and check the change against every row.

Step 3 makes four comparisons: the **proof** that a mutation landed, the **contents** check, the **mode** check, and the **collateral** check. Each is blind to something, and the blind spots are the whole reason there are four. Most of this skill's defects were a change to one comparison made without asking what the others could still see — so the table is here to be read as a table, not as prose.

`mutation-testing/scripts/mutation-guard.py` runs every comparison, one subcommand per column, and a change to a comparison is a change to that subcommand:

- **Proof** — `prove`, bytes against the backup.
- **Contents** and **mode** — `check`, bytes and permission bits against the backup, path by path.
- **Collateral** — `check`, the current `git status --porcelain -uall` against the file `snapshot` wrote, byte for byte.

Two subcommands refuse the rows with no safe handling instead of comparing them: `backup` exits 1 on a symlink or on a file in a directory the caller cannot write, and `snapshot --guard` exits 1 on an ignored file.

The column that matters most is the last one. This skill runs on a tree carrying the user's uncommitted work, so any comparison against git's index or HEAD cannot tell that work from the run's own mutation.

## The table

| Path kind | Proof (`prove`: bytes vs backup) | Contents (`check`: bytes vs backup) | Mode (`check`: vs backup) | Collateral (`check`: `status --porcelain -uall` vs snapshot) |
|---|---|---|---|---|
| Regular file, tracked, unmodified before the run | sees it | sees it | sees it | sees it: status goes from absent to ` M` |
| Regular file, tracked, **already modified** before the run | sees it | sees it | sees it | **blind**: reads ` M path` before and after, whatever the contents |
| Regular file, untracked | sees it | sees it | sees it | sees it only with `-uall`; bare `porcelain` coalesces a wholly-untracked directory to `?? dir/` |
| Ignored file | sees it | sees it | sees it | **blind**: status never reports it. Out of DIFF for this reason |
| Symlink | **errors**: a relative link in the backup dangles there | **blind**: follows both sides, compares the target | **blind**: compares the link's mode, not the target's | **blind** where the target was already modified | 
| A symlink's target, written through the link | **blind**: the proof compares the link | **blind**: the target is not a backed-up path | **blind**: same | **blind** where the target was already ` M` |
| Regular file in a directory the caller cannot write | sees it | sees it | sees it | as for its tracked or untracked row. Every column works, and `restore` does not: it removes the path before copying back, the removal fails, and the mutation stays on disk |
| Directory | n/a | n/a | n/a | sees a wholly-untracked one as one entry, not per file |
| A path no mutation touched | n/a | **blind**: nothing compares it | n/a | sees it, which is the only reason this check exists |

Three rows carry no safe handling and are refused rather than measured: **symlinks**, **ignored files**, and **files in a directory the caller cannot write**. Every attempt to handle the symlink row produced a defect worse than the one before it, which is recorded in ledger rows 30 and 35.

## How to use it when changing a check

1. Name the comparison you are changing and find its column.
2. Read the column top to bottom. Every cell that says *blind* is a case your change must not make worse, and every cell that says *sees it* is a property your change must not lose.
3. Then read the **row** for the path kind your change is about, across all four columns. A defect gets through when one comparison is fixed for a row and the others are assumed to cover it. That is what happened with mode, with symlinks, and with the symlink's target.
4. Demonstrate the change against every row of the table in a scratch repo, not only against the case that motivated it. Verifying a fix against the failure that prompted it is the same circularity this skill exists to break, one level up.

A new row is a new path kind. Add it to the table before adding handling for it, and prefer refusing it to handling it: refusal is correct in one line, and handling is correct only when every column is filled in and demonstrated.
