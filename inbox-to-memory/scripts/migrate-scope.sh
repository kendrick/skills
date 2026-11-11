#!/usr/bin/env bash
# Rewrite one opted-in scope's v1 frontmatter onto the v2 contract, and touch
# nothing below the fence.
#
# Tier 1 is the mechanical half of migration: every transformation here has
# exactly one correct answer, which is why the whole tier can be approved in one
# go. Anything needing judgment (writing a summary, naming entities, choosing a
# relation for a bare id) is reported and left alone.
#
# Tier 2 covers the two judgment calls this script can enforce without making
# them itself: summary and entities. `--tier2-extract` hands an agent each v1
# note's extracted sections plus a proposals file to fill in; `--tier2 --apply`
# then holds that file to what the extract actually says, refusing anything it
# can't verify rather than trusting the agent that wrote it.
#
# The body is copied byte for byte, so a migrated file is v2 above the fence and
# v1 below it. It says so with `body_schema: 1`, which is what stops the lint from
# holding a note written in 2025 to a grammar that did not exist yet.
#
# `--to-ltm` is a separate pass over `schema: 2` records, moving them onto
# long-term-memory-kit's `schema: 1` and writing the scope's memory-bank.yaml.
# A bare facet takes its prefix from the facet map alone, and any record the
# pass can't rewrite refuses the whole apply.
#
# Requires bash, awk, yq, and git. The awk does the frontmatter rewrite because
# the transform needs keyed lookups, and the bash that ships on macOS has none.
set -euo pipefail

NOTE_KEY_ORDER="schema body_schema id date type summary attendees tags topics entities source_file raw_file transcript_corrections open_questions resolved_questions deferred_tensions unpromoted_candidates related"
RECORD_KEY_ORDER="schema body_schema id memory_type title status date effective_from effective_to last_confirmed source_refs applies_to owners tags themes related exception_to supersedes superseded_by"
# long-term-memory-kit's order, copied byte for byte from lint-scope.sh, which
# says where it comes from. --to-ltm writes it.
LTM_RECORD_KEY_ORDER="schema id memory_type title status date effective_from effective_to last_confirmed review_by summary superseded_by supersedes promoted_from promoted_to subject applies_to owners tags source_refs related body_schema exception_to"

FRONTMATTER_LINE_BUDGET=20

apply=0
allow_dirty=0
scope=""
tier2_file=""
tier2_extract_dir=""
to_ltm=0
dry_run=0
facet_map=""

usage() {
  cat >&2 <<'USAGE'
usage: migrate-scope.sh <scope-path> [--apply] [--allow-dirty]
       migrate-scope.sh <scope-path> --tier2-extract <dir>
       migrate-scope.sh <scope-path> --tier2 <proposals-file> --apply
       migrate-scope.sh <scope-path> --to-ltm [--facet-map <file>] [--apply] [--allow-dirty]

  <scope-path>       a directory with _inbox/ or notes/_inbox/, plus _memory/ or entries/
  --apply            write the changes; without it nothing is written
  --allow-dirty      proceed even though the working tree has uncommitted changes
  --tier2-extract    for each v1 note, write its extracted sections and a
                      proposals skeleton to <dir>, and write nothing to the scope
  --tier2            merge summary/entities from a filled-in proposals file into
                      the Tier 1 rewrite; only takes effect together with --apply
  --dry-run          the default; named so a command can say so, and never mixes with --apply
  --to-ltm           move schema 2 records under _memory/ to long-term-memory-kit's
                      schema 1 and write memory-bank.yaml; refuses the whole scope
                      if any record can't move
  --facet-map        a YAML file mapping bare applies_to/owners values to a prefix
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1 ;;
    --allow-dirty) allow_dirty=1 ;;
    --dry-run) dry_run=1 ;;
    --to-ltm) to_ltm=1 ;;
    --facet-map)
      shift
      [[ $# -gt 0 ]] || {
        echo "--facet-map requires a file argument" >&2
        exit 2
      }
      facet_map="$1"
      ;;
    --tier2)
      shift
      [[ $# -gt 0 ]] || {
        echo "--tier2 requires a proposals file argument" >&2
        exit 2
      }
      tier2_file="$1"
      ;;
    --tier2-extract)
      shift
      [[ $# -gt 0 ]] || {
        echo "--tier2-extract requires a directory argument" >&2
        exit 2
      }
      tier2_extract_dir="$1"
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
        echo "migrate one scope at a time" >&2
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

[[ -d "$scope" ]] || {
  echo "not a directory: $scope" >&2
  exit 2
}

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

command -v yq >/dev/null 2>&1 || {
  echo "yq is required and not on PATH (brew install yq)" >&2
  exit 2
}

# Extract and apply are separate runs by design (see the header comment on
# extract_body): the extract has to exist and be reviewed before anything
# claims to be sourced from it, so one invocation never does both.
if [[ -n "$tier2_file" && -n "$tier2_extract_dir" ]]; then
  echo "--tier2 and --tier2-extract do not mix in one run" >&2
  exit 2
fi

if [[ "$dry_run" -eq 1 && "$apply" -eq 1 ]]; then
  echo "--dry-run and --apply contradict each other" >&2
  exit 2
fi

# The ltm move is a different contract from Tier 1/2, with its own all-or-nothing
# rule; letting it ride along with a Tier 2 merge would put two refusal policies
# on one run.
if [[ "$to_ltm" -eq 1 && ( -n "$tier2_file" || -n "$tier2_extract_dir" ) ]]; then
  echo "--to-ltm does not mix with --tier2 or --tier2-extract" >&2
  exit 2
fi

if [[ -n "$facet_map" ]]; then
  [[ "$to_ltm" -eq 1 ]] || {
    echo "--facet-map only applies with --to-ltm" >&2
    exit 2
  }
  [[ -f "$facet_map" ]] || {
    echo "facet map not found: $facet_map" >&2
    exit 2
  }
  yq '.' "$facet_map" >/dev/null 2>&1 || {
    echo "facet map does not parse as YAML: $facet_map" >&2
    exit 2
  }
fi

if [[ -n "$tier2_file" ]]; then
  [[ -f "$tier2_file" ]] || {
    echo "tier2 proposals file not found: $tier2_file" >&2
    exit 2
  }
fi

if [[ -n "$tier2_extract_dir" ]]; then
  [[ "$apply" -eq 0 ]] || {
    echo "--tier2-extract only writes extracts; it never applies" >&2
    exit 2
  }
  mkdir -p "$tier2_extract_dir"
fi

# Every safety claim this script makes rests on `git diff` being readable
# afterward. Starting from a dirty tree makes a mistake here indistinguishable
# from whatever was already uncommitted, so the escape hatch is explicit.
if [[ "$apply" -eq 1 && "$allow_dirty" -eq 0 ]]; then
  if ! git -C "$scope" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "not inside a git repository; rerun with --allow-dirty if that is intended" >&2
    exit 2
  fi
  if [[ -n "$(git -C "$scope" status --porcelain .)" ]]; then
    echo "working tree has uncommitted changes under $scope" >&2
    echo "commit or stash first, or rerun with --allow-dirty" >&2
    exit 2
  fi
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/i2m-migrate.XXXXXX")"
trap 'rm -rf "$work"' EXIT

migrated=0
skipped=0
refused=0
: >"$work/findings"

has_schema_key() {
  awk '
    NR == 1 { if ($0 == "---") { in_fm = 1; next } else { exit } }
    in_fm && $0 == "---" { exit }
    in_fm && /^schema:/ { found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

frontmatter_end() {
  awk '
    NR == 1 && $0 != "---" { print 0; done = 1; exit }
    NR > 1 && $0 == "---" { print NR; done = 1; exit }
    END { if (!done) print 0 }
  ' "$1"
}

# Byte-for-byte the extraction the lint uses. Two implementations of one counting
# rule is how a migrated scope ends up failing the check meant to certify it.
extract_body() {
  awk '
    { sub(/\r$/, "") }
    f && /^## Raw Content/ { exit }
    f && /<!--/ { in_comment = 1 }
    f && in_comment { if (/-->/) in_comment = 0; next }
    f { print }
    /^---$/ { c++; if (c == 2) f = 1 }
  ' "$1"
}

count_matches() {
  { grep -oE -- "$2" "$1" 2>/dev/null || true; } | wc -l | tr -d ' '
}

count_open_contradictions() {
  { grep -F -- '[contradicts accepted:' "$1" || true; } |
    { grep -Fvc -- '| dismissed:' || true; } | tr -d ' '
}

# Must match lint-scope.sh: a dismissed update-existing line keeps its candidate token, so the migrated count gives it back or the lint rejects the note.
count_dismissed_amends() {
  { grep -F -- '[memory candidate: update existing' "$1" || true; } |
    { grep -Fc -- '| dismissed:' || true; } | tr -d ' '
}

# Must match lint-scope.sh: a landed working-state line keeps its token as provenance, so the count gives it back or the lint rejects the note.
count_landed_working_state() {
  { grep -F -- '[working-state candidate]' "$1" || true; } |
    { grep -Fc -- '| landed:' || true; } | tr -d ' '
}

props_value() {
  awk -v k="$2" '
    { sep = index($0, " = "); if (sep == 0) next }
    substr($0, 1, sep - 1) == k { print substr($0, sep + 3); exit }
  ' "$1"
}

render_frontmatter() {
  awk -v order="$2" -v extras="$3" -v label="$4" '
    # Inside a flow sequence a colon is only structural when a space follows it,
    # which is what lets `extends::JJuYgImRWn` stay bare and match the shape the
    # templates emit. Titles and summaries are prose and always get quoted, so a
    # migrated record reads the same as one the skill wrote today.
    function yamlize(k, v) {
      if (k == "title" || k == "summary" || v == "" ||
          v ~ /[#,[\]{}'"'"']/ || v ~ /: / || v ~ /:$/ ||
          v ~ /^[ ]/ || v ~ /[ ]$/) {
        gsub(/'"'"'/, "'"'"''"'"'", v)
        return "'"'"'" v "'"'"'"
      }
      return v
    }
    function note(msg) { print "  " label ": " msg > "/dev/stderr" }
    BEGIN {
      split(order, ord, " ")
      n_ex = split(extras, ex, ";")
      for (i = 1; i <= n_ex; i++) {
        if (ex[i] == "") continue
        p = index(ex[i], "=")
        k = substr(ex[i], 1, p - 1)
        scal[k] = substr(ex[i], p + 1)
        have[k] = 1
      }
    }
    {
      sep = index($0, " = ")
      if (sep == 0) next
      path = substr($0, 1, sep - 1)
      value = substr($0, sep + 3)
      nd = split(path, part, ".")
      key = part[1]
      if (!(key in seen)) { seen[key] = 1; order_in[++nk] = key }
      if (nd == 1) {
        if (!(key in have)) scal[key] = value
        have[key] = 1
      } else if (nd == 2) {
        idx = part[2] + 0
        item[key SUBSEP idx] = value
        if (idx + 1 > cnt[key]) cnt[key] = idx + 1
        islist[key] = 1
      } else {
        idx = part[2] + 0
        field[key SUBSEP idx SUBSEP part[3]] = value
        subfields[key SUBSEP idx] = subfields[key SUBSEP idx] " " part[3]
        if (idx + 1 > cnt[key]) cnt[key] = idx + 1
        islist[key] = 1
      }
    }
    END {
      # A relationship is one greppable string. The left half carries the meaning,
      # so an entry that never recorded one cannot be flattened without inventing
      # it: that entry keeps its bare id and gets named in the report instead.
      for (k in cnt) {
        for (i = 0; i < cnt[k]; i++) {
          if ((k SUBSEP i) in item) continue
          id = ((k SUBSEP i SUBSEP "note_id") in field) ? field[k SUBSEP i SUBSEP "note_id"] : ""
          lhs = ""
          if (k == "related" && (k SUBSEP i SUBSEP "relation") in field)
            lhs = field[k SUBSEP i SUBSEP "relation"]
          if (k == "source_refs" && (k SUBSEP i SUBSEP "path") in field)
            lhs = field[k SUBSEP i SUBSEP "path"]
          if (lhs != "" && id != "") item[k SUBSEP i] = lhs "::" id
          else if (id != "") item[k SUBSEP i] = id
          else item[k SUBSEP i] = ""

          # A compound string has room for exactly two halves. Anything else the
          # old mapping carried is about to stop existing, so it gets named here
          # rather than discovered missing a year from now.
          consumed = (k == "source_refs") ? " note_id path " : " note_id relation "
          n_sub = split(subfields[k SUBSEP i], subkey, " ")
          for (s = 1; s <= n_sub; s++) {
            if (subkey[s] == "" || index(consumed, " " subkey[s] " ")) continue
            note("`" k "` entry " i " dropped `" subkey[s] ": " field[k SUBSEP i SUBSEP subkey[s]] "`, which the compound form has no room for")
          }
        }
      }
      for (i = 0; i < cnt["related"]; i++) {
        v = item["related" SUBSEP i]
        if (v != "" && index(v, "::") == 0)
          note("`related` holds bare id `" v "`; a relation has to be chosen by hand")
      }

      for (i = 1; i in ord; i++) emit(ord[i])
      # Anything the contract never named survives at the end rather than being
      # dropped. Silent loss during a migration is the failure nobody notices
      # until the note they needed it from is a year old.
      for (i = 1; i <= nk; i++) {
        k = order_in[i]
        if (k in emitted) continue
        emit(k)
        note("`" k "` is in neither key order and was kept at the end")
      }
    }
    function emit(k,   i, items, v) {
      if (k in emitted) return
      if (islist[k]) {
        items = ""
        for (i = 0; i < cnt[k]; i++) {
          v = item[k SUBSEP i]
          if (v == "") continue
          items = items (items == "" ? "" : ", ") yamlize(k, v)
        }
        print k ": [" items "]"
        emitted[k] = 1
      } else if (k in have) {
        print k ": " yamlize(k, scal[k])
        emitted[k] = 1
      }
    }
  ' "$1"
}

shopt -s nullglob

# --to-ltm moves records, and only records, onto long-term-memory-kit's schema 1.
# It checks every record before it writes any, because a scope left half in each
# format fails ltm validate and the lint at once, and nothing says which half is
# which. A refusal anywhere means nothing is written anywhere.
if [[ "$to_ltm" -eq 1 ]]; then
  : >"$work/ltm-refusals"
  : >"$work/ltm-unmapped"
  : >"$work/ltm-used"
  : >"$work/ltm-writes"
  to_ltm_count=0
  already_ltm=0
  n_refusals=0

  refuse() {
    echo "  $1: $2" >>"$work/ltm-refusals"
    n_refusals=$((n_refusals + 1))
  }

  # Quote every item except a facet. A plain id like 1234567890 or 1e10000000
  # parses as a number, and ltm wants a string. A facet opens with `prefix:`,
  # which no YAML number, bool, null or date can, so it stays plain and
  # greppable as `topic:billing`.
  ltm_item() {
    local v="$1"
    if [[ "$v" =~ ^[a-z][a-z0-9-]*:[A-Za-z0-9_./][A-Za-z0-9_./:\ -]*$ && "$v" != *": "* && "$v" != *" " && "$v" != *: ]]; then
      printf '%s' "$v"
    else
      # Bash 3.2 keeps the backslashes in a quoted \'\' replacement, which breaks the YAML; a variable replacement behaves the same in 3.2 and 5.
      local q="''"
      printf "'%s'" "${v//\'/$q}"
    fi
  }

  map_prefix() {
    [[ -n "$facet_map" ]] || return 0
    FM_K="$2" yq -r ".$1[strenv(FM_K)] // \"\"" "$facet_map"
  }

  for file in "$scope"/_memory/*/*.md; do
    case "${file##*/}" in
      CLAUDE.md | README.md) continue ;;
    esac

    # Skipping a CRLF record let an apply exit 0 with it still at schema 2, and rewriting it byte-safe is a second code path for a rare input, so refuse it. Check every line, since an LF opening fence over CRLF lines hides the closing fence just as well.
    if grep -q $'\r$' "$file"; then
      refuse "$file" "CRLF line endings; convert the record to LF and commit it first"
      continue
    fi
    end="$(frontmatter_end "$file")"
    [[ "$end" -eq 0 ]] && continue
    sed -n "2,$((end - 1))p" "$file" >"$work/block"
    if ! yq '.' "$work/block" >/dev/null 2>&1; then
      refuse "$file" "yq could not parse the frontmatter"
      continue
    fi
    # Runs ahead of the yq reads below: yq takes the last duplicate, so a repeated
    # schema or memory_type would decide the skip before this check saw it, and an
    # empty repeat types as null. Column-0 keys only, since this precedes the
    # one-key-per-line refusal and list items would read as keys.
    dup_key="$(awk '/^[A-Za-z_]/ { k = substr($0, 1, index($0, ":") - 1); if (k in s) { print k; exit } s[k] = 1 }' "$work/block")"
    if [[ -n "$dup_key" ]]; then
      refuse "$file" "key '$dup_key' appears more than once in the frontmatter"
      continue
    fi
    memory_type="$(yq -r '.memory_type // ""' "$work/block")"
    [[ -n "$memory_type" ]] || continue

    schema_value="$(yq -r '.schema // "absent"' "$work/block")"
    case "$schema_value" in
      absent)
        refuse "$file" "v1 record; run the Tier 1 migration first"
        continue
        ;;
      1)
        already_ltm=$((already_ltm + 1))
        for key in applies_to owners; do
          yq -r "(.$key // []) | .[]" "$work/block" 2>/dev/null |
            { grep -oE '^[a-z][a-z0-9-]*:' || true; } | tr -d ':' >>"$work/ltm-used"
        done
        continue
        ;;
      2) ;;
      *)
        refuse "$file" "schema: $schema_value is neither 2 nor 1"
        continue
        ;;
    esac

    # The rewrite swaps whole lines, which is only sound on the v2 contract's
    # one-key-per-line block. A block list or folded scalar needs a human.
    if grep -qvE '^([A-Za-z_][A-Za-z0-9_]*:( |$)|#|[[:space:]]*$)' "$work/block"; then
      refuse "$file" "frontmatter is not one key per line"
      continue
    fi

    : >"$work/repl"
    record_refused=0
    has_key() { grep -qE "^$1:( |$)" "$work/block"; }
    ytype() { yq -r ".$1 | type" "$work/block"; }

    printf 'schema\tschema: 1\n' >>"$work/repl"

    case "$memory_type" in
      Rule) printf 'memory_type\tmemory_type: PolicyRule\n' >>"$work/repl" ;;
      Decision | PolicyRule | Exception | Context) ;;
      *)
        refuse "$file" "memory_type $memory_type has no long-term-memory-kit type"
        record_refused=1
        ;;
    esac

    for key in applies_to owners; do
      has_key "$key" || continue
      case "$(ytype "$key")" in
        '!!null')
          printf '%s\t\n' "$key" >>"$work/repl"
          continue
          ;;
        '!!seq') ;;
        *)
          refuse "$file" "$key is not a list"
          record_refused=1
          continue
          ;;
      esac
      items=""
      while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        if [[ "$entry" =~ ^([a-z][a-z0-9-]*)::(.+)$ ]]; then
          prefix="${BASH_REMATCH[1]}"
          new="$prefix:${BASH_REMATCH[2]}"
        elif [[ "$entry" =~ ^([a-z][a-z0-9-]*):[^:] ]]; then
          prefix="${BASH_REMATCH[1]}"
          new="$entry"
        else
          # Never infer a prefix: `billing` could be a system, a topic, or a
          # team, and a guessed one reads exactly like a chosen one.
          prefix="$(map_prefix "$key" "$entry")"
          if [[ -z "$prefix" ]]; then
            printf '  %s: %s\n' "$key" "$entry" >>"$work/ltm-unmapped"
            refuse "$file" "$key value '$entry' has no prefix and no facet-map entry"
            record_refused=1
            continue
          fi
          if ! [[ "$prefix" =~ ^[a-z][a-z0-9-]*$ ]]; then
            refuse "$file" "the facet map gives $key value '$entry' the prefix '$prefix', which is not a lowercase prefix"
            record_refused=1
            continue
          fi
          new="$prefix:$entry"
        fi
        if ! [[ "$new" =~ ^[a-z][a-z0-9-]*:[^:] ]]; then
          refuse "$file" "$key value '$entry' would become '$new', which still has a doubled colon"
          record_refused=1
          continue
        fi
        echo "$prefix" >>"$work/ltm-used"
        items="${items:+$items, }$(ltm_item "$new")"
      done < <(yq -r ".$key[]" "$work/block")
      printf '%s\t%s: [%s]\n' "$key" "$key" "$items" >>"$work/repl"
    done

    if has_key related; then
      case "$(ytype related)" in
        '!!null') printf 'related\t\n' >>"$work/repl" ;;
        '!!seq')
          while IFS= read -r entry; do
            [[ -n "$entry" ]] || continue
            if ! [[ "$entry" =~ ^[a-z_]+::[A-Za-z0-9_-]{10}$ ]]; then
              refuse "$file" "related entry '$entry' is not <relation>::<10-character id>"
              record_refused=1
            fi
          done < <(yq -r '.related[]' "$work/block")
          ;;
        *)
          refuse "$file" "related is not a list"
          record_refused=1
          ;;
      esac
    fi

    # The kit's id and date patterns reject a literal null or an empty string,
    # so an unset optional key goes rather than staying as a placeholder.
    for key in effective_from effective_to superseded_by supersedes; do
      has_key "$key" || continue
      if [[ "$(ytype "$key")" == '!!null' || -z "$(yq -r ".$key" "$work/block")" ]]; then
        printf '%s\t\n' "$key" >>"$work/repl"
      elif [[ "$key" == supersedes && "$(ytype "$key")" != '!!seq' ]]; then
        printf 'supersedes\tsupersedes: [%s]\n' "$(ltm_item "$(yq -r '.supersedes' "$work/block")")" >>"$work/repl"
      fi
    done

    [[ "$record_refused" -eq 0 ]] || continue

    awk -F '\t' '
      NR == FNR { repl[$1] = $2; seen[$1] = 1; next }
      {
        k = substr($0, 1, index($0, ":") - 1)
        if (k in seen) { if (repl[k] != "") print repl[k]; next }
        print
      }
    ' "$work/repl" "$work/block" >"$work/new-fm"

    # ltm re-emits a record in this order on its first write, so writing any
    # other order hands the user a lint failure (#318). Refuse an unknown key,
    # since the lint fails any key outside this order. A commented-out key
    # (the v2 templates ship them) holds no value, so it is dropped, not
    # refused: refusing blocked every scope filled from the template. Any other
    # comment gets its own sentinel: it has no colon, so its key reads as empty,
    # and an empty bad would let END print a block truncated at the comment.
    if ! awk -v order="$LTM_RECORD_KEY_ORDER" '
      BEGIN { n = split(order, o, " "); for (i = 1; i <= n; i++) at[o[i]] = i }
      /^[[:space:]]*$/ { next }
      /^# *[A-Za-z_][A-Za-z0-9_]*:/ { next }
      /^#/ { bad = "#"; exit }
      {
        k = substr($0, 1, index($0, ":") - 1)
        if (!(k in at)) { bad = k; exit }
        line[at[k]] = $0
      }
      END {
        if (bad != "") { print bad > "/dev/stderr"; exit 1 }
        for (i = 1; i <= n; i++) if (i in line) print line[i]
      }
    ' "$work/new-fm" >"$work/new-fm.ordered" 2>"$work/bad-key"; then
      if [[ "$(cat "$work/bad-key")" == "#" ]]; then
        refuse "$file" "frontmatter holds a comment, which long-term-memory-kit's writers drop"
      else
        refuse "$file" "key '$(cat "$work/bad-key")' is not in long-term-memory-kit's key order"
      fi
      continue
    fi
    mv "$work/new-fm.ordered" "$work/new-fm"

    lines="$(wc -l <"$work/new-fm" | tr -d ' ')"
    if [[ $((lines + 2)) -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
      refuse "$file" "rewritten frontmatter needs $((lines + 2)) lines, past the $FRONTMATTER_LINE_BUDGET-line budget"
      continue
    fi
    if ! yq '.' "$work/new-fm" >/dev/null 2>&1; then
      refuse "$file" "the rewritten frontmatter does not parse"
      continue
    fi

    to_ltm_count=$((to_ltm_count + 1))
    candidate="$work/ltm-candidate.$to_ltm_count"
    {
      echo "---"
      cat "$work/new-fm"
      echo "---"
      tail -n +$((end + 1)) "$file"
    } >"$candidate"
    printf '%s\t%s\n' "$candidate" "$file" >>"$work/ltm-writes"

    echo "--- $file"
    diff -u <(sed -n "1,${end}p" "$file") <(sed -n "1,$((lines + 2))p" "$candidate") |
      tail -n +3 || true
  done

  bank="$scope/memory-bank.yaml"
  bank_status="present, left alone"
  if [[ -f "$bank" ]]; then
    # An existing bank file is the owner's; the pass checks it covers the
    # records and never edits it.
    declared="$(yq -r '(.facet_prefixes // []) | .[]' "$bank" 2>/dev/null || true)"
    while IFS= read -r prefix; do
      [[ -n "$prefix" ]] || continue
      grep -qxF -- "$prefix" <<<"$declared" ||
        refuse "$bank" "records use the prefix '$prefix', which facet_prefixes does not declare"
    done < <(sort -u "$work/ltm-used")
    # Without this entry the kit looks for PolicyRule in _memory/policy-rules/,
    # so the rules this pass rewrites would validate clean and then be invisible
    # to `ltm show` (#276 F-r1-authz-01). The bank is the owner's file, so the
    # pass names the fix rather than writing it.
    if [[ -d "$scope/_memory/rules" ]]; then
      rules_folder="$(yq -r '.folders.PolicyRule // ""' "$bank" 2>/dev/null || true)"
      [[ "${rules_folder%/}" == "_memory/rules" ]] ||
        refuse "$bank" "folders maps no PolicyRule to _memory/rules; add 'folders: {PolicyRule: _memory/rules}' by hand"
    fi
  else
    if [[ -n "$facet_map" ]]; then
      while IFS= read -r prefix; do
        [[ -n "$prefix" ]] || continue
        if [[ "$prefix" =~ ^[a-z][a-z0-9-]*$ ]]; then
          echo "$prefix" >>"$work/ltm-used"
        else
          refuse "$facet_map" "prefixes entry '$prefix' is not a lowercase prefix"
        fi
      done < <(yq -r '(.prefixes // []) | .[]' "$facet_map")
    fi
    prefixes="$(sort -u "$work/ltm-used" | paste -sd ',' - | sed 's/,/, /g')"
    if [[ -z "$prefixes" ]]; then
      refuse "$bank" "no facet prefix to declare, since no record uses one; list at least one under the facet map's prefixes key"
    fi
    bank_name="$(basename "$(cd "$scope" && pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"
    {
      echo "schema: 1"
      echo "name: '$bank_name'"
      echo "facet_prefixes: [$prefixes]"
      [[ -d "$scope/_memory/rules" ]] && echo "folders: {PolicyRule: _memory/rules}"
    } >"$work/bank"
    bank_status="would be written"
  fi

  echo
  echo "scope: $scope"
  echo "to ltm: $to_ltm_count"
  echo "already ltm: $already_ltm"
  echo "memory-bank.yaml: $bank_status"

  if [[ -s "$work/ltm-unmapped" ]]; then
    echo
    echo "unmapped:"
    sort -u "$work/ltm-unmapped"
  fi

  if [[ "$n_refusals" -gt 0 ]]; then
    echo
    echo "needs a human:"
    cat "$work/ltm-refusals"
    echo
    echo "refused; nothing was written. resolve every line above, then rerun."
    exit 1
  fi

  if [[ "$apply" -eq 1 ]]; then
    while IFS=$'\t' read -r candidate target; do
      cat "$candidate" >"$target"
    done <"$work/ltm-writes"
    [[ -f "$work/bank" ]] && cp "$work/bank" "$bank" && echo "memory-bank.yaml: written"
  else
    echo
    echo "dry run; nothing was written. rerun with --apply to write these changes."
  fi
  exit 0
fi

for file in "$scope"/notes/*.md "$scope"/_memory/*/*.md "$scope"/entries/*.md; do
  case "${file##*/}" in
    CLAUDE.md | README.md) continue ;;
  esac

  if has_schema_key "$file"; then
    skipped=$((skipped + 1))
    continue
  fi

  end="$(frontmatter_end "$file")"
  if [[ "$end" -eq 0 ]]; then
    echo "  $file: no frontmatter block to migrate" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  sed -n "2,$((end - 1))p" "$file" >"$work/block"

  if ! yq -o=props '.' "$work/block" >"$work/props" 2>/dev/null; then
    echo "  $file: yq could not parse the existing frontmatter, left alone" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  extras="schema=2;body_schema=1"

  if grep -q '^memory_type = ' "$work/props"; then
    order="$RECORD_KEY_ORDER"
    # A record nobody has re-confirmed was last confirmed the day it was written.
    # A later date would claim a review the migrator has no evidence of; process
    # mode supplies that evidence when an input confirms the record, and
    # stamp-confirmed.sh then writes the date onto an accepted record.
    if ! grep -q '^last_confirmed = ' "$work/props"; then
      record_date="$(props_value "$work/props" date)"
      [[ -n "$record_date" ]] && extras="$extras;last_confirmed=$record_date"
    fi
  else
    order="$NOTE_KEY_ORDER"
    extract_body "$file" >"$work/body"
    unpromoted="$(count_matches "$work/body" '\[(memory candidate:|journal candidate:|working-state candidate\])')"
    extras="$extras;open_questions=$(count_matches "$work/body" '\[open question:')"
    extras="$extras;resolved_questions=$(count_matches "$work/body" '\[open question resolved:')"
    extras="$extras;deferred_tensions=$(count_matches "$work/body" '\[tension: deferred\]')"
    extras="$extras;unpromoted_candidates=$((unpromoted + $(count_open_contradictions "$work/body") - $(count_dismissed_amends "$work/body") - $(count_landed_working_state "$work/body")))"

    note_id="$(props_value "$work/props" id)"

    if [[ -n "$tier2_extract_dir" ]]; then
      # This is the same $work/body the counts above just read. A second read of
      # the file here would risk a boundary that drifts from extract_body's, and
      # the entity check below trusts this file to be that one true extract.
      cp "$work/body" "$tier2_extract_dir/$note_id.extract.md"
      [[ -f "$tier2_extract_dir/proposals.yaml" ]] || echo "notes:" >"$tier2_extract_dir/proposals.yaml"
      {
        printf '  %s:\n' "$note_id"
        printf '    file: %s\n' "$file"
        printf "    summary: ''\n"
        printf '    entities: []\n'
      } >>"$tier2_extract_dir/proposals.yaml"
    fi

    if [[ -n "$tier2_file" ]]; then
      tier2_proposed="$(YQ_ID="$note_id" yq -o=json '.notes[env(YQ_ID)] // "absent"' "$tier2_file")"
      if [[ "$tier2_proposed" != '"absent"' ]]; then
        tier2_summary="$(YQ_ID="$note_id" yq -r '.notes[env(YQ_ID)].summary // ""' "$tier2_file")"

        # A summary that spans lines fails frontmatter-single-line the moment the
        # lint sees it. Catching it here, before the write, is what keeps that
        # failure from landing in a file someone already treats as migrated.
        if [[ "$tier2_summary" == *$'\n'* ]]; then
          echo "  $file: tier2-summary-multiline: summary must be a single line; left alone" >>"$work/findings"
          refused=$((refused + 1))
          continue
        fi

        tier2_unsourced=""
        while IFS= read -r tier2_entity; do
          [[ -n "$tier2_entity" ]] || continue
          tier2_matches="$(grep -Fc -- "$tier2_entity" "$work/body" 2>/dev/null || true)"
          if [[ "${tier2_matches:-0}" -eq 0 ]]; then
            tier2_unsourced="$tier2_entity"
            break
          fi
        done < <(YQ_ID="$note_id" yq -r '.notes[env(YQ_ID)].entities[]' "$tier2_file")

        # An entity absent from the extract came from raw content or from the
        # model's own memory, neither of which belongs in a field the skill
        # later greps as fact.
        if [[ -n "$tier2_unsourced" ]]; then
          echo "  $file: tier2-entity-unsourced: \"$tier2_unsourced\" does not appear in this note's Tier 2 extract; left alone" >>"$work/findings"
          refused=$((refused + 1))
          continue
        fi

        # Fed straight into the props file rather than through `extras`: a
        # summary is free prose, and `extras` splits on `;`, which a summary is
        # entitled to contain.
        {
          echo "summary = $tier2_summary"
          tier2_idx=0
          while IFS= read -r tier2_entity; do
            [[ -n "$tier2_entity" ]] || continue
            echo "entities.$tier2_idx = $tier2_entity"
            tier2_idx=$((tier2_idx + 1))
          done < <(YQ_ID="$note_id" yq -r '.notes[env(YQ_ID)].entities[]' "$tier2_file")
        } >>"$work/props"
      fi
    fi
  fi

  # The renderer writes findings to stderr, so a crash would otherwise land in the
  # report looking like one more thing needing a human. A migrator that fails
  # quietly is worse than one that fails.
  if ! render_frontmatter "$work/props" "$order" "$extras" "$file" \
    >"$work/new-fm" 2>"$work/notes"; then
    echo "could not rewrite the frontmatter of $file" >&2
    cat "$work/notes" >&2
    exit 1
  fi
  cat "$work/notes" >>"$work/findings"

  lines="$(wc -l <"$work/new-fm" | tr -d ' ')"
  if [[ $((lines + 2)) -gt "$FRONTMATTER_LINE_BUDGET" ]]; then
    echo "  $file: rewritten frontmatter needs $((lines + 2)) lines, past the $FRONTMATTER_LINE_BUDGET-line budget; left alone" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  if ! yq '.' "$work/new-fm" >/dev/null 2>&1; then
    echo "  $file: the rewritten frontmatter does not parse; left alone" >>"$work/findings"
    refused=$((refused + 1))
    continue
  fi

  {
    echo "---"
    cat "$work/new-fm"
    echo "---"
    tail -n +$((end + 1)) "$file"
  } >"$work/candidate"

  echo "--- $file"
  diff -u <(sed -n "1,${end}p" "$file") <(sed -n "1,$((lines + 2))p" "$work/candidate") |
    tail -n +3 || true

  [[ "$apply" -eq 1 ]] && cat "$work/candidate" >"$file"
  migrated=$((migrated + 1))
done

echo
echo "scope: $scope"
echo "migrated: $migrated"
echo "already v2: $skipped"
echo "left alone: $refused"

if [[ -s "$work/findings" ]]; then
  echo
  echo "needs a human:"
  cat "$work/findings"
fi

if [[ "$apply" -eq 0 ]]; then
  echo
  echo "dry run; nothing was written. rerun with --apply to write these changes."
fi

if [[ -n "$tier2_extract_dir" ]]; then
  echo
  echo "tier2 extracts: $tier2_extract_dir"
fi
