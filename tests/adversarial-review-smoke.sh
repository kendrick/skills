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

[[ "$(find adversarial-review -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "adversarial-review/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. Manual invocation is a deliberate choice: three ambient skills
# contend for review vocabulary, and a misfire here costs a long fan-out.
require_text adversarial-review/SKILL.md "name: adversarial-review"
require_text adversarial-review/SKILL.md "disable-model-invocation: true"
require_text adversarial-review/SKILL.md "Use ONLY when the user explicitly invokes adversarial-review."
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
require_text adversarial-review/SKILL.md ".git/info/exclude"

# Territories: literal paths, disjointness enforced by script, hard stop on
# overlap. The overlap check is what the verification gate stands on.
require_text adversarial-review/SKILL.md "check-territories.py validate"
require_text adversarial-review/SKILL.md "A non-zero exit is a hard stop, not a warning."
require_text adversarial-review/SKILL.md "Disjoint ownership, layered lenses"

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

require_text _maintenance/adversarial-review/RATIONALE.md "## Decision Ledger"
require_text _maintenance/adversarial-review/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/adversarial-review/RATIONALE.md "## Known Limitations"
require_text README.md "npx skills add kendrick/skills --skill adversarial-review"

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
