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
require_file divvy-up/scripts/wave-snapshot.py
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

# Frontmatter. Model-invocation is deliberate and load-bearing: `work-issue`
# reaches this skill at its own Step 0, and a user-invoked skill is one no
# sibling can call at all. The misfire guard the flag used to carry now sits
# at Step 4's confirmation, which is pinned below.
require_text divvy-up/SKILL.md "name: divvy-up"
# The flag coming back would not read as a bug. A sibling's Skill call
# would be refused outright, because a stripped description is stripped
# from siblings too—work-issue reaches it at its own Step 0. Refuted on the bare
# key so `: false` fails here as loudly as `: true`.
refute_text divvy-up/SKILL.md "disable-model-invocation"
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

# Rendering: the orchestrator used to type ~15k characters per worker prompt
# (~37 s each). Step 5 renders to a file outside the tree and dispatches a
# pointer, so these strings are what keep the dispatch short and the file out
# of Step 6's ownership diff.
dispatch_sentence="Read <path> in full before doing anything else. It is your complete task instructions; follow it exactly as if it were this message."
require_text divvy-up/SKILL.md "- **PROMPT_DIR** — where rendered worker prompts go"
require_text divvy-up/SKILL.md "then render every task in the wave with \`scripts/render-prompt.py\`"
require_text divvy-up/SKILL.md "$dispatch_sentence"
require_text divvy-up/SKILL.md "every prompt was rendered by \`render-prompt.py\` exiting 0"
require_text divvy-up/references/worker-prompt.md "$dispatch_sentence"
require_text divvy-up/references/worker-prompt.md "On a direct run PROMPT_DIR is a \`mktemp -d\` made once per invocation. Under a wrapping skill it is the directory that skill names"
require_text divvy-up/references/worker-prompt.md "\`none recorded\` goes in when no earlier wave landed one."
require_text divvy-up/README.md "render-prompt.py        # fills a task's worker prompt into a file the dispatch points at"
require_text _maintenance/divvy-up/RATIONALE.md "| 44 | Step 5 renders each task's worker prompt to a file"
require_text _maintenance/divvy-up/EVALS.md "| 31 | A worker dispatched with only the sentence"

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

# Reference contracts: the nine placeholders every dispatch substitutes, and
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

# {{CALLER_NOTES}}: the seam a wrapping skill uses to hand every worker a
# preamble divvy-up's own template has no slot for. Blank by default, so a
# direct run stays byte-identical to before the seam existed.
require_text divvy-up/references/worker-prompt.md "{{CALLER_NOTES}}"

# Step 4's folded question: a wrapping skill that already asked the user
# whether to run wave 0 answers it here on the user's behalf instead of
# asking a second time in the same turn.
require_text divvy-up/SKILL.md "answers it here on the user's behalf"

# kendrick/skills#188: the verify baseline. Without it, a suite already red
# before the run fails the first task to meet it, fails the retry one rung up,
# and stops the run naming a healthy task.

# This pin greps only the template. The Placeholders list names {{BASELINE}}
# too, so a file-wide grep would stay green after the template lost the slot
# and workers stopped seeing the baseline.
baseline_template="$(awk '/^## Template$/{f=1; next} /^## Placeholders$/{f=0} f' divvy-up/references/worker-prompt.md)"
grep -Fq -- "{{BASELINE}}" <<<"$baseline_template" || {
  echo "missing expected text in divvy-up/references/worker-prompt.md's template: {{BASELINE}}" >&2
  exit 1
}
require_text divvy-up/references/worker-prompt.md "- \`{{BASELINE}}\` — BASELINE as it stands when the wave dispatches: a first line \`exit: <n>\` with its exit status, then its output tail verbatim."
require_text divvy-up/references/worker-prompt.md "for every later wave it is the refresh Step 6 made from the last passing wave's verification."
require_text divvy-up/references/worker-prompt.md "The same command ran on this tree before this wave started, and printed"

# Step 3's capture, and the two cases that skip running it. A wrapper's
# baseline has to replace the run: work-issue reaches Step 3 before its
# worktree exists, so a capture there would run on the wrong tree.
require_text divvy-up/SKILL.md "Then capture **BASELINE**, which starts as the verify command's output before any task runs"
require_text divvy-up/SKILL.md "A wrapping skill's baseline replaces the run."
require_text divvy-up/SKILL.md "or says one will be named before Step 5"
require_text divvy-up/SKILL.md "With no command found, VERIFY_CMD and BASELINE are both \`absent\`"

# With no command, the worker prompt still carries `{{VERIFY_CMD}}` in a shell
# block, now holding `absent`. Without the sentence after that block a worker
# runs `absent` as a command and reports its task failed, though Step 6 skips
# verification (PR #229 review).
require_text divvy-up/references/worker-prompt.md "Where that command reads \`absent\`, this repo has no verification command:"
require_text divvy-up/references/worker-prompt.md "run nothing, write \`absent\` in \`verify_output\`, and set \`status\` by the"
require_text divvy-up/references/worker-prompt.md "The literal \`absent\` goes in when Step 3 found no command"
# The baseline paragraph claims a command ran and adds its own status rule,
# both false for a worker handed `absent`, so the template routes it past.
require_text divvy-up/references/worker-prompt.md "Where the command above reads \`absent\`, skip the baseline below and the"
require_text divvy-up/references/worker-prompt.md "The worker runs the command before reporting"
require_text divvy-up/SKILL.md "Both placeholders still go into the worker prompt as the literal \`absent\`, and the template tells a worker handed that to run nothing"

# Step 4's red-baseline clause. Refusing outright on a red baseline would
# block the plan written to fix that very failure.
require_text divvy-up/SKILL.md "When BASELINE is red, the same question names each failure BASELINE shows"
require_text divvy-up/SKILL.md "A red baseline does not stop the run on its own"
require_text divvy-up/SKILL.md "When a red BASELINE names no individual failures, the question says so in their place"
# Decision 36 cut ralph-grind's refuse-on-a-red-gate preflight. A red BASELINE
# goes into Step 4's question instead, since the plan may exist to fix it.
refute_text divvy-up/SKILL.md "red BASELINE stops the run"
# refute_text is case-sensitive, so the line above misses "a red baseline
# stops the run". This check is case-blind. Step 4's "A red baseline does not
# stop the run on its own" doesn't match it.
if grep -iFq -- "red BASELINE stops the run" divvy-up/SKILL.md; then
  echo "unexpected text in divvy-up/SKILL.md: red BASELINE stops the run (any case)" >&2
  exit 1
fi

# The README tells the user the same rules: the baseline is captured before
# the go-ahead, the gate judges each failure against it, and the stop fires
# only on a red baseline. When the README's stop once lost that scope, every
# suite stayed green.
require_text divvy-up/README.md "it runs the repo's verification command once on the untouched tree and keeps the output as a baseline"
require_text divvy-up/README.md "found on disk rather than asked for, and checks each failure against the baseline."
require_text divvy-up/README.md "When the baseline is red and either output names no individual failures, the gate can't tell new failures from old ones, so it stops the run and shows you both outputs."

# A wrapper's file replaces the run but not the lookup, since Step 6 still
# runs VERIFY_CMD, and it has to come from the HEAD the run starts at. Its
# status comes from an `exit:` first line (PR #229 review): read off the
# output, a suite that exited non-zero without printing a failure read as
# green. A file without the line reads red.
# #434: a wrapper that names its own verify command (work-issue names the plan's)
# must win over the repo-disk harvest, or the gate runs the wide suite against a narrow baseline.
require_text divvy-up/SKILL.md "Where the wrapping skill names a verify command, that command is **VERIFY_CMD**, and the repo-disk resolution below is skipped."
require_text divvy-up/SKILL.md "Resolve VERIFY_CMD all the same, because Step 6 runs it; a command the wrapper named is that resolution."
require_text divvy-up/SKILL.md "The wrapper must have recorded the run-start file at the HEAD this run starts from, and a later wave's file at the HEAD that wave's gate passed on"
require_text divvy-up/SKILL.md "keep its exit status and the tail of its output as a first line \`exit: <n>\` followed by the tail, the shape a wrapper's file has and \`{{BASELINE}}\` hands workers."
require_text divvy-up/SKILL.md "A wrapping skill that continues the run at a later wave can name another file, and that file replaces BASELINE from then on."
require_text divvy-up/SKILL.md "A named file's first line \`exit: <n>\` gives its status: green on 0, red otherwise."
require_text divvy-up/SKILL.md "That line is a status, not a failure, so attribution reads failures from the rest of the file."
require_text divvy-up/SKILL.md "A named file with no \`exit:\` first line reads as red, because a status nobody recorded can't be called green"
require_text divvy-up/README.md "A handed-over file states the command's exit status on its first line, and a file without that line counts as red"
# Decision 37 cut reading a named file's status from its output text.
refute_text divvy-up/SKILL.md "read it as red when its output reports a failure"

# The refresh (PR #229 review). Judged against the run-start BASELINE, a
# failure wave 0 fixed and wave 1 brings back still shows in BASELINE, so
# wave 1 passes and the final diff ships broken.
require_text divvy-up/SKILL.md "Step 6 refreshes it after each passing wave."
require_text divvy-up/SKILL.md "Once the wave passes its gate, BASELINE becomes the exit status and output tail of the verification run that passed it, the run after any retries, and every later wave's workers and gate read that refreshed BASELINE"
require_text divvy-up/SKILL.md "a failure an earlier wave fixed and a later wave brings back must count against the later wave."
require_text divvy-up/SKILL.md "A wave that changed nothing refreshes the same way."
require_text divvy-up/SKILL.md "Step 4's question reads the run-start BASELINE alone"
require_text divvy-up/SKILL.md "With VERIFY_CMD \`absent\`, skip this check, and nothing refreshes."
require_text divvy-up/SKILL.md "Once the wave passes, BASELINE holds its gate's last verification run."
require_text divvy-up/README.md "Once a wave passes, the gate's own verification run becomes the baseline for the next wave."

# The attribution rule, at the gate and in the worker's own contract. Drop
# either half and a pre-existing failure gets charged to a task again.
require_text divvy-up/SKILL.md "Run VERIFY_CMD, the command Step 3 resolved or the wrapper named, so the gate verifies with the same command BASELINE ran."
require_text divvy-up/SKILL.md "a failure routes a task as \`failed\` only when BASELINE does not show that same test or check."
require_text divvy-up/references/worker-prompt.md "A failure that also appears in this baseline is not yours."
require_text divvy-up/references/worker-prompt.md "a failure the baseline already shows aside"

# #106: a worker sets status by its own done-when and its own files. Mid-wave,
# a peer's half-written file fails the tree-wide command, and the gate that
# runs after every task lands owns that failure. Holding the worker to it
# again is the unreachable bar Step 1 now forbids.
require_text divvy-up/references/worker-prompt.md "Neither is a failure in a file you do not own"
require_text divvy-up/references/worker-prompt.md "Set \`status\` by your own done-when"
refute_text divvy-up/references/worker-prompt.md "and set \`status\` by everything else."
refute_text divvy-up/references/worker-prompt.md "everything else verification printed"
refute_text divvy-up/references/worker-prompt.md "reports \`done\` with a broken build"

# Output that names no individual failures can't be attributed, so the gate
# stops the run. work-issue's stop table quotes this message, so the wording
# is pinned byte for byte. The stop is scoped to a red BASELINE: on a green or
# absent one every failure is the wave's and retries one rung up.
require_text divvy-up/SKILL.md "With a green or \`absent\` BASELINE every failure belongs to the wave and routes as \`failed\`."
require_text divvy-up/SKILL.md "With a red BASELINE, where verification fails and either this wave's output or BASELINE names no individual failures, nothing can be attributed"
require_text divvy-up/SKILL.md "| Verification failed on a red BASELINE, and this wave's output or BASELINE names no individual failures |"
require_text divvy-up/SKILL.md "Verification failed without naming individual failures, so this wave's failures can't be told from the baseline's."

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

# #106: a done-when has to be reachable while peers are still writing. In a
# schema-widening wave, wave 0's bar was `pnpm typecheck passes`, which every
# producer kept red until its own wave-1 task landed, so the only route to
# green was the shortcut the constraint cell forbade. Lose any of these and
# Step 1 asks only for a bar somebody could fail, so a tree-wide command
# becomes a task's default done-when again.
require_text divvy-up/SKILL.md "A done-when also has to be reachable while peers are still writing."
require_text divvy-up/SKILL.md "the suite belongs to the gate"
require_text divvy-up/SKILL.md "that the task can reach from its own files while its peers are still writing"

# #81: work can meet its done-when honestly by widening its file. In #80's
# build a worker held to "three new require_text calls" added a
# require_text_joined helper, and the orchestrator deleted it by hand after
# the gate. A stricter done-when can't catch that, since widening meets any
# bar, so only a constraint naming the file's boundary does. The refute pins
# the cut judgment route in Step 6 (RATIONALE, Deliberately Not Built).
require_text divvy-up/SKILL.md "the constraint names that boundary and tells the worker to work inside it"
require_text divvy-up/SKILL.md "any vocabulary boundary the task's file holds"
# The opening definition and the empty-cell default have to admit the
# boundary too, or they exclude what the widening sentence asks for.
require_text divvy-up/SKILL.md "or the boundary the work stays inside"
require_text divvy-up/SKILL.md "no such path and no such boundary"
refute_text divvy-up/SKILL.md "judges the addition excessive"

# Maintenance ledger. A rationale doc without its section headings is prose
# nobody can navigate under time pressure.
require_text _maintenance/divvy-up/RATIONALE.md "## Decision Ledger"
require_text _maintenance/divvy-up/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/divvy-up/RATIONALE.md "## Known Limitations"
# The root README carries this skill's own install flag, in the map
# table's third column. The command form around it is pinned once, in
# repo-docs-smoke.sh, so this does not re-pin it twelve times.
require_text README.md "--skill divvy-up"

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
require_text divvy-up/scripts/wave-snapshot.py "git stash create"
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
require_text divvy-up/scripts/wave-snapshot.py "git hash-object"

# `fable` is the top rung and has no escalation target.
require_text divvy-up/SKILL.md "Failed on \`fable\`"

# Third review round. Both of these are gaps the worker contract opened rather
# than defects in the gate, and both are one deleted paragraph from returning.

# Workers share one index. A worker commit stages its peers' half-written work
# and moves HEAD out from under the revert that undoes a failed task.
require_text divvy-up/references/worker-prompt.md "leave every git write to the orchestrator"
require_text divvy-up/references/worker-prompt.md "outlive its own"

# kendrick/skills#123: on PR #121 a reproducer's `cp -R` copy of the worktree
# kept the `.git` pointer file and staged into the real index. A method
# pinned without its reason gets routed around, so this pins both.
require_text divvy-up/references/worker-prompt.md "run \`rm -f <copy>/.git\` before"
require_text divvy-up/references/worker-prompt.md "a file pointing at the original repository"
require_text divvy-up/references/worker-prompt.md "\`git -C <copy> rev-parse --git-dir\` fails."
require_text divvy-up/references/worker-prompt.md "fails. The one other safe answer is"
require_text divvy-up/references/worker-prompt.md "outside every checkout and repeat the check."
# Deliberately Not Built (#216): `git archive HEAD` exports committed HEAD
# only, so a copy made mid-wave silently drops the worker's uncommitted edits.
refute_text divvy-up/references/worker-prompt.md "git archive"
# PR #213 review: `git diff --stat HEAD` never lists an untracked file, so a
# wave whose only output is a new file would read as unchanged.
require_text divvy-up/SKILL.md "Take any other read of what the wave changed from \`git diff --stat HEAD\` plus the untracked paths the manifest comparison above finds, rather than \`git status\`"
# Deliberately Not Built: detecting a corrupted index at the gate. #123 chose
# prevention, and this is the command such a gate would run.
refute_text divvy-up/SKILL.md "git diff --cached"

# kendrick/skills#116: six workers ran a whole-tree formatter at once. A
# byte-identical rewrite leaves no diff, so the dispatch is the only guard.
require_text divvy-up/references/worker-prompt.md "Run no command that writes files outside the ones you own"
require_text divvy-up/references/worker-prompt.md "skipping it here drops no step"
require_text divvy-up/references/worker-prompt.md "the rule against writing outside your own files wins"
# A formatter that cannot be scoped leaves the worker's own files unformatted,
# and a check-only verify flags them; without this the obedient worker reports
# `failed` and Step 6 reverts it.
require_text divvy-up/references/worker-prompt.md "formatting-only complaint is the format pass's"
require_text divvy-up/SKILL.md "Every git write belongs to you"
require_text divvy-up/SKILL.md "**format pass**"
require_text divvy-up/SKILL.md "after the ownership check, because its writes are yours"
require_text divvy-up/SKILL.md "only scoped to its own paths"
require_text divvy-up/README.md "leave any tree-wide format"
# A format-pass write outside the derived set never matches WAVE_BASE again,
# so a retry gated against that base fails `owners` on the orchestrator's
# own write. Reproduced by adversarial-review of #116 (F-r1-authz-01).
require_text divvy-up/SKILL.md "record WAVE_BASE and its untracked manifest again"
require_text divvy-up/SKILL.md "each revert uses the base recorded before the dispatch it undoes"
# The derived set includes deleted paths, and a `--fix` linter exits non-zero
# on what it cannot fix; neither is a task's failure (F-r1-authz-02).
require_text divvy-up/SKILL.md "derived paths that still exist"
require_text divvy-up/SKILL.md "A non-zero exit from the pass is no task's failure"

# Deliberately Not Built: detecting a tree-wide write at the gate by
# modification time. Workers' own verification touches files they do not
# own, and a timestamp cannot say which concurrent agent wrote a path.
refute_text divvy-up/SKILL.md "mtime"
# The same row's second cut: checking `files_changed` against the diff. A
# stale write-back restores WAVE_BASE bytes and leaves no diff to compare.
# The backticked form is pinned with its object, since Step 6 legitimately
# checks `files_changed` against `owns`.
refute_text divvy-up/SKILL.md "files_changed against"
refute_text divvy-up/SKILL.md "\`files_changed\` against the diff"
refute_text divvy-up/SKILL.md "\`files_changed\` against the derived"

# A format command that errors partway leaves a partial rewrite, and a
# resumed run's fresh WAVE_BASE would absorb it unchecked (PR #180 review).
require_text divvy-up/SKILL.md "where the command itself errored, revert every path it changed outside the derived set back to WAVE_BASE, then classify the error by the paths its output names"
# A worker can leave an owned file the formatter can't parse, and a retry can
# fix that. Stopping the run instead left the task's changes in place and
# escalated nothing (PR #180 review, r4213929212).
refute_text divvy-up/SKILL.md "outside the derived set back to WAVE_BASE, then stop"
require_text divvy-up/SKILL.md "A non-zero exit from the pass is no task's failure by itself"
require_text divvy-up/SKILL.md "An error naming only paths inside the derived set is the failure of each task that owns one of them"
require_text divvy-up/SKILL.md "route every other task in the wave by its own report"
# Routing the other tasks by report never skips the wave's verification.
require_text divvy-up/SKILL.md "Verification still runs for the wave as usual; after it, route every other task"
require_text divvy-up/SKILL.md "as repo-relative paths, resolving an absolute path against the repo root first"
# A tree-wide pass can also choke on a file that was broken before the wave
# started. Retrying the task whose path it also named sends a healthy task
# back.
require_text divvy-up/SKILL.md "Output naming both a derived path and a path outside the derived set counts as one that cannot be tied"
# A partial rewrite left in place gets absorbed by a resumed run's fresh
# WAVE_BASE, so the revert precedes every branch.
require_text divvy-up/SKILL.md "The revert comes first on every branch"
# The stop branches belong in Done-when, or a run that stopped there reads as
# unfinished.
require_text divvy-up/SKILL.md "or on a format-command error naming no derived path or one that could not be tied to a path"
require_text divvy-up/SKILL.md "An error naming no derived path, such as a missing tool, a bad config, or a repo-level failure, stops the run"
# A guess here sends a healthy task back for a retry.
require_text divvy-up/SKILL.md "Where the output cannot be tied to a path either way, stop the same way"
require_text divvy-up/README.md "When the error names only files the wave's tasks wrote, each task that owns one of them has failed"
require_text divvy-up/SKILL.md "Paths inside the derived set keep the pass's writes"
require_text divvy-up/SKILL.md "rerun the derivation above and take every path it now lists"
require_text divvy-up/README.md "A half-finished reformat of those files never reaches the next run's starting point"
require_text divvy-up/SKILL.md "Revert each one the way reverting a task, below, reverts an owned path"

# The write ban covers what the gate can see. Ignored build output is
# invisible to `--exclude-standard`, and banning it contradicts running
# {{VERIFY_CMD}} (PR #180 review).
require_text divvy-up/references/worker-prompt.md "The files this rule covers are the ones git would show you"
require_text divvy-up/references/worker-prompt.md "never sees ignored ones either"

# `stopped` had no rollback and no resume, so a stopped task satisfied no branch
# of Step 6's completion rule.
require_text divvy-up/SKILL.md "re-dispatch the task alone at the same rung"
require_text divvy-up/SKILL.md "no worker has committed anything"

# Fourth review round.

# `git hash-object` without -w prints a hash and stores nothing, so the manifest
# could name a file it had no bytes to restore.
require_text divvy-up/scripts/wave-snapshot.py "git hash-object -w"
require_text divvy-up/scripts/wave-snapshot.py "git cat-file -p"
require_text divvy-up/SKILL.md "\`-w\` is what makes the manifest more than a detector"
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

# kendrick/skills#122: with no .git above the cwd, validate skips the on-disk
# entry checks on purpose, yet it used to print the same `OK:` line as a full
# run. On PR #121 a `git archive` baseline went green on checks that never ran.
# Two trees with the same bytes, one inside a checkout and one not. Each runs
# from inside its own tree, because repo_root_for walks up from the cwd, not
# from the plan file.
repro="$tmp/repro-122"
mkdir -p "$repro/in-checkout/src"
git -C "$repro/in-checkout" init -q
echo x > "$repro/in-checkout/src/keep.py"
cat > "$repro/in-checkout/plan.md" <<'PLAN'
# P

## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
| --- | --- | --- | --- | --- | --- |
| 0 | a | src | sonnet | done | |
PLAN
cp -R "$repro/in-checkout" "$repro/no-git"
rm -rf "$repro/no-git/.git"

set +e
checkout_err="$(cd "$repro/in-checkout" && python3 "$repo_root/$waves" validate plan.md 2>&1 >/dev/null)"
checkout_status=$?
nogit_out="$(cd "$repro/no-git" && python3 "$repo_root/$waves" validate plan.md 2>/dev/null)"
nogit_status=$?
set -e

[[ "$checkout_status" == "1" ]] || {
  echo "kendrick/skills#122: a slashless directory entry inside a checkout should exit 1, got $checkout_status: $checkout_err" >&2
  exit 1
}
grep -Fq "malformed entry 'src' in a: exists as a directory but lacks the trailing '/'" <<<"$checkout_err" || {
  echo "kendrick/skills#122: the checkout run must name the slashless entry: $checkout_err" >&2
  exit 1
}
# Exit 0 is the contract: a plan validated outside a checkout is an intended
# run (Decision 33), so the degraded run warns rather than fails.
[[ "$nogit_status" == "0" ]] || {
  echo "kendrick/skills#122: a run with no .git above the cwd should still exit 0, got $nogit_status: $nogit_out" >&2
  exit 1
}
grep -Fq "skipped: on-disk entry checks (a directory entry missing its trailing '/', a trailing '/' on a file)" <<<"$nogit_out" || {
  echo "kendrick/skills#122: a run with no .git above the cwd must say which checks it skipped: $nogit_out" >&2
  exit 1
}
grep -Fq "OK (spelling only): 1 task in 1 wave, disjoint" <<<"$nogit_out" || {
  echo "kendrick/skills#122: a degraded run must end on the spelling-only success line: $nogit_out" >&2
  exit 1
}
# A caller matching ^OK: must see full validations only.
if grep -Eq '^OK: ' <<<"$nogit_out"; then
  echo "kendrick/skills#122: a degraded run must not print the full-run success line: $nogit_out" >&2
  exit 1
fi

# A degraded run that fails must still say what it skipped, or a reader fixing
# the overlap would take the next green run for a full one. The overlap is a
# spelling-level problem, so the no-root path still catches it.
cat > "$repro/no-git/plan-overlap.md" <<'PLAN'
# P

## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
| --- | --- | --- | --- | --- | --- |
| 0 | a | src/keep.py | sonnet | done | |
| 0 | b | src/keep.py | sonnet | done | |
PLAN
set +e
nogit_fail_out="$(cd "$repro/no-git" && python3 "$repo_root/$waves" validate plan-overlap.md 2>/dev/null)"
nogit_fail_status=$?
set -e
[[ "$nogit_fail_status" == "1" ]] || {
  echo "kendrick/skills#122: an in-wave overlap with no .git above the cwd should exit 1, got $nogit_fail_status: $nogit_fail_out" >&2
  exit 1
}
grep -Fq "skipped: on-disk entry checks (a directory entry missing its trailing '/', a trailing '/' on a file)" <<<"$nogit_fail_out" || {
  echo "kendrick/skills#122: a failing run with no .git above the cwd must still say which checks it skipped: $nogit_fail_out" >&2
  exit 1
}
if grep -Eq '^OK' <<<"$nogit_fail_out"; then
  echo "kendrick/skills#122: a failing degraded run must print no OK line: $nogit_fail_out" >&2
  exit 1
fi

# The other half of the distinction: a full run keeps its old line and stays
# silent about skipping, or the two would still read alike.
full_out="$(python3 "$waves" validate "$fixtures/waves-good.md")"
grep -Eq '^OK: ' <<<"$full_out" || {
  echo "kendrick/skills#122: a full run from the repo root must still print OK: $full_out" >&2
  exit 1
}
if grep -Fq "skipped:" <<<"$full_out"; then
  echo "kendrick/skills#122: a full run from the repo root must not print a skipped: line: $full_out" >&2
  exit 1
fi

# Deliberately Not Built: failing validate when no repo root is found. The
# phrase a failure for that case would carry; the behavioral exit-0 assertion
# above catches the rest.
refute_text divvy-up/scripts/check-waves.py "no repo root"

# kendrick/skills#123, end to end, following the issue's reproduction. The
# `rm -f` step has to cut a `cp -R` copy loose, or the paragraph pinned above
# teaches a method that still writes the real index.
repro123="$tmp/repro-123"
mkdir -p "$repro123"
# g sets identity and turns off signing per command, so commits work on a
# machine whose global config lacks a name or requires a GPG agent.
g() { git -c user.name=divvy-smoke -c user.email=divvy-smoke@example.invalid -c commit.gpgsign=false "$@"; }
g init -q "$repro123/main"
echo one > "$repro123/main/f.txt"
g -C "$repro123/main" add f.txt
g -C "$repro123/main" commit -qm one
g -C "$repro123/main" branch base
g -C "$repro123/main" worktree add -q -b feature "$repro123/wt"
echo two > "$repro123/wt/f.txt"
g -C "$repro123/wt" commit -qam two

cp -R "$repro123/wt" "$repro123/copy"
rm -f "$repro123/copy/.git"
# Without a ceiling, git in the copy walks up into any repository that
# encloses the temp dir and runs the checkout against that repository instead.
if (cd "$repro123/copy" && GIT_CEILING_DIRECTORIES="$(dirname "$tmp")" git checkout base -- . >/dev/null 2>&1); then
  echo "kendrick/skills#123: git checkout inside a cp -R copy with .git removed must fail, since the copy is no longer a repository" >&2
  exit 1
fi
cut_status="$(git -C "$repro123/wt" status --short)"
[[ -z "$cut_status" ]] || {
  echo "kendrick/skills#123: the source worktree must stay clean after git ran in its cut-loose copy, got: $cut_status" >&2
  exit 1
}

# The control: the same copy with the pointer left in place must dirty the
# source index, or the case above passes on a setup that never reproduced #123.
cp -R "$repro123/wt" "$repro123/copy-pointer"
(cd "$repro123/copy-pointer" && GIT_CEILING_DIRECTORIES="$(dirname "$tmp")" git checkout base -- . >/dev/null 2>&1) || true
pointer_status="$(git -C "$repro123/wt" status --short)"
[[ -n "$pointer_status" ]] || {
  echo "kendrick/skills#123: a cp -R copy that keeps .git should write the source worktree's index; the reproduction no longer reproduces" >&2
  exit 1
}

# PR #213 review: `rm -f` does not cut loose a copy made beneath another
# checkout, because git walks up from the copy and finds that checkout. The
# worker prompt's `rev-parse --git-dir` check catches this, so the check has to
# succeed on a copy nested under the main checkout and fail on one outside it.
mkdir -p "$repro123/main/.scratch"
cp -R "$repro123/wt" "$repro123/main/.scratch/copy"
rm -f "$repro123/main/.scratch/copy/.git"
GIT_CEILING_DIRECTORIES="$(dirname "$tmp")" git -C "$repro123/main/.scratch/copy" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "kendrick/skills#123: git -C <copy> rev-parse --git-dir must succeed on a copy nested under the main checkout, since git finds that checkout" >&2
  exit 1
}
if GIT_CEILING_DIRECTORIES="$(dirname "$tmp")" git -C "$repro123/copy" rev-parse --git-dir >/dev/null 2>&1; then
  echo "kendrick/skills#123: git -C <copy> rev-parse --git-dir must fail on a cut-loose copy outside every checkout" >&2
  exit 1
fi

# A plain checkout's `.git` is a directory, so `rm -f` leaves it and the copy
# keeps a repository of its own. The worker prompt calls `.git` the one other
# safe answer, so a worker copying a plain checkout doesn't read it as a walk-up
# and remake the copy forever.
g init -q "$repro123/plain"
echo one > "$repro123/plain/f.txt"
g -C "$repro123/plain" add f.txt
g -C "$repro123/plain" commit -qm one
cp -R "$repro123/plain" "$repro123/plain-copy"
if rm -f "$repro123/plain-copy/.git" 2>/dev/null; then
  echo "kendrick/skills#123: rm -f on a plain checkout's .git directory should fail" >&2
  exit 1
fi
[[ -d "$repro123/plain-copy/.git" ]] || {
  echo "kendrick/skills#123: rm -f should leave a plain checkout copy's .git directory in place" >&2
  exit 1
}
plain_gitdir="$(GIT_CEILING_DIRECTORIES="$(dirname "$tmp")" git -C "$repro123/plain-copy" rev-parse --git-dir 2>&1)"
[[ "$plain_gitdir" == ".git" ]] || {
  echo "kendrick/skills#123: git -C <copy> rev-parse --git-dir on a plain checkout copy must print exactly .git, got: $plain_gitdir" >&2
  exit 1
}

# #163: run alone, divvy-up reads the commit style with one jq expression and
# no script. jq's `null == false` is false, so a token that can't administer
# the repo reads all-null settings as the full pass; only squash-only is bare.
squash_jq='.allow_squash_merge == true and .allow_merge_commit == false and .allow_rebase_merge == false'
require_text divvy-up/SKILL.md "gh api repos/{owner}/{repo} --jq '$squash_jq'"
require_text divvy-up/SKILL.md "\`squash-only repo: in-branch commits get bare subjects\`"
if command -v jq >/dev/null 2>&1; then
  # Run the expression SKILL.md carries, not the copy above, so an edit to the
  # skill's command is what this case exercises.
  skill_jq="$(grep -o -- "--jq '[^']*allow_squash_merge[^']*'" divvy-up/SKILL.md | head -n 1 | sed -e "s/^--jq '//" -e "s/'\$//")"
  [[ -n "$skill_jq" ]] || {
    echo "#163: no --jq expression naming allow_squash_merge found in divvy-up/SKILL.md" >&2
    exit 1
  }
  jq_case() {
    local label="$1" want="$2" body="$3" got
    got="$(jq "$skill_jq" <<<"$body")"
    [[ "$got" == "$want" ]] || {
      echo "#163: divvy-up's commit-style jq on $label should print $want, got: $got" >&2
      exit 1
    }
  }
  jq_case squash-only true '{"allow_squash_merge": true, "allow_merge_commit": false, "allow_rebase_merge": false}'
  jq_case merge-allowed false '{"allow_squash_merge": true, "allow_merge_commit": true, "allow_rebase_merge": false}'
  jq_case rebase-allowed false '{"allow_squash_merge": true, "allow_merge_commit": false, "allow_rebase_merge": true}'
  jq_case no-admin false '{"allow_squash_merge": null, "allow_merge_commit": null, "allow_rebase_merge": null}'
  jq_case squash-null false '{"allow_squash_merge": true, "allow_merge_commit": null, "allow_rebase_merge": null}'
fi

# --- render-prompt.py: fills worker-prompt.md's Template block from the Waves
# table, so the orchestrator dispatches a pointer instead of typing ~15k chars.
render=divvy-up/scripts/render-prompt.py
rt="$tmp/render"
mkdir -p "$rt"
rplan="$fixtures/render-plan.md"

# exit_of runs a command and prints its status, so each case can assert the
# exit code without tripping `set -e`.
exit_of() {
  local s=0
  "$@" >/dev/null 2>"$rt/stderr" || s=$?
  echo "$s"
}

python3 "$render" "$rplan" --wave 1 --task api --out "$rt/api.md" >"$rt/stdout"
[[ "$(cat "$rt/stdout")" == "$rt/api.md" ]] || {
  echo "render-prompt should print the written path, got: $(cat "$rt/stdout")" >&2
  exit 1
}
require_text "$rt/api.md" "Your task: api"
require_text "$rt/api.md" "pytest -q | tail -1"
require_text "$rt/api.md" '"task": "api",'
refute_text "$rt/api.md" "{{"

# An empty Constraints cell, no contract, no verify command, and no baseline
# all take their documented defaults.
python3 "$render" "$rplan" --wave 1 --task ui --out "$rt/ui.md" >/dev/null
# Multi-line anchors go through python: grep -F treats a newline in its pattern
# as a list of alternatives, so a grep here would pass on any one line.
python3 - "$rt/ui.md" <<'PY' || {
import sys
text = open(sys.argv[1], encoding="utf-8").read()
for want in (
    "verbatim from the wave table:\n\nnone recorded\n",
    "migration a prior wave already landed:\n\nnone recorded\n",
    "actually prints:\n\n    absent\n",
    "its exit status on the first line:\n\nabsent\n",
):
    if want not in text:
        sys.exit(f"ui render lacks {want!r}")
PY
  echo "the ui render must carry the documented defaults" >&2
  exit 1
}

# Data crosses verbatim. A PRIOR report that quotes a placeholder is not an
# unfilled placeholder and is never substituted again.
printf 'earlier report mentions {{NOT_A_PLACEHOLDER}} and {{TASK}}\n' >"$rt/prior.md"
[[ "$(exit_of python3 "$render" "$rplan" --wave 1 --task api --prior "$rt/prior.md" --out "$rt/prior-out.md")" == 0 ]] || {
  echo "a {{...}} inside --prior must render, not fail: $(cat "$rt/stderr")" >&2
  exit 1
}
require_text "$rt/prior-out.md" "earlier report mentions {{NOT_A_PLACEHOLDER}} and {{TASK}}"

# Caller notes carry issue text, so a placeholder in them is data: only {{TASK}}
# fills, and everything else crosses verbatim, never rescanned (F-r1-authz-01).
python3 "$render" "$rplan" --wave 1 --task api --caller-notes "$fixtures/render-caller-ok.md" --out "$rt/caller.md" >/dev/null
require_text "$rt/caller.md" "Caller preamble for api: stay inside the issue branch."
[[ "$(exit_of python3 "$render" "$rplan" --wave 1 --task api --caller-notes "$fixtures/render-caller-unfilled.md" --out "$rt/unfilled.md")" == 0 ]] || {
  echo "caller notes holding {{ISSUE}} must render, not fail: $(cat "$rt/stderr")" >&2
  exit 1
}
require_text "$rt/unfilled.md" "Work issue {{ISSUE}} only."

# The finding's repro: a criterion quoting {{BASELINE}} and {{CALLER_NOTES}}
# stays byte-for-byte, and the baseline text lands only where the template's
# own {{BASELINE}} sits.
crit='- [ ] the script fills {{BASELINE}} from a file and {{CALLER_NOTES}} from another'
printf '%s\n' "$crit" >"$rt/crit-notes.md"
printf 'exit: 1\nFAILED test_x\n' >"$rt/crit-baseline.md"
[[ "$(exit_of python3 "$render" "$rplan" --wave 1 --task api --caller-notes "$rt/crit-notes.md" --baseline "$rt/crit-baseline.md" --out "$rt/crit.md")" == 0 ]] || {
  echo "quoted placeholders in caller notes must render: $(cat "$rt/stderr")" >&2
  exit 1
}
grep -Fxq -- "$crit" "$rt/crit.md" || {
  echo "the criterion line must cross byte-for-byte" >&2
  exit 1
}
[[ "$(grep -c 'FAILED test_x' "$rt/crit.md")" == 1 ]] || {
  echo "the baseline must appear once, at the template's own {{BASELINE}}" >&2
  exit 1
}
# {{BASELINE}} alone is the case the old rescan spliced silently; the line above
# also trips the old unfilled-{{CALLER_NOTES}} exit, so it can't catch a splice.
crit_b='- [ ] the script fills {{BASELINE}} from a file'
printf '%s\n' "$crit_b" >"$rt/critb-notes.md"
python3 "$render" "$rplan" --wave 1 --task api --caller-notes "$rt/critb-notes.md" --baseline "$rt/crit-baseline.md" --out "$rt/critb.md" >/dev/null
grep -Fxq -- "$crit_b" "$rt/critb.md" || {
  echo "a criterion quoting only {{BASELINE}} must cross byte-for-byte, not take the baseline" >&2
  exit 1
}

# A placeholder the script does not know, as a template edit would add one.
awk '/^Your task: \{\{TASK\}\}$/ && !done { print "{{NEW_THING}}"; done=1 } { print }' \
  divvy-up/references/worker-prompt.md >"$rt/template.md"
[[ "$(exit_of python3 "$render" "$rplan" --wave 1 --task api --template "$rt/template.md" --out "$rt/new.md")" == 1 ]] || {
  echo "a template placeholder the script cannot fill must exit 1" >&2
  exit 1
}
grep -Fq '{{NEW_THING}}' "$rt/stderr" || {
  echo "the unknown placeholder must be named on stderr: $(cat "$rt/stderr")" >&2
  exit 1
}

# A label outside the wave, and one repeated inside it, must not render a row.
[[ "$(exit_of python3 "$render" "$rplan" --wave 1 --task nope --out "$rt/nope.md")" == 1 ]] || {
  echo "a task absent from the wave must exit 1" >&2
  exit 1
}
[[ "$(exit_of python3 "$render" "$rplan" --wave 0 --task api --out "$rt/nope.md")" == 1 ]] || {
  echo "a task in a different wave must exit 1" >&2
  exit 1
}
sed 's/^| 1 | ui |/| 1 | api |/; s#src/ui/#src/ui2/#' "$rplan" >"$rt/dup-plan.md"
[[ "$(exit_of python3 "$render" "$rt/dup-plan.md" --wave 1 --task api --out "$rt/dup.md")" == 1 ]] || {
  echo "a task repeated in its wave must exit 1" >&2
  exit 1
}

# --out inside the work tree would read as an unowned write at Step 6. The
# repo's .git is where a run directory lives, so it stays allowed.
[[ "$(exit_of python3 "$render" "$rplan" --wave 1 --task api --out "$PWD/tmp-render.md")" == 1 ]] || {
  rm -f "$PWD/tmp-render.md"
  echo "--out inside the work tree must exit 1" >&2
  exit 1
}
[[ ! -e "$PWD/tmp-render.md" ]] || {
  rm -f "$PWD/tmp-render.md"
  echo "a refused --out must not leave a file behind" >&2
  exit 1
}
# The check follows --out, not the cwd: an orchestrator often runs from outside
# the tree it renders into.
outside_cwd="$(mktemp -d)"
tree_here="$PWD"
[[ "$(cd "$outside_cwd" && exit_of python3 "$tree_here/$render" "$tree_here/$rplan" --wave 1 --task api --out "$tree_here/tmp-render-cwd.md")" == 1 ]] || {
  rm -f "$tree_here/tmp-render-cwd.md"
  rm -rf "$outside_cwd"
  echo "--out inside the work tree must exit 1 even when the cwd is outside it" >&2
  exit 1
}
rm -rf "$outside_cwd"
[[ ! -e "$tree_here/tmp-render-cwd.md" ]] || {
  rm -f "$tree_here/tmp-render-cwd.md"
  echo "a refused --out must not leave a file behind when the cwd is outside the tree" >&2
  exit 1
}
git_common="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
[[ "$(exit_of python3 "$render" "$rplan" --wave 1 --task api --out "$git_common/render-test.md")" == 0 ]] || {
  rm -f "$git_common/render-test.md"
  echo "--out under the repo's .git must render: $(cat "$rt/stderr")" >&2
  exit 1
}
rm -f "$git_common/render-test.md"

[[ "$(exit_of python3 "$render" "$rt/no-such-plan.md" --wave 1 --task api --out "$rt/x.md")" == 3 ]] || {
  echo "a missing plan file must exit 3" >&2
  exit 1
}

# The fixture was filled by hand from the Template block under the Placeholders
# rules, so this compares the script against the rules rather than against
# itself.
python3 "$render" "$rplan" --wave 1 --task api --verify-cmd 'bash t.sh' \
  --contract "$fixtures/render-contract.md" --baseline "$fixtures/render-baseline.txt" \
  --out "$rt/api-full.md" >/dev/null
cmp -s "$rt/api-full.md" "$fixtures/render-api-expected.md" || {
  echo "the api render differs from the hand-filled fixture:" >&2
  diff "$rt/api-full.md" "$fixtures/render-api-expected.md" >&2 || true
  exit 1
}

# --- wave-snapshot cases (#395) ---
# Step 5's snapshot and Step 6's derivation and revert used to be git the
# orchestrator typed by hand, pinned only by their wording. These run the
# script on throwaway repos, so an edit that keeps the strings and breaks the
# steps between them fails here.
snap="$repo_root/divvy-up/scripts/wave-snapshot.py"
# Steps 5 and 6 call the script for every part of the procedure, so a step
# that drifts back to hand-typed git loses one of these.
require_text divvy-up/SKILL.md "wave-snapshot.py record --out PROMPT_DIR/wave-N.json"
require_text divvy-up/SKILL.md "wave-snapshot.py changed PROMPT_DIR/wave-N.json > PROMPT_DIR/wave-N.changed && divvy-up/scripts/check-waves.py owners <PLAN> --wave N < PROMPT_DIR/wave-N.changed"
require_text divvy-up/SKILL.md "\`owners\` exits 0 on empty input, so a \`changed\` that failed"
require_text divvy-up/SKILL.md "run \`changed\` before the pass and again after it, and keep the lines new in the second run"
require_text divvy-up/SKILL.md "A non-zero exit from either \`changed\` run stops the run the way a format-command error naming no derived path stops it"
require_text divvy-up/SKILL.md "wave-snapshot.py revert PROMPT_DIR/wave-N.json --plan <PLAN> --wave N --task <LABEL>"
require_text divvy-up/SKILL.md "again with \`wave-snapshot.py record\` into a new file in PROMPT_DIR"
require_text divvy-up/SKILL.md "[scripts/wave-snapshot.py](scripts/wave-snapshot.py)"
require_text divvy-up/SKILL.md "The script hashes with \`--no-filters\`, so a clean filter or an eol rule cannot normalize the recorded bytes"
require_text divvy-up/SKILL.md "An untracked symlink is recorded by its link text, the way git stores one"
require_text divvy-up/SKILL.md "applying by hand the per-path case \`revert\` applies"
require_text divvy-up/README.md "wave-snapshot.py        # records a wave's base and manifest"
require_text _maintenance/divvy-up/RATIONALE.md "run through \`scripts/wave-snapshot.py\`"
require_text _maintenance/divvy-up/RATIONALE.md "The scope stops at #344's boundary"
ws="$tmp/wave-snapshot"
mkdir -p "$ws"

# A fresh repo with identity and signing set locally, because `git stash
# create` writes a commit and the script runs plain `git`.
snap_repo() {
  local r="$1"
  git init -q "$r"
  git -C "$r" config user.name divvy-smoke
  git -C "$r" config user.email divvy-smoke@example.invalid
  git -C "$r" config commit.gpgsign false
  local f
  for f in t.txt peer.txt fmt.txt; do echo "$f base" > "$r/$f"; done
  git -C "$r" add t.txt peer.txt fmt.txt
  git -C "$r" commit -qm base
}

snap_plan="$ws/plan.md"
cat > "$snap_plan" <<'PLAN'
## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
| --- | --- | --- | --- | --- | --- |
| 1 | a | m.txt, t.txt, made.txt | haiku | done | |
| 1 | b | peer.txt, peer-new.txt | haiku | done | |
PLAN

snap_case_clean_base() {
  local r="$ws/clean"
  snap_repo "$r"
  (cd "$r" && python3 "$snap" record --out "$ws/clean.json") || {
    echo "wave-snapshot: record on a clean tree must exit 0" >&2
    exit 1
  }
  local base
  base="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["wave_base"])' "$ws/clean.json")"
  [[ "$base" == "$(git -C "$r" rev-parse HEAD)" ]] || {
    echo "wave-snapshot: on a clean tree WAVE_BASE must be HEAD, got: $base" >&2
    exit 1
  }
}

snap_case_dirty_base() {
  local r="$ws/dirty"
  snap_repo "$r"
  # A stash entry already on the list, so an accidental `stash push` shows.
  echo stashed > "$r/t.txt"
  git -C "$r" stash push -q -m pre-existing
  echo "dirty bytes" > "$r/t.txt"
  echo "untracked bytes" > "$r/u.txt"
  local status_before stash_before
  status_before="$(git -C "$r" status --porcelain)"
  stash_before="$(git -C "$r" stash list)"
  (cd "$r" && python3 "$snap" record --out "$ws/dirty.json") || {
    echo "wave-snapshot: record on a dirty tree must exit 0" >&2
    exit 1
  }
  [[ "$(git -C "$r" status --porcelain)" == "$status_before" ]] || {
    echo "wave-snapshot: record changed git status --porcelain" >&2
    exit 1
  }
  [[ "$(git -C "$r" stash list)" == "$stash_before" ]] || {
    echo "wave-snapshot: record changed git stash list" >&2
    exit 1
  }
  local base blob
  base="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["wave_base"])' "$ws/dirty.json")"
  [[ "$base" != "$(git -C "$r" rev-parse HEAD)" && "$(git -C "$r" cat-file -t "$base")" == commit ]] || {
    echo "wave-snapshot: on a dirty tree WAVE_BASE must be a stash-create commit, not HEAD, got: $base" >&2
    exit 1
  }
  [[ "$(git -C "$r" show "$base:t.txt")" == "dirty bytes" ]] || {
    echo "wave-snapshot: the dirty-tree WAVE_BASE must hold the working tree's tracked bytes" >&2
    exit 1
  }
  blob="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["untracked"]["u.txt"])' "$ws/dirty.json")"
  [[ "$(git -C "$r" cat-file -p "$blob")" == "untracked bytes" ]] || {
    echo "wave-snapshot: the manifest must map u.txt to a stored blob of its bytes" >&2
    exit 1
  }
}

# Decision 12: wave 1 leaves t.txt at ` M`, a wave-2 worker rewrites it, and
# the status line never moves.
snap_case_decision_12() {
  local r="$ws/d12"
  snap_repo "$r"
  echo "wave 1" > "$r/t.txt"
  (cd "$r" && python3 "$snap" record --out "$ws/d12.json")
  [[ -z "$(cd "$r" && python3 "$snap" changed "$ws/d12.json")" ]] || {
    echo "wave-snapshot: changed must be empty right after record" >&2
    exit 1
  }
  local status_before
  status_before="$(git -C "$r" status --porcelain)"
  echo "wave 2" > "$r/t.txt"
  [[ "$(git -C "$r" status --porcelain)" == "$status_before" ]] || {
    echo "wave-snapshot: decision 12 setup must leave the status line unchanged" >&2
    exit 1
  }
  [[ "$(cd "$r" && python3 "$snap" changed "$ws/d12.json")" == "t.txt" ]] || {
    echo "wave-snapshot: decision 12: a ' M' file rewritten in wave 2 must appear in changed" >&2
    exit 1
  }
}

# Decision 15 and the falsifier's first perturbation: same `?? new.txt` line,
# same name, different bytes.
snap_case_decision_15() {
  local r="$ws/d15"
  snap_repo "$r"
  echo "wave 1" > "$r/new.txt"
  (cd "$r" && python3 "$snap" record --out "$ws/d15.json")
  [[ -z "$(cd "$r" && python3 "$snap" changed "$ws/d15.json")" ]] || {
    echo "wave-snapshot: decision 15: an untracked file left untouched must not appear in changed" >&2
    exit 1
  }
  local status_before
  status_before="$(git -C "$r" status --porcelain)"
  echo "wave 2" > "$r/new.txt"
  [[ "$(git -C "$r" status --porcelain)" == "$status_before" ]] || {
    echo "wave-snapshot: decision 15 setup must leave the ?? line unchanged" >&2
    exit 1
  }
  [[ "$(cd "$r" && python3 "$snap" changed "$ws/d15.json")" == "new.txt" ]] || {
    echo "wave-snapshot: decision 15: an untracked file rewritten in wave 2 must appear in changed" >&2
    exit 1
  }
}

# The falsifier's second perturbation: a new mtime with the same bytes.
snap_case_touch() {
  local r="$ws/touch"
  snap_repo "$r"
  (cd "$r" && python3 "$snap" record --out "$ws/touch.json")
  touch -t 203001010000 "$r/t.txt"
  [[ -z "$(cd "$r" && python3 "$snap" changed "$ws/touch.json")" ]] || {
    echo "wave-snapshot: a touched tracked file with unchanged bytes must not appear in changed" >&2
    exit 1
  }
}

# Decision 21: the manifest restores bytes a worker overwrote or deleted.
# Takes the script so the -w mutation below can run it against a copy;
# returns non-zero rather than exiting, so that case can assert the failure.
snap_revert_restores() {
  local script="$1" r="$2"
  snap_repo "$r"
  echo "manifest bytes $r" > "$r/m.txt"
  cp "$r/m.txt" "$r.orig"
  (cd "$r" && python3 "$script" record --out "$r.json") || return 1
  echo "clobbered" > "$r/m.txt"
  (cd "$r" && python3 "$script" revert "$r.json" --plan "$snap_plan" --wave 1 --task a) >/dev/null 2>&1 || return 1
  cmp -s "$r/m.txt" "$r.orig" || return 1
  rm "$r/m.txt"
  (cd "$r" && python3 "$script" revert "$r.json" --plan "$snap_plan" --wave 1 --task a) >/dev/null 2>&1 || return 1
  cmp -s "$r/m.txt" "$r.orig" || return 1
}

snap_case_decision_21() {
  snap_revert_restores "$snap" "$ws/d21" || {
    echo "wave-snapshot: decision 21: revert must restore an overwritten and a deleted manifest file byte for byte" >&2
    exit 1
  }
}

# revert takes only task a's paths: its created file goes, its tracked edit
# goes back, and task b's edits stay byte for byte.
snap_case_revert_scope() {
  local r="$ws/scope"
  snap_repo "$r"
  (cd "$r" && python3 "$snap" record --out "$ws/scope.json")
  echo "a edit" > "$r/t.txt"
  echo "a made" > "$r/made.txt"
  echo "b edit" > "$r/peer.txt"
  echo "b made" > "$r/peer-new.txt"
  cp "$r/peer.txt" "$ws/scope-peer.orig"
  cp "$r/peer-new.txt" "$ws/scope-peer-new.orig"
  (cd "$r" && python3 "$snap" revert "$ws/scope.json" --plan "$snap_plan" --wave 1 --task a >/dev/null) || {
    echo "wave-snapshot: revert --task a must exit 0" >&2
    exit 1
  }
  [[ ! -e "$r/made.txt" ]] || {
    echo "wave-snapshot: revert must delete an untracked file the task created" >&2
    exit 1
  }
  [[ "$(cat "$r/t.txt")" == "t.txt base" ]] || {
    echo "wave-snapshot: revert must restore a tracked file the task changed" >&2
    exit 1
  }
  cmp -s "$r/peer.txt" "$ws/scope-peer.orig" && cmp -s "$r/peer-new.txt" "$ws/scope-peer-new.orig" || {
    echo "wave-snapshot: revert --task a must leave task b's paths untouched" >&2
    exit 1
  }
}

# Decision 29: a format-pass write outside every task, then a fresh record,
# leaves the retry's derivation holding only what the retry wrote.
snap_case_decision_29() {
  local r="$ws/d29"
  snap_repo "$r"
  (cd "$r" && python3 "$snap" record --out "$ws/d29-1.json")
  echo "a try 1" > "$r/t.txt"
  (cd "$r" && python3 "$snap" revert "$ws/d29-1.json" --plan "$snap_plan" --wave 1 --task a >/dev/null)
  echo "formatted" > "$r/fmt.txt"
  (cd "$r" && python3 "$snap" record --out "$ws/d29-2.json")
  echo "a try 2" > "$r/made.txt"
  local got
  got="$(cd "$r" && python3 "$snap" changed "$ws/d29-2.json")"
  [[ "$got" == "made.txt" ]] || {
    echo "wave-snapshot: decision 29: changed after a fresh record must list only the retry's write, got: $got" >&2
    exit 1
  }
}

snap_case_in_tree_out() {
  local r="$ws/intree"
  snap_repo "$r"
  local s=0
  (cd "$r" && python3 "$snap" record --out "$r/snap.json") 2>/dev/null || s=$?
  [[ "$s" == 1 ]] || {
    echo "wave-snapshot: record --out inside the work tree must exit 1, got $s" >&2
    exit 1
  }
  [[ ! -e "$r/snap.json" && -z "$(git -C "$r" status --porcelain)" ]] || {
    echo "wave-snapshot: a refused record --out must write nothing" >&2
    exit 1
  }
}

snap_case_bad_snapshot() {
  local r="$ws/bad"
  snap_repo "$r"
  echo "not json" > "$ws/bad.json"
  local s=0
  (cd "$r" && python3 "$snap" changed "$ws/bad.json") 2>/dev/null || s=$?
  [[ "$s" == 3 ]] || {
    echo "wave-snapshot: an unreadable snapshot file must exit 3, got $s" >&2
    exit 1
  }
}

# Dropping -w leaves a manifest of hashes with no bytes behind them, so the
# decision 21 revert has to fail against a copy of the script without it.
snap_case_no_w_mutation() {
  local mut="$ws/mut"
  mkdir -p "$mut"
  cp "$repo_root/divvy-up/scripts/check-waves.py" "$mut/"
  sed 's/hash-object -w/hash-object/g' "$repo_root/divvy-up/scripts/wave-snapshot.py" > "$mut/wave-snapshot.py"
  ! grep -Fq -- "hash-object -w" "$mut/wave-snapshot.py" && grep -Fq -- "hash-object" "$mut/wave-snapshot.py" || {
    echo "wave-snapshot: the -w mutation did not apply to the scratch copy" >&2
    exit 1
  }
  if snap_revert_restores "$mut/wave-snapshot.py" "$ws/mut-repo"; then
    echo "wave-snapshot: the decision 21 revert passed with -w dropped, so it no longer tests -w" >&2
    exit 1
  fi
}

# PR #454 review: `owners` exits 0 on empty input, so a `changed` that fails
# upstream of a pipe passes the gate in any shell without pipefail. Runs Step
# 6's own command line, lifted from SKILL.md, under plain `sh`.
snap_case_gate_propagates() {
  local r="$ws/gate" pd="$ws/gate-prompt"
  snap_repo "$r"
  mkdir -p "$pd"
  local line
  line="$(grep -F 'wave-snapshot.py changed PROMPT_DIR/wave-N.json' divvy-up/SKILL.md | grep -F 'check-waves.py owners' | sed 's/^ *//')"
  [[ -n "$line" ]] || {
    echo "wave-snapshot: Step 6's ownership command line is missing from SKILL.md" >&2
    exit 1
  }
  line="${line//python3 <skill-dir>\/scripts\//python3 $repo_root/divvy-up/scripts/}"
  line="${line//divvy-up\/scripts\/check-waves.py/python3 $repo_root/divvy-up/scripts/check-waves.py}"
  line="${line//PROMPT_DIR/$pd}"
  line="${line//<PLAN>/$snap_plan}"
  line="${line//wave-N/wave-1}"
  line="${line//--wave N/--wave 1}"
  # Unreadable snapshot: the gate line must fail.
  echo "not json" > "$pd/wave-1.json"
  if (cd "$r" && sh -c "$line") >/dev/null 2>&1; then
    echo "wave-snapshot: Step 6's ownership line exited 0 on an unreadable snapshot: $line" >&2
    exit 1
  fi
  # Control: the pipe shape it replaced passes the same input, or this case
  # tests nothing.
  if ! (cd "$r" && sh -c "python3 $snap changed $pd/wave-1.json | python3 $repo_root/divvy-up/scripts/check-waves.py owners $snap_plan --wave 1") >/dev/null 2>&1; then
    echo "wave-snapshot: the piped ownership line should exit 0 on an unreadable snapshot; the control no longer reproduces" >&2
    exit 1
  fi
  # A real snapshot and an owned write still pass and name the owner.
  (cd "$r" && python3 "$snap" record --out "$pd/wave-1.json")
  echo "b edit" > "$r/peer.txt"
  # Status and output checked apart: a line that prints `b` and then exits
  # non-zero rejects every valid wave, and a string compare alone misses it.
  local out
  out="$(cd "$r" && sh -c "$line")" || {
    echo "wave-snapshot: Step 6's ownership line must exit 0 on a wave whose writes are owned: $line" >&2
    exit 1
  }
  [[ "$out" == "b" ]] || {
    echo "wave-snapshot: Step 6's ownership line must name the owner b, got: $out" >&2
    exit 1
  }
  # An unowned write must fail the line, or an edit that swallows owners'
  # status (a trailing `| tee`, say) passes every wave.
  echo "nobody's" > "$r/fmt.txt"
  if (cd "$r" && sh -c "$line") >/dev/null 2>&1; then
    echo "wave-snapshot: Step 6's ownership line must exit non-zero on a write no task owns: $line" >&2
    exit 1
  fi
}

# PR #454 review: a task that swaps a manifest file for a symlink to a peer's
# file must not turn the restore into a write through the link.
snap_case_symlink_restore() {
  local r="$ws/symlink"
  snap_repo "$r"
  echo "snapshot bytes" > "$r/m.txt"
  cp "$r/m.txt" "$ws/symlink-m.orig"
  cp "$r/peer.txt" "$ws/symlink-peer.orig"
  (cd "$r" && python3 "$snap" record --out "$ws/symlink.json")
  rm "$r/m.txt"
  ln -s peer.txt "$r/m.txt"
  (cd "$r" && python3 "$snap" revert "$ws/symlink.json" --plan "$snap_plan" --wave 1 --task a >/dev/null) || {
    echo "wave-snapshot: revert over a symlinked manifest file must exit 0" >&2
    exit 1
  }
  [[ -f "$r/m.txt" && ! -L "$r/m.txt" ]] && cmp -s "$r/m.txt" "$ws/symlink-m.orig" || {
    echo "wave-snapshot: revert must restore m.txt as a regular file holding its recorded bytes" >&2
    exit 1
  }
  cmp -s "$r/peer.txt" "$ws/symlink-peer.orig" || {
    echo "wave-snapshot: revert wrote through m.txt's symlink into task b's peer.txt" >&2
    exit 1
  }
}

# PR #454 review: a clean filter or eol conversion makes hash-object store
# normalized bytes, so a CRLF file came back as LF and a CRLF-to-LF rewrite
# never showed in changed.
snap_case_eol_filters() {
  local r="$ws/eol"
  snap_repo "$r"
  printf '*.txt text eol=crlf\n' > "$r/.gitattributes"
  git -C "$r" add .gitattributes
  git -C "$r" commit -qm attrs
  printf 'original\r\n' > "$r/m.txt"
  cp "$r/m.txt" "$ws/eol-m.orig"
  (cd "$r" && python3 "$snap" record --out "$ws/eol.json")
  # Unchanged right after record, or a filtered comparison hash (LF) against
  # the unfiltered stored one (CRLF) flags every untouched CRLF file.
  [[ -z "$(cd "$r" && python3 "$snap" changed "$ws/eol.json")" ]] || {
    echo "wave-snapshot: an untouched CRLF file under eol=crlf must not appear in changed" >&2
    exit 1
  }
  printf 'original\n' > "$r/m.txt"
  [[ "$(cd "$r" && python3 "$snap" changed "$ws/eol.json")" == "m.txt" ]] || {
    echo "wave-snapshot: a CRLF-to-LF rewrite of an untracked file must appear in changed" >&2
    exit 1
  }
  echo "clobbered" > "$r/m.txt"
  (cd "$r" && python3 "$snap" revert "$ws/eol.json" --plan "$snap_plan" --wave 1 --task a >/dev/null)
  cmp -s "$r/m.txt" "$ws/eol-m.orig" || {
    echo "wave-snapshot: revert under eol=crlf must restore m.txt byte for byte" >&2
    exit 1
  }
}

# PR #454 review: an untracked symlink in the snapshot is a link, not its
# target's bytes. A peer rewriting the target leaves the link unchanged, and
# reverting the link's owner keeps it a link.
snap_case_link_kept() {
  local r="$ws/link-kept"
  snap_repo "$r"
  ln -s peer.txt "$r/m.txt"
  (cd "$r" && python3 "$snap" record --out "$ws/link-kept.json")
  echo "b edit" > "$r/peer.txt"
  local got
  got="$(cd "$r" && python3 "$snap" changed "$ws/link-kept.json")"
  [[ "$got" == "peer.txt" ]] || {
    echo "wave-snapshot: a peer rewriting a link's target must not list the link, got: $got" >&2
    exit 1
  }
  (cd "$r" && python3 "$snap" revert "$ws/link-kept.json" --plan "$snap_plan" --wave 1 --task a >/dev/null)
  [[ -L "$r/m.txt" && "$(readlink "$r/m.txt")" == "peer.txt" && "$(cat "$r/peer.txt")" == "b edit" ]] || {
    echo "wave-snapshot: revert of the link's owner must leave m.txt a symlink to peer.txt and peer.txt as task b left it" >&2
    exit 1
  }
}

# A recorded link a worker swapped for a regular file comes back as the link,
# even when the file holds exactly the link text.
snap_case_link_restored() {
  local r="$ws/link-restored"
  snap_repo "$r"
  ln -s peer.txt "$r/m.txt"
  (cd "$r" && python3 "$snap" record --out "$ws/link-restored.json")
  rm "$r/m.txt"
  printf 'peer.txt' > "$r/m.txt"
  [[ "$(cd "$r" && python3 "$snap" changed "$ws/link-restored.json")" == "m.txt" ]] || {
    echo "wave-snapshot: a link replaced by a regular file must appear in changed" >&2
    exit 1
  }
  (cd "$r" && python3 "$snap" revert "$ws/link-restored.json" --plan "$snap_plan" --wave 1 --task a >/dev/null)
  [[ -L "$r/m.txt" && "$(readlink "$r/m.txt")" == "peer.txt" ]] || {
    echo "wave-snapshot: revert must restore a recorded link as a symlink to peer.txt" >&2
    exit 1
  }
}

# Red-team on PR #454: a restore that cannot write under a read-only parent
# reports one line naming the path and exits 1, never a traceback. Covers a
# link a worker re-pointed (the os.remove before the restore) and one it
# deleted (the os.symlink).
snap_case_restore_readonly() {
  local r="$ws/readonly"
  snap_repo "$r"
  mkdir "$r/sub"
  ln -s ../peer.txt "$r/sub/m.txt"
  local plan="$ws/readonly-plan.md"
  sed 's/| m.txt, t.txt, made.txt |/| sub\/, t.txt, made.txt |/' "$snap_plan" > "$plan"
  (cd "$r" && python3 "$snap" record --out "$ws/readonly.json")
  local how s
  for how in repoint delete; do
    rm "$r/sub/m.txt"
    [[ "$how" == repoint ]] && ln -s ../t.txt "$r/sub/m.txt"
    chmod 555 "$r/sub"
    s=0
    (cd "$r" && python3 "$snap" revert "$ws/readonly.json" --plan "$plan" --wave 1 --task a) >/dev/null 2>"$ws/readonly.err" || s=$?
    chmod u+w "$r/sub"
    [[ "$s" == 1 && "$(wc -l < "$ws/readonly.err" | tr -d ' ')" == 1 ]] && grep -q '^wave-snapshot: sub/m.txt: ' "$ws/readonly.err" || {
      echo "wave-snapshot: a $how-then-read-only restore must exit 1 with one line naming sub/m.txt, got exit $s: $(cat "$ws/readonly.err")" >&2
      exit 1
    }
    ln -sf ../peer.txt "$r/sub/m.txt"
  done
}

# A recorded link a worker replaced with a directory is reported, not removed.
snap_case_restore_dir() {
  local r="$ws/restore-dir"
  snap_repo "$r"
  ln -s peer.txt "$r/m.txt"
  (cd "$r" && python3 "$snap" record --out "$ws/restore-dir.json")
  rm "$r/m.txt"
  mkdir "$r/m.txt"
  echo inner > "$r/m.txt/inner"
  local s=0
  (cd "$r" && python3 "$snap" revert "$ws/restore-dir.json" --plan "$snap_plan" --wave 1 --task a) >/dev/null 2>"$ws/restore-dir.err" || s=$?
  [[ "$s" == 1 && "$(wc -l < "$ws/restore-dir.err" | tr -d ' ')" == 1 ]] && grep -q '^wave-snapshot: m.txt: ' "$ws/restore-dir.err" && ! grep -q Traceback "$ws/restore-dir.err" || {
    echo "wave-snapshot: a directory at a recorded link path must exit 1 with one line naming m.txt, got exit $s: $(cat "$ws/restore-dir.err")" >&2
    exit 1
  }
  [[ -d "$r/m.txt" && "$(cat "$r/m.txt/inner")" == inner ]] || {
    echo "wave-snapshot: revert must leave a directory at a recorded link path untouched" >&2
    exit 1
  }
}

snap_case_clean_base
snap_case_dirty_base
snap_case_decision_12
snap_case_decision_15
snap_case_touch
snap_case_decision_21
snap_case_revert_scope
snap_case_decision_29
snap_case_in_tree_out
snap_case_bad_snapshot
snap_case_no_w_mutation
snap_case_gate_propagates
snap_case_symlink_restore
snap_case_eol_filters
snap_case_link_kept
snap_case_link_restored
snap_case_restore_readonly
snap_case_restore_dir
# --- end wave-snapshot cases ---

echo "divvy-up smoke: OK"
