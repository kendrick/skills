#!/usr/bin/env bash
# tools/refresh.sh
#
# Keep the Databricks skill files in sync with upstream Databricks docs.
#
# Modes:
#   --backfill  Walk docs/raw/ and (re)build {domain}/docs/sources.json from
#               whatever is on disk. Safe to re-run; preserves fetched_at for
#               files whose sha256 still matches.
#   --check     (default) Re-fetch each tracked URL via Jina, compare hashes,
#               write refresh-report-{domain}.md listing drift. Read-only
#               against the repo (no writes to raw docs or manifest).
#   --apply     Same as --check, plus overwrite changed raw docs and bump
#               sources.json. Does NOT touch the compressed skill files —
#               that's the refresh skill's job (semantic regen).

set -euo pipefail

# --- bash version guard ----------------------------------------------------

if [[ -z "${BASH_VERSION:-}" ]]; then
    echo "ERROR: refresh.sh requires bash. Run as 'bash tools/refresh.sh' or './tools/refresh.sh'." >&2
    exit 3
fi

# --- dep check (fail fast with a useful message) ---------------------------

hint_for() {
    case "$1" in
        curl)      echo "usually pre-installed; otherwise 'brew install curl' (macOS) or 'apt install curl' (Debian/Ubuntu)" ;;
        jq)        echo "'brew install jq' (macOS) or 'apt install jq' (Debian/Ubuntu)" ;;
        awk)       echo "part of base system; install 'gawk' or 'mawk' if somehow missing" ;;
        sed)       echo "part of base system; install via your package manager if missing" ;;
        diff)      echo "part of 'diffutils'; install via your package manager if missing" ;;
        shasum)    echo "ships with Perl on macOS/Linux; install 'perl' if missing" ;;
        sha256sum) echo "part of GNU coreutils; install 'coreutils' if missing" ;;
        *)         echo "" ;;
    esac
}

SHA_CMD=""
if command -v shasum >/dev/null 2>&1; then
    SHA_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
    SHA_CMD="sha256sum"
fi

check_deps() {
    local missing=()
    local cmd
    for cmd in curl jq awk sed diff; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [[ -z "$SHA_CMD" ]]; then
        missing+=("shasum-or-sha256sum")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: refresh.sh is missing required command(s):" >&2
        for cmd in "${missing[@]}"; do
            if [[ "$cmd" == "shasum-or-sha256sum" ]]; then
                echo "  - shasum OR sha256sum" >&2
                echo "      shasum: $(hint_for shasum)" >&2
                echo "      sha256sum: $(hint_for sha256sum)" >&2
            else
                echo "  - $cmd ($(hint_for "$cmd"))" >&2
            fi
        done
        echo "" >&2
        echo "Install the missing tool(s) and re-run." >&2
        exit 3
    fi
}
check_deps

# --- config + CLI ----------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="check"
DOMAIN=""
VERBOSE=0
JINA_SLEEP=3

usage() {
    cat <<EOF
Usage: $0 [--backfill | --check | --apply | --refetch-broken] [--domain <name>] [--verbose]

Modes:
  --backfill         Build {domain}/docs/sources.json from on-disk raw docs (idempotent).
  --check            (default) Re-fetch via Jina and report drift. Read-only.
  --apply            Re-fetch via Jina, overwrite changed raw docs, update manifest.
  --refetch-broken   Find raw/*.md cached as Jina partial-render placeholders and re-fetch them.

Options:
  --domain <name>  Limit to a single domain (e.g. genie). Default: all domains.
  --verbose        Print per-operation progress to stderr.
  -h, --help       Show this help.

Prereqs: curl, jq, awk, sed, diff, and shasum (or sha256sum).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --backfill) MODE="backfill"; shift ;;
        --check)    MODE="check"; shift ;;
        --apply)    MODE="apply"; shift ;;
        --refetch-broken) MODE="refetch-broken"; shift ;;
        --domain)   DOMAIN="${2:-}"; [[ -z "$DOMAIN" ]] && { echo "ERROR: --domain requires a value" >&2; exit 2; }; shift 2 ;;
        --verbose)  VERBOSE=1; shift ;;
        -h|--help)  usage; exit 0 ;;
        *)          echo "ERROR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
    esac
done

# --- helpers ---------------------------------------------------------------

log()  { [[ $VERBOSE -eq 1 ]] && echo "$@" >&2 || true; }
info() { echo "$@" >&2; }

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
hash_file() { $SHA_CMD "$1" | awk '{print $1}'; }

# Parse "URL Source: https://..." from line 3 of a raw file (Jina format).
parse_url() {
    sed -n '3p' "$1" | sed 's/^URL Source: //'
}

# Apply the same Jina nav-strip as databricks-skill-generator-prompt.md, Phase 0c,
# then drop the per-request ad tracking pixel Databricks injects on every page
# (`![Image N](https://insight.adsrvr.org/...)`). The tracker has a fresh query
# string on every fetch, so leaving it in would make every doc look "changed."
clean_jina() {
    local f="$1"
    awk '
      NR<=5 { print; next }
      /^## / && !found { found=1 }
      found { print }
    ' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
    # Drop the tracking pixel line and any trailing blank line it leaves behind.
    awk '!/^!\[Image [0-9]+\]\(https:\/\/insight\.adsrvr\.org\//' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
    # Normalize trailing whitespace-only lines so a single final newline is canonical.
    # Without this, Jina's variable trailing-blank output makes every doc look "changed."
    awk '/[^[:space:]]/ {last=NR} {lines[NR]=$0} END {for (i=1; i<=last; i++) print lines[i]}' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
}

# Discover domains: top-level dirs containing docs/raw/.
discover_domains() {
    local d name
    for d in "$REPO_ROOT"/*/; do
        name=$(basename "$d")
        [[ -d "$d/docs/raw" ]] && echo "$name"
    done
}

domains_to_process() {
    if [[ -n "$DOMAIN" ]]; then
        if [[ ! -d "$REPO_ROOT/$DOMAIN/docs/raw" ]]; then
            echo "ERROR: domain '$DOMAIN' has no docs/raw/ directory at $REPO_ROOT/$DOMAIN/docs/raw" >&2
            exit 4
        fi
        echo "$DOMAIN"
    else
        discover_domains
    fi
}

rel_path() { echo "${1#$REPO_ROOT/}"; }

# --- backfill --------------------------------------------------------------

backfill_domain() {
    local domain="$1"
    local raw_dir="$REPO_ROOT/$domain/docs/raw"
    local manifest="$REPO_ROOT/$domain/docs/sources.json"
    local existing="[]"
    [[ -f "$manifest" ]] && existing=$(cat "$manifest")
    local now; now=$(now_iso)
    local f op url sha prev_ts ts

    {
        for f in "$raw_dir"/*.md; do
            [[ -f "$f" ]] || continue
            op=$(basename "$f" .md)
            url=$(parse_url "$f")
            sha=$(hash_file "$f")
            # Preserve fetched_at if existing entry has the same sha.
            prev_ts=$(echo "$existing" | jq -r --arg op "$op" --arg sha "$sha" \
                '.[] | select(.operation == $op and .sha256 == $sha) | .fetched_at')
            if [[ -n "$prev_ts" && "$prev_ts" != "null" ]]; then
                ts="$prev_ts"
            else
                ts="$now"
            fi
            jq -n --arg op "$op" --arg url "$url" --arg ts "$ts" --arg sha "$sha" \
                '{operation: $op, url: $url, fetched_at: $ts, sha256: $sha}'
            log "  $op"
        done
    } | jq -s 'sort_by(.operation)' > "$manifest"

    local count; count=$(jq 'length' "$manifest")
    info "backfill $domain: $count operations -> $(rel_path "$manifest")"
}

# --- check / apply ---------------------------------------------------------

# Fetch a URL via Jina to stdout, with the nav-strip applied. Returns non-zero on failure.
# Two failure modes Jina gives us look like success: a near-empty body (SPA never
# loaded) and a body containing the literal "page maybe not yet fully loaded" warning
# (SPA partially loaded). Both used to land in the cache and look like real docs on
# subsequent runs. We catch both, bump X-Timeout above Jina's default to give SPAs
# room to hydrate, and retry once before giving up.
fetch_clean() {
    local url="$1"
    local tmp; tmp=$(mktemp)
    local placeholder='page maybe not yet fully loaded'
    local attempt
    for attempt in 1 2; do
        local timeout_s=$(( attempt == 1 ? 30 : 60 ))
        if curl -sf -H "X-Timeout: $timeout_s" "https://r.jina.ai/${url}" -o "$tmp" \
            && [[ $(wc -c < "$tmp") -ge 200 ]] \
            && ! grep -q "$placeholder" "$tmp"; then
            clean_jina "$tmp"
            cat "$tmp"
            rm -f "$tmp"
            return 0
        fi
        [[ $attempt -eq 1 ]] && sleep 10
    done
    rm -f "$tmp"
    return 1
}

check_or_apply_domain() {
    local domain="$1"
    local mode="$2"  # "check" or "apply"
    local raw_dir="$REPO_ROOT/$domain/docs/raw"
    local manifest="$REPO_ROOT/$domain/docs/sources.json"
    local report="$REPO_ROOT/refresh-report-${domain}.md"

    if [[ ! -f "$manifest" ]]; then
        info "ERROR: manifest not found at $(rel_path "$manifest"). Run: bash tools/refresh.sh --backfill --domain $domain"
        return 5
    fi

    local total=0 changed=0 failed=0 unchanged=0
    local now; now=$(now_iso)
    local fetched_tmp; fetched_tmp=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '$fetched_tmp'" RETURN

    {
        echo "# Refresh report: $domain"
        echo
        echo "- Generated: $now"
        echo "- Mode: $mode"
        echo
    } > "$report"

    # Consistency: raw files on disk vs. manifest entries.
    local raw_ops manifest_ops untracked missing
    raw_ops=$(cd "$raw_dir" && ls *.md 2>/dev/null | sed 's/\.md$//' | sort || true)
    manifest_ops=$(jq -r '.[].operation' "$manifest" | sort)
    untracked=$(comm -23 <(echo "$raw_ops") <(echo "$manifest_ops") | sed '/^$/d' || true)
    missing=$(comm -13 <(echo "$raw_ops") <(echo "$manifest_ops") | sed '/^$/d' || true)

    if [[ -n "$untracked" ]]; then
        {
            echo "## UNTRACKED raw files (present on disk, absent from manifest)"
            echo
            echo "Run 'bash tools/refresh.sh --backfill --domain $domain' to add."
            echo
            echo "$untracked" | sed 's/^/- /'
            echo
        } >> "$report"
    fi
    if [[ -n "$missing" ]]; then
        {
            echo "## MISSING raw files (in manifest but not on disk)"
            echo
            echo "$missing" | sed 's/^/- /'
            echo
        } >> "$report"
    fi

    # Drift check per tracked operation.
    local op url cached_sha cached_file new_file new_sha
    while IFS= read -r op; do
        [[ -z "$op" ]] && continue
        total=$((total + 1))
        url=$(jq -r --arg op "$op" '.[] | select(.operation == $op) | .url' "$manifest")
        cached_sha=$(jq -r --arg op "$op" '.[] | select(.operation == $op) | .sha256' "$manifest")
        cached_file="$raw_dir/$op.md"
        new_file="$fetched_tmp/$op.md"

        log "fetch $domain/$op"
        if ! fetch_clean "$url" > "$new_file" 2>/dev/null; then
            failed=$((failed + 1))
            {
                echo "## FAILED: $op"
                echo
                echo "Could not fetch $url (Jina returned empty/error)."
                echo
            } >> "$report"
            sleep "$JINA_SLEEP"
            continue
        fi

        new_sha=$(hash_file "$new_file")
        if [[ "$new_sha" == "$cached_sha" ]]; then
            unchanged=$((unchanged + 1))
        else
            changed=$((changed + 1))
            {
                echo "## CHANGED: $op"
                echo
                echo "- URL: $url"
                echo "- Old sha256: $cached_sha"
                echo "- New sha256: $new_sha"
                echo
                echo "Unified diff (cached vs fetched):"
                echo
                echo '```diff'
                diff -u "$cached_file" "$new_file" || true
                echo '```'
                echo
            } >> "$report"

            if [[ "$mode" == "apply" ]]; then
                cp "$new_file" "$cached_file"
                local tmp_manifest; tmp_manifest=$(mktemp)
                jq --arg op "$op" --arg sha "$new_sha" --arg ts "$now" \
                    '(.[] | select(.operation == $op)) |= (.sha256 = $sha | .fetched_at = $ts)' \
                    "$manifest" > "$tmp_manifest" && mv "$tmp_manifest" "$manifest"
            fi
        fi
        sleep "$JINA_SLEEP"
    done <<< "$manifest_ops"

    {
        echo "## Summary"
        echo
        echo "- Total tracked: $total"
        echo "- Unchanged: $unchanged"
        echo "- Changed: $changed"
        echo "- Failed: $failed"
        [[ -n "$untracked" ]] && echo "- Untracked raw files: $(echo "$untracked" | wc -l | tr -d ' ')"
        [[ -n "$missing" ]] && echo "- Missing raw files: $(echo "$missing" | wc -l | tr -d ' ')"
    } >> "$report"

    info "$mode $domain: $total ops ($unchanged unchanged, $changed changed, $failed failed) -> $(basename "$report")"

    # Suppress report file when nothing of interest is in it.
    if [[ "$changed" -eq 0 && "$failed" -eq 0 && -z "$untracked" && -z "$missing" ]]; then
        rm -f "$report"
        info "  no drift; report omitted"
    fi
}

# --- refetch-broken --------------------------------------------------------

# Walk a domain's cached raw docs, find any that contain the Jina partial-render
# warning ("page maybe not yet fully loaded"), and re-fetch each via fetch_clean
# (which has the same hardening as --check/--apply). On success: replace the file
# and bump sha256 + fetched_at in the manifest. On failure: leave the file alone
# and report it so the user can investigate.
refetch_broken_domain() {
    local domain="$1"
    local raw_dir="$REPO_ROOT/$domain/docs/raw"
    local manifest="$REPO_ROOT/$domain/docs/sources.json"
    local placeholder='page maybe not yet fully loaded'
    local now; now=$(now_iso)
    local ok=0 fail=0 total=0

    if [[ ! -f "$manifest" ]]; then
        info "ERROR: manifest not found at $(rel_path "$manifest")."
        return 5
    fi

    local f op url tmp sha tmp_m
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        total=$((total + 1))
        op=$(basename "$f" .md)
        url=$(jq -r --arg op "$op" '.[] | select(.operation == $op) | .url' "$manifest")
        if [[ -z "$url" || "$url" == "null" ]]; then
            info "  SKIP  $domain/$op: not in manifest"
            fail=$((fail + 1))
            continue
        fi
        log "refetch $domain/$op"
        tmp=$(mktemp)
        if fetch_clean "$url" > "$tmp" 2>/dev/null; then
            sha=$(hash_file "$tmp")
            mv "$tmp" "$f"
            tmp_m=$(mktemp)
            jq --arg op "$op" --arg sha "$sha" --arg ts "$now" \
                '(.[] | select(.operation == $op)) |= (.sha256 = $sha | .fetched_at = $ts)' \
                "$manifest" > "$tmp_m" && mv "$tmp_m" "$manifest"
            info "  OK    $domain/$op"
            ok=$((ok + 1))
        else
            rm -f "$tmp"
            info "  FAIL  $domain/$op (still broken; manual investigation needed)"
            fail=$((fail + 1))
        fi
        sleep "$JINA_SLEEP"
    done < <(grep -rl "$placeholder" "$raw_dir" 2>/dev/null | sort)

    info "refetch-broken $domain: $total placeholder file(s) ($ok recovered, $fail still broken)"
}

# --- main ------------------------------------------------------------------

case "$MODE" in
    backfill)
        for d in $(domains_to_process); do
            backfill_domain "$d"
        done
        ;;
    check|apply)
        for d in $(domains_to_process); do
            check_or_apply_domain "$d" "$MODE"
        done
        ;;
    refetch-broken)
        for d in $(domains_to_process); do
            refetch_broken_domain "$d"
        done
        ;;
esac
