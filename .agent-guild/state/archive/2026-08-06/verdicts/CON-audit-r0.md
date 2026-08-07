---
task: CON-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: PASS
checked_at: 2026-08-06T22:02:02Z
---

Audit of `.agent-guild/state/constitution.md` against `.agent-guild/state/spec.md`
(`kendrick/skills#16`). Round 0 on this machine; four prior rounds ran on the old
machine and their verdict files did not survive the handoff, so nothing here builds
on an unread earlier verdict. Every line-number and arithmetic claim below was
re-derived from the working tree at `eac74fe`, not taken from the clause text.

## Per-clause results

| clause | result | severity | description | evidence |
| ------ | ------ | -------- | ----------- | -------- |
| C-1 | PASS | blocker | Check names the assertion that must exist (extract omits the raw-content-only name) and the implementation property (one `extract_body`, not a second copy). Falsifiable; the fixture seam it falsifies against is specified in "The testability fixture". | `inbox-to-memory/scripts/migrate-scope.sh:123` (`extract_body`, stops at `/^## Raw Content/`); fixture placeholder confirmed at `tests/fixtures/inbox-to-memory/old-only/notes/2025-11-04-atlas-scoping-call-3iMu15QJ_x.md:45-47` |
| C-2 | PASS | blocker | Names a diagnostic string (`tier2-entity-unsourced`), a byte-identity condition, and the proposals row that triggers it. Concrete failing artifact statable. | clause text; fixture seam as above |
| C-3 | PASS | blocker | Weakest check in the set, but not vague: the rubric is claim-by-claim traceability from summary to that note's extract, with a concrete failing example. See Note 4 on what it can and cannot pin. | clause text |
| C-4 | PASS | blocker | Two separable assertions: no `summary:`/`entities:` line after a Tier-1-only apply, and per-file grouping in the dry-run report. Both falsifiable. | `migrate-scope.sh:342-347` (dry-run/apply seam) |
| C-5 | PASS | blocker | Byte-identity comparison between a Tier-1-only note and the same note after a `--tier2` apply that omits it. Mechanically checkable. | clause text |
| C-6 | PASS | blocker | Both cited yq preflights reproduce exactly, so the retired trigger is correctly retired. The stub-lint abort trigger is the only one that separates a status-reading implementation from a grep-based one, and it works: a stub exiting 2 with no summary needs no yq. Sibling resolution anchor confirmed. | `lint-scope.sh:63` and `migrate-scope.sh:76` are both the `command -v yq` line; `tests/inbox-to-memory-smoke.sh:8` is the `dirname "${BASH_SOURCE[0]}"` repo-root resolution; `failures: 18` on the broken fixture is pinned at `tests/inbox-to-memory-smoke.sh:159` |
| C-7 | PASS | blocker | Names the discriminating property (targets counted from the pre-migration ref, not the post-migration tree), the fallback count, and the `verify-link` diagnostic. | clause text |
| C-8 | PASS | blocker | The git claim reproduces. In a throwaway repo built from the old-only fixture, a committed `git mv` yields 0 `git status --porcelain` lines and one `R100` line from `git diff --name-status -M <base>`. The check's "committed, not working-tree" wording is what makes a porcelain implementation fail. | reproduced locally; `git diff --name-status -M <base>` → `R100 scope/_inbox/.gitkeep scope/_inbox/renamed-note.md`, porcelain → 0 lines |
| C-9 | PASS | blocker | Byte-identity before/after a failing run, plus "two planted defects report both" to catch fail-fast. Falsifiable. | clause text |
| C-10 | PASS | blocker | Three separable assertions: paragraph on stdout with matching counts, absent from every file under the scope, absent entirely on a failing run. | clause text |
| C-11 | PASS | major | Extends an assertion that already exists rather than inventing a new shape. | existing second-run assertion at `tests/inbox-to-memory-smoke.sh:607` region |
| C-12 | PASS | blocker | Check runs against something the worker does not author (the diff from `1f17478`). `tests/` is unmodified since that commit, so the baseline is clean. The cited example assertion exists. | `git diff --stat 1f17478 -- tests/` → empty; `require_output "$apply_out" "left alone: 0"` at `tests/inbox-to-memory-smoke.sh:607`; `tests/file-issue-smoke.sh` and `tests/handoff-smoke.sh` both exit 0 today |
| C-13 | PASS | blocker | Deterministic check runs and exits 0. Exclusions are pathspec-side, not `grep -q`-side, which is correct for this environment. The pathspec leaves 413 tracked files in view, so an edit to any of them would be caught; `git ls-files --others` covers the untracked case and `merge-base` covers the committed case. | check executed, exit 0; `git merge-base main HEAD` = `eac74fe`; `git ls-files -- <same exclusions>` → 413 paths |
| C-14 | PASS | blocker | The string the failing example depends on is really there, so the clause is falsifiable today. | `inbox-to-memory/references/migration.md:19` contains "Tier 2 is tracked in its own ticket and is not implemented here." |
| C-15 | PASS | major | Both legs of the argument and both arithmetic claims reproduce, and the check is a real tripwire rather than a restatement. | `NOTE_KEY_ORDER` holds 17 names → 19 lines with fences; `RECORD_KEY_ORDER` holds 19 → 21, matching "Records reach 21"; check executed, exit 0 (17+2=19 ≤ 20), and 19+2=21 > 20 for the two-key failing example; `frontmatter-known-keys` is at `lint-scope.sh:133` as the non-goal cites |
| C-16 | PASS | major | Rubric points at a named pattern list and correctly carves out the two house exceptions (title case, unspaced em dashes) so a checker does not flag them as findings. | clause text; `~/.claude/CLAUDE.md` prose preferences |

Protected content: the constitution asserts no passages manifest is needed because
nothing here ships verbatim author words. That holds—the deliverable is two scripts,
two docs, and test assertions—and the byte-identity guarantee that does matter (note
bodies) is already pinned by the Tier 1 suite. No dangling manifest reference.

Spec coverage: all eight acceptance criteria in `spec.md` map onto clauses
(C-1/C-2/C-3, C-4, C-5, C-6, C-7, C-8, C-9, C-10). No criterion is unclaimed.

No contradictions found between clauses.

## Preconditions before dispatch

Not a defect in the constitution, but the orchestrator must clear it before
dispatching any worker, because a PASS here unblocks `dispatch-guard`:

**`yq` is not installed on this machine.** `command -v yq` finds nothing, and there
is no binary at `/opt/homebrew/bin/yq` or `/usr/local/bin/yq`. Consequence at HEAD,
before any Tier 2 work exists: `bash tests/inbox-to-memory-smoke.sh` exits 1 on its
first lint call with `yq is required and not on PATH`. Five clauses (C-1, C-4, C-6,
C-8, C-12) require that suite to exit 0 as part of their check, and seven more (C-2,
C-5, C-7, C-9, C-10, C-11, C-14) turn on assertions inside it that only a run can
confirm. Until `yq` is on PATH, every one of those checks is `blocked`, not FAIL,
and no worker can demonstrate compliance. Install it (`brew install yq`) before
Phase 2. `tests/file-issue-smoke.sh` and `tests/handoff-smoke.sh` are unaffected and
pass today.

## Notes for decomposition

These are advisory. None of them fails a clause; each is a place where the
decomposition should pin something the constitution leaves as premise.

1. **C-6 assumes a preflight no clause requires.** The check's rationale retires the
   yq-removal trigger on the grounds that `verify-migration.sh` carries its own yq
   preflight "because both neighbors do." Nothing in any clause's *text* requires the
   new script to carry one. Since `yq` is currently absent, a `verify-migration.sh`
   built without that preflight would fail in a confusing place rather than a clear
   one. Put the preflight in the task's acceptance, not just in C-6's reasoning.

2. **C-2's "unmodified" is only unambiguous under the settled two-run shape.** It
   reads correctly when `--tier2 --apply` runs against notes Tier 1 already migrated:
   refusing an unsourced entity means no Tier 2 keys get written. If a worker builds a
   combined single-pass apply instead, "leaves the note unmodified" would also cost
   that note its Tier 1 write—not a contradiction with C-5 as written (C-5 governs
   omission and declining, not refusal), but a real fork in behavior. Have the task
   state which shape it builds.

3. **Cosmetic line-cite drift in C-15.** The clause cites `lint-scope.sh:174` for
   "`check_frontmatter` admits comments and blank lines." The regex that does the
   admitting is line 173; 174 is the `if [[ -n "$offender" ]]` guard that consumes it.
   Same two-line construct, and the claim itself is true. Worth correcting on the next
   edit to the file, not worth a round trip on its own.

4. **What C-3 can and cannot pin.** C-3 governs generation-time behavior, so at check
   time the only evidence is the proposals the worker itself authored during the job's
   own run—the exact trap the constitution's own preamble names. Routing to
   `checker-judgment` is the right mitigation and the clause passes on that basis, but
   unlike C-1, C-2, and C-4 it names no assertion that must exist in the suite, so
   nothing guards it against regression later. If the decomposition can pin one
   (a fixture proposal whose summary asserts something the extract does not support,
   asserted to be caught or flagged), C-3 gets teeth it currently lacks.
