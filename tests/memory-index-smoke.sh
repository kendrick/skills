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
# Before anything runs the script, so no case reads or writes the developer's
# real ~/.local/state/memory-index/.
export XDG_STATE_HOME="$tmp/state"
state="$XDG_STATE_HOME/memory-index"

mkdir -p "$tmp/bin" "$tmp/pybin"
cat >"$tmp/bin/qmd" <<'SHIM'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$QMD_LOG"
# Real qmd takes 3-4.8 s per call, so the hook cases sleep to prove they never wait on one.
[[ -n "${QMD_SLOW:-}" ]] && sleep "$QMD_SLOW"
[[ -n "${QMD_FAIL:-}" && "$1" == "$QMD_FAIL" ]] && exit 1
# QMD_COLLECTIONS lines are name<TAB>path<TAB>pattern; output mimics qmd 2.8.3.
if [[ "$1 ${2:-}" == "collection list" && -n "${QMD_COLLECTIONS:-}" ]]; then
  echo "Collections ($(wc -l <"$QMD_COLLECTIONS" | tr -d ' ')):"
  while IFS=$'\t' read -r n p m; do
    printf '%s (qmd://%s/)\n  Pattern:  %s\n' "$n" "$n" "$m"
  done <"$QMD_COLLECTIONS"
elif [[ "$1 ${2:-}" == "collection show" && -n "${QMD_COLLECTIONS:-}" ]]; then
  while IFS=$'\t' read -r n p m; do
    [[ "$n" == "$3" ]] && {
      printf 'Collection: %s\n  Path:     %s\n  Pattern:  %s\n' "$n" "$p" "$m"
      exit 0
    }
  done <"$QMD_COLLECTIONS"
  echo "Collection not found: $3" >&2
  exit 1
fi
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

## Record Types (lightweight mode)

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

# Case 6: refresh is update, embed, then the collection list it stamps, and
# stops at the first failure without stamping.
log6="$tmp/case6.log"
: >"$log6"
QMD_LOG="$log6" PATH="$shim_path" python3 "$script" refresh
printf '%s\n' update embed 'collection list' >"$expected"
same_file "$expected" "$log6" "case 6 refresh"

: >"$log6"
rm -f "$state/last-refresh.json"
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
[[ ! -e "$state/last-refresh.json" ]] || {
  echo "case 6: a failed refresh wrote the stamp" >&2
  exit 1
}

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

# Case 9: a description that names another type must not win the match. The
# Decision bullet says "rules", so a whole-line match gave the rules collection
# the Decision context. Each shape is a legal way to write the label: spaced
# dash, flush dash (house style), period after the bold, parenthetical.
n=0
for shape in 'D — d' 'D—d' 'D. d' 'D (d)'; do
  n=$((n + 1))
  gamma="$tmp/Gamma Scope $n"
  mkdir -p "$gamma/_memory/decisions" "$gamma/_memory/rules"
  dec="${shape/D/**Decision**}"
  dec="${dec/d/a choice made under standing rules}"
  printf '## Record Types (lightweight mode)\n\n- %s\n- **Rule** — a standing constraint\n' "$dec" >"$gamma/_memory/CLAUDE.md"
  gdry="$(PATH="$bare_path" python3 "$script" register "$gamma" --dry-run)"
  grep -F "context add qmd://gamma-scope-$n-rules " <<<"$gdry" | grep -Fq 'rules records: Rule — a standing constraint' || {
    echo "case 9 ($shape): rules collection did not get the Rule line; got:" >&2
    echo "$gdry" >&2
    exit 1
  }
  grep -F "context add qmd://gamma-scope-$n-decisions " <<<"$gdry" | grep -Fq 'decisions records: Decision' || {
    echo "case 9 ($shape): decisions collection did not get the Decision line; got:" >&2
    echo "$gdry" >&2
    exit 1
  }
done

# Plain bullets with no bold, no backticks, and no separator: the label is the
# leading capitalized words, so the lowercase description can't be read as one.
plain="$tmp/Plain Scope"
mkdir -p "$plain/_memory/decisions" "$plain/_memory/rules"
printf '## Record Types (lightweight mode)\n\n- Decision a choice made under standing rules\n- Rule a standing constraint\n' >"$plain/_memory/CLAUDE.md"
pdry="$(PATH="$bare_path" python3 "$script" register "$plain" --dry-run)"
grep -F 'context add qmd://plain-scope-rules ' <<<"$pdry" | grep -Fq 'rules records: Rule a standing constraint' || {
  echo "case 9 (plain bullets): rules collection did not get the Rule line; got:" >&2
  echo "$pdry" >&2
  exit 1
}

# Cases 10-23: `refresh --if-changed`, the hook mode.
cols="$tmp/collections.tsv"
printf '%s\t%s\t%s\n' \
  acme-pursuit-decisions "$abs/_memory/decisions" '**/*.md' \
  acme-pursuit-rules "$abs/_memory/rules" '**/*.md' \
  acme-pursuit-notes "$abs/notes" '*.md' \
  >"$cols"
log="$tmp/ic.log"

now_ms() {
  python3 -c 'import time; print(time.time_ns() // 1000000)'
}

# Command substitution waits for every writer of the pipe to close, which is
# how a harness reads a hook, so a child holding stdout would show in ic_ms.
if_changed() {
  local t0
  t0="$(now_ms)"
  set +e
  ic_out="$(env "$@" QMD_LOG="$log" PATH="${ic_path:-$shim_path}" python3 "$script" refresh --if-changed 2>"$tmp/ic.err")"
  ic_rc=$?
  set -e
  ic_ms=$(($(now_ms) - t0))
}

assert_hook_ok() {
  [[ "$ic_rc" == 0 ]] || {
    echo "$1: --if-changed exited $ic_rc" >&2
    exit 1
  }
  [[ -z "$ic_out" ]] || {
    echo "$1: --if-changed printed on stdout: $ic_out" >&2
    exit 1
  }
  [[ "$ic_ms" -lt 1000 ]] || {
    echo "$1: --if-changed took ${ic_ms} ms" >&2
    exit 1
  }
}

# The lock file outlives every refresh, so "running" means another process
# holds its flock. Probes only the state dir, never a scope.
lock_held() {
  ! python3 -c 'import fcntl,os,sys; fd=os.open(sys.argv[1], os.O_CREAT|os.O_WRONLY); fcntl.flock(fd, fcntl.LOCK_EX|fcntl.LOCK_NB)' "$state/refresh.lock" 2>/dev/null
}

wait_unlocked() {
  local i=0
  while lock_held; do
    i=$((i + 1))
    [[ "$i" -le 150 ]] || {
      echo "$1: refresh still holds the lock after 15 s" >&2
      exit 1
    }
    sleep 0.1
  done
}

log_empty() {
  [[ ! -s "$log" ]] || {
    echo "$1: qmd ran; log:" >&2
    cat "$log" >&2
    exit 1
  }
}

no_lock() {
  ! lock_held || {
    echo "$1: a refresh holds the lock" >&2
    exit 1
  }
}

count_is() {
  local want="$1"
  local line="$2"
  local what="$3"
  [[ "$(grep -cx -- "$line" "$log")" == "$want" ]] || {
    echo "$what: expected $want '$line' line(s) in the qmd log; got:" >&2
    cat "$log" >&2
    exit 1
  }
}

# Case 10: refresh stamps the collections it read from qmd, outside the scope.
: >"$log"
QMD_COLLECTIONS="$cols" QMD_LOG="$log" PATH="$shim_path" python3 "$script" refresh
printf '%s\n' update embed 'collection list' \
  'collection show acme-pursuit-decisions' \
  'collection show acme-pursuit-rules' \
  'collection show acme-pursuit-notes' \
  >"$expected"
same_file "$expected" "$log" "case 10 refresh"
require_file "$state/last-refresh.json"
[[ -z "$(find "$scope" -name 'last-refresh*' -o -name 'refresh.l*')" ]] || {
  echo "case 10: refresh wrote state inside the scope" >&2
  exit 1
}

# Case 11: nothing changed, so no qmd call, even one that would take 3 s.
: >"$log"
if_changed QMD_SLOW=3
assert_hook_ok "case 11"
log_empty "case 11"
no_lock "case 11"

# Case 12, falsifier: notes/raw/ and notes/_inbox/ sit under the notes
# collection's path but outside its *.md mask.
: >"$log"
printf x >"$scope/notes/raw/new.md"
printf x >"$scope/notes/_inbox/new.md"
if_changed QMD_SLOW=3
assert_hook_ok "case 12"
log_empty "case 12"
no_lock "case 12"

# Case 13, falsifier: a record changed, so one detached refresh starts, and a
# second call while it runs starts nothing.
: >"$log"
touch "$scope/_memory/decisions/vendor-a1b2c3.md"
if_changed QMD_SLOW=1 QMD_COLLECTIONS="$cols"
assert_hook_ok "case 13 first call"
lock_held || {
  echo "case 13: no lock while the refresh runs" >&2
  exit 1
}
if_changed QMD_SLOW=1 QMD_COLLECTIONS="$cols"
assert_hook_ok "case 13 second call"
wait_unlocked "case 13"
count_is 1 update "case 13"
count_is 1 embed "case 13"
cp "$log" "$tmp/case13.log"
if_changed QMD_SLOW=1 QMD_COLLECTIONS="$cols"
assert_hook_ok "case 13 third call"
wait_unlocked "case 13 third call"
same_file "$tmp/case13.log" "$log" "case 13 third call after the refresh"

# Case 14: the stamp is the refresh's start time, so a note written while
# update runs still counts as changed afterward. Waiting for the `update` line
# makes sure the child took its stamp before the write.
: >"$log"
touch "$scope/_memory/rules/deploys-g7h8i9.md"
if_changed QMD_SLOW=1 QMD_COLLECTIONS="$cols"
assert_hook_ok "case 14 first call"
i=0
until grep -qx update "$log"; do
  i=$((i + 1))
  [[ "$i" -le 50 ]] || {
    echo "case 14: the detached refresh never ran qmd update" >&2
    exit 1
  }
  sleep 0.1
done
lock_held || {
  echo "case 14: refresh finished before the mid-run write" >&2
  exit 1
}
touch "$scope/notes/2026-10-27-kickoff-abc123.md"
wait_unlocked "case 14 first refresh"
if_changed QMD_SLOW=1 QMD_COLLECTIONS="$cols"
assert_hook_ok "case 14 second call"
wait_unlocked "case 14 second refresh"
count_is 2 update "case 14"

# Case 15: a held lock blocks a refresh, and the kernel frees it when the
# holder dies, even by SIGKILL, so the next call refreshes without waiting.
: >"$log"
touch "$scope/_memory/decisions/vendor-a1b2c3.md"
python3 -c 'import fcntl,os,sys,time; fd=os.open(sys.argv[1], os.O_CREAT|os.O_WRONLY); fcntl.flock(fd, fcntl.LOCK_EX); time.sleep(60)' "$state/refresh.lock" &
holder=$!
i=0
until lock_held; do
  i=$((i + 1))
  [[ "$i" -le 50 ]] || {
    echo "test setup: case 15 holder never took the lock" >&2
    exit 1
  }
  sleep 0.1
done
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 15 held lock"
log_empty "case 15 held lock"
kill -9 "$holder"
wait "$holder" 2>/dev/null || true
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 15 killed holder"
wait_unlocked "case 15 killed holder"
count_is 1 update "case 15"

# Case 16: failures stay off stdout and exit 0, and a failed refresh keeps the
# old stamp.
: >"$log"
touch "$scope/_memory/decisions/vendor-a1b2c3.md"
cp "$state/last-refresh.json" "$tmp/stamp.before"
if_changed QMD_FAIL=update
assert_hook_ok "case 16 qmd failing"
wait_unlocked "case 16 qmd failing"
cmp -s "$tmp/stamp.before" "$state/last-refresh.json" || {
  echo "case 16: a failed refresh changed the stamp" >&2
  exit 1
}
require_text "$state/refresh.log" "FAILED: qmd update"

ic_path="$bare_path" if_changed
assert_hook_ok "case 16 no qmd"
no_lock "case 16 no qmd"
require_text "$tmp/ic.err" "qmd not on PATH"

: >"$tmp/a-file"
if_changed XDG_STATE_HOME="$tmp/a-file"
assert_hook_ok "case 16 state dir unwritable"

# Case 17: no stamp means nothing proves the index current.
: >"$log"
rm "$state/last-refresh.json"
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 17"
wait_unlocked "case 17"
count_is 1 update "case 17"
require_file "$state/last-refresh.json"

mtime_ns() {
  python3 -c 'import os,sys; print(os.stat(sys.argv[1]).st_mtime_ns)' "$1"
}

# Case 18: mv keeps a record's mtime, so only the stamp's file list shows the
# rename.
: >"$log"
before="$(mtime_ns "$scope/_memory/decisions/ship-d4e5f6.md")"
mv "$scope/_memory/decisions/ship-d4e5f6.md" "$scope/_memory/decisions/ship-moved-d4e5f6.md"
[[ "$(mtime_ns "$scope/_memory/decisions/ship-moved-d4e5f6.md")" == "$before" ]] || {
  echo "test setup: case 18 mv changed the record's mtime" >&2
  exit 1
}
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 18 rename"
wait_unlocked "case 18 rename"
count_is 1 update "case 18 rename"

# Case 19: a deleted record leaves no file newer than the stamp.
: >"$log"
rm "$scope/_memory/rules/deploys-g7h8i9.md"
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 19 delete"
wait_unlocked "case 19 delete"
count_is 1 update "case 19 delete"

# Case 20: the refresh after the delete recorded the new list, so nothing is stale.
: >"$log"
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 20"
log_empty "case 20"
no_lock "case 20"

# Case 21, falsifier: a move inside notes/raw/ stays outside the notes mask.
: >"$log"
mv "$scope/notes/raw/new.md" "$scope/notes/raw/moved.md"
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 21"
log_empty "case 21"
no_lock "case 21"

# Case 22: a stamp written before stamps listed files can't show the file set
# is unchanged, so the hook refreshes once to rewrite it.
: >"$log"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); [c.pop("files") for c in d["collections"]]; json.dump(d, open(p, "w"))' "$state/last-refresh.json"
if_changed QMD_COLLECTIONS="$cols"
assert_hook_ok "case 22 legacy stamp"
wait_unlocked "case 22 legacy stamp"
count_is 1 update "case 22 legacy stamp"

# Case 23: two hook calls started at once on a changed collection start one
# refresh between them.
: >"$log"
touch "$scope/_memory/decisions/vendor-a1b2c3.md"
for _ in 1 2; do
  env QMD_SLOW=1 QMD_COLLECTIONS="$cols" QMD_LOG="$log" PATH="$shim_path" python3 "$script" refresh --if-changed >/dev/null 2>&1 &
done
wait
wait_unlocked "case 23 simultaneous calls"
count_is 1 update "case 23 simultaneous calls"

require_text memory-index/SKILL.md 'python3 SCRIPT refresh --if-changed'
require_text memory-index/SKILL.md '`refresh --if-changed` is the hook mode. It prints nothing on stdout and exits 0 in every case.'
require_text memory-index/SKILL.md 'python3 <absolute path to scripts/memory-index.py> refresh --if-changed'
require_text memory-index/SKILL.md 'or when a matching file was added, renamed, moved, or deleted since then'
require_text memory-index/README.md 'or for a file added, renamed, moved, or deleted since then'
# Deliberately Not Built: SessionEnd's budget is too short for a refresh.
refute_text memory-index/SKILL.md 'SessionEnd'
refute_text memory-index/SKILL.md 'session-end'

echo "memory-index smoke: OK"
