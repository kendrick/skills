#!/usr/bin/env bash
# Write an input's raw sidecar, then dispose of the input, as two calls that
# keep phase 3's order: sidecar first, then the note, then disposal. Phase 4
# deletes a text source, and its words survive only in the sidecar, so the
# check that the sidecar is real has to run before the delete. Left to the
# agent, the first mechanical check was phase 6's lint, after the source was
# already gone (#388).
#
# `dispose` keys on the note's own `id` and `raw_file`, never on what happens
# to sit in notes/raw/. A folder-level check passes a note pointing at another
# note's sidecar, which is the wrong-id mistake the check exists to catch.
#
# Exit codes follow AGENTS.md's validator convention, since `dispose` gates a
# delete: 0 done, 1 refused with one stderr line per problem, 3 usage or
# unreadable input. Every refusal leaves the source in _inbox/.
#
# The only bash here is 3.2.57, Apple's: no associative arrays, no mapfile,
# no ${x,,}.
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: dispose-source.sh raw <scope-root> <inbox-file> --id <id> [--text <file>]
       dispose-source.sh dispose <scope-root> <inbox-file> --note <note-path>

  raw      write <scope-root>/notes/raw/<id>.md and print its raw_file line.
           .md and .txt are copied byte for byte, .vtt goes through
           collapse-vtt.sh, and a .pdf, .docx, or .pptx needs --text, the
           text another skill extracted from it.
  dispose  check the note's raw_file is raw/<its id>.md and that sidecar is
           a non-empty regular file, then delete a text source, or move a
           binary one to notes/attachments/ and print its source_file line.

  Paths are absolute, or relative to <scope-root>.
USAGE
}

fail_usage() {
  echo "$1" >&2
  exit 3
}

resolve() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$scope/$1" ;;
  esac
}

# Decided by extension, the same split phase 4 draws.
kind_of() {
  case "$(printf '%s' "${1##*.}" | tr '[:upper:]' '[:lower:]')" in
    md | txt | vtt) echo text ;;
    pdf | docx | pptx) echo binary ;;
    *) echo unknown ;;
  esac
}

[[ $# -ge 1 ]] || {
  usage
  exit 3
}
cmd="$1"
shift
case "$cmd" in
  raw | dispose) ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 3
    ;;
esac

[[ $# -ge 2 ]] || {
  usage
  exit 3
}
scope="${1%/}"
src_arg="$2"
shift 2
id="" text_arg="" note_arg=""
while [[ $# -gt 0 ]]; do
  [[ $# -ge 2 ]] || fail_usage "$1 needs a value"
  case "$cmd $1" in
    "raw --id") id="$2" ;;
    "raw --text") text_arg="$2" ;;
    "dispose --note") note_arg="$2" ;;
    *) fail_usage "unknown argument for $cmd: $1" ;;
  esac
  shift 2
done

[[ -d "$scope" ]] || fail_usage "not a directory: $scope"
src="$(resolve "$src_arg")"
[[ -f "$src" && -r "$src" ]] || fail_usage "not a readable file: $src"
kind="$(kind_of "$src")"
[[ "$kind" != unknown ]] || fail_usage "not a .md, .txt, .vtt, .pdf, .docx, or .pptx source: $src"

do_raw() {
  [[ -n "$id" ]] || fail_usage "raw needs --id"
  # The id lands in a path, so it gets nanoid's alphabet and nothing else.
  [[ "$id" =~ ^[A-Za-z0-9_-]+$ ]] || fail_usage "id is not a nanoid: $id"
  local text=""
  if [[ "$kind" == binary ]]; then
    [[ -n "$text_arg" ]] || fail_usage "a binary source needs --text with its extracted text: $src"
    text="$(resolve "$text_arg")"
    [[ -f "$text" && -r "$text" ]] || fail_usage "not a readable file: $text"
  else
    [[ -z "$text_arg" ]] || fail_usage "--text is for binary sources; $src is its own text"
  fi

  # Globals, not locals: the EXIT trap below reads them.
  raw_dir="$scope/notes/raw"
  local sidecar="$raw_dir/$id.md"
  if [[ -e "$sidecar" ]]; then
    echo "sidecar already exists, refusing to overwrite: $sidecar" >&2
    exit 1
  fi

  # A refusal undoes the mkdir too, notes/ included on a fresh scope.
  made_notes=0 made_raw=0
  [[ -d "$scope/notes" ]] || made_notes=1
  [[ -d "$raw_dir" ]] || made_raw=1
  mkdir -p "$raw_dir"
  # The temp file sits beside the sidecar so the final mv is a rename, and
  # no refusal can leave a half-written sidecar under the real name.
  tmp="$(mktemp "$raw_dir/.dispose-source.XXXXXX")"
  # mktemp makes the file 0600 and the rename keeps it, so give the sidecar
  # the mode a plain write would get under the caller's umask.
  chmod "$(printf '%o' $((0666 & ~0$(umask))))" "$tmp"
  trap 'rm -f "$tmp"; [[ $made_raw == 0 ]] || rmdir "$raw_dir"; [[ $made_notes == 0 ]] || rmdir "$scope/notes"; true' EXIT

  if [[ "$kind" == binary ]]; then
    cp "$text" "$tmp"
  elif [[ "$src" == *.[vV][tT][tT] ]]; then
    if ! bash "$(dirname "$0")/collapse-vtt.sh" "$src" >"$tmp"; then
      echo "collapse-vtt.sh refused $src; source left in place" >&2
      exit 1
    fi
  else
    cp "$src" "$tmp"
  fi

  if [[ ! -s "$tmp" ]]; then
    echo "raw text is empty, refusing to write a sidecar: $src" >&2
    exit 1
  fi
  mv "$tmp" "$sidecar"
  trap - EXIT
  echo "raw_file: raw/$id.md"
}

frontmatter() {
  awk '
    NR == 1 { if ($0 == "---") next; else exit }
    $0 == "---" { exit }
    { print }
  ' "$1"
}

do_dispose() {
  [[ -n "$note_arg" ]] || fail_usage "dispose needs --note"
  command -v yq >/dev/null 2>&1 || fail_usage "yq is required and not on PATH (brew install yq)"
  local note fields note_id raw_file
  note="$(resolve "$note_arg")"
  [[ -f "$note" && -r "$note" ]] || fail_usage "not a readable note: $note"
  fields="$(frontmatter "$note" | yq -r '(.id // ""), (.raw_file // "")' 2>/dev/null)" ||
    fail_usage "yq could not parse the frontmatter of $note"
  note_id="$(printf '%s\n' "$fields" | sed -n 1p)"
  raw_file="$(printf '%s\n' "$fields" | sed -n 2p)"

  # raw writes under <scope-root>/notes/, so a note anywhere else names a
  # sidecar raw never wrote, and attachments would land outside the scope.
  local bad=0 note_dir
  note_dir="$(cd "$(dirname "$note")" && pwd -P)"
  if [[ "$note_dir" != "$(cd "$scope" && pwd -P)/notes" ]]; then
    echo "note is not directly in $scope/notes/: $note" >&2
    exit 1
  fi
  local sidecar
  if [[ -z "$note_id" ]]; then
    echo "note has no id: $note" >&2
    bad=1
  elif [[ ! "$note_id" =~ ^[A-Za-z0-9_-]+$ ]]; then
    # raw's alphabet, so id: ../other can't walk the sidecar path out of raw/.
    echo "note's id is not a nanoid: $note_id: $note" >&2
    bad=1
  else
    sidecar="$note_dir/raw/$note_id.md"
    if [[ "$raw_file" != "raw/$note_id.md" ]]; then
      echo "note's raw_file is '$raw_file', want raw/$note_id.md: $note" >&2
      bad=1
    fi
    # -s alone passes a directory, and a symlink borrows a file raw never
    # wrote for this note, so only a regular non-empty file counts.
    if [[ -L "$sidecar" || ! -f "$sidecar" || ! -s "$sidecar" ]]; then
      echo "sidecar is missing, empty, or not a regular file: $sidecar" >&2
      bad=1
    fi
  fi

  local name att=""
  name="$(basename "$src")"
  if [[ "$kind" == binary ]]; then
    att="$note_dir/attachments/$name"
    # Renaming to dodge the clash is the user's call, not this script's.
    if [[ -e "$att" ]]; then
      echo "attachment name already taken: attachments/$name" >&2
      bad=1
    fi
  fi
  [[ "$bad" == 0 ]] || exit 1

  if [[ "$kind" == text ]]; then
    rm -- "$src"
    return
  fi
  mkdir -p "$note_dir/attachments"
  mv -n -- "$src" "$att"
  if [[ -e "$src" ]]; then
    echo "attachments/$name appeared during the move; source left in place" >&2
    exit 1
  fi
  echo "source_file: attachments/$name"
}

if [[ "$cmd" == raw ]]; then do_raw; else do_dispose; fi
