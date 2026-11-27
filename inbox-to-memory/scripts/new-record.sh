#!/usr/bin/env bash
# Write one phase 5 record, or one journal entry, from its template: id,
# folder, dates, source_refs and status filled, and memory-bank.yaml written
# first when the scope has none. The title and body stay for the agent. Done
# by hand, these were five steps per record that took no judgment, and a
# mistyped id or a wrong folder passed the lint (#411).
#
# The folder comes from memory_type and the scope's mode, and from nothing
# else. A rule picked from the slug or the template's filename puts a
# canonical `rule-of-thumb` PolicyRule in rules/.
#
# Every check runs before the first write, so a refusal writes nothing. Exit
# codes follow dispose-source.sh: 0 written, 1 refused with one stderr line
# per problem, 3 usage. Stdout is the new file's path relative to the root.
#
# The only bash here is 3.2.57, Apple's: no associative arrays, no mapfile,
# no ${x,,}.
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: new-record.sh <scope-root> --type <memory_type> --slug <slug> --note <note-id> [--status proposed|accepted]
       new-record.sh <journal-root> --journal --slug <slug> --note <note-id> --source-scope <path>

  A record lands in <scope-root>/_memory/<folder>/<slug>-<id>.md, the folder
  set by --type and the scope's memory mode. --status defaults to proposed.
  A journal entry lands in <journal-root>/entries/YYYY-MM-DD-<slug>-<id>.md,
  and --source-scope is the note's scope path from the vault root.
USAGE
}

fail_usage() {
  echo "$1" >&2
  exit 3
}

problems=0
refuse() {
  echo "$1" >&2
  problems=$((problems + 1))
}

stop_if_refused() {
  [[ $problems -eq 0 ]] || exit 1
}

# Quoted pattern and replacement: bash 5.2's patsub_replacement reads a bare
# `&` in the replacement as the match, and a source path may hold one.
fill() {
  content=${content//"$1"/"$2"}
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  "" | -*)
    usage
    exit 3
    ;;
esac
scope="${1%/}"
shift
journal=0 type="" slug="" note="" status="" source_scope="" status_set=0
while [[ $# -gt 0 ]]; do
  if [[ "$1" == --journal ]]; then
    journal=1
    shift
    continue
  fi
  [[ $# -ge 2 ]] || fail_usage "$1 needs a value"
  case "$1" in
    --type) type="$2" ;;
    --slug) slug="$2" ;;
    --note) note="$2" ;;
    --status)
      status="$2"
      status_set=1
      ;;
    --source-scope) source_scope="$2" ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
  shift 2
done

[[ -n "$slug" ]] || fail_usage "--slug is required"
[[ -n "$note" ]] || fail_usage "--note is required"
if [[ $journal -eq 1 ]]; then
  [[ -z "$type" ]] || fail_usage "--journal takes no --type"
  [[ $status_set -eq 0 ]] || fail_usage "--journal takes no --status; a new entry is always current"
  [[ -n "$source_scope" ]] || fail_usage "--journal needs --source-scope"
else
  [[ -n "$type" ]] || fail_usage "--type is required"
  [[ -z "$source_scope" ]] || fail_usage "--source-scope is for --journal"
  [[ $status_set -eq 1 ]] || status=proposed
fi

assets="$(cd "$(dirname "$0")/.." && pwd)/assets"

[[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || refuse "slug is not lowercase kebab-case: $slug"
# The note id lands in source_refs, so it gets nanoid's alphabet and nothing else.
[[ "$note" =~ ^[A-Za-z0-9_-]+$ ]] || refuse "note id is not a nanoid: $note"

if [[ $journal -eq 1 ]]; then
  # Either one breaks the quoted '<scope>::<note-id>' string in source_refs.
  case "$source_scope" in
    *"'"* | *"::"*) refuse "--source-scope holds ' or ::, which source_refs can't carry: $source_scope" ;;
  esac
  [[ -d "$scope/entries" ]] || refuse "not a journal root, no entries/: $scope"
  stop_if_refused
  template="$assets/records/journal-entry.template.md"
else
  case "$status" in
    proposed | accepted) ;;
    *) refuse "status is not proposed or accepted: $status" ;;
  esac
  [[ -d "$scope/_memory" ]] || refuse "not an opted-in scope, no _memory/: $scope"
  stop_if_refused

  # The bank wins over CLAUDE.md, since the bank is what the lint and ltm read.
  bank="$scope/memory-bank.yaml"
  mode=""
  if [[ -f "$bank" ]]; then
    if ! folders="$(yq -o=json -I=0 '.folders' "$bank" 2>/dev/null)"; then
      refuse "yq could not parse $bank"
    elif [[ "$folders" == null ]]; then
      mode=canonical
    elif [[ "$folders" == '{"PolicyRule":"_memory/rules"}' ]]; then
      mode=lightweight
    else
      refuse "memory-bank.yaml's folders is neither absent nor {PolicyRule: _memory/rules}: $folders"
    fi
  else
    mode="$(grep -oE '\*\*Memory mode:\*\* (lightweight|canonical)' "$scope/CLAUDE.md" 2>/dev/null | head -n 1 | sed 's/.* //' || true)"
    [[ -n "$mode" ]] || refuse "no memory-bank.yaml and no **Memory mode:** line in $scope/CLAUDE.md"
  fi
  stop_if_refused

  case "$type $mode" in
    "Decision "*) folder=decisions template=decision ;;
    "Context "*) folder=context template=context ;;
    "PolicyRule lightweight") folder=rules template=rule ;;
    "PolicyRule canonical") folder=policy-rules template=policy-rule ;;
    "Exception canonical") folder=exceptions template=exception ;;
    "Exception lightweight") refuse "a lightweight scope holds no Exception records; write a Decision or list it under the rule's Known Exceptions" ;;
    *) refuse "memory_type is not Decision, Context, PolicyRule or Exception: $type" ;;
  esac
  stop_if_refused
  template="$assets/records/$template.template.md"

  if [[ ! -f "$bank" ]]; then
    # Vendored from scope_name() in memory-index/scripts/memory-index.py
    # (line 35), 2026-11-27, in migrate-scope.sh's shape. Upstream is
    # authoritative: fix a bug there first, then re-copy. A bank name that
    # drifts from the collection names memory-index registers labels the
    # same scope two ways. This skill installs standalone, so it can't
    # import it. The scope is resolved with pwd -P because memory-index
    # names Path(...).resolve(), so a symlinked scope takes its target's
    # name there too.
    if ! bank_name="$(python3 -c 'import re, sys; from pathlib import Path; root = Path(sys.argv[1]); print(re.sub(r"[^a-z0-9]+", "-", root.name.lower()).strip("-"))' "$(cd "$scope" && pwd -P)")"; then
      refuse "python3 failed while deriving the bank name from the scope directory"
    elif [[ -z "$bank_name" ]]; then
      # Unlike --to-ltm (row 95): the lint fails an empty name, so writing
      # one would break the scope this call is adding a record to.
      refuse "the scope directory's name has no a-z or 0-9 character, so the bank name would be empty; rename the directory"
    fi
  fi
fi

if ! id="$(nanoid -s 10)"; then
  refuse "nanoid -s 10 failed"
elif [[ ! "$id" =~ ^[A-Za-z0-9_-]{10}$ ]]; then
  refuse "nanoid -s 10 printed something other than a 10-character id: $id"
fi
stop_if_refused

today="$(date +%F)"
if [[ $journal -eq 1 ]]; then
  rel="entries/$today-$slug-$id.md"
else
  rel="_memory/$folder/$slug-$id.md"
fi
target="$scope/$rel"
[[ ! -e "$target" ]] || refuse "already exists, refusing to overwrite: $target"
stop_if_refused

# Read with a sentinel so $(...) keeps the template's trailing newline.
content="$(
  cat "$template"
  printf x
)"
content="${content%x}"
fill "{{nanoid}}" "$id"
fill "{{YYYY-MM-DD}}" "$today"
fill "{{note-id}}" "$note"
if [[ $journal -eq 1 ]]; then
  fill "{{scope path from vault root}}" "$source_scope"
else
  fill "{{proposed | accepted}}" "$status"
fi

# noclobber, so a file another writer created after the exists check is never overwritten.
set -o noclobber
if [[ $journal -eq 0 && ! -f "$bank" ]]; then
  bank_text="$(
    if [[ "$mode" == canonical ]]; then
      # Drop the folders line and the comment block that describes it.
      awk '/^#/ { buf = buf $0 "\n"; next }
           /^folders:/ { buf = ""; next }
           { printf "%s", buf; buf = ""; print }
           END { printf "%s", buf }' "$assets/memory-bank.template.yaml"
    else
      cat "$assets/memory-bank.template.yaml"
    fi
  )"
  bank_text=${bank_text//"{{SCOPE_NAME}}"/"$bank_name"}
  if ! printf '%s\n' "$bank_text" >"$bank" 2>/dev/null; then
    echo "memory-bank.yaml appeared while writing, refusing to overwrite: $bank" >&2
    exit 1
  fi
fi
mkdir -p "$(dirname "$target")"
if ! printf '%s' "$content" >"$target" 2>/dev/null; then
  echo "already exists, refusing to overwrite: $target" >&2
  exit 1
fi
printf '%s\n' "$rel"
