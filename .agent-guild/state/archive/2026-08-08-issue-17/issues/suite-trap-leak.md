`tests/inbox-to-memory-smoke.sh` cleans up its throwaway scopes with a chain of `EXIT` traps, and each one restates every temp dir declared before it. That accumulator idiom is what keeps a single `EXIT` handler responsible for the whole file. One link in the chain is now broken, so the suite leaks a directory per run.

Found by a checker during the guild run for #28, in the code that run had just authored. It escaped every clause the job carried: nothing is asserted away, nothing leaves the allowed diff scope, and it is not prose. Filing it rather than folding a fix into that job, since widening an already-audited decomposition costs more than a ticket.

## Steps to Reproduce

1. Note the temp directories present before a run:

   ```bash
   ls -d "${TMPDIR:-/tmp}"/i2m-* 2>/dev/null | wc -l
   ```

2. Run the suite:

   ```bash
   bash tests/inbox-to-memory-smoke.sh
   ```

3. Count again. One `i2m-overrun.*` directory survives, and another appears on each subsequent run.

## Observed vs. Expected

**Observed:** `tests/inbox-to-memory-smoke.sh:196` sets `trap 'rm -rf "$overrun_scope"' EXIT`. The next trap in the file, at `:239`, is `trap 'rm -rf "$not_a_scope" "$inline_scope"' EXIT` — it replaces the handler and does not carry `$overrun_scope` forward, and no later trap picks it up. Because a shell has one `EXIT` handler, whichever trap ran last is the only one that fires, so `$overrun_scope` is never removed.

**Expected:** every temp dir the suite creates is gone when it exits, however many times it runs. The file's existing idiom achieves that by having each trap restate all prior directories.

## Minimal Reproduction

The suite itself is the reproduction. No fixture needed.

## Acceptance Criteria

- [ ] Running the suite leaves no `i2m-*` directory behind, verified by counting before and after.
- [ ] The fix holds when the suite exits early on a failing assertion, not only on a clean pass.
- [ ] Whatever shape the fix takes, adding a new throwaway scope later does not silently reintroduce the leak. If the accumulator chain is kept, the next trap carries every prior dir; if it is replaced with a single cleanup array or a `TRAPPED_DIRS` accumulator, the new mechanism is used by every scope in the file rather than sitting alongside the old one.
- [ ] All three suites under `tests/` still exit 0.

## For a Coding Agent

- **Verify with:** `bash tests/inbox-to-memory-smoke.sh && bash tests/file-issue-smoke.sh && bash tests/handoff-smoke.sh`
- **Setup:** `bash`, `awk`, and `yq` (`brew install yq`). No package manifest; the suites under `tests/` are the whole test surface.
- **Start here:** every `trap ... EXIT` in `tests/inbox-to-memory-smoke.sh`. The break is at `:196` versus `:239`, but the accumulator pattern runs the length of the file and the fix should be judged against all of it.
- **Done when:** the before/after directory count is unchanged across a passing run and a failing one.
- **Out of scope:** the assertions themselves, and the other two suites unless they share the same defect.
