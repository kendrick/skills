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

refute_text() {
  local file="$1"
  local text="$2"
  if grep -Fq -- "$text" "$file"; then
    echo "unexpected text in $file: $text" >&2
    exit 1
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

require_file AGENTS.md
require_file CLAUDE.md
require_file README.md

# Eight per-skill suites pin their own "--skill <name>" against the root README's
# map table, and none pins the command that flag belongs to, so deleting the
# whole Install section would leave fourteen table rows, eight green suites, and
# a reader with no way to install anything. This is that command, pinned once.
# The counts move whenever a skill lands; they are colour, and the check below
# is what actually holds.
require_text README.md "npx skills add kendrick/skills"

# --- The map table is the README's index of the collection, and a skill absent
# from it is a skill nobody installs. Scattering that across the per-skill
# suites cannot work: eli5 and databricks-api ship no suite to pin from, and a
# suite pinning a bare flag can be satisfied by the Install section's example
# instead of the row. So the table's inventory is checked here, against the
# directories on disk. ---

table_skills=""
while IFS= read -r row; do
  name="$(sed -E 's/^\| \[([a-z0-9-]+)\].*/\1/' <<<"$row")"
  flag="$(grep -oE -- '--skill [a-z0-9-]+' <<<"$row" | head -1)"
  [[ "$flag" == "--skill $name" ]] || {
    echo "README map row for '$name' carries install flag '$flag'" >&2
    exit 1
  }
  [[ -f "$name/SKILL.md" ]] || {
    echo "README map lists '$name', which is not a skill in this repo" >&2
    exit 1
  }
  table_skills+="$name"$'\n'
done < <(grep -E '^\| \[[a-z0-9-]+\]\(' README.md)

for skill_md in */SKILL.md; do
  skill="$(dirname "$skill_md")"
  grep -qx "$skill" <<<"$table_skills" || {
    echo "$skill ships a SKILL.md but has no row in the README map table" >&2
    exit 1
  }
done

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

# The P0 band has to reach the case Scope now names. Left at "another
# document", an intra-document contradiction is in scope with no severity to
# land in, and a reviewer files it as a P2 wording nit.
require_text AGENTS.md "A step that contradicts another document in the same skill, or the document it sits in."
require_text AGENTS.md "**P1 — fix before merge, or record why not.**"

# Codex reads only the AGENTS.md of the repo under review, so work-issue's PR
# review rules reach this repo's reviews through the installed block, and a
# stale or missing block means Codex reviews without them. check exits 1 on
# either, which set -e turns into a failed suite.
python3 work-issue/scripts/review-rules.py check .

# The P0 band stops at input a real caller produces. The old sentence put a
# constructed edge case in a heuristic script at P0, which the block's
# Heuristic scripts rule now bands P1; both bands left standing contradict
# each other inside one file.
require_text AGENTS.md "A script that fails on valid input a real caller in this repo produces, or passes on invalid input one produces."
if grep -Fq -- "A script that fails on valid input or passes on invalid input." AGENTS.md; then
  echo "AGENTS.md still carries the unnarrowed P0 sentence for scripts" >&2
  exit 1
fi
require_text AGENTS.md "**P2 — non-blocking.**"

# The Scope rule reaches inside one file, not only across the four artifacts
# its examples name. Both P0s on #115 were one document contradicting itself
# within a bullet or a paragraph, and three reviewers read the cross-document
# half of this rule and looked outward.
require_text AGENTS.md "read the whole bullet or paragraph it lands in and the section around it"
require_text AGENTS.md "A sweep that stops at the first file is how one error ships twice"

# The single fact the rest of the conventions follow from.
require_text AGENTS.md "a skill lands alone"

# The script checks below enforce these three rules, so restating them in
# AGENTS.md sends Codex to review what this suite already fails. The entry keeps
# the one check a reviewer still has to run by hand.
refute_text AGENTS.md "**A script.** Standard library only."
refute_text AGENTS.md "A vendored block is byte-identical to its source and keeps its provenance header."
refute_text AGENTS.md "A gating script exits 0/1/3."
require_text AGENTS.md "**A script.** Feed it a malformed input"

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

# A skill ships two files at its top level, plus an optional AGENTS.md that
# carries its own review rules, because Codex reads the AGENTS.md on a changed
# file's path. Its directories are the three AGENTS.md names. The router is the
# one exception, and the prose has to say so.
require_text AGENTS.md "\`databricks-api\` is the exception"
for skill_md in */SKILL.md; do
  skill="$(dirname "$skill_md")"
  count="$(find "$skill" -maxdepth 1 -type f ! -name AGENTS.md | wc -l | tr -d ' ')"
  [[ "$count" == "2" ]] || {
    echo "$skill/ ships $count files at its top level besides AGENTS.md; AGENTS.md allows SKILL.md and README.md" >&2
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

# --- Script checks. Codex can only catch a breach of these three rules by
# reading, and a vendored block drifted from its source with nobody noticing
# (#465). Each is a job for a diff tool, so the suite runs them. ---

# One checker, a root, and a mode, so each falsifier below can run one mode
# against a scratch copy of the scripts. Problems go to stderr, one per line,
# each naming the file; notes go to stdout.
cat >"$tmp/check-scripts.py" <<'PY'
import ast
import re
import subprocess
import sys
from pathlib import Path

# sys.stdlib_module_names is the only stdlib list that doesn't need a hand-kept
# copy, and it arrived in 3.10.
if sys.version_info < (3, 10):
    sys.exit("repo-docs smoke needs Python 3.10 or later for sys.stdlib_module_names")

root = Path(sys.argv[1]).resolve()
mode = sys.argv[2]
problems = []


def rel(path):
    return path.relative_to(root).as_posix()


def py_scripts():
    return sorted(root.glob("*/scripts/*.py"))


def check_imports():
    # ast.walk rather than the module body, so an import inside a function or a
    # try block can't slip a third-party package past the check. A path-loaded
    # sibling (spec_from_file_location) is no import statement and needs none.
    for path in py_scripts():
        siblings = {p.stem for p in path.parent.glob("*.py")}
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                names = [alias.name for alias in node.names]
            elif isinstance(node, ast.ImportFrom) and node.level == 0:
                names = [node.module]
            else:
                continue
            for name in names:
                top = name.split(".")[0]
                if top not in sys.stdlib_module_names and top not in siblings:
                    problems.append(
                        f"imports: {rel(path)}:{node.lineno}: imports {name}, "
                        f"which is neither the standard library nor a script in {rel(path.parent)}/"
                    )


# A script is held to exit 3 on a usage error when its own docstring promises
# that. The Johnny.Decimal scripts and a few others document argparse's 2 and
# their ledgers record why, so a blanket rule would fail them for doing what
# they document. Whitespace is collapsed first because ledger.py wraps "3 for a usage
# error" across two lines. The suite asserts check-plan.py is covered, so a
# regex that drifts to match nothing fails the suite.
COVERAGE = re.compile(r"\b3\b[^;.]*?\busage\b", re.IGNORECASE)


def covered():
    out = []
    for path in py_scripts():
        doc = ast.get_docstring(ast.parse(path.read_text(encoding="utf-8"))) or ""
        if COVERAGE.search(" ".join(doc.split())):
            out.append(path)
    return out


def check_exits():
    for path in covered():
        try:
            # subprocess's timeout, because macOS ships no timeout(1).
            result = subprocess.run(
                [sys.executable, str(path), "--no-such-flag"],
                cwd=root,
                stdin=subprocess.DEVNULL,
                capture_output=True,
                timeout=20,
            )
        except subprocess.TimeoutExpired:
            problems.append(f"exits: {rel(path)}: still running 20s after --no-such-flag")
            continue
        if result.returncode != 3:
            problems.append(f"exits: {rel(path)}: exits {result.returncode} on --no-such-flag, want 3")


# A block opens on its header, whose comment run ends at the first `# ---` rule
# or the first non-comment line, and closes on `# end vendored`. The text
# between, minus edge blanks and rules, must appear verbatim in the named
# source. A copy that joins non-adjacent source ranges has to be split into one
# block per range, because a looser match (paragraph by paragraph) passes a
# drifted copy on short paragraphs like `return None` that match anywhere.
HEADER = re.compile(r"^\s*# Vendored verbatim from (\S+)")
CLOSE = re.compile(r"^\s*# end vendored\s*$")
RULE = re.compile(r"^\s*# ---")
COMMENT = re.compile(r"^\s*#")


def check_vendored():
    top_dirs = {p.name for p in root.iterdir() if p.is_dir()}
    # Every file under scripts/, not only *.py: shell scripts in inbox-to-memory
    # carry Python vendored from memory-index and bench-fixture.sh.
    files = sorted(p for p in root.glob("*/scripts/**/*") if p.is_file() and "__pycache__" not in p.parts)
    for path in files:
        try:
            lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
        except UnicodeDecodeError:
            continue
        i = 0
        while i < len(lines):
            match = HEADER.match(lines[i])
            if not match:
                i += 1
                continue
            where = f"{rel(path)}:{i + 1}"
            token = match.group(1).rstrip(".,:;)")
            j = i + 1
            while j < len(lines) and COMMENT.match(lines[j]) and not HEADER.match(lines[j]):
                j += 1
                if RULE.match(lines[j - 1]):
                    break
            k = j
            while k < len(lines) and not CLOSE.match(lines[k]) and not HEADER.match(lines[k]):
                k += 1
            if k == len(lines) or not CLOSE.match(lines[k]):
                problems.append(f"vendored: {where}: no '# end vendored' before the next header or end of file (source {token})")
                i = k
                continue
            body = lines[j:k]
            while body and (not body[0].strip() or RULE.match(body[0])):
                body.pop(0)
            while body and (not body[-1].strip() or RULE.match(body[-1])):
                body.pop()
            i = k + 1
            # A source outside this repo (agent-guild today) has nothing here to
            # compare against, so the check reports it and moves on.
            if token.split("/")[0] not in top_dirs:
                print(f"vendored: skipped {where}, source outside this repo: {token}")
                continue
            source = root / token
            if not source.is_file():
                problems.append(f"vendored: {where}: names source {token}, which is not a file")
            elif not body:
                problems.append(f"vendored: {where}: block from {token} is empty")
            elif "".join(body) not in source.read_text(encoding="utf-8"):
                problems.append(f"vendored: {where}: block is not verbatim in its source {token}")


if mode == "imports":
    check_imports()
elif mode == "vendored":
    check_vendored()
elif mode == "exits":
    check_exits()
elif mode == "covered":
    for path in covered():
        print(rel(path))
else:
    sys.exit(f"unknown mode: {mode}")

for problem in problems:
    print(problem, file=sys.stderr)
sys.exit(1 if problems else 0)
PY

check_scripts() { python3 "$tmp/check-scripts.py" "$@"; }

# The problem lines a mode reports against a root, sorted for comm.
problems_in() { { check_scripts "$1" "$2" 2>&1 >/dev/null || true; } | sort; }

# Copy only the scripts directories: the checks read nothing else, and a copy
# with no .git can't reach the real index.
fresh_copy() {
  rm -rf "$tmp/tree"
  mkdir "$tmp/tree"
  for dir in */scripts; do
    mkdir -p "$tmp/tree/${dir%/scripts}"
    cp -R "$dir" "$tmp/tree/$dir"
  done
}

# Replace exactly one occurrence, so an anchor that has moved fails the suite
# instead of leaving the copy unedited and the falsifier green for nothing.
edit_once() {
  python3 - "$@" <<'PY'
import sys
from pathlib import Path

path, old, new = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
text = path.read_text(encoding="utf-8")
count = text.count(old)
if count != 1:
    sys.exit(f"falsifier anchor found {count} times in {path}, want 1: {old!r}")
path.write_text(text.replace(old, new), encoding="utf-8")
PY
}

# Each falsifier diffs the edited copy's problems against the unedited copy's,
# so a mode that already fails on the real tree can't satisfy one by accident:
# the edit has to add a problem naming the files, or add none for a control.
new_problems() {
  comm -13 <(printf '%s\n' "$3") <(problems_in "$1" "$2")
}

falsify() {
  local mode="$1" file="$2" old="$3" new="$4" before added
  fresh_copy
  before="$(problems_in "$tmp/tree" "$mode")"
  edit_once "$tmp/tree/$file" "$old" "$new" || exit 1
  added="$(new_problems "$tmp/tree" "$mode" "$before")"
  printf '%s' "$added"
}

expect_named() {
  local label="$1" added="$2"
  shift 2
  [[ -n "$added" ]] || {
    echo "falsifier '$label' added no problem" >&2
    exit 1
  }
  for name in "$@"; do
    grep -Fq -- "$name" <<<"$added" || {
      echo "falsifier '$label' did not name $name: $added" >&2
      exit 1
    }
  done
}

expect_clean() {
  local label="$1" added="$2"
  [[ -z "$added" ]] || {
    echo "control '$label' added a problem: $added" >&2
    exit 1
  }
}

# Check the real tree first, and run all three modes before failing on any, so
# a real-tree problem reaches stderr even when a falsifier below exits. Real
# drift can leave a falsifier nothing to add, or delete the falsifier's anchor,
# and either failure names no file on its own.
script_checks_ok=1
for mode in imports vendored exits; do
  check_scripts . "$mode" || script_checks_ok=0
done

added="$(falsify imports work-issue/scripts/check-plan.py $'import argparse\n' $'import argparse\nimport requests\n')"
expect_named "import requests" "$added" work-issue/scripts/check-plan.py

added="$(falsify imports work-issue/scripts/drive.py $'import argparse\n' $'import argparse\nimport resume_checks\n')"
expect_clean "import a sibling" "$added"

added="$(falsify vendored work-wave/scripts/check-footprints.py $'def paths_overlap(a, b):\n' $'def paths_overlap(a, b): \n')"
expect_named "a byte inside paths_overlap" "$added" work-wave/scripts/check-footprints.py work-issue/scripts/check-inflight.py

added="$(falsify vendored work-wave/scripts/check-footprints.py '"""Prove that the lanes' '"""Prove that  the lanes')"
expect_clean "a byte in the module docstring" "$added"

added="$(falsify exits work-issue/scripts/check-plan.py 'def error(self, message):' 'def no_error(self, message):')"
expect_named "the error override removed" "$added" work-issue/scripts/check-plan.py

check_scripts . covered | grep -qx "work-issue/scripts/check-plan.py" || {
  echo "the exit check's coverage rule no longer covers work-issue/scripts/check-plan.py" >&2
  exit 1
}

[[ "$script_checks_ok" == 1 ]] || exit 1

echo "repo-docs smoke: OK"
