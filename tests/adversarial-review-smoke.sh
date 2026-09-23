#!/usr/bin/env bash
# Pin the adversarial-review skill's load-bearing behavior. Many of these are
# refutes: the mechanisms this design explicitly cut are all reasonable-sounding
# ideas, and a well-meaning edit is exactly how they come back.
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

require_file adversarial-review/SKILL.md
require_file adversarial-review/README.md
require_file adversarial-review/references/trigger-table.md
require_file adversarial-review/references/finder-prompt.md
require_file adversarial-review/references/verifier-prompt.md
require_file adversarial-review/assets/scope.schema.json
require_file adversarial-review/assets/finding.schema.json
require_file adversarial-review/assets/event.schema.json
require_file adversarial-review/scripts/check-territories.py
require_file adversarial-review/scripts/ledger.py
require_file _maintenance/adversarial-review/RATIONALE.md
require_file _maintenance/adversarial-review/EVALS.md
require_file tests/fixtures/adversarial-review/scope-good.json
require_file tests/fixtures/adversarial-review/scope-overlap.json
require_file tests/fixtures/adversarial-review/scope-glob.json
require_file tests/fixtures/adversarial-review/scope-backtick.json

[[ "$(find adversarial-review -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "adversarial-review/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. Model-invocation is load-bearing: `work-issue` invokes this
# skill at its Step 4, and a user-invoked skill has its description stripped
# from siblings as well as from the agent, so the Skill tool refuses that call
# (#124, RATIONALE row 34). The misfire guard the flag used to carry now sits
# at Step 2's question, pinned below.
require_text adversarial-review/SKILL.md "name: adversarial-review"
# The flag coming back would surface as a refused call in the middle of an
# unattended run, which nobody would read as a bug. Refuted on the bare key so
# `: false` fails here as loudly as `: true`.
refute_text adversarial-review/SKILL.md "disable-model-invocation"
# A description telling the agent to wait for the user is one a sibling's call
# can never satisfy, so the agent would refuse that call in prose.
refute_text adversarial-review/SKILL.md "Use ONLY when the user explicitly invokes adversarial-review."
require_text adversarial-review/SKILL.md "use code-review"
require_text adversarial-review/SKILL.md "use security-review"
require_text adversarial-review/SKILL.md "use grilling"

# A description that summarizes the workflow becomes a shortcut the model takes
# instead of reading the body, which is how a multi-stage skill collapses.
refute_text adversarial-review/SKILL.md "description: \"Step 1"

# Preflight. Each of these failed in front of the user by design; discovering
# any of them inside six parallel subagents costs six times as much.
require_text adversarial-review/SKILL.md "git rev-parse --verify"
require_text adversarial-review/SKILL.md "When it is absent, ask."
require_text adversarial-review/SKILL.md "git merge-base"
require_text adversarial-review/SKILL.md "commit or stash first"
require_text adversarial-review/SKILL.md "git rev-parse --git-path info/exclude"

# `.git` is a file, not a directory, inside a linked worktree, so a hardcoded
# `.git/info/exclude` path silently doesn't exist there and the append fails.
refute_text adversarial-review/SKILL.md ".git/info/exclude"

# Territories: literal paths, disjointness enforced by script, hard stop on
# overlap. The overlap check is what the verification gate stands on.
require_text adversarial-review/SKILL.md "check-territories.py validate"
require_text adversarial-review/SKILL.md "A non-zero exit is a hard stop, not a warning."
require_text adversarial-review/SKILL.md "Disjoint ownership, layered lenses"

# Step 2's question is the whole misfire guard now that an agent can reach the
# skill, so it has to come before the fan-out spends anything. The waiver
# lets `work-issue`'s Step 0 yes answer it, so an unattended run does not stall
# on a second prompt nobody is there to answer. The Done-when has to accept
# that answer too, or the step can never complete under a wrapper.
require_text adversarial-review/SKILL.md "Ask once, in one question, before any subagent spends a token"
# The waiver holds only up to the depth the wrapper showed (row 35). Without the
# bound, a yes to a Depth 1 forecast fans out a Depth 2 run nobody agreed to.
require_text adversarial-review/SKILL.md "A wrapping skill's confirmation answers that question on the user's behalf only where it put this review to the user at a depth at or above the one this step derived."
require_text adversarial-review/SKILL.md "a confirmation that showed a lower depth, or no depth, answers nothing, and the question is asked."
# The waiver reads its depth from a line the wrapper hands over at invocation
# (row 35). A resumed work-issue run has no conversation to read it from.
require_text adversarial-review/SKILL.md "Read that depth from the wrapper confirmation line handed over at invocation"
require_text adversarial-review/SKILL.md "- **Wrapper confirmation** — the confirmation line a wrapping skill hands over in the arguments"
# work-issue hands over its mode line verbatim, and a --deep run's line names
# --deep. Read as a flag, that token would pin Depth 2 on a resumed run whose
# own flags no longer carry it, overriding the pass-through work-issue row 95
# keys on the run's own flag.
require_text adversarial-review/SKILL.md "treat the line itself as quoted text, including any \`--deep\` it names"
# This skill prints the depth line itself, because only Step 2 knows the
# derived depth. Without it the waived run leaves no correction point in the log.
require_text adversarial-review/SKILL.md "this skill still prints the depth line and the out-of-scope list itself, marked as answered"
require_text adversarial-review/SKILL.md "and the fan-out was confirmed, or answered by a wrapping skill's confirmation that showed this review at this depth or deeper, with the depth line printed and marked as answered."
# The README told users a work-issue yes always answers the question, which
# stopped being true once the carry got a depth bound.
require_text adversarial-review/README.md "as long as the review comes out no deeper than the depth that confirmation forecast"
# A wrapper yes covers the fan-out's cost, not a scope the user never saw
# (row 36). Without the escalation route, a settled decision missing from the
# out-of-scope list comes back as a blocker and gets "fixed" unattended.
require_text adversarial-review/SKILL.md "That run is **waived**: the yes covered the fan-out's cost, given before the user saw the territories or the list the finders read."
require_text adversarial-review/SKILL.md "In a **waived** run (Step 2), REPRODUCED + blocking routes to escalation instead"
require_text adversarial-review/SKILL.md "record \`ESCALATED\` with the reason \`waived: scope not confirmed\`, and write no test, no fix, and no issue."
require_text adversarial-review/README.md "reports its findings to you rather than fixing them or filing issues"
# file-issue waits for a confirmation nobody is there to give, and an inbox
# write persists a finding the user never scoped (row 37).
require_text adversarial-review/SKILL.md "An UNVERIFIABLE finding stays in the report, recorded \`QUESTION_FILED\` with that reason and no artifact. A waived run writes nothing outside its run directory."
# The "only chance" claim is what made the waiver contradict itself (row 36).
refute_text adversarial-review/SKILL.md "the only chance to add what the conversation left off the list"

# The depth governor keeps a naive invocation from costing a full fan-out.
require_text adversarial-review/SKILL.md "Depth 1: 3 territories"
require_text adversarial-review/SKILL.md '`--fast` pins Depth 0'

# The verification gate itself.
require_text adversarial-review/SKILL.md "REPRODUCED"
require_text adversarial-review/SKILL.md "NOT_REPRODUCED"
require_text adversarial-review/SKILL.md "UNVERIFIABLE"
require_text adversarial-review/SKILL.md "Only REPRODUCED can block."
require_text adversarial-review/SKILL.md "zero UNVERIFIED"
require_text adversarial-review/SKILL.md "never the finder's reasoning"

# Disposition routing, including the rule that makes findings survive their own
# fixes.
require_text adversarial-review/SKILL.md "before** writing the fix"
require_text adversarial-review/SKILL.md "file-issue"
require_text adversarial-review/SKILL.md "inbox-to-memory"

# The round loop's rationale is load-bearing, not decoration: it is the whole
# reason the loop exists past round 1.
require_text adversarial-review/SKILL.md "introduced while fixing"
require_text adversarial-review/SKILL.md "check-territories.py intersect"
require_text adversarial-review/SKILL.md "escalation.md"

# Per-territory verdicts and the calibration signal that deliberately does not
# re-trigger a round.
require_text adversarial-review/SKILL.md "no single cross-territory verdict"
require_text adversarial-review/SKILL.md "calibration:"

# The representation row and the renumber it forced. The depth condition is the
# renumber's one live consequence, and it names `general` rather than a row
# number because the number moves: left at 6 it would have fired Depth 0 on a
# diff whose only substantive hit is the new row, and any literal breaks again on
# the next insertion.
require_text adversarial-review/references/trigger-table.md "| 6 | representation |"
require_text adversarial-review/references/trigger-table.md "| 7 | general |"
require_text adversarial-review/references/trigger-table.md "An assertion that recomputes the implementation rather than observing the result."
require_text adversarial-review/references/trigger-table.md "A unit suffix matches against the number in front of it"
require_text adversarial-review/SKILL.md 'no row above `general` matched'
refute_text adversarial-review/SKILL.md "no row above 6 matched"
refute_text adversarial-review/SKILL.md "no row above 7 matched"

# Method independence. Authorship independence alone cleared a real defect four
# rounds running, because the reproduction used the implementation's own method.
require_text adversarial-review/SKILL.md "recomputes the implementation proves the code equals itself"
require_text adversarial-review/SKILL.md "lands UNVERIFIABLE naming the method"

# The frontmatter description is the one line a person reads to learn what the
# gate is, and the one a sibling skill reads before invoking it. It shipped
# naming authorship independence alone, which row 27 quotes as the defect.
# "and by" keeps this pin off the body's own phrasing in its opening paragraph.
require_text adversarial-review/SKILL.md "and by a route the code does not take"
refute_text adversarial-review/SKILL.md "did not author it before it can block"

# The README states the same rule for a human reader. Pinned because this repo's
# documents describe each other, so the README can drift away from a SKILL.md
# that still carries the rule, and a reader trusting the README learns the old
# gate.
require_text adversarial-review/README.md "reach the value some other way than the code does"
require_text adversarial-review/references/verifier-prompt.md "measure where the value is consumed"
require_text adversarial-review/references/verifier-prompt.md "no route to the quantity except the one the code itself"
require_text adversarial-review/references/finder-prompt.md "agrees with it by construction"

# A finder with no independent route still fills `proposed_repro`: the schema
# makes it required, and a findings file that fails the contract marks the
# territory failed, so the finding would surface as UNREVIEWED rather than the
# UNVERIFIABLE the rule intends.
require_text adversarial-review/references/finder-prompt.md "finding carries a command, this one included."
refute_text adversarial-review/references/finder-prompt.md "instead of proposing a command"

# Scenario 15 grades the sixth plant, which has an independent route. Accepting
# UNVERIFIABLE there would pass the eval on the one verdict Step 5 forbids when
# a route exists.
require_text _maintenance/adversarial-review/EVALS.md "stopped short of the route that was there"

# Reference contracts.
require_text adversarial-review/references/finder-prompt.md "Verify against code."
require_text adversarial-review/references/finder-prompt.md "quoted_evidence"
require_text adversarial-review/references/finder-prompt.md "must not be run by this repo's own auditor or checker agents"
require_text adversarial-review/references/verifier-prompt.md "REPRODUCED is the verdict you failed to avoid"
require_text adversarial-review/references/verifier-prompt.md "read-only"
require_text adversarial-review/references/verifier-prompt.md "unsafe repro"
require_text adversarial-review/references/verifier-prompt.md "observed_output"
require_text adversarial-review/references/trigger-table.md "First-match by table order is the whole determinism mechanism"

# Provenance on the vendored predicate. Losing this line is how a local edit
# silently forks from the upstream that owns the semantics.
require_text adversarial-review/scripts/check-territories.py "Vendored verbatim from agent-guild"
require_text adversarial-review/scripts/check-territories.py "Upstream is authoritative"

# --- The cut features. Each sounds reasonable; each was refused for a reason
# recorded in the RATIONALE ledger. ---

# Finder quotas manufacture findings and never terminate in a multi-round loop.
refute_text adversarial-review/references/finder-prompt.md "must find at least"
refute_text adversarial-review/references/finder-prompt.md "at least one issue"

# Personas were replaced by suspicion classes. Their checklists were mined; the
# identities were not kept.
refute_text adversarial-review/references/finder-prompt.md "You are a"
refute_text adversarial-review/SKILL.md "persona"

# Severity promotion on agreement is meaningless once territories are disjoint.
refute_text adversarial-review/SKILL.md "severity is upgraded"
refute_text adversarial-review/SKILL.md "agree on a finding"

# Globs own nothing; the vendored predicate rejects them outright.
refute_text adversarial-review/SKILL.md "glob"

# A finder that writes a verdict paragraph reintroduces the parsing gap the
# JSON-only contract closes.
refute_text adversarial-review/references/finder-prompt.md "verdict"

# The rule gates which verdict a verifier may record. A field holding the
# verifier's own account of its independence has nothing checking that account.
refute_text adversarial-review/assets/event.schema.json "independent_route"

# A reserved token in `proposed_repro` would say what the claim already says,
# and split the field into two types for every later reader of the ledger.
refute_text adversarial-review/references/finder-prompt.md "NO_INDEPENDENT_ROUTE"
refute_text adversarial-review/assets/finding.schema.json "NO_INDEPENDENT_ROUTE"

require_text _maintenance/adversarial-review/RATIONALE.md "## Decision Ledger"
require_text _maintenance/adversarial-review/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/adversarial-review/RATIONALE.md "## Known Limitations"
# The root README carries this skill's own install flag, in the map
# table's third column. The command form around it is pinned once, in
# repo-docs-smoke.sh, so this does not re-pin it twelve times.
require_text README.md "--skill adversarial-review"

# --- Functional checks. Cheap, deterministic, no subagents. ---

fixtures=tests/fixtures/adversarial-review
territories=adversarial-review/scripts/check-territories.py
ledger_py=adversarial-review/scripts/ledger.py

python3 "$territories" validate "$fixtures/scope-good.json" >/dev/null || {
  echo "scope-good.json should validate" >&2
  exit 1
}

overlap_err="$(python3 "$territories" validate "$fixtures/scope-overlap.json" 2>&1 >/dev/null || true)"
grep -Fq "overlap:" <<<"$overlap_err" || {
  echo "overlapping territories must be reported as an overlap: $overlap_err" >&2
  exit 1
}

glob_err="$(python3 "$territories" validate "$fixtures/scope-glob.json" 2>&1 >/dev/null || true)"
grep -Fq "glob character" <<<"$glob_err" || {
  echo "a glob entry must be rejected: $glob_err" >&2
  exit 1
}

# A decorated entry (backtick or markdown link) is refused outright, never
# stripped: the bare spelling has to be what a peer task can also write, or
# R13's overlap check silently answers "no overlap" for the same file (#232).
backtick_err="$(python3 "$territories" validate "$fixtures/scope-backtick.json" 2>&1 >/dev/null || true)"
grep -Fq "backtick; write the path bare, without markdown decoration" <<<"$backtick_err" || {
  echo "a backticked entry must be rejected: $backtick_err" >&2
  exit 1
}

# An empty intersection is how the round loop terminates, so it must exit 0 with
# no output rather than being an error.
intersect_out="$(printf 'src/billing/tax.py\n' | python3 "$territories" intersect "$fixtures/scope-good.json")"
[[ "$intersect_out" == "money" ]] || {
  echo "fix diff in src/billing/ should intersect the money territory, got: $intersect_out" >&2
  exit 1
}

# A fix touching a path nobody owns is a blind spot, and must stop rather than
# be skipped.
printf 'README.md\n' | python3 "$territories" intersect "$fixtures/scope-good.json" >/dev/null 2>&1 && {
  echo "an unowned path in the fix diff must exit non-zero" >&2
  exit 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
L="$tmp/ledger.jsonl"

python3 "$ledger_py" append-finding --ledger "$L" \
  --id F-r1-money-01 --round 1 --territory money --file src/billing/invoice.py \
  --quoted-evidence 'total += round(x, 2)' --claim 'rounds per line' \
  --proposed-fix 'round once at the end' --proposed-repro 'pytest -k rounding' \
  --claimed-severity blocking >/dev/null

# A fresh finding is UNVERIFIED because no event has landed, not because a field
# says so. That is what keeps the ledger append-only.
python3 "$ledger_py" state --ledger "$L" | grep -Fq "UNVERIFIED" || {
  echo "a finding with no events must derive as UNVERIFIED" >&2
  exit 1
}

python3 "$ledger_py" append-event --ledger "$L" --finding-id F-nope \
  --disposition CLOSED --actor smoke >/dev/null 2>&1 && {
  echo "an event for an unknown finding must be refused" >&2
  exit 1
}

# The evidence rule: a REPRODUCED verdict with nothing behind it is the exact
# artifact this skill exists to refuse.
python3 "$ledger_py" append-event --ledger "$L" --finding-id F-r1-money-01 \
  --disposition REPRODUCED --actor verifier-r1-money \
  --repro-command 'pytest -k rounding' >/dev/null 2>&1 && {
  echo "REPRODUCED without observed output must be refused" >&2
  exit 1
}

python3 "$ledger_py" append-event --ledger "$L" --finding-id F-r1-money-01 \
  --disposition REPRODUCED --actor verifier-r1-money \
  --repro-command 'pytest -k rounding' --observed-output 'assert 10.01 == 10.00' >/dev/null

python3 "$ledger_py" state --ledger "$L" | grep -Fq "REPRODUCED" || {
  echo "state must derive REPRODUCED from the appended event" >&2
  exit 1
}

python3 "$ledger_py" validate --ledger "$L" >/dev/null || {
  echo "ledger round-trip must validate" >&2
  exit 1
}

echo "adversarial-review smoke: OK"
