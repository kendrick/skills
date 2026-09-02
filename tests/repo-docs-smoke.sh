#!/usr/bin/env bash
# Pin the repo-level agent docs. Everything here is a string whose removal
# leaves every other suite green while the mechanism it names silently stops
# working, which is the failure mode worth a test: a rule that is gone is
# obvious, and a rule that is present and never consulted is not.
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

require_file AGENTS.md
require_file CLAUDE.md

# The import is the whole reason two files can coexist without drifting. Lose
# it and Claude Code reads a stub, follows no repo rules, and every suite here
# still passes.
require_text CLAUDE.md "@AGENTS.md"

# Its target has to be resolvable, not just named.
import_target="$(grep -oE '^@[A-Za-z0-9_./-]+' CLAUDE.md | head -1 | tr -d '@')"
[[ -n "$import_target" && -f "$import_target" ]] || {
  echo "CLAUDE.md imports '$import_target', which is not a file" >&2
  exit 1
}

# CLAUDE.md is a pointer, and a pointer that grows is a second source of truth
# drifting into existence. The bound is deliberately loose; it catches someone
# starting to write rules here, not a reworded sentence.
claude_lines="$(wc -l < CLAUDE.md | tr -d ' ')"
[[ "$claude_lines" -le 15 ]] || {
  echo "CLAUDE.md is $claude_lines lines; it imports AGENTS.md rather than restating it" >&2
  exit 1
}

# Codex searches for this exact heading. Retitle it and Codex still reads the
# file, applies none of it, and posts a review that looks entirely normal.
require_text AGENTS.md "## Code Review Rules"

# Its subsections nest under that heading. Promoting one back to `##` lifts it
# out of the section Codex is reading.
for section in Scope Severity Evidence "What not to flag" Output; do
  require_text AGENTS.md "### $section"
done

# The severity vocabulary the review output is written against.
require_text AGENTS.md "**P0 — blocks merge.**"
require_text AGENTS.md "**P1 — fix before merge, or record why not.**"
require_text AGENTS.md "**P2 — non-blocking.**"

# The single fact the rest of the conventions follow from.
require_text AGENTS.md "a skill lands alone"

# --- Functional checks. The exception lists in AGENTS.md are load-bearing in
# the other direction: a reviewer reads them and skips a finding, so an entry
# that has quietly become false suppresses a real one. ---

# Read the exception sets out of the prose rather than restating them here.
# An earlier version asserted only that each excepted skill's name appeared
# somewhere in AGENTS.md, which any unrelated mention satisfied: deleting a
# skill from the exception clause left the suite green while the exception it
# claimed to pin was gone.
exception_line="$(grep -F 'carry no `RATIONALE.md`' AGENTS.md | head -1)"
[[ -n "$exception_line" ]] || {
  echo "AGENTS.md no longer states which skills carry no RATIONALE.md" >&2
  exit 1
}

names_in() { grep -oE '`[a-z0-9-]+`' <<<"$1" | tr -d '`'; }

no_ledger="$(names_in "$(sed 's/ carry no .*//' <<<"$exception_line")")"
no_test="$(names_in "$(sed -e 's/.*carry no `RATIONALE.md`, and //' -e 's/ have no smoke test.*//' <<<"$exception_line")")"

[[ -n "$no_ledger" && -n "$no_test" ]] || {
  echo "could not read the exception sets out of: $exception_line" >&2
  exit 1
}

# Every skill the prose excuses must actually lack the artifact it is excused for.
for skill in $no_ledger; do
  [[ -d "$skill" ]] || {
    echo "AGENTS.md excuses '$skill' from carrying a ledger, but no such skill exists" >&2
    exit 1
  }
  [[ -f "_maintenance/$skill/RATIONALE.md" ]] && {
    echo "AGENTS.md says $skill carries no ledger, but _maintenance/$skill/RATIONALE.md exists" >&2
    exit 1
  }
done

for skill in $no_test; do
  [[ -f "tests/$skill-smoke.sh" ]] && {
    echo "AGENTS.md says $skill has no smoke test, but tests/$skill-smoke.sh exists" >&2
    exit 1
  }
done

# And every skill it does not excuse must meet the bar, so a new one cannot land
# without a ledger by going unmentioned.
for skill_md in */SKILL.md; do
  skill="$(dirname "$skill_md")"
  grep -qx "$skill" <<<"$no_ledger" && continue
  [[ -f "_maintenance/$skill/RATIONALE.md" ]] || {
    echo "$skill is held to the full bar but has no _maintenance/$skill/RATIONALE.md" >&2
    exit 1
  }
done

# A skill ships two files at its top level, and its directories are the three
# AGENTS.md names. The router is the one exception, and the prose has to say so.
require_text AGENTS.md "\`databricks-api\` is the exception"
for skill_md in */SKILL.md; do
  skill="$(dirname "$skill_md")"
  count="$(find "$skill" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [[ "$count" == "2" ]] || {
    echo "$skill/ ships $count files at its top level; AGENTS.md allows SKILL.md and README.md" >&2
    exit 1
  }
  [[ "$skill" == "databricks-api" ]] && continue
  while IFS= read -r sub; do
    [[ -z "$sub" ]] && continue
    case "$(basename "$sub")" in
      references|scripts|assets) ;;
      *)
        echo "$sub is not one of the references/, scripts/, or assets/ directories AGENTS.md allows" >&2
        exit 1
        ;;
    esac
  done < <(find "$skill" -maxdepth 1 -mindepth 1 -type d)
done

echo "repo-docs smoke: OK"
