# AGENTS.md

Review rules for a diff under `divvy-up/`. Root `AGENTS.md` still applies.

## Code Review Rules

**Revert stays inside what the run wrote.** `wave-snapshot.py revert --task` writes, deletes, or replaces a link only at a changed path that task owns. It follows no link and refuses a path whose parent is now a symlink. Step 6's by-hand revert after a failed format pass holds to the same over the paths the pass changed outside the derived set. Neither reaches a peer's path or anything outside the work tree. A change that lets either one write, delete, or follow a link past that line, or lose data, is P0. In the finding, name the path it reaches and cite this rule. Safe path: refuse the write and report the path. The cases and the incident behind them are `_maintenance/divvy-up/RATIONALE.md` row 46, from #395's seven repair rounds.
