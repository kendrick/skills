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

# The queue is the opt-in marker, but it doesn't sit in the same place in every
# layout: scaffold mode puts it under notes/ for client and project scopes, and at
# the scope root only for journals. Check exactly those two spots. Matching
# _inbox/ at any depth would let a client root opt itself in on a queue belonging
# to one of its own projects.
if { [[ ! -d "$scope/_inbox" ]] && [[ ! -d "$scope/notes/_inbox" ]]; } ||
   { [[ ! -d "$scope/_memory" ]] && [[ ! -d "$scope/entries" ]]; }; then
  echo "not an opted-in scope: $scope (needs _inbox/ or notes/_inbox/, plus _memory/ or entries/)" >&2
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
      # The ./ is load-bearing. ls-tree run inside the scope prints paths
      # relative to it, but `show ref:path` resolves from the repo root unless
      # the path is written cwd-relative. Without it every read fails on a scope
      # that isn't the repo root, and the sweep reports zero links checked
      # alongside zero failures, which reads as a pass.
      *.md) git -C "$scope" show "$since_ref:./$f" ;;
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
  # Both finds prune every notes/raw/, nested project scopes' included. A sidecar
  # is named `<id>.md`, so a link to a note the migration deleted would otherwise
  # pass on the sidecar it left. The pattern names no scope path because `-path`
  # reads it as a glob, and a scope path holding `[` or `*` would match nothing.
  # `find -name` reads its argument as a glob, so the target is escaped: `[[*]]`
  # would otherwise match any note.
  esc="$(printf '%s' "$target" | sed 's/[][*?\\]/\\&/g')"
  by_name="$(find "$scope" -path '*/notes/raw' -prune -o -name "$esc.md" -print -quit)"
  if [[ -n "$by_name" ]]; then
    continue
  fi
  # Filenames first, then the trailing ten-character id: a target that used to
  # resolve by name and now only resolves by id is a pass, and worth counting
  # separately from one that resolved by name both times.
  id="${target: -10}"
  # A target under ten characters has no id: bash 5 yields "" for it, and an
  # empty id makes `-name "**.md"`, which matches every note.
  by_id=""
  if [[ "${#target}" -ge 10 ]]; then
    esc="$(printf '%s' "$id" | sed 's/[][*?\\]/\\&/g')"
    by_id="$(find "$scope" -path '*/notes/raw' -prune -o -name "*$esc*.md" -print -quit)"
  fi
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
# --to-ltm writes <scope>/memory-bank.yaml, so once committed that one file is
# an expected `A`. name-status paths are relative to the repo root, not the
# scope, hence the prefix.
bank_path="$(git -C "$scope" rev-parse --show-prefix)memory-bank.yaml"
while IFS=$'\t' read -r status path1 path2; do
  case "$status" in
    M) : ;;
    A)
      if [[ "$path1" != "$bank_path" ]]; then
        fail "$scope" "verify-rename: \`$path1\` has unexpected status \`$status\`"
      fi
      ;;
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

# --- ltm sweep ---------------------------------------------------------------
#
# Runs only beside a memory-bank.yaml: a pre-migration scope has no bank for the
# kit to validate. A missing `ltm` skips rather than fails, because this script
# stays runnable without the kit; the summary says so, since a skip is not a pass.
#
# ltm gets the bank file and the `schema: 1` records by path, never the scope
# root. Phase 5 writes the bank before --to-ltm runs, and `schema: 2` and v1
# records stay legal until then, so validating the whole bank failed every one
# of them (#276 F-r1-state-01). The test is yq's `.schema == 1`, the same one
# lint-scope.sh uses, so the lint and ltm judge the same set.
ltm_summary=""
if [[ -f "$scope/memory-bank.yaml" ]]; then
  if command -v ltm >/dev/null 2>&1; then
    ltm_paths=("$scope/memory-bank.yaml")
    if [[ -d "$scope/_memory" ]]; then
      while IFS= read -r rec; do
        # A CRLF record's fence reads `---\r`; without the strip it's never
        # selected and ltm never sees it (#276 round 3).
        fm="$(awk '{ sub(/\r$/, "") } NR == 1 { if ($0 != "---") exit; next } /^---$/ { exit } { print }' "$rec")"
        [[ "$(printf '%s\n' "$fm" | yq '.schema' 2>/dev/null || true)" == 1 ]] && ltm_paths+=("$rec")
      done < <(find "$scope/_memory" -name '*.md' -type f | sort)
    fi
    if ltm_out="$(ltm validate "${ltm_paths[@]}" 2>&1)"; then
      ltm_status=0
    else
      ltm_status=$?
    fi
    # Naming the bank file is the only way to have ltm check it without the
    # rest of the bank, and ltm answers that one path with this walk error
    # because the file isn't a record. Verify drops that one expected line and
    # doesn't treat the exit 1 it causes as a silent failure.
    ltm_errors=0
    bank_walk=0
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if [[ "$line" == "memory-bank.yaml:1: error walk: -: not a Record file under any configured type folder" ]]; then
        bank_walk=1
        continue
      fi
      # ltm prints `<file>:<line>: <severity> <rule>: <key>: <message>`. Only an
      # error fails: ltm itself exits 0 on warnings, so failing on one here
      # would fail a bank the kit accepts.
      case "$line" in
        *:[0-9]*': error '*)
          ltm_errors=$((ltm_errors + 1))
          fail "$scope" "verify-ltm: $line"
          ;;
        *) echo "info $scope: verify-ltm: $line" ;;
      esac
    done < <(printf '%s\n' "$ltm_out")
    if [[ "$ltm_status" -ne 0 && "$ltm_errors" -eq 0 && "$bank_walk" -eq 0 ]]; then
      ltm_errors=1
      fail "$scope" "verify-ltm: ltm validate exited $ltm_status without a finding"
    fi
    [[ "$ltm_errors" -ne 0 ]] || ltm_summary="ltm: validated"
  else
    ltm_summary="ltm: not installed; skipped"
  fi
fi

echo "scope: $scope"
echo "since: $since_ref"
echo "lint failures: $lint_failures"
echo "links checked: $links_checked (id fallback: $links_fallback)"
echo "renames: $renames"
echo "deletions: $deletions"
[[ -z "$ltm_summary" ]] || echo "$ltm_summary"
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
