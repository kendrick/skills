# Locally collected evidence for T-003's deterministic clauses (retry 1)

Collected by the orchestrator on the project host at 2026-08-06, against the
reworked tree. The far side executes nothing; it judges these results as given.

## C-12 — no assertion deleted or weakened

`git diff 1f17478 -- tests/` has exactly one removed content line across the
whole `tests/` tree, and it is fixture prose rather than an assertion:

```
-Verbatim transcript omitted from the fixture. Line refs above are illustrative.
```

That line was the old one-line `## Raw Content` placeholder in the old-only
fixture note, replaced by the seam T-001 planted. No `require_*` or `refute_*`
line appears among the removals.

Assertion counts in `tests/inbox-to-memory-smoke.sh`, base versus current — the
rework only added:

```
at 1f17478:  require_* 152   refute_* 12
current:     require_* 190   refute_* 17
```

All three suites, run verbatim against the reworked tree:

```
bash tests/inbox-to-memory-smoke.sh   -> exit 0
bash tests/file-issue-smoke.sh        -> exit 0
bash tests/handoff-smoke.sh           -> exit 0
```

## C-13 — the diff stays in scope

The constitution's command, run verbatim:

```
test -z "$( { git diff --name-only $(git merge-base main HEAD) -- ':(exclude)inbox-to-memory/' ':(exclude)tests/' ':(exclude).agent-guild/' ':(exclude)CLAUDE.md' ':(exclude).gitignore'; git ls-files --others --exclude-standard -- ':(exclude)inbox-to-memory/' ':(exclude)tests/' ':(exclude).agent-guild/' ':(exclude)CLAUDE.md' ':(exclude).gitignore'; } )"
```

exit 0 — nothing outside the allowed paths has changed since the branch point,
tracked or untracked. The one new file, `inbox-to-memory/scripts/verify-migration.sh`,
sits inside the allowed set.

## What changed between r0 and r1

Round 0 failed on C-7 and C-10. In both cases the script was correct and the
suite failed to pin it — each was proved by a mutation that the suite let
through. The rework added suite assertions only; `verify-migration.sh` is
byte-identical to the r0 version. The two new assertions:

- **C-7**: a `v_linkdrop` scenario (suite 1074-1106) where a wiki link is
  observable only at the pre-migration `--since` ref — the sentence carrying the
  link is edited out of note A post-migration (an ordinary `M`, keeping C-8 out
  of it) while note B, the link's target, is renamed away. It asserts both
  `links checked: 1 (id fallback: 0)` and the `verify-link` failure.
- **C-10**: `require_output "$pass_out" "0 lint failures, 1 links checked (1 by
  id fallback), 0 renames, 0 deletions"` at suite:986, pinning the record
  paragraph's own interior rather than the summary block above it, which also
  prints on failing runs.
