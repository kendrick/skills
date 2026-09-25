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
require_file adversarial-review/scripts/match-triggers.py
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
# The round loop ends on reproduced blockers, not on reproduced findings of
# any severity (row 40): advisories alone kept cambium #23/#26 looping.
require_text adversarial-review/SKILL.md "zero REPRODUCED findings whose \`claimed_severity\` is \`blocking\`"
require_text adversarial-review/SKILL.md "ledger.py state --ledger RUN_DIR/ledger.jsonl --round N"
require_text adversarial-review/SKILL.md "printed \`loop: stop\` for the newest round"
refute_text adversarial-review/SKILL.md "zero REPRODUCED findings in the territories it re-reviewed"
# A reproduced advisory is listed by default and filed only on request (row
# 39). The refute pins the old default row, which filed one issue per finding.
require_text adversarial-review/SKILL.md "| REPRODUCED + advisory | List it: record \`LISTED\`"
require_text adversarial-review/SKILL.md "Under \`--file-advisories\`, hand it to the \`file-issue\` skill instead"
require_text adversarial-review/SKILL.md "every \`LISTED\` finding appears in the listed section with its repro command"
require_text adversarial-review/assets/event.schema.json '"LISTED"'
refute_text adversarial-review/SKILL.md "| REPRODUCED + advisory | Hand to the \`file-issue\` skill"
require_text adversarial-review/SKILL.md "inbox-to-memory"

# The round loop's rationale is load-bearing, not decoration: it is the whole
# reason the loop exists past round 1.
require_text adversarial-review/SKILL.md "introduced while fixing"
require_text adversarial-review/SKILL.md "check-territories.py intersect"
# Step 7 filters exclusions in the script. The grep stage it replaced printed
# nothing under ugrep for an empty excluded.txt (RATIONALE row 38).
require_text adversarial-review/SKILL.md "--exclude RUN_DIR/excluded.txt"
require_text adversarial-review/SKILL.md "write the \`excluded\` entries to \`RUN_DIR/excluded.txt\`"
refute_text adversarial-review/SKILL.md "grep -vFf"
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
# Step 2 matches through the script, which reads the table's own signals
# (RATIONALE row 41). The recipe it replaced, rebuilt by hand each run, exits 2
# on the `round(` signal (#114), so the refutes pin that recipe's sentence and
# the outline that sent a reader to build it.
require_text adversarial-review/SKILL.md "adversarial-review/scripts/match-triggers.py rows"
require_text adversarial-review/references/trigger-table.md "implements these rules"
require_text adversarial-review/references/trigger-table.md "adversarial-review/scripts/match-triggers.py rows\` for each changed file"
refute_text adversarial-review/references/trigger-table.md "In practice, \`grep -Ei"
refute_text adversarial-review/references/trigger-table.md "Grep the file's hunks"
refute_text adversarial-review/SKILL.md "grep each changed file's hunks"
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

# Step 6 lists a reproduced advisory as LISTED instead of filing an issue for
# it (#152, RATIONALE row 39). LISTED carries a reason and no artifact, and it
# is valid only on an advisory: a blocker recorded LISTED would skip the
# failing test and the fix without anything noticing.
listed_ledger() {
  local out="$1" blocker_outcome="$2"
  : >"$out"
  python3 "$ledger_py" append-finding --ledger "$out" \
    --id F-r1-money-01 --round 1 --territory money --file src/billing/invoice.py \
    --quoted-evidence 'total += round(x, 2)' --claim 'rounds per line' \
    --proposed-fix 'round once at the end' --proposed-repro 'pytest -k rounding' \
    --claimed-severity blocking >/dev/null
  python3 "$ledger_py" append-finding --ledger "$out" \
    --id F-r1-money-02 --round 1 --territory money --file src/billing/tax.py \
    --quoted-evidence 'rate = 0.2' --claim 'magic number' \
    --proposed-fix 'name the constant' --proposed-repro 'grep -n 0.2 src/billing/tax.py' \
    --claimed-severity advisory >/dev/null
  local id
  for id in F-r1-money-01 F-r1-money-02; do
    python3 "$ledger_py" append-event --ledger "$out" --finding-id "$id" \
      --disposition REPRODUCED --actor verifier-r1-money \
      --repro-command 'pytest -k rounding' --observed-output 'assert 10.01 == 10.00' >/dev/null
  done
  # Written as raw lines so the validate check below meets the ledger a
  # hand-edited or older-script ledger could hold, not only what append-event
  # lets through.
  printf '%s\n' \
    "{\"record\": \"event\", \"finding_id\": \"F-r1-money-01\", \"disposition\": \"$blocker_outcome\", \"actor\": \"orchestrator\", \"repro_command\": null, \"observed_output\": null, \"counter_evidence\": null, \"reason\": \"listed in PR Left Out\", \"artifact\": \"tests/test_rounding.py\", \"at\": \"2026-09-24T00:00:00Z\"}" \
    '{"record": "event", "finding_id": "F-r1-money-02", "disposition": "LISTED", "actor": "orchestrator", "repro_command": null, "observed_output": null, "counter_evidence": null, "reason": "listed in PR Left Out", "artifact": null, "at": "2026-09-24T00:00:00Z"}' \
    >>"$out"
}
listed_ledger "$tmp/listed-ok.jsonl" TEST_WRITTEN
listed_ok_out="$(python3 "$ledger_py" validate --ledger "$tmp/listed-ok.jsonl" 2>&1)" || {
  echo "an advisory LISTED beside a blocker TEST_WRITTEN must validate: $listed_ok_out" >&2
  exit 1
}
# validate holds a LISTED line to the same reason rule append-event does, so
# a hand-edited ledger can't carry a listing nobody explained.
cp "$tmp/listed-ok.jsonl" "$tmp/listed-noreason.jsonl"
printf '%s\n' '{"record": "event", "finding_id": "F-r1-money-02", "disposition": "LISTED", "actor": "orchestrator", "repro_command": null, "observed_output": null, "counter_evidence": null, "reason": null, "artifact": null, "at": "2026-09-24T00:00:01Z"}' >>"$tmp/listed-noreason.jsonl"
noreason_out="$(python3 "$ledger_py" validate --ledger "$tmp/listed-noreason.jsonl" 2>&1)" && {
  echo "validate must refuse a LISTED event with no reason" >&2
  exit 1
}
grep -Fq "LISTED requires reason" <<<"$noreason_out" || {
  echo "validate's refusal must name LISTED and its reason, got: $noreason_out" >&2
  exit 1
}
# An event placed ahead of its finding still meets the severity rule: a
# hand-edited ledger with the LISTED line first once validated clean.
{
  printf '%s\n' '{"record": "event", "finding_id": "F-r1-money-01", "disposition": "LISTED", "actor": "orchestrator", "repro_command": null, "observed_output": null, "counter_evidence": null, "reason": "listed in PR Left Out", "artifact": null, "at": "2026-09-24T00:00:00Z"}'
  head -1 "$tmp/listed-ok.jsonl"
} >"$tmp/listed-forward.jsonl"
forward_out="$(python3 "$ledger_py" validate --ledger "$tmp/listed-forward.jsonl" 2>&1)" && {
  echo "validate must refuse a LISTED event on a blocker even when the event precedes the finding" >&2
  exit 1
}
grep -Fq "LISTED is valid only on an advisory finding" <<<"$forward_out" || {
  echo "the forward-reference refusal must name LISTED's severity rule, got: $forward_out" >&2
  exit 1
}
# An event naming no finding anywhere in the ledger fails validate. derive()
# drops such an event, so a hand-edited LISTED line for a missing finding
# would vanish from the report while the ledger still read as valid.
printf '%s\n' '{"record": "event", "finding_id": "F-missing", "disposition": "LISTED", "actor": "orchestrator", "repro_command": null, "observed_output": null, "counter_evidence": null, "reason": "listed in PR Left Out", "artifact": null, "at": "2026-09-24T00:00:00Z"}' >"$tmp/listed-orphan.jsonl"
orphan_out="$(python3 "$ledger_py" validate --ledger "$tmp/listed-orphan.jsonl" 2>&1)" && {
  echo "validate must refuse an event whose finding is absent" >&2
  exit 1
}
grep -Fq "unknown finding_id F-missing" <<<"$orphan_out" || {
  echo "the orphan-event refusal must name the missing finding, got: $orphan_out" >&2
  exit 1
}
# An event above its finding fails validate even when every other rule
# holds: derive() folds in file order and drops it, so an advisory's LISTED
# line placed first would vanish from state while validate said OK.
{
  printf '%s\n' '{"record": "event", "finding_id": "F-r1-money-02", "disposition": "LISTED", "actor": "orchestrator", "repro_command": null, "observed_output": null, "counter_evidence": null, "reason": "listed in PR Left Out", "artifact": null, "at": "2026-09-24T00:00:00Z"}'
  sed -n 2p "$tmp/listed-ok.jsonl"
} >"$tmp/listed-forward-advisory.jsonl"
fwd_adv_out="$(python3 "$ledger_py" validate --ledger "$tmp/listed-forward-advisory.jsonl" 2>&1)" && {
  echo "validate must refuse an event that precedes its finding, got OK: $fwd_adv_out" >&2
  exit 1
}
grep -Fq "precedes its finding F-r1-money-02" <<<"$fwd_adv_out" || {
  echo "the forward-event refusal must name the finding, got: $fwd_adv_out" >&2
  exit 1
}
listed_ledger "$tmp/listed-blocker.jsonl" LISTED
listed_bad_out="$(python3 "$ledger_py" validate --ledger "$tmp/listed-blocker.jsonl" 2>&1)" && {
  echo "a blocking finding recorded LISTED must fail validate" >&2
  exit 1
}
grep -Fq "LISTED is valid only on an advisory finding" <<<"$listed_bad_out" || {
  echo "validate must name LISTED's severity rule for a blocker recorded LISTED, got: $listed_bad_out" >&2
  exit 1
}
listed_append_err="$(python3 "$ledger_py" append-event --ledger "$tmp/listed-ok.jsonl" \
  --finding-id F-r1-money-02 --disposition LISTED --actor orchestrator 2>&1)" && {
  echo "LISTED with no --reason must be refused" >&2
  exit 1
}
grep -Fq "LISTED requires --reason" <<<"$listed_append_err" || {
  echo "the refusal must name LISTED and --reason, got: $listed_append_err" >&2
  exit 1
}
python3 "$ledger_py" append-event --ledger "$tmp/listed-ok.jsonl" \
  --finding-id F-r1-money-02 --disposition LISTED --actor orchestrator \
  --reason "listed in PR Left Out" >/dev/null || {
  echo "LISTED with --reason on an advisory must append" >&2
  exit 1
}
listed_blocker_err="$(python3 "$ledger_py" append-event --ledger "$tmp/listed-ok.jsonl" \
  --finding-id F-r1-money-01 --disposition LISTED --actor orchestrator \
  --reason "listed in PR Left Out" 2>&1)" && {
  echo "append-event must refuse LISTED on a blocking finding" >&2
  exit 1
}
grep -Fq "LISTED is valid only on an advisory finding" <<<"$listed_blocker_err" || {
  echo "append-event's refusal must name LISTED's severity rule, got: $listed_blocker_err" >&2
  exit 1
}

# Step 7's termination rule, decided by ledger.py itself (#151, row 40): a
# round whose reproduced findings are all advisory ends the loop, and one
# reproduced blocker in that round continues it. Ending only on zero
# reproduced findings of any severity, the rule this replaced, continues on
# the first fixture, which is how the loops around cambium #23/#26 ran 7 repair cycles per lane.
round_ledger() {
  local out="$1" second_severity="$2"
  : >"$out"
  # A round-1 blocker that round 2 exists to follow up. It must not count
  # toward round 2's decision.
  python3 "$ledger_py" append-finding --ledger "$out" \
    --id F-r1-money-01 --round 1 --territory money --file src/billing/invoice.py \
    --quoted-evidence 'total += round(x, 2)' --claim 'rounds per line' \
    --proposed-fix 'round once at the end' --proposed-repro 'pytest -k rounding' \
    --claimed-severity blocking >/dev/null
  python3 "$ledger_py" append-finding --ledger "$out" \
    --id F-r2-money-01 --round 2 --territory money --file src/billing/invoice.py \
    --quoted-evidence 'ROUNDING = 2' --claim 'constant lacks a comment' \
    --proposed-fix 'say why 2' --proposed-repro 'grep -n ROUNDING src/billing/invoice.py' \
    --claimed-severity advisory >/dev/null
  python3 "$ledger_py" append-finding --ledger "$out" \
    --id F-r2-money-02 --round 2 --territory money --file tests/test_invoice.py \
    --quoted-evidence 'assert total' --claim 'test asserts truthiness only' \
    --proposed-fix 'assert the value' --proposed-repro 'pytest -k total' \
    --claimed-severity "$second_severity" >/dev/null
  local id
  for id in F-r1-money-01 F-r2-money-01 F-r2-money-02; do
    python3 "$ledger_py" append-event --ledger "$out" --finding-id "$id" \
      --disposition REPRODUCED --actor verifier-money \
      --repro-command 'pytest -k total' --observed-output 'assert 10.01 == 10.00' >/dev/null
  done
}
round_ledger "$tmp/round-advisory.jsonl" advisory
loop_out="$(python3 "$ledger_py" state --ledger "$tmp/round-advisory.jsonl" --round 2 2>&1)" || true
grep -Fq "loop: stop" <<<"$loop_out" || {
  echo "a round whose reproduced findings are all advisory must end the loop, got: $loop_out" >&2
  exit 1
}
round_ledger "$tmp/round-blocking.jsonl" blocking
loop_out="$(python3 "$ledger_py" state --ledger "$tmp/round-blocking.jsonl" --round 2 2>&1)" || true
grep -Fq "loop: continue" <<<"$loop_out" || {
  echo "a round with one reproduced blocker must continue the loop, got: $loop_out" >&2
  exit 1
}

# Step 7's command, run as SKILL.md writes it rather than paraphrased. On
# cambium #23/#26 the old `grep -vFf RUN_DIR/excluded.txt` stage printed
# nothing under ugrep whenever excluded.txt was empty, so `intersect` saw no
# input, exited 0, and the loop ended with the fix unreviewed. The second run
# puts a grep on PATH that always fails, so the case fails on any machine if
# the command pipes through grep again, whichever grep is installed.
step7_cmd="$(awk '/Once fixes are committed:/{f=1;next} f&&/^```$/{if(in_block)exit; in_block=1;next} in_block{print}' adversarial-review/SKILL.md \
  | sed -e 's/\\$//' | tr '\n' ' ')"
[[ -n "$step7_cmd" ]] || {
  echo "could not extract Step 7's command from adversarial-review/SKILL.md" >&2
  exit 1
}
s7="$tmp/step7"
mkdir -p "$s7/repo/src/billing" "$s7/run" "$s7/shim"
cp "$fixtures/scope-good.json" "$s7/run/scope.json"
: >"$s7/run/excluded.txt"
printf '#!/bin/sh\necho "grep called from the Step 7 pipe" >&2\nexit 97\n' >"$s7/shim/grep"
chmod +x "$s7/shim/grep"
(
  cd "$s7/repo"
  git init -q
  git -c user.name=smoke -c user.email=smoke@example.invalid commit -q --allow-empty -m base
  git rev-parse HEAD >"$s7/prev_sha"
  echo 'rate = 0.2' >src/billing/tax.py
  git add src/billing/tax.py
  git -c user.name=smoke -c user.email=smoke@example.invalid commit -q -m fix
  # Untracked, so the script path resolves without entering the fix diff.
  ln -s "$repo_root/adversarial-review" adversarial-review
)
step7_run="${step7_cmd//<prev_round_head_sha>/$(cat "$s7/prev_sha")}"
step7_run="${step7_run//RUN_DIR/$s7/run}"
# Stdout only: the shim also catches grep calls a runtime makes on its own,
# such as pyenv's python3 shim resolving a version, and those leave stderr
# noise without touching the answer. A grep stage in the pipe itself empties
# stdout, which is what fails here.
for step7_shim in "" "$s7/shim:"; do
  step7_label="ambient PATH"
  [[ -z "$step7_shim" ]] || step7_label="grep shimmed to fail"
  step7_out="$(cd "$s7/repo" && PATH="$step7_shim$PATH" bash -o pipefail -c "$step7_run" 2>/dev/null)" || true
  [[ "$step7_out" == "money" ]] || {
    echo "Step 7's command with an empty excluded.txt must print the fix's territory ($step7_label), got: $step7_out" >&2
    exit 1
  }
done

# An excluded path drops out before ownership is checked: dist/app.js belongs
# to no territory, so without the filter this diff would exit 1 as unowned.
# A directory entry covers what sits under it; a missing file excludes nothing.
printf 'dist/app.js\n' >"$tmp/excluded-one.txt"
printf 'dist/\n' >"$tmp/excluded-dir.txt"
only_src="$(printf 'src/billing/tax.py\n' | python3 "$territories" intersect "$fixtures/scope-good.json")"
for ex in "$tmp/excluded-one.txt" "$tmp/excluded-dir.txt"; do
  with_dist="$(printf 'dist/app.js\nsrc/billing/tax.py\n' | python3 "$territories" intersect "$fixtures/scope-good.json" --exclude "$ex")" || {
    echo "an excluded path must not reach the unowned check ($ex)" >&2
    exit 1
  }
  [[ "$with_dist" == "$only_src" ]] || {
    echo "excluding dist/app.js must intersect like src/billing/tax.py alone ($ex): got '$with_dist', want '$only_src'" >&2
    exit 1
  }
done
# Exit 1 with the unowned line, not merely non-zero: a missing file rejected
# as unreadable (exit 3) would pass a bare status check while excluding
# nothing no longer held.
set +e
missing_err="$(printf 'dist/app.js\n' | python3 "$territories" intersect "$fixtures/scope-good.json" --exclude "$tmp/no-such-file.txt" 2>&1 >/dev/null)"
missing_status=$?
set -e
[[ "$missing_status" == "1" ]] && grep -Fq "unowned in fix diff: dist/app.js" <<<"$missing_err" || {
  echo "a missing --exclude file must exclude nothing, so dist/app.js stays unowned (exit 1), got $missing_status: $missing_err" >&2
  exit 1
}
# Unreadable input is a usage failure under the validator convention, never
# a traceback that exits 1 and reads as an unowned path.
printf '\377\n' >"$tmp/excluded-binary.txt"
set +e
printf 'src/billing/tax.py\n' | python3 "$territories" intersect "$fixtures/scope-good.json" --exclude "$tmp/excluded-binary.txt" >/dev/null 2>&1
binary_status=$?
set -e
[[ "$binary_status" == "3" ]] || {
  echo "an unreadable --exclude file must exit 3, got: $binary_status" >&2
  exit 1
}

# match-triggers.py: each falsifier from #157 runs through the real script on
# its committed fixture. Exact stdout and exit code, because an empty stdout is
# the passing answer for half of them, and a crash also prints nothing.
match_py=adversarial-review/scripts/match-triggers.py
diffs="$fixtures/diffs"
expect_match() {
  local want="$1"
  shift
  local got status
  set +e
  got="$(python3 "$match_py" rows "$@")"
  status=$?
  set -e
  [[ "$status" == "0" && "$got" == "$want" ]] || {
    echo "match-triggers.py rows $*: want exit 0 and '$want', got exit $status and '$got'" >&2
    exit 1
  }
}
expect_match "1 money" --only 1 <"$diffs/money-round-paren.diff"
expect_match "1 money" --only 1 < <(printf '+total = round(amount, 2)\n')
# Whole-word: `index` inside `page_index` is no schema signal, and a bare
# `CREATE INDEX` is. A substring matcher prints `4 schema` for both.
expect_match "" <"$diffs/schema-page-index.diff"
expect_match "4 schema" <"$diffs/schema-create-index.diff"
# Unit suffix: `px` matches after a digit, never as an identifier.
expect_match "6 representation" <"$diffs/unit-12px.diff"
expect_match "" <"$diffs/unit-const-px.diff"
# The only `round(` in this diff sits on an unchanged context line.
expect_match "" <"$diffs/context-only.diff"
# Every unit in the table's "The unit suffixes are" sentence gets the digit
# rule, row 1's `ms` and `kb` included (RATIONALE row 42). A hardcoded
# `px`/`rem`/`em` set matched `ms = 3` as a word and missed `500ms`.
expect_match "1 money" --only 1 < <(printf '+timeout = 500ms\n')
expect_match "1 money" --only 1 < <(printf '+size = 10kb\n')
expect_match "" --only 1 < <(printf '+ms = 3\n')
# Inside a hunk, `---`/`+++` lines are content (row 43). A removed SQL
# comment and an added `++total;` each carry their fixture's only signal.
expect_match "4 schema" <"$diffs/schema-removed-sql-comment.diff"
expect_match "1 money" --only 1 <"$diffs/money-plusplus-added.diff"
# Two files back to back: the second file's `---`/`+++` headers sit after
# the first hunk's counts run out, so they stay headers.
expect_match "1 money
4 schema" --only 1,4 < <(cat "$diffs/schema-removed-sql-comment.diff" "$diffs/money-plusplus-added.diff")
# The same two-file change, once plain and once as `git -c color.ui=always
# diff` wrote it, escape bytes and all (row 45). Without the strip, the
# colored copy prints nothing and exits 0, which reads as a diff with no
# triggers.
grep -q $'\x1b\\[' "$diffs/colored-money-schema.diff" || {
  echo "colored-money-schema.diff lost its ANSI escapes, so it no longer tests the strip" >&2
  exit 1
}
expect_match "1 money
4 schema
6 representation" <"$diffs/plain-money-schema.diff"
expect_match "1 money
4 schema
6 representation" <"$diffs/colored-money-schema.diff"

# The recipe the script replaced, filled in for `round(`, is a regex error
# rather than a match: exit 2 on the very line the script matches (#114).
set +e
printf '+total = round(amount, 2)\n' | grep -Ei '\bround(\b' >/dev/null 2>&1
recipe_status=$?
set -e
[[ "$recipe_status" == "2" ]] || {
  echo "grep -Ei '\\bround(\\b' was expected to exit 2 on round(amount, 2), got: $recipe_status" >&2
  exit 1
}

# A table the script can't parse exits 1, so Step 2 stops rather than
# deriving every file into `general`. A missing table is unreadable input: 3.
printf '# not a trigger table\n\nno rows here\n' >"$tmp/bad-table.md"
set +e
python3 "$match_py" rows --table "$tmp/bad-table.md" </dev/null >/dev/null 2>&1
bad_table_status=$?
python3 "$match_py" rows --table "$tmp/no-such-table.md" </dev/null >/dev/null 2>&1
missing_table_status=$?
set -e
[[ "$bad_table_status" == "1" ]] || {
  echo "an unparseable --table must exit 1, got: $bad_table_status" >&2
  exit 1
}
[[ "$missing_table_status" == "3" ]] || {
  echo "a missing --table must exit 3, got: $missing_table_status" >&2
  exit 1
}

# The unit list is table data (row 42), so a table that drops the "The unit
# suffixes are" sentence can't be parsed and exits 1.
sed 's/The unit suffixes are `px`[^.]*\. //' adversarial-review/references/trigger-table.md >"$tmp/no-units-table.md"
refute_text "$tmp/no-units-table.md" 'The unit suffixes are `'
set +e
python3 "$match_py" rows --table "$tmp/no-units-table.md" </dev/null >/dev/null 2>&1
no_units_status=$?
set -e
[[ "$no_units_status" == "1" ]] || {
  echo "a --table with no unit-suffix sentence must exit 1, got: $no_units_status" >&2
  exit 1
}

# Usage errors exit 3 under the validator convention (row 44); argparse's
# own default is 2.
set +e
python3 "$match_py" rows --bogus </dev/null >/dev/null 2>&1
bogus_flag_status=$?
python3 "$match_py" </dev/null >/dev/null 2>&1
no_command_status=$?
set -e
[[ "$bogus_flag_status" == "3" && "$no_command_status" == "3" ]] || {
  echo "usage errors must exit 3: rows --bogus got $bogus_flag_status, no subcommand got $no_command_status" >&2
  exit 1
}

echo "adversarial-review smoke: OK"
