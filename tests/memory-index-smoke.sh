#!/usr/bin/env bash
# Pin the memory-index skill. `qmd` is a PATH shim that only logs its argv, so
# the suite checks the exact commands `register` and `refresh` issue and runs
# without qmd installed. A real qmd on PATH never runs: the shim goes first,
# and the no-qmd cases build a PATH that cannot reach it.
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

expect_rc() {
  local want="$1"
  local got="$2"
  local what="$3"
  [[ "$got" == "$want" ]] || {
    echo "$what: expected exit $want, got $got" >&2
    exit 1
  }
}

same_file() {
  local want="$1"
  local got="$2"
  local what="$3"
  cmp -s "$want" "$got" || {
    echo "$what: log differs from expected" >&2
    diff "$want" "$got" >&2 || true
    exit 1
  }
}

script=memory-index/scripts/memory-index.py

require_file memory-index/SKILL.md
require_file memory-index/README.md
require_file "$script"
require_file _maintenance/memory-index/RATIONALE.md

[[ "$(find memory-index -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "memory-index/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

require_text README.md "--skill memory-index"
require_text memory-index/README.md "npx skills add kendrick/skills --skill memory-index"

# Model-invocable on purpose (ledger row 1): the dry run, not the flag, guards
# against a misfire.
refute_text memory-index/SKILL.md "disable-model-invocation"

# Case 8: the cuts in Deliberately Not Built, and the dry-run-first rule.
refute_text "$script" "index.yml"
refute_text memory-index/SKILL.md "--daemon"
refute_text "$script" "memory_type"
require_text memory-index/SKILL.md 'Run `register` with `--dry-run` first, show the user every command it prints, and run it for real only on a yes:'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/pybin"
cat >"$tmp/bin/qmd" <<'SHIM'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$QMD_LOG"
[[ -n "${QMD_FAIL:-}" && "$1" == "$QMD_FAIL" ]] && exit 1
exit 0
SHIM
chmod +x "$tmp/bin/qmd"
# python3 alone, so a PATH built from this dir has no qmd on it.
ln -s "$(command -v python3)" "$tmp/pybin/python3"
shim_path="$tmp/bin:$PATH"
bare_path="$tmp/pybin:/usr/bin:/bin"
PATH="$bare_path" command -v qmd >/dev/null 2>&1 && {
  echo "test setup: qmd reachable on $bare_path, the no-qmd cases would prove nothing" >&2
  exit 1
}

register() {
  local root="$1"
  local log="$2"
  : >"$log"
  QMD_LOG="$log" PATH="$shim_path" python3 "$script" register "$root"
}

# Fixture scope. The name carries a space and capitals so the slug rule shows.
scope="$tmp/Acme Pursuit"
mkdir -p "$scope/_memory/decisions" "$scope/_memory/rules" "$scope/notes/raw" "$scope/notes/_inbox"
cat >"$scope/CLAUDE.md" <<'EOF'
# Acme Pursuit

## The Project in One Paragraph

<!-- Fill in: replaced below -->
Acme is bidding on
the harbor contract.

## Next
EOF
cat >"$scope/_memory/CLAUDE.md" <<'EOF'
# Memory

## Record Types

- **Decision** — a choice made and why
- **Rule** — a standing constraint
EOF
printf -- '---\nmemory_type: Decision\n---\nPick vendor A.\n' >"$scope/_memory/decisions/vendor-a1b2c3.md"
printf -- '---\nmemory_type: Decision\n---\nShip in May.\n' >"$scope/_memory/decisions/ship-d4e5f6.md"
printf -- '---\nmemory_type: Rule\n---\nNo weekend deploys.\n' >"$scope/_memory/rules/deploys-g7h8i9.md"
printf 'groomed\n' >"$scope/notes/2026-10-27-kickoff-abc123.md"
printf 'transcript\n' >"$scope/notes/raw/2026-10-27-kickoff-abc123.md"

# The script resolves the root, so on macOS /var becomes /private/var.
abs="$(cd "$scope" && pwd -P)"
para="Acme is bidding on the harbor contract."

# Case 1: one collection per type folder plus notes, each followed by its
# context, with the mask on notes only.
expected="$tmp/expected.log"
printf '%s\n' \
  "collection add $abs/_memory/decisions --name acme-pursuit-decisions" \
  "context add qmd://acme-pursuit-decisions $para decisions records: Decision — a choice made and why" \
  "collection add $abs/_memory/rules --name acme-pursuit-rules" \
  "context add qmd://acme-pursuit-rules $para rules records: Rule — a standing constraint" \
  "collection add $abs/notes --name acme-pursuit-notes --mask *.md" \
  "context add qmd://acme-pursuit-notes $para Groomed notes, one per input; raw transcripts live in notes/raw/ and are not indexed." \
  >"$expected"

log1="$tmp/case1.log"
out="$(register "$scope" "$log1")"
same_file "$expected" "$log1" "case 1 register"
mcp='MCP: add {"qmd": {"command": "qmd", "args": ["mcp"]}} to your client'"'"'s mcpServers'
[[ "$(tail -n1 <<<"$out")" == "$mcp" ]] || {
  echo "case 1: stdout does not end with the MCP line; got: $(tail -n1 <<<"$out")" >&2
  exit 1
}

# Case 2: notes/raw/ is kept out by the mask, never registered as a path.
grep '^collection add' "$log1" | grep -Fq 'notes/raw' && {
  echo "case 2: a collection add names notes/raw" >&2
  exit 1
}

# Case 3, falsifier 1: a record moved between folders changes nothing, because
# collections are folders, not files.
mv "$scope/_memory/decisions/vendor-a1b2c3.md" "$scope/_memory/rules/"
log3="$tmp/case3.log"
register "$scope" "$log3" >/dev/null
same_file "$log1" "$log3" "case 3 register after a move"
rules_line="$(grep -F -- '--name acme-pursuit-rules' "$log3")"
rules_path="${rules_line#collection add }"
rules_path="${rules_path% --name acme-pursuit-rules}"
[[ "$rules_path" == */_memory/rules ]] || {
  echo "case 3: rules collection path does not end _memory/rules: $rules_path" >&2
  exit 1
}
mv "$scope/_memory/rules/vendor-a1b2c3.md" "$scope/_memory/decisions/"

# Case 4, falsifier 2: frontmatter never decides a collection.
sed -i.bak 's/^memory_type: Decision$/memory_type: Rule/' "$scope/_memory/decisions/ship-d4e5f6.md"
rm -f "$scope/_memory/decisions/ship-d4e5f6.md.bak"
grep -Fxq 'memory_type: Rule' "$scope/_memory/decisions/ship-d4e5f6.md" || {
  echo "test setup: case 4 frontmatter edit did not land" >&2
  exit 1
}
log4="$tmp/case4.log"
register "$scope" "$log4" >/dev/null
same_file "$log1" "$log4" "case 4 register after a frontmatter change"

# Case 5: the filled paragraph reaches every context (checked in case 1); an
# unfilled one falls back to the scope name. The fill-in comment spans lines,
# so a line-wise comment strip would leak it.
beta="$tmp/Beta Scope"
mkdir -p "$beta/_memory/context"
cat >"$beta/CLAUDE.md" <<'EOF'
## The Project in One Paragraph

<!-- Fill in: what this project is,
     who it is for -->

## Next
EOF
log5="$tmp/case5.log"
register "$beta" "$log5" >/dev/null
printf '%s\n' \
  "collection add $(cd "$beta" && pwd -P)/_memory/context --name beta-scope-context" \
  "context add qmd://beta-scope-context Memory scope beta-scope. context records." \
  >"$expected"
same_file "$expected" "$log5" "case 5 unfilled paragraph"

# Case 6: refresh is update then embed, and stops at the first failure.
log6="$tmp/case6.log"
: >"$log6"
QMD_LOG="$log6" PATH="$shim_path" python3 "$script" refresh
printf '%s\n' update embed >"$expected"
same_file "$expected" "$log6" "case 6 refresh"

: >"$log6"
set +e
err="$(QMD_FAIL=update QMD_LOG="$log6" PATH="$shim_path" python3 "$script" refresh 2>&1 >/dev/null)"
rc=$?
set -e
expect_rc 1 "$rc" "case 6 refresh with update failing"
grep -Fq 'FAILED: qmd update' <<<"$err" || {
  echo "case 6: missing FAILED: line; got: $err" >&2
  exit 1
}
printf '%s\n' update >"$expected"
same_file "$expected" "$log6" "case 6 refresh stops before embed"

# Case 7: unusable input exits 3 before any qmd command runs.
mkdir -p "$tmp/not-a-scope"
log7="$tmp/case7.log"
: >"$log7"
set +e
QMD_LOG="$log7" PATH="$shim_path" python3 "$script" register "$tmp/not-a-scope" 2>/dev/null
rc=$?
set -e
expect_rc 3 "$rc" "case 7 register without _memory/"
[[ ! -s "$log7" ]] || {
  echo "case 7: qmd ran on a dir without _memory/" >&2
  exit 1
}

set +e
err="$(PATH="$bare_path" python3 "$script" register "$scope" 2>&1 >/dev/null)"
rc=$?
set -e
expect_rc 3 "$rc" "case 7 register with no qmd on PATH"
grep -Fq 'qmd not on PATH' <<<"$err" || {
  echo "case 7: missing 'qmd not on PATH'; got: $err" >&2
  exit 1
}

set +e
err="$(PATH="$bare_path" python3 "$script" refresh 2>&1 >/dev/null)"
rc=$?
set -e
expect_rc 3 "$rc" "case 7 refresh with no qmd on PATH"

# The dry run needs no qmd and prints what case 1 logged, shell-quoted.
dry="$(PATH="$bare_path" python3 "$script" register "$scope" --dry-run)"
grep -Fxq "qmd collection add '$abs/notes' --name acme-pursuit-notes --mask '*.md'" <<<"$dry" || {
  echo "dry run: notes command missing or unquoted; got:" >&2
  echo "$dry" >&2
  exit 1
}
[[ "$(grep -c '^qmd ' <<<"$dry")" == "6" ]] || {
  echo "dry run: expected 6 qmd commands" >&2
  exit 1
}

echo "memory-index smoke: OK"
