#!/usr/bin/env bash
# Verify a migration someone already ran and committed, standalone from the
# migrator itself. It reads git history rather than the working tree's status
# for exactly that reason: by the time anyone runs this, `--apply` is long
# finished and `git status` on a committed change reports a clean tree.
#
# Requires bash, awk, git, and yq (brew install yq).
set -euo pipefail

usage() {
  echo "usage: ${0##*/} <scope-path> --since <ref>" >&2
}

scope=""
since_ref=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      shift
      [[ $# -gt 0 ]] || {
        echo "--since requires a ref argument" >&2
        exit 2
      }
      since_ref="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      [[ -n "$scope" ]] && {
        echo "verify one scope at a time" >&2
        exit 2
      }
      scope="${1%/}"
      ;;
  esac
  shift
done

[[ -n "$scope" ]] || {
  usage
  exit 2
}

[[ -n "$since_ref" ]] || {
  echo "--since <ref> is required" >&2
  usage
  exit 2
}

if [[ ! -d "$scope" ]]; then
  echo "not a directory: $scope" >&2
  exit 2
fi

if [[ ! -d "$scope/_inbox" ]] || { [[ ! -d "$scope/_memory" ]] && [[ ! -d "$scope/entries" ]]; }; then
  echo "not an opted-in scope: $scope (needs _inbox/ plus _memory/ or entries/)" >&2
  exit 2
fi

# This script's own terms, not the lint's: a scope missing yq has to fail here,
# before ever reaching a sibling that would otherwise take the blame.
if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required and not on PATH (brew install yq)" >&2
  exit 2
fi

if ! git -C "$scope" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "not inside a git repository: $scope" >&2
  exit 2
fi

if ! git -C "$scope" rev-parse --verify -q "${since_ref}^{commit}" >/dev/null; then
  echo "not a commit reachable from $scope: $since_ref" >&2
  exit 2
fi

failures=0
fail() {
  echo "FAIL $1: $2"
  failures=$((failures + 1))
}

# --- Lint sweep (C-6) --------------------------------------------------------
#
# Resolved as a sibling, not by a path back into this repo, so a copy of
# scripts/ runs that copy's lint rather than the one checked in here. That is
# the seam the abort case below is tested through.
lint_bin="$(dirname "${BASH_SOURCE[0]}")/lint-scope.sh"

if lint_out="$(bash "$lint_bin" "$scope" 2>&1)"; then
  lint_status=0
else
  lint_status=$?
fi

# An aborted lint (bad input, or its own yq preflight firing) never reaches its
# summary line, so a check that greps for "failures:" would read the abort as
# a clean sweep. The exit status is read directly instead, and it is the only
# signal that survives every shape of failure, including one that prints
# nothing at all.
if [[ "$lint_status" -eq 0 ]]; then
  lint_failures=0
else
  lint_failures="$(printf '%s\n' "$lint_out" | awk -F': ' '/^failures:/ { print $2 }')"
  if [[ -n "$lint_failures" ]]; then
    while IFS= read -r line; do
      fail "$scope" "verify-lint: $line"
    done < <(printf '%s\n' "$lint_out" | grep -E '^FAIL ')
  else
    lint_failures="unknown (aborted before a summary)"
    fail "$scope" "verify-lint: lint-scope.sh aborted with exit status $lint_status before printing a summary"
  fi
fi

# --- Link sweep (C-7) --------------------------------------------------------
#
# Targets come from the scope as it stood at --since, never from the migrated
# tree: a link deleted along with its target during migration still has to be
# checked, and reading targets from the post-migration tree would drop it
# before the sweep ever saw it.
since_tree_targets() {
  local f
  while IFS= read -r f; do
    case "$f" in
      *.md) git -C "$scope" show "$since_ref:$f" ;;
    esac
  done < <(git -C "$scope" ls-tree -r --name-only "$since_ref") |
    grep -oE '\[\[[^]|]*' | sed 's/^\[\[//' | sort -u
}

declare -a link_targets=()
while IFS= read -r target; do
  [[ -z "$target" ]] && continue
  # An unsubstituted placeholder is not a link; templates ship with them.
  case "$target" in
    *'{{'* | *'<'*) continue ;;
  esac
  link_targets+=("$target")
done < <(since_tree_targets)

links_checked=0
links_fallback=0
for target in ${link_targets[@]+"${link_targets[@]}"}; do
  links_checked=$((links_checked + 1))
  by_name="$(find "$scope" -name "$target.md" -print -quit)"
  if [[ -n "$by_name" ]]; then
    continue
  fi
  # Filenames first, then the trailing ten-character id: a target that used to
  # resolve by name and now only resolves by id is a pass, and worth counting
  # separately from one that resolved by name both times.
  id="${target: -10}"
  by_id="$(find "$scope" -name "*$id*.md" -print -quit)"
  if [[ -n "$by_id" ]]; then
    links_fallback=$((links_fallback + 1))
    continue
  fi
  fail "$scope" "verify-link: \`$target\` resolves neither by name nor by id \`$id\`"
done

# --- Rename sweep (C-8) -------------------------------------------------------
#
# A single-ref diff, not `git status --porcelain`: porcelain compares the
# index to the working tree and reports clean the moment a rename is
# committed, which is exactly the state this script exists to check.
renames=0
deletions=0
while IFS=$'\t' read -r status path1 path2; do
  case "$status" in
    M) : ;;
    R*)
      renames=$((renames + 1))
      fail "$scope" "verify-rename: \`$path1\` renamed to \`$path2\`"
      ;;
    D)
      deletions=$((deletions + 1))
      fail "$scope" "verify-rename: \`$path1\` deleted"
      ;;
    *)
      fail "$scope" "verify-rename: \`$path1\` has unexpected status \`$status\`"
      ;;
  esac
done < <(git -C "$scope" diff --name-status -M "$since_ref" -- .)

echo "scope: $scope"
echo "since: $since_ref"
echo "lint failures: $lint_failures"
echo "links checked: $links_checked (id fallback: $links_fallback)"
echo "renames: $renames"
echo "deletions: $deletions"
echo "failures: $failures"

# The record is stdout-only and exists for a passing run alone: a migration
# that did not verify has nothing paste-ready to say, and nothing here ever
# touches patterns-journal/ or any other file. The paste instruction prints
# above the paragraph rather than inside it: an instruction welded into the
# record travels with it into the journal, where the entry then tells the
# reader to file it somewhere it already is. Printing it first also leaves the
# record as the last thing the run prints.
if [[ "$failures" -eq 0 ]]; then
  # Links are the only counter here that can carry a one. The other three call
  # `fail` when nonzero, and a failing run prints no record at all, so they
  # only ever reach this paragraph at zero, where the plural is already right.
  links_noun=links
  if [[ "$links_checked" -eq 1 ]]; then
    links_noun=link
  fi
  printf '\nPaste the paragraph below into the scope'"'"'s patterns journal.\n\n'
  printf 'Verified %s against %s on %s: %s lint failures, %s %s checked (%s by id fallback), %s renames, %s deletions. The link count covers every distinct wiki-link target the scope carried at that ref, resolved against the tree as it stands now.\n' \
    "$scope" "$since_ref" "$(date +%Y-%m-%d)" "$lint_failures" "$links_checked" "$links_noun" "$links_fallback" "$renames" "$deletions"
fi

[[ "$failures" -eq 0 ]]
