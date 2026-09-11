#!/usr/bin/env bash
# Pin the divvy-up skill's load-bearing behavior. Many of these are refutes:
# the mechanisms this design explicitly cut are all reasonable-sounding ideas,
# and a well-meaning edit is exactly how they come back.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

require_file() {
  [[ -f "$1" ]] || {
    echo "missing required file: $1" >&2
    exit 1
  }
}

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || {
    echo "missing expected text in $file: $text" >&2
    exit 1
  }
}

# The trailing `return 0` matters: under `set -e`, a function ending on a failed
# grep aborts the script.
refute_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" && {
    echo "unexpected text in $file: $text" >&2
    exit 1
  }
  return 0
}

require_file divvy-up/SKILL.md
require_file divvy-up/README.md
require_file divvy-up/references/worker-prompt.md
require_file divvy-up/scripts/check-waves.py
require_file _maintenance/divvy-up/RATIONALE.md
require_file _maintenance/divvy-up/EVALS.md
require_file tests/fixtures/divvy-up/waves-good.md
require_file tests/fixtures/divvy-up/waves-overlap.md
require_file tests/fixtures/divvy-up/waves-glob.md
require_file tests/fixtures/divvy-up/waves-model.md

[[ "$(find divvy-up -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "divvy-up/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. Manual invocation is deliberate: a misfire during ordinary
# planning spends a whole fan-out, while a missed trigger costs the user one
# word.
require_text divvy-up/SKILL.md "name: divvy-up"
require_text divvy-up/SKILL.md "disable-model-invocation: true"
require_text divvy-up/SKILL.md "argument-hint: '[plan path] [--max N] [--commit]'"

# A description that summarizes the workflow becomes a shortcut the model takes
# instead of reading the body, which is how a multi-step skill collapses.
refute_text divvy-up/SKILL.md "description: \"Step 1"

# --- The safety property. These are the assertions the whole design rests on. ---

# A soft overlap check would let a fan-out run on top of an unproven wave, and
# the lost write it produces reports as nothing at all.
require_text divvy-up/SKILL.md "A non-zero exit is a hard stop, not a warning."

# One dispatch per message is the serialization the wave exists to remove, and
# it looks identical in the transcript to the real thing.
require_text divvy-up/SKILL.md "in a SINGLE message so they run concurrently"

# Ownership proved before dispatch is what makes the wave safe to fan out at
# all; proving it after (or not at all) is the "watch out for conflicts" note
# this design replaces.
require_text divvy-up/SKILL.md "proved by a script before anything is dispatched"

# A retry onto a half-written tree hands the second attempt the first one's
# leftovers to debug instead of the actual task.
require_text divvy-up/SKILL.md "Revert before the retry"

# Two rungs up on one failure is a second guess stacked on the first; the
# design allows exactly one rung, once.
require_text divvy-up/SKILL.md "one rung up"

# An omitted model inherits the session's, usually the most expensive one
# available, and the routing savings evaporate while the run still looks fine.
require_text divvy-up/SKILL.md "Name each dispatch's model explicitly."

# The wave-base rule: ownership derives against a recorded baseline, not the
# whole working tree. This was a defect found and fixed during the build, and
# losing it silently fails every task from wave 2 onward.
require_text divvy-up/SKILL.md "against WAVE_BASE, not against the working tree as a whole"

# The four rungs of the ladder. Losing one silently collapses routing onto the
# rungs that remain.
require_text divvy-up/SKILL.md "haiku"
require_text divvy-up/SKILL.md "sonnet"
require_text divvy-up/SKILL.md "opus"
require_text divvy-up/SKILL.md "fable"

# The guild handoff. Without it, a repo that already has `.agent-guild/` gets
# dispatched into twice, on two different ownership derivations of the same
# plan.
require_text divvy-up/SKILL.md "/agent-guild:job"

# Reference contracts: the seven placeholders every dispatch substitutes, and
# the JSON-only rule that keeps the gate from having to arbitrate between a
# report and a summary paragraph sitting next to it.
require_text divvy-up/references/worker-prompt.md "{{TASK}}"
require_text divvy-up/references/worker-prompt.md "{{OWNS}}"
require_text divvy-up/references/worker-prompt.md "{{CONTRACT}}"
require_text divvy-up/references/worker-prompt.md "{{DONE_WHEN}}"
require_text divvy-up/references/worker-prompt.md "{{CONSTRAINTS}}"
require_text divvy-up/references/worker-prompt.md "{{VERIFY_CMD}}"
require_text divvy-up/references/worker-prompt.md "{{PRIOR}}"
require_text divvy-up/references/worker-prompt.md "Your final message is exactly one fenced json block and nothing else"

# The constraint mechanism and the coupling question are each one deleted
# paragraph from being gone, and this smoke test is the only thing that would
# notice.

# A constraint's whole definition lives in this sentence: the shortcut that
# reaches done-when without doing the real work. Losing it leaves
# {{CONSTRAINTS}} substituting into a paragraph that no longer tells the
# worker what it's being warned off.
require_text divvy-up/references/worker-prompt.md "doing the work. Taking it fails your task even when verification passes"

# Step 6's third check now reads a report against its constraint as well as
# its done-when. Drop "and its constraints" here and a worker that reached
# done-when by the exact shortcut its constraint named passes the gate that
# exists to catch it.
require_text divvy-up/SKILL.md "and its constraints, not against whether it sounds finished"

# The coupling question: disjoint files only prove two tasks can't clobber
# each other's writes, not that they're unrelated. Losing this sentence
# collapses Step 1 back to file-ownership alone, and a plan with real mutual
# coupling ships two tasks that silently invalidate each other's work.
require_text divvy-up/SKILL.md "Disjoint paths prove two tasks cannot lose each other's writes; they do not prove the two tasks are about different things."

# Maintenance ledger. A rationale doc without its section headings is prose
# nobody can navigate under time pressure.
require_text _maintenance/divvy-up/RATIONALE.md "## Decision Ledger"
require_text _maintenance/divvy-up/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/divvy-up/RATIONALE.md "## Known Limitations"
require_text README.md "npx skills add kendrick/skills --skill divvy-up"

# Provenance on the vendored predicate. Losing this line is how a local edit
# silently forks from the upstream that owns the semantics.
require_text divvy-up/scripts/check-waves.py "Vendored verbatim from"
require_text divvy-up/scripts/check-waves.py "Upstream is authoritative"

# --- The cut features. Each sounds reasonable; each was refused for a reason
# recorded in the RATIONALE ledger. ---

# Run-state tracking is what makes agent-guild the guild; a parallel ledger
# here would just restate the `## Waves` table until the two drifted apart.
refute_text divvy-up/SKILL.md "run directory"
refute_text divvy-up/SKILL.md "ledger"

# Globs own nothing; the vendored predicate rejects them outright because a
# pattern can claim territory no file yet occupies.
refute_text divvy-up/SKILL.md "glob"

# A "be careful" note is exactly the failure mode separate waves exist to
# remove: it asks a human to catch what a script should have caught first.
refute_text divvy-up/SKILL.md "be careful"

# Per-tier retry counters are guild machinery for a skill with no run state to
# hold them; the retry rule here is fixed at one re-dispatch, one rung up.
refute_text divvy-up/SKILL.md "retry counter"

# A Dependencies column looks like documentation; it would just restate what
# wave placement already proves. The ledger cuts it for exactly that reason,
# and a dependency stays visible only as which wave a task landed in.
refute_text divvy-up/SKILL.md "Dependencies |"

# The three defects a Codex review found on the shipping PR. Each was reproduced
# before it was fixed, and each fix is one sentence away from being edited back
# out, so they are pinned by the string that carries the rule.

# A revert bounded by nothing destroys uncommitted work the run never wrote.
require_text divvy-up/SKILL.md "commit or stash first"
require_text divvy-up/README.md "clean tree before it dispatches"

# A status snapshot cannot see a second write that leaves the same status line.
require_text divvy-up/SKILL.md "git stash create"
require_text divvy-up/SKILL.md "status text cannot see a second write"
refute_text divvy-up/SKILL.md "otherwise a snapshot of \`git status"

# `owners` answers who owns a path, never who wrote it.
require_text divvy-up/SKILL.md "never which agent wrote it"
require_text divvy-up/SKILL.md "files_changed"
require_text divvy-up/references/worker-prompt.md "report every path you touched"

# A conversation-only plan still gets proved, through stdin.
require_text divvy-up/SKILL.md "validate -"

# Step 1's questions reach the user before a dispatch spends a rung on them.
require_text divvy-up/SKILL.md "before asking anything else"

# The second review round. Three of these were regressions introduced by the
# first round's fixes, which is why each is pinned by the string that states
# the rule rather than by the behavior being absent.

# The clean-tree check must precede the table write, or the skill's own edit to
# a tracked plan file stops every ordinary run.
require_text divvy-up/SKILL.md "before writing anything"
require_text divvy-up/SKILL.md "ahead of the table"

# `owners` refuses `-`, so a conversation-only plan needs a real pathname before
# any worker touches the tree.
require_text divvy-up/SKILL.md "Write the table to a temporary file"
refute_text divvy-up/SKILL.md "pipe the same text through"

# Untracked baseline is content, not names: the tracked-half defect again.
require_text divvy-up/SKILL.md "git hash-object"

# `fable` is the top rung and has no escalation target.
require_text divvy-up/SKILL.md "Failed on \`fable\`"

# Third review round. Both of these are gaps the worker contract opened rather
# than defects in the gate, and both are one deleted paragraph from returning.

# Workers share one index. A worker commit stages its peers' half-written work
# and moves HEAD out from under the revert that undoes a failed task.
require_text divvy-up/references/worker-prompt.md "leave every git write to the orchestrator"
require_text divvy-up/references/worker-prompt.md "outlive its own"
require_text divvy-up/SKILL.md "Every git write belongs to you"

# `stopped` had no rollback and no resume, so a stopped task satisfied no branch
# of Step 6's completion rule.
require_text divvy-up/SKILL.md "re-dispatch the task alone at the same rung"
require_text divvy-up/SKILL.md "no worker has committed anything"

# Fourth review round.

# `git hash-object` without -w prints a hash and stores nothing, so the manifest
# could name a file it had no bytes to restore.
require_text divvy-up/SKILL.md "git hash-object -w"
require_text divvy-up/SKILL.md "git cat-file -p"
refute_text divvy-up/SKILL.md "with its \`git hash-object\`."

# An entry naming an existing directory without its trailing slash owns nothing
# beneath itself, and only the repo-root branch of the predicate catches it.
require_text divvy-up/scripts/check-waves.py "def repo_root_for"
require_text divvy-up/scripts/check-waves.py "owns_entry_problem(entry, repo_root)"

# kendrick/skills#97: a plan copied from the skill's own example table backticks
# every cell, so the example row itself has to demonstrate a bare path or an
# agent following it verbatim reproduces the bug this wave fixed.
require_text divvy-up/SKILL.md "| 0 | add-user-schema | src/db/schema.ts | opus | schema exported, migration applies cleanly | |"

# Deliberately Not Built: stripping or rewriting backtick/link decoration
# instead of refusing it. Silent normalization here is how the original bug
# came back — the entry `paths_overlap` compares is the one the author typed,
# and quietly rewriting it would let a backticked and a bare spelling of one
# path validate as disjoint again.
refute_text divvy-up/scripts/check-waves.py '.replace("`"'
refute_text divvy-up/scripts/check-waves.py '.strip("`")'

# --- Functional checks. Cheap, deterministic, no subagents. ---

fixtures=tests/fixtures/divvy-up
waves=divvy-up/scripts/check-waves.py

python3 "$waves" validate "$fixtures/waves-good.md" >/dev/null || {
  echo "waves-good.md should validate" >&2
  exit 1
}

overlap_err="$(python3 "$waves" validate "$fixtures/waves-overlap.md" 2>&1 >/dev/null || true)"
grep -Fq "overlap:" <<<"$overlap_err" || {
  echo "overlapping owners in one wave must be reported as an overlap: $overlap_err" >&2
  exit 1
}

glob_err="$(python3 "$waves" validate "$fixtures/waves-glob.md" 2>&1 >/dev/null || true)"
grep -Fq "glob character" <<<"$glob_err" || {
  echo "a glob entry must be rejected: $glob_err" >&2
  exit 1
}

model_err="$(python3 "$waves" validate "$fixtures/waves-model.md" 2>&1 >/dev/null || true)"
grep -Fq "unknown model" <<<"$model_err" || {
  echo "a model outside the four rungs must be rejected: $model_err" >&2
  exit 1
}

# A path owned by exactly one task in the wave must name that task, since the
# gate's whole job is attributing a write to the task responsible for it.
owner_out="$(printf 'src/auth/login.ts\n' | python3 "$waves" owners "$fixtures/waves-good.md" --wave 1)"
[[ "$owner_out" == "Implement auth" ]] || {
  echo "src/auth/login.ts should be owned by Implement auth in wave 1, got: $owner_out" >&2
  exit 1
}

# A path no task in the wave owns is a blind spot, and must stop rather than
# be skipped—the same assertion the exemplar makes for an unowned path in a
# fix diff.
printf 'src/other/file.ts\n' | python3 "$waves" owners "$fixtures/waves-good.md" --wave 1 >/dev/null 2>&1 && {
  echo "an unowned path in the wave must exit non-zero" >&2
  exit 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A missing plan is an environment problem, not a planning one, and the script
# keeps that exit code separate from a semantic failure like an overlap.
set +e
python3 "$waves" validate "$tmp/does-not-exist.md" >/dev/null 2>&1
missing_status=$?
set -e
[[ "$missing_status" == "3" ]] || {
  echo "a missing plan file should exit 3, got: $missing_status" >&2
  exit 1
}

cat > "$tmp/pipe.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | probe | src/a.py | sonnet | `printf x \| grep x` exits 0 | |
PLAN

python3 "$waves" validate "$tmp/pipe.md" >/dev/null || {
  echo "an escaped pipe inside a cell must stay in that cell, not split a column" >&2
  exit 1
}

# The script must not warn on import; a SyntaxWarning on every invocation is
# noise a caller cannot silence.
python3 -W error::SyntaxWarning -c "import ast,sys; ast.parse(open('divvy-up/scripts/check-waves.py').read())" || {
  echo "check-waves.py raises a SyntaxWarning" >&2
  exit 1
}

# A slashless entry naming a directory that exists must stop before dispatch,
# not come back as an unowned path after the wave has written the tree.
cat > "$tmp/noslash.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | api | divvy-up | sonnet | it builds | |
PLAN

noslash_err="$(python3 "$waves" validate "$tmp/noslash.md" 2>&1 >/dev/null || true)"
grep -Fq "lacks the trailing" <<<"$noslash_err" || {
  echo "a slashless existing directory must be refused: $noslash_err" >&2
  exit 1
}

# A task's whole job is often to create the tree it owns, so a path that does
# not exist yet must still validate.
cat > "$tmp/newtree.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | api | brand-new/tree/ | sonnet | it builds | |
PLAN

python3 "$waves" validate "$tmp/newtree.md" >/dev/null || {
  echo "an owned path that does not exist yet must still validate" >&2
  exit 1
}

# Constraints is legitimately empty for most tasks, and the validator never
# reads its content, so a blank cell there must not block an otherwise sound
# plan.
cat > "$tmp/no-constraint.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | api | brand-new/tree/ | sonnet | it builds | |
PLAN

python3 "$waves" validate "$tmp/no-constraint.md" >/dev/null || {
  echo "an empty Constraints cell must still validate" >&2
  exit 1
}

# The exemption is Constraints-only. Every other column, Done when included,
# stays required, so a blank one must still fail with its own named complaint.
cat > "$tmp/no-done-when.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | api | brand-new/tree/ | sonnet | | do not raise timeouts |
PLAN

no_done_err="$(python3 "$waves" validate "$tmp/no-done-when.md" 2>&1 >/dev/null || true)"
grep -Fq "empty Done when cell" <<<"$no_done_err" || {
  echo "an empty Done when cell must still fail: $no_done_err" >&2
  exit 1
}

# #232: a backticked path reads as an ordinary path to the author who wrote
# it, and it is worse than an unowned one — it differs from the bare spelling
# a peer task wrote for the same file. Refused, not stripped, so the reason
# can quote text the author can find in their own file.
cat > "$tmp/backtick.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | schema-task | `src/db/schema.ts` | opus | it builds | |
PLAN

set +e
backtick_out="$(python3 "$waves" validate "$tmp/backtick.md" 2>&1)"
backtick_status=$?
set -e
[[ "$backtick_status" != "0" ]] || {
  echo "a backticked Files-owned entry must exit non-zero: $backtick_out" >&2
  exit 1
}
grep -Fq "malformed entry '\`src/db/schema.ts\`' in schema-task: backtick; write the path bare, without markdown decoration" <<<"$backtick_out" || {
  echo "a backticked entry must be reported by name, task, and reason: $backtick_out" >&2
  exit 1
}

# The link test is `](`, not a bracket, so a real path shape like
# app/[slug]/page.tsx stays legal while a Markdown link around a path is
# refused the same way a backtick is.
cat > "$tmp/link.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | link-task | [a](src/a.py) | opus | it builds | |
PLAN

set +e
link_out="$(python3 "$waves" validate "$tmp/link.md" 2>&1)"
link_status=$?
set -e
[[ "$link_status" != "0" ]] || {
  echo "a markdown-link Files-owned entry must exit non-zero: $link_out" >&2
  exit 1
}
grep -Fq "malformed entry '[a](src/a.py)' in link-task: markdown link; write the path bare, without markdown decoration" <<<"$link_out" || {
  echo "a markdown-link entry must be reported by name, task, and reason: $link_out" >&2
  exit 1
}

# kendrick/skills#97, the defect itself: before this wave, a bare and a
# backticked spelling of one path compared as different strings, so two tasks
# in one wave rode straight past the overlap check onto the same file. This
# used to print "OK: 2 tasks in 1 wave, disjoint" and exit 0.
cat > "$tmp/mixed-decoration.md" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | quote-bare | src/shared/util.ts | haiku | bare owner ready | |
| 0 | quote-decorated | `src/shared/util.ts` | sonnet | decorated owner ready | |
PLAN

set +e
mixed_out="$(python3 "$waves" validate "$tmp/mixed-decoration.md" 2>&1)"
mixed_status=$?
set -e
[[ "$mixed_status" != "0" ]] || {
  echo "kendrick/skills#97: a bare and backticked spelling of one path in one wave must not validate: $mixed_out" >&2
  exit 1
}
grep -Fq "malformed entry '\`src/shared/util.ts\`' in quote-decorated: backtick; write the path bare, without markdown decoration" <<<"$mixed_out" || {
  echo "kendrick/skills#97: the decorated entry and its owning task must be named: $mixed_out" >&2
  exit 1
}

echo "divvy-up smoke: OK"
