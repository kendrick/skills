#!/usr/bin/env bash
# Pin the wave-plan skill's load-bearing behavior. Many of these are refutes:
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

require_file wave-plan/SKILL.md
require_file wave-plan/README.md
require_file wave-plan/references/worker-prompt.md
require_file wave-plan/scripts/check-waves.py
require_file _maintenance/wave-plan/RATIONALE.md
require_file _maintenance/wave-plan/EVALS.md
require_file tests/fixtures/wave-plan/waves-good.md
require_file tests/fixtures/wave-plan/waves-overlap.md
require_file tests/fixtures/wave-plan/waves-glob.md
require_file tests/fixtures/wave-plan/waves-model.md

[[ "$(find wave-plan -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "wave-plan/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. Manual invocation is deliberate: a misfire during ordinary
# planning spends a whole fan-out, while a missed trigger costs the user one
# word.
require_text wave-plan/SKILL.md "name: wave-plan"
require_text wave-plan/SKILL.md "disable-model-invocation: true"
require_text wave-plan/SKILL.md "argument-hint: '[plan path] [--max N] [--commit]'"

# A description that summarizes the workflow becomes a shortcut the model takes
# instead of reading the body, which is how a multi-step skill collapses.
refute_text wave-plan/SKILL.md "description: \"Step 1"

# --- The safety property. These are the assertions the whole design rests on. ---

# A soft overlap check would let a fan-out run on top of an unproven wave, and
# the lost write it produces reports as nothing at all.
require_text wave-plan/SKILL.md "A non-zero exit is a hard stop, not a warning."

# One dispatch per message is the serialization the wave exists to remove, and
# it looks identical in the transcript to the real thing.
require_text wave-plan/SKILL.md "in a SINGLE message so they run concurrently"

# Ownership proved before dispatch is what makes the wave safe to fan out at
# all; proving it after (or not at all) is the "watch out for conflicts" note
# this design replaces.
require_text wave-plan/SKILL.md "proved by a script before anything is dispatched"

# A retry onto a half-written tree hands the second attempt the first one's
# leftovers to debug instead of the actual task.
require_text wave-plan/SKILL.md "Revert before the retry"

# Two rungs up on one failure is a second guess stacked on the first; the
# design allows exactly one rung, once.
require_text wave-plan/SKILL.md "one rung up"

# An omitted model inherits the session's, usually the most expensive one
# available, and the routing savings evaporate while the run still looks fine.
require_text wave-plan/SKILL.md "Name each dispatch's model explicitly."

# The wave-base rule: ownership derives against a recorded baseline, not the
# whole working tree. This was a defect found and fixed during the build, and
# losing it silently fails every task from wave 2 onward.
require_text wave-plan/SKILL.md "against WAVE_BASE, not against the working tree as a whole"

# The four rungs of the ladder. Losing one silently collapses routing onto the
# rungs that remain.
require_text wave-plan/SKILL.md "haiku"
require_text wave-plan/SKILL.md "sonnet"
require_text wave-plan/SKILL.md "opus"
require_text wave-plan/SKILL.md "fable"

# The guild handoff. Without it, a repo that already has `.agent-guild/` gets
# dispatched into twice, on two different ownership derivations of the same
# plan.
require_text wave-plan/SKILL.md "/agent-guild:job"

# Reference contracts: the six placeholders every dispatch substitutes, and the
# JSON-only rule that keeps the gate from having to arbitrate between a report
# and a summary paragraph sitting next to it.
require_text wave-plan/references/worker-prompt.md "{{TASK}}"
require_text wave-plan/references/worker-prompt.md "{{OWNS}}"
require_text wave-plan/references/worker-prompt.md "{{CONTRACT}}"
require_text wave-plan/references/worker-prompt.md "{{DONE_WHEN}}"
require_text wave-plan/references/worker-prompt.md "{{VERIFY_CMD}}"
require_text wave-plan/references/worker-prompt.md "{{PRIOR}}"
require_text wave-plan/references/worker-prompt.md "Your final message is exactly one fenced json block and nothing else"

# Maintenance ledger. A rationale doc without its section headings is prose
# nobody can navigate under time pressure.
require_text _maintenance/wave-plan/RATIONALE.md "## Decision Ledger"
require_text _maintenance/wave-plan/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/wave-plan/RATIONALE.md "## Known Limitations"
require_text README.md "npx skills add kendrick/skills --skill wave-plan"

# Provenance on the vendored predicate. Losing this line is how a local edit
# silently forks from the upstream that owns the semantics.
require_text wave-plan/scripts/check-waves.py "Vendored verbatim from"
require_text wave-plan/scripts/check-waves.py "Upstream is authoritative"

# --- The cut features. Each sounds reasonable; each was refused for a reason
# recorded in the RATIONALE ledger. ---

# Run-state tracking is what makes agent-guild the guild; a parallel ledger
# here would just restate the `## Waves` table until the two drifted apart.
refute_text wave-plan/SKILL.md "run directory"
refute_text wave-plan/SKILL.md "ledger"

# Globs own nothing; the vendored predicate rejects them outright because a
# pattern can claim territory no file yet occupies.
refute_text wave-plan/SKILL.md "glob"

# A "be careful" note is exactly the failure mode separate waves exist to
# remove: it asks a human to catch what a script should have caught first.
refute_text wave-plan/SKILL.md "be careful"

# Per-tier retry counters are guild machinery for a skill with no run state to
# hold them; the retry rule here is fixed at one re-dispatch, one rung up.
refute_text wave-plan/SKILL.md "retry counter"

# --- Functional checks. Cheap, deterministic, no subagents. ---

fixtures=tests/fixtures/wave-plan
waves=wave-plan/scripts/check-waves.py

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

echo "wave-plan smoke: OK"
