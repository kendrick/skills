#!/usr/bin/env bash
# Pin the jira-refine skill's load-bearing behavior. Many of these are refutes:
# the mechanisms this design explicitly cut are all reasonable-sounding ideas,
# and a well-meaning edit is exactly how they come back. The functional half
# runs the real scripts against the real fixtures, including the two-transport
# idempotency proof rule 8 of tracker-contract.md names by hand.
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

require_file jira-refine/SKILL.md
require_file jira-refine/README.md
require_file jira-refine/references/ticket-template.md
require_file jira-refine/references/staging-format.md
require_file jira-refine/references/tracker-contract.md
require_file jira-refine/assets/jira-refine.example.toml
require_file jira-refine/scripts/segment.py
require_file jira-refine/scripts/check-staging.py
require_file jira-refine/scripts/jira-apply.py
require_file _maintenance/jira-refine/RATIONALE.md
require_file _maintenance/jira-refine/EVALS.md

require_file tests/fixtures/jira-refine/README.md
require_file tests/fixtures/jira-refine/refinement.vtt
require_file tests/fixtures/jira-refine/refinement.srt
require_file tests/fixtures/jira-refine/refinement.txt
require_file tests/fixtures/jira-refine/jira-refine.toml
require_file tests/fixtures/jira-refine/issues.json
require_file tests/fixtures/jira-refine/staging-good.md
require_file tests/fixtures/jira-refine/staging-bad.md
require_file tests/fixtures/jira-refine/fake-jira
require_file tests/fixtures/jira-refine/fake-jira-rest.py

[[ "$(find jira-refine -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "jira-refine/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# `JiraCliTransport.__init__` resolves the binary with `shutil.which("jira")`,
# which only finds a file the OS is willing to exec. A fake that lost its
# executable bit would fail the CLI leg below with a transport error that reads
# like a bug in jira-apply.py.
[[ -x tests/fixtures/jira-refine/fake-jira ]] || {
  echo "tests/fixtures/jira-refine/fake-jira must carry the executable bit" >&2
  exit 1
}

# --- Frontmatter. -----------------------------------------------------------

# User-invoked is the whole safety posture: a misfire writes into a client's
# tracker, and a miss costs the user one typed word.
require_text jira-refine/SKILL.md "name: jira-refine"
require_text jira-refine/SKILL.md "disable-model-invocation: true"
require_text jira-refine/SKILL.md "argument-hint: '[transcript path] [--session-date YYYY-MM-DD] | --apply <staging.md> [--dry-run]'"

# A description that summarizes the workflow becomes a shortcut the model takes
# instead of reading the body, which is how a two-mode skill collapses to one.
refute_text jira-refine/SKILL.md "description: \"Step 1"

# --- The rules the design rests on. -----------------------------------------

# The never-invent rule. One fabricated acceptance criterion costs the tech lead
# their trust in every other line of the file, which is the only reason running
# this is worth anything.
require_text jira-refine/SKILL.md "**NEVER invent acceptance criteria.**"
require_text jira-refine/SKILL.md "A criterion that follows logically from what was said is still not something anyone said."
require_text jira-refine/references/ticket-template.md "**only what the room stated goes in.**"
require_text jira-refine/references/ticket-template.md "Never derive a criterion."

# A blank section and a section nobody discussed look identical unless the file
# says which one it is. The literal line is what the validator cross-checks.
require_text jira-refine/SKILL.md "- not discussed: <section>"
require_text jira-refine/references/staging-format.md "- not discussed: <section>"
require_text jira-refine/references/staging-format.md "never both and never neither"

# Outcomes, not implementation: the room discussing a queue is not the room
# deciding the ticket is about a queue.
require_text jira-refine/SKILL.md "**Describe outcomes, not implementation.**"
require_text jira-refine/references/ticket-template.md "**Describe outcomes, not implementation.**"

# The anchor's snippet is authoritative, so a reader can tell a quoted criterion
# from an invented one without trusting the fill.
require_text jira-refine/SKILL.md "The snippet is authoritative and quoted exactly from the excerpt"
require_text jira-refine/references/staging-format.md "The captured snippet is four to ten verbatim words and is authoritative"

# Apply reads the staging file off disk, not from what this conversation
# remembers writing. That is what makes a hand edit between the two modes count
# for as much as the model's own fill.
require_text jira-refine/SKILL.md "Apply mode reads that file from disk and pushes what it finds there"
require_text jira-refine/SKILL.md "Run \`check-staging.py validate STAGING\` again, against the file as it now sits on disk."
require_text jira-refine/README.md "reads that staging file back from disk, never from what the conversation remembers writing"

# Stage mode holds no credentials and opens no connection. A user with no Jira
# access at all can run every step of it.
require_text jira-refine/SKILL.md "**Stage mode never calls \`jira-apply.py\`.**"
require_text jira-refine/SKILL.md "It holds no credentials, opens no connection, and cannot write to a tracker even if asked."

# Apply always dry-runs and always asks. This is the one moment the skill can
# irreversibly touch a client's tracker.
require_text jira-refine/SKILL.md "Dry run, always"
require_text jira-refine/SKILL.md "The confirmation always runs, and no flag skips it."
require_text jira-refine/README.md "asks for confirmation before pushing anything for real; no flag skips that ask"

# The gap handoff. A gap ticket drafted from a passing mention has not been
# interviewed, and file-issue exists to run that interview.
require_text jira-refine/SKILL.md "**Never create it here**, and never route it through \`jira-apply.py create\`."
require_text jira-refine/SKILL.md "A command that would file a client's ticket into the wrong tracker is worse than no command."

# The session date never comes from mtime: a transcript copied off a share
# carries the copy's date, and this value lands in the label and every
# Provenance block.
require_text jira-refine/SKILL.md "Never the file's mtime"

# --- The tracker contract. --------------------------------------------------

# The sentinel is a heading because `h6.` survives a v2 round-trip where a wiki
# macro does not, and the block is the only record that a push already happened.
require_text jira-refine/references/tracker-contract.md "h6. jira-refine begin"
require_text jira-refine/scripts/jira-apply.py "h6. jira-refine begin"

# `already-present` is how rule 8 reports a clean second run; losing the state
# collapses idempotency into "write every time".
require_text jira-refine/references/tracker-contract.md "already-present"
require_text jira-refine/scripts/jira-apply.py "already-present"

# `on_conflict` is the only door out of a conflict, and it is opened per entry
# by a human editing the staging file.
require_text jira-refine/references/tracker-contract.md "on_conflict"
require_text jira-refine/references/staging-format.md "on_conflict"
require_text jira-refine/scripts/jira-apply.py "on_conflict"

# Link presence is checked by type, direction, and key together. `inwardIssue`
# is the direction half: D blocks X means D outward, X inward.
require_text jira-refine/references/tracker-contract.md "inwardIssue"
require_text jira-refine/scripts/jira-apply.py "inwardIssue"

# v2 wiki markup is the one rendering path the idempotency rules are proven
# against.
require_text jira-refine/references/tracker-contract.md "/rest/api/2"
require_text jira-refine/scripts/jira-apply.py "/rest/api/2"

# --- The cut features. Each has a row in Deliberately Not Built. -------------

# Auto-approve or `--yolo`: `status: approved` is the only gate between a
# transcript and a client's tracker.
for f in jira-refine/SKILL.md jira-refine/README.md jira-refine/references/*.md jira-refine/scripts/*.py; do
  refute_text "$f" "--yolo"
  refute_text "$f" "auto-approve"
done

# Auto-creating gap tickets. `file-issue` owns the interview a gap ticket has
# not had; a `gh issue create` here skips it.
refute_text jira-refine/SKILL.md "gh issue create"
refute_text jira-refine/README.md "gh issue create"

# ADF / API v3. A second rendering format needs its own sentinel and its own
# byte-comparison rule, not a toggle on the existing one.
refute_text jira-refine/scripts/jira-apply.py "/rest/api/3"
refute_text jira-refine/scripts/jira-apply.py "\"type\": \"doc\""
refute_text jira-refine/references/tracker-contract.md "/rest/api/3"

# Merging into a human-written description. Rule 3 treats unmarked prose as a
# conflict; merging into it automatically is the guess that rule exists to
# refuse.
refute_text jira-refine/scripts/jira-apply.py "auto-merge"
require_text jira-refine/references/tracker-contract.md "is a \`conflict\` unless \`on_conflict\` is set"

# Cross-ticket duplicate detection. Each entry validates against its own
# excerpt; scanning the rest of the tracker answers a question nobody asked.
refute_text jira-refine/SKILL.md "duplicate detection"
refute_text jira-refine/scripts/jira-apply.py "duplicate detection"

# Hardcoded or regex key pattern. The pattern is derived from `projects` plus
# `[spoken_aliases]` at run time; a config-carried regex would need hand-editing
# for every new project and fail silently when nobody remembered.
refute_text jira-refine/assets/jira-refine.example.toml "key_pattern ="
refute_text tests/fixtures/jira-refine/jira-refine.toml "key_pattern ="
require_text jira-refine/assets/jira-refine.example.toml "a session names its projects, not its regexes"

# Hydrating Jira state at stage time. `jira-apply.py` is the only file that
# knows Jira exists, so nothing upstream of it may reach the network.
refute_text jira-refine/scripts/segment.py "urllib"
refute_text jira-refine/scripts/check-staging.py "urllib"
refute_text jira-refine/scripts/segment.py "subprocess"
refute_text jira-refine/scripts/check-staging.py "subprocess"

# Other-tracker adapters. Build the one tracker in front of you deeply;
# generalize when a second one is real.
refute_text jira-refine/scripts/jira-apply.py "LinearTransport"
refute_text jira-refine/scripts/jira-apply.py "GitHubTransport"
refute_text jira-refine/scripts/jira-apply.py "AsanaTransport"

# A skill lands alone, so a sibling-script import breaks the moment the sibling
# is not installed. The pipeline between these scripts is a shell pipe, never an
# import.
refute_text jira-refine/scripts/jira-apply.py "import check_staging"
refute_text jira-refine/scripts/jira-apply.py "import segment"
refute_text jira-refine/scripts/jira-apply.py "sys.path"

# Transitions, assignees, sprints, estimates, comments. None of the five is
# something a spoken session states, and each would multiply the idempotency
# rules for a field the template does not hold.
refute_text jira-refine/scripts/jira-apply.py "transition"
refute_text jira-refine/scripts/jira-apply.py "assignee"
refute_text jira-refine/scripts/jira-apply.py "sprint"

# A `mark` verb for flipping status. Status flips happen by hand in an editor;
# a verb that flips them reopens the auto-approve risk through a side door.
refute_text jira-refine/scripts/check-staging.py "add_parser(\"mark\""

# Broadening `file-issue` into a `manage-issue` that both creates and edits.
# The repo already split this way once, as `jd-file` and `jd-audit`.
for f in jira-refine/SKILL.md jira-refine/README.md jira-refine/references/*.md jira-refine/scripts/*.py; do
  refute_text "$f" "manage-issue"
done

# --- Maintenance and the root README. ---------------------------------------

require_text _maintenance/jira-refine/RATIONALE.md "## Where This Came From"
require_text _maintenance/jira-refine/RATIONALE.md "## Decision Ledger"
require_text _maintenance/jira-refine/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/jira-refine/RATIONALE.md "## Known Limitations"
require_text README.md "npx skills add kendrick/skills --skill jira-refine"

# --- Functional checks. Real scripts, real fixtures, no network. ------------

python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' || {
  echo "these checks need Python 3.11 or newer: jira-refine reads its config with tomllib" >&2
  exit 1
}

fixtures="$repo_root/tests/fixtures/jira-refine"
segment="$repo_root/jira-refine/scripts/segment.py"
staging="$repo_root/jira-refine/scripts/check-staging.py"
apply="$repo_root/jira-refine/scripts/jira-apply.py"
config="$fixtures/jira-refine.toml"

tmp="$(mktemp -d)"
rest_pid=""
cleanup() {
  if [[ -n "$rest_pid" ]]; then
    kill "$rest_pid" 2>/dev/null || true
    wait "$rest_pid" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT

# An inherited config path would silently outrank the `--config` flags below on
# any rung the scripts consult before their arguments.
unset JIRA_REFINE_CONFIG || true

# The three transcripts encode one session three ways, so a segmenter that
# reads a container format wrong shows up here as a key list that stops
# matching its siblings rather than as a plausible-looking single run.
for ext in vtt srt txt; do
  python3 "$segment" "$fixtures/refinement.$ext" --config "$config" \
    --session-date 2026-09-07 --json > "$tmp/segments-$ext.json" || {
    echo "segment.py failed on refinement.$ext" >&2
    exit 1
  }
  keys="$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(",".join(e["key"] for e in json.load(f)["entries"]))
' "$tmp/segments-$ext.json")"
  [[ "$keys" == "PROJ-412,PROJ-413,PLAT-77,PROJ-455" ]] || {
    echo "refinement.$ext should segment to the four fixture keys, got: $keys" >&2
    exit 1
  }
done

# PLAT-77 is reopened later in the session and PROJ-455 runs long against the
# median; both flags are arithmetic segment.py owns, and both are what the
# skill's Summary step reads before a human adds `circular` by hand.
python3 -c '
import json, sys
flags = {}
for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    flags[path] = [(e["key"], e["revisited"], e["long"]) for e in data["entries"]]
    stats = data["stats"]
    if stats["revisited_total"] != 1 or stats["mentioned_in_passing"] != 1:
        sys.exit(f"unexpected stats in {path}: {stats}")
values = list(flags.values())
if any(v != values[0] for v in values):
    sys.exit(f"the three transcripts disagree on revisited/long: {flags}")
if ("PLAT-77", 1, False) not in values[0] or ("PROJ-455", 0, True) not in values[0]:
    sys.exit(f"PLAT-77 should be revisited and PROJ-455 long: {values[0]}")
' "$tmp/segments-vtt.json" "$tmp/segments-srt.json" "$tmp/segments-txt.json" || exit 1

python3 "$staging" validate "$fixtures/staging-good.md" >/dev/null || {
  echo "staging-good.md should validate" >&2
  exit 1
}

# One line per broken rule, not one line per file: a validator that stopped at
# the first problem would send the user back through the loop six times.
set +e
bad_err="$(python3 "$staging" validate "$fixtures/staging-bad.md" 2>&1 >/dev/null)"
bad_status=$?
set -e
[[ "$bad_status" == "1" ]] || {
  echo "staging-bad.md should exit 1, got: $bad_status" >&2
  exit 1
}
bad_count="$(printf '%s\n' "$bad_err" | grep -c '^check-staging: ')"
[[ "$bad_count" == "6" ]] || {
  echo "staging-bad.md should report exactly six problems, got $bad_count:" >&2
  printf '%s\n' "$bad_err" >&2
  exit 1
}
# Each planted defect is a distinct grammar rule, spread across the frontmatter
# and two entries so no failure can cascade into another.
grep -Fq "frontmatter: schema is '2', expected '1'" <<<"$bad_err" || {
  echo "the wrong-schema defect went unreported: $bad_err" >&2
  exit 1
}
grep -Fq "is not YYYY-MM-DDTHH:MM:SS" <<<"$bad_err" || {
  echo "the malformed generated timestamp went unreported: $bad_err" >&2
  exit 1
}
grep -Fq "entry PROJ-500: status 'pending' is not one of" <<<"$bad_err" || {
  echo "the illegal status went unreported: $bad_err" >&2
  exit 1
}
grep -Fq "Acceptance criteria line has no valid anchor" <<<"$bad_err" || {
  echo "the unanchored criterion went unreported: $bad_err" >&2
  exit 1
}
grep -Fq "entry PROJ-501: Dependencies references its own key" <<<"$bad_err" || {
  echo "the self-referential dependency went unreported: $bad_err" >&2
  exit 1
}
grep -Fq "entry PROJ-501: Goal has both content and a not-discussed line" <<<"$bad_err" || {
  echo "the filled-and-marked-empty Goal went unreported: $bad_err" >&2
  exit 1
}

# A missing file is an environment problem, not a grammar one, and the
# validator convention keeps that exit code separate from a semantic failure.
set +e
python3 "$staging" validate "$tmp/does-not-exist.md" >/dev/null 2>&1
missing_status=$?
set -e
[[ "$missing_status" == "3" ]] || {
  echo "a missing staging file should exit 3, got: $missing_status" >&2
  exit 1
}

python3 "$staging" entries "$fixtures/staging-good.md" --status approved > "$tmp/entries.jsonl"
entry_keys="$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(",".join(json.loads(line)["key"] for line in f if line.strip()))
' "$tmp/entries.jsonl")"
[[ "$entry_keys" == "PROJ-412,PROJ-413,PROJ-398" ]] || {
  echo "entries --status approved should emit the three approved keys, got: $entry_keys" >&2
  exit 1
}

# `entries` feeds a live tracker directly, so a file that no longer parses has
# to produce nothing at all rather than the half of it that still reads.
set +e
bad_entries="$(python3 "$staging" entries "$fixtures/staging-bad.md" --status approved 2>/dev/null)"
bad_entries_status=$?
set -e
[[ "$bad_entries_status" == "1" ]] || {
  echo "entries on staging-bad.md should exit 1, got: $bad_entries_status" >&2
  exit 1
}
[[ -z "$bad_entries" ]] || {
  echo "entries on staging-bad.md must emit nothing, got: $bad_entries" >&2
  exit 1
}

# --- Idempotency, both transports. Rule 8 of tracker-contract.md. -----------
#
# `$FAKE_JIRA_LOG` gets one line per mutating call and nothing on a read, so a
# second run's line count is the only claim worth making: "no writes" rather
# than the far more fragile "no requests", which a caller that legitimately
# re-reads before deciding to skip would break.

# Bound to nothing but the fakes, so real credentials in the environment cannot
# reach a real tracker from here even if `site` were misread.
export JIRA_EMAIL="smoke@example.invalid"
export JIRA_API_TOKEN="not-a-real-token"

log_lines() {
  if [[ -f "$1" ]]; then
    wc -l < "$1" | tr -d ' '
  else
    echo 0
  fi
}

# A hardcoded port collides with whatever the developer already has listening;
# the kernel picks a free one and the fake is told which.
port="$(python3 -c '
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
')"

rest_log="$tmp/rest.log"
FAKE_JIRA_LOG="$rest_log" python3 "$fixtures/fake-jira-rest.py" \
  --port "$port" --seed "$fixtures/issues.json" &
rest_pid=$!

python3 -c '
import socket, sys, time
port = int(sys.argv[1])
deadline = time.time() + 15
while time.time() < deadline:
    try:
        socket.create_connection(("127.0.0.1", port), 0.25).close()
        sys.exit(0)
    except OSError:
        time.sleep(0.05)
sys.exit(1)
' "$port" || {
  echo "the REST fake never came up on port $port" >&2
  exit 1
}

export JIRA_REFINE_TEST_SITE="http://127.0.0.1:$port"
export FAKE_JIRA_LOG="$rest_log"

# A dry run's whole promise is that nothing moves. The log file not existing is
# a stronger assertion than an empty one: the fake only creates it on a write.
set +e
python3 "$apply" update --config "$config" --dry-run \
  < "$tmp/entries.jsonl" > "$tmp/rest-dry.json" 2> "$tmp/rest-dry.err"
set -e
[[ ! -e "$rest_log" ]] || {
  echo "a --dry-run must write nothing, but the REST fake logged: $(cat "$rest_log")" >&2
  exit 1
}
grep -Fq '"dry_run": true' "$tmp/rest-dry.json" || {
  echo "the dry-run report should mark itself a dry run" >&2
  exit 1
}

# PROJ-413 is seeded with a human-written description. Rule 3 makes that a
# conflict rather than a silent clobber, and the dry run has to say so before
# the ask, not after the write.
grep -Fq '"description": "conflict"' "$tmp/rest-dry.json" || {
  echo "PROJ-413's human-written description should plan a conflict" >&2
  exit 1
}
grep -Fq "description holds text this run did not write; set on_conflict to append or replace" \
  "$tmp/rest-dry.json" || {
  echo "the conflict should name on_conflict as the way out" >&2
  exit 1
}

set +e
python3 "$apply" update --config "$config" \
  < "$tmp/entries.jsonl" > "$tmp/rest-1.json" 2> "$tmp/rest-1.err"
set -e
rest_after_first="$(log_lines "$rest_log")"
[[ "$rest_after_first" -gt 0 ]] || {
  echo "the first REST run should have written something" >&2
  exit 1
}

set +e
python3 "$apply" update --config "$config" \
  < "$tmp/entries.jsonl" > "$tmp/rest-2.json" 2> "$tmp/rest-2.err"
set -e
rest_after_second="$(log_lines "$rest_log")"
[[ "$rest_after_second" == "$rest_after_first" ]] || {
  echo "a second REST run must write nothing: log went $rest_after_first -> $rest_after_second" >&2
  exit 1
}
grep -Fq "0 writes" "$tmp/rest-2.err" || {
  echo "the second REST run should report zero writes:" >&2
  cat "$tmp/rest-2.err" >&2
  exit 1
}
grep -Fq '"description": "already-present"' "$tmp/rest-2.json" || {
  echo "the second REST run should report the block already present" >&2
  exit 1
}
grep -Fq '"result": "already-present"' "$tmp/rest-2.json" || {
  echo "the second REST run should report the dependency link already present" >&2
  exit 1
}

# The conflict's only door out: an entry the human marked `on_conflict: append`
# keeps the text somebody wrote by hand and puts the block after it. Losing that
# turns a resolution into a clobber.
python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as src, open(sys.argv[2], "w", encoding="utf-8") as out:
    for line in src:
        entry = json.loads(line)
        if entry["key"] == "PROJ-413":
            entry["on_conflict"] = "append"
            out.write(json.dumps(entry) + "\n")
' "$tmp/entries.jsonl" "$tmp/append.jsonl"

python3 "$apply" update --config "$config" \
  < "$tmp/append.jsonl" > "$tmp/rest-append.json" 2>/dev/null || {
  echo "on_conflict: append should resolve PROJ-413's conflict and exit 0" >&2
  exit 1
}
python3 "$apply" get PROJ-413 --config "$config" > "$tmp/proj-413.json"
python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    description = json.load(f)["fields"]["description"] or ""
if "A human wrote this by hand." not in description:
    sys.exit("on_conflict: append destroyed the human-written text")
if "h6. jira-refine begin" not in description:
    sys.exit("on_conflict: append never wrote the block")
if description.index("A human wrote this by hand.") > description.index("h6. jira-refine begin"):
    sys.exit("on_conflict: append should keep the existing text first")
' "$tmp/proj-413.json" || exit 1

kill "$rest_pid" 2>/dev/null || true
wait "$rest_pid" 2>/dev/null || true
rest_pid=""

# The jira-cli leg. `JiraCliTransport.__init__` resolves its binary with
# `shutil.which("jira")`, so the fake is reached under that name through a
# symlink rather than by putting the fixtures directory on PATH — the directory
# holds `fake-jira`, and `which` matches on the name it was asked for.
mkdir -p "$tmp/bin"
ln -s "$fixtures/fake-jira" "$tmp/bin/jira"

cli_log="$tmp/cli.log"
export PATH="$tmp/bin:$PATH"
export FAKE_JIRA_LOG="$cli_log"
export FAKE_JIRA_SEED="$fixtures/issues.json"
export FAKE_JIRA_STATE="$tmp/cli-state.json"
# jira-cli writes a custom field by its declared name and the raw API returns it
# by id, so the fake needs the same name-to-id declaration the real CLI carries
# in its own config. Both halves are already in the fixture config as
# `goal_cli_name` and `goal`; deriving the map from there rather than restating
# the pair keeps a config edit from silently splitting the write key from the
# read key, which is the shape of the bug this leg exists to catch.
export FAKE_JIRA_CUSTOM_FIELDS="$(python3 -c '
import json, sys, tomllib
with open(sys.argv[1], "rb") as f:
    fields = tomllib.load(f).get("fields") or {}
name = (fields.get("goal_cli_name") or "").strip()
field_id = (fields.get("goal") or "").strip()
if not name or not field_id:
    sys.exit("the fixture config must set both fields.goal and fields.goal_cli_name")
print(json.dumps({name: field_id}))
' "$config")" || exit 1
# The CLI transport never opens a socket, and pointing `site` at a dead port
# proves it: a leg that quietly fell back to REST would fail here instead of
# passing on the wrong transport.
export JIRA_REFINE_TEST_SITE="http://127.0.0.1:1"

set +e
python3 "$apply" update --config "$config" --transport jira-cli --dry-run \
  < "$tmp/entries.jsonl" > "$tmp/cli-dry.json" 2> "$tmp/cli-dry.err"
set -e
[[ ! -e "$cli_log" ]] || {
  echo "a --dry-run must write nothing, but the CLI fake logged: $(cat "$cli_log")" >&2
  exit 1
}
[[ ! -e "$FAKE_JIRA_STATE" ]] || {
  echo "a --dry-run must not touch the CLI fake's state file" >&2
  exit 1
}
grep -Fq '"transport": "jira-cli"' "$tmp/cli-dry.json" || {
  echo "--transport jira-cli should override the config's rest transport" >&2
  exit 1
}

set +e
python3 "$apply" update --config "$config" --transport jira-cli \
  < "$tmp/entries.jsonl" > "$tmp/cli-1.json" 2> "$tmp/cli-1.err"
set -e
cli_after_first="$(log_lines "$cli_log")"
[[ "$cli_after_first" -gt 0 ]] || {
  echo "the first jira-cli run should have written something" >&2
  exit 1
}

set +e
python3 "$apply" update --config "$config" --transport jira-cli \
  < "$tmp/entries.jsonl" > "$tmp/cli-2.json" 2> "$tmp/cli-2.err"
set -e
cli_after_second="$(log_lines "$cli_log")"
[[ "$cli_after_second" == "$cli_after_first" ]] || {
  echo "a second jira-cli run must write nothing: log went $cli_after_first -> $cli_after_second" >&2
  exit 1
}
grep -Fq "0 writes" "$tmp/cli-2.err" || {
  echo "the second jira-cli run should report zero writes:" >&2
  cat "$tmp/cli-2.err" >&2
  exit 1
}
grep -Fq '"description": "already-present"' "$tmp/cli-2.json" || {
  echo "the second jira-cli run should report the block already present" >&2
  exit 1
}
# Both transports plan against the same pure `plan_ops`, so the same seeded
# description has to conflict identically whichever wire it went over.
grep -Fq '"description": "conflict"' "$tmp/cli-1.json" || {
  echo "PROJ-413 should conflict on the jira-cli transport too" >&2
  exit 1
}

# --- Portability. -----------------------------------------------------------

# Standard library only, so a skill stays copy-in portable. A third-party import
# would fail on a user's machine well after the skill looked installed.
python3 -c '
import ast, sys
stdlib = sys.stdlib_module_names
problems = []
for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as f:
        tree = ast.parse(f.read())
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            names = [alias.name for alias in node.names]
        elif isinstance(node, ast.ImportFrom):
            names = [node.module or ""]
        else:
            continue
        for name in names:
            top = name.split(".")[0]
            if top and top not in stdlib:
                problems.append(f"{path} imports {name}")
if problems:
    sys.exit("\n".join(problems))
' "$segment" "$staging" "$apply" || {
  echo "jira-refine scripts must import the standard library only" >&2
  exit 1
}

# A SyntaxWarning on every invocation is noise a caller cannot silence.
for script in "$segment" "$staging" "$apply"; do
  python3 -W error::SyntaxWarning -c '
import ast, sys
with open(sys.argv[1], encoding="utf-8") as f:
    ast.parse(f.read())
' "$script" || {
    echo "$script raises a SyntaxWarning" >&2
    exit 1
  }
done

# --- The five P0 defects a Codex review found on PR #82 ---------------------
# Each of these shipped once. Every pin below drives the real script, because a
# string pin passes on code that has stopped behaving.

# A WebVTT NOTE block ended at its first line, so the rest became continuation
# speech: editor commentary reached a Source excerpt and a ticket key nobody
# spoke appeared in the output. That is the never-invent rule failing at the
# parser, before any judgment is involved.
cat > "$tmp/note-block.vtt" <<'VTT'
WEBVTT

00:00:01.000 --> 00:00:09.000
<v Dan>Okay, PROJ dash four twelve. The export times out on large reports and marketing keeps asking about it.

NOTE
PROJ dash nine hundred was archived by legal before this call and is not in scope.

STYLE
::cue { color: PLAT dash five five }

00:00:20.000 --> 00:00:28.000
<v Kendrick>Right, and that work depends on the query layer landing first.
VTT
note_out="$("$segment" "$tmp/note-block.vtt" --config "$config" --session-date 2026-09-07 --min-words 0)"
for ghost in PROJ-900 PLAT-55 "archived by legal" "::cue"; do
  case "$note_out" in
    *"$ghost"*)
      echo "a NOTE or STYLE block leaked '$ghost' into the staging output" >&2
      exit 1
      ;;
  esac
done
case "$note_out" in
  *PROJ-412*) : ;;
  *) echo "skipping comment blocks must not drop the real speaker turns" >&2; exit 1 ;;
esac

# `_request` returned None on a 404 for every method, so a PUT the tracker
# rejected was counted as a write and reconcile stamped the entry applied. A
# read and a mutation have to diverge on 404, and only the reads opt in.
require_text jira-refine/scripts/jira-apply.py "def _request(self, method, path, payload=None, read=False):"
python3 - "$apply" <<'PY' || exit 1
import ast, sys
tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
reads = 0
for node in ast.walk(tree):
    if not isinstance(node, ast.Call):
        continue
    fn = node.func
    if not (isinstance(fn, ast.Attribute) and fn.attr == "_request"):
        continue
    verb = node.args[0].value if node.args and isinstance(node.args[0], ast.Constant) else None
    opted = any(k.arg == "read" and getattr(k.value, "value", False) is True for k in node.keywords)
    if verb != "GET" and opted:
        sys.exit(f"a mutating _request call passes read=True: {verb}")
    if verb == "GET" and opted:
        reads += 1
if reads < 2:
    sys.exit("both GET call sites must pass read=True; a 404 is a real answer only on a read")
PY

# A failed set_field reported `unmapped` plus a description fallback that
# nothing had written, so an approved Goal landed nowhere while the report said
# it had. The failure path must claim no fallback; the plan-time unmapped path
# still takes one, and conflating the two is how this comes back.
python3 - "$apply" <<'PY' || exit 1
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
block = re.search(r'elif name == "set_field":(.*?)elif name == "create_link":', src, re.S)
if not block:
    sys.exit("the set_field failure branch is gone from _record_failure")
body = block.group(1)
# Match the append itself, not the word: the branch's comment explains at
# length why it must not claim a fallback, and a bare substring test fires on
# the explanation.
if 'unmapped"].append' in body or "unmapped'].append" in body:
    sys.exit("a failed set_field must not append an unmapped fallback claim")
if '"unmapped"' in body.replace("#", "\n#").split("\n#")[0]:
    sys.exit("a failed set_field must not report unmapped")
if 'outcomes["goal"] = "conflict"' not in body:
    sys.exit("a failed set_field must report the goal as a conflict")
PY
require_text jira-refine/scripts/jira-apply.py 'FALLBACK_BLOCK'

# The anchor word range was documented and unenforced, so a one-word snippet
# passed. The floor is what carries the guarantee: a snippet short enough to
# match anywhere cannot locate anything.
anchor_case() {  # <word-count|literal> <coordinate|""> <pass|fail>
  python3 - "$fixtures/staging-good.md" "$tmp/anchor.md" "$1" "$2" <<'PY'
import re, sys
src, dst, want, coord = sys.argv[1:5]
text = open(src, encoding="utf-8").read()
first = re.search(r'\(raw: "([^"]+)" ([^)]+)\)', text)
# A snippet has to appear verbatim in the entry's own excerpt, so build it by
# slicing the real excerpt rather than by repeating words: a fabricated snippet
# would fail the snippet-in-excerpt rule and mask the word-count rule under test.
entry = text[text.rindex("## ", 0, first.start()):]
fence = re.search(r"```text\n(.*?)```", entry, re.S).group(1)
speech = max((re.sub(r"^\[[^\]]*\]\s*\S+?:\s*", "", ln) for ln in fence.splitlines() if ln.strip()),
             key=lambda s: len(s.split()))
words = speech.split()
new = " ".join(words[:int(want)]) if want.isdigit() else want
if want.isdigit() and len(words) < int(want):
    sys.exit(f"fixture excerpt has only {len(words)} words; cannot build a {want}-word snippet")
text = text.replace(first.group(0), f'(raw: "{new}" {coord or first.group(2)})', 1)
open(dst, "w", encoding="utf-8").write(text)
PY
  if "$staging" validate "$tmp/anchor.md" >/dev/null 2>&1; then
    [[ "$3" == pass ]] || { echo "anchor case '$1' '$2' should have failed validation" >&2; exit 1; }
  else
    [[ "$3" == fail ]] || { echo "anchor case '$1' '$2' should have validated" >&2; exit 1; }
  fi
}
anchor_case 1 "" fail
anchor_case 3 "" fail
anchor_case 4 "" pass
anchor_case 10 "" pass
anchor_case 11 "" fail

# An L<n> coordinate was accepted on an entry whose excerpt carries clock
# timestamps, which cannot be traced with the coordinates the excerpt holds.
# The mode comes from the entry's own excerpt, so both directions have to fail.
anchor_case 5 L64 fail
require_text jira-refine/scripts/check-staging.py "Source excerpt"

# --- The three P0s the second Codex review round found -----------------------
# Each sits in territory the first round's fixes touched, which is the argument
# for re-reviewing after a fix rather than only before one.

# A cue carrying plain caption text opened no turn, because an unlabelled line
# continued a speaker that did not exist yet and flush() never recorded it. A
# valid speakerless transcript produced nothing and blamed the user's config,
# and most machine-generated captions carry no speaker labels at all.
cat > "$tmp/speakerless.vtt" <<'VTT'
WEBVTT

00:00:01.000 --> 00:00:09.000
Okay, PROJ dash four twelve. The export times out on large reports and marketing keeps asking about it every week.

00:00:12.000 --> 00:00:20.000
So we need the query layer to land first before any of that export work can start properly.

00:01:30.000 --> 00:01:40.000
Next up, PLAT 77. The audit log needs to record who exported what and retain it for ninety days.

00:01:45.000 --> 00:01:55.000
Agreed, and that one is independent of the export work so it can go in either order.
VTT
"$segment" "$tmp/speakerless.vtt" --config "$config" --session-date 2026-09-07 --min-words 0 --json > "$tmp/speakerless.json" || {
  echo "a speakerless caption file must still segment" >&2
  exit 1
}
python3 - "$tmp/speakerless.json" <<'PY' || exit 1
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
keys = [e["key"] for e in d["entries"]]
# Both keys open their own cue. Merging every unlabelled cue into one turn
# would leave only the first as a boundary and demote the rest to mentions,
# which reads as "nobody discussed those" on a staging file.
if keys != ["PROJ-412", "PLAT-77"]:
    sys.exit(f"speakerless cues must each open a boundary; got {keys}")
if d["passing"]:
    sys.exit(f"nothing should be demoted here; got {[p['key'] for p in d['passing']]}")
PY

# The same rule must not fire on a key spoken mid-sentence: that is a mention,
# and the distinction is the whole reason boundaries are positional.
cat > "$tmp/midcue.vtt" <<'VTT'
WEBVTT

00:00:01.000 --> 00:00:09.000
Okay, PROJ dash four twelve. The export times out on large reports and marketing keeps asking about it every week.

00:00:12.000 --> 00:00:20.000
We should be careful here because the work in PLAT 77 already covers part of that audit requirement.
VTT
"$segment" "$tmp/midcue.vtt" --config "$config" --session-date 2026-09-07 --min-words 0 --json > "$tmp/midcue.json"
python3 - "$tmp/midcue.json" <<'PY' || exit 1
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
if [e["key"] for e in d["entries"]] != ["PROJ-412"]:
    sys.exit("a key spoken mid-sentence must not open a boundary")
if [p["key"] for p in d["passing"]] != ["PLAT-77"]:
    sys.exit("a mid-sentence key must still be recorded as mentioned in passing")
PY

# The anchor coordinate was checked for shape and never against the excerpt, so
# an invented timestamp passed. A reference that silently points at the wrong
# moment is worse than one that points nowhere, which is why the snippet is
# authoritative in the first place.
anchor_coord() {  # <coordinate-substitution> <pass|fail>
  python3 - "$fixtures/staging-good.md" "$tmp/coord.md" "$1" <<'PY'
import re, sys
src, dst, mode = sys.argv[1:4]
text = open(src, encoding="utf-8").read()
m = re.search(r'\(raw: "([^"]+)" (\d\d:\d\d:\d\d)\)', text)
entry = text[text.rindex("## ", 0, m.start()):]
stamps = re.findall(r"^\[(\d\d:\d\d:\d\d)\]", re.search(r"```text\n(.*?)```", entry, re.S).group(1), re.M)
coord = "23:59:59" if mode == "absent" else next(s for s in stamps if s != m.group(2))
open(dst, "w", encoding="utf-8").write(text.replace(m.group(0), f'(raw: "{m.group(1)}" {coord})', 1))
PY
  if "$staging" validate "$tmp/coord.md" >/dev/null 2>&1; then
    [[ "$2" == pass ]] || { echo "anchor coordinate case '$1' should have failed" >&2; exit 1; }
  else
    [[ "$2" == fail ]] || { echo "anchor coordinate case '$1' should have validated" >&2; exit 1; }
  fi
}
anchor_coord absent fail    # labels no line in the excerpt at all
anchor_coord wrongturn fail # a real timestamp, but not the turn holding the snippet

# A preflight against an unreachable tracker returned 1, the same code as an
# issue that genuinely is not there, so apply mode read a Jira outage as a
# missing ticket and walked on toward the writes.
require_text jira-refine/references/tracker-contract.md "preflight"
python3 - "$apply" <<'PY' || exit 1
import ast, sys
tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
for fn in ast.walk(tree):
    if not (isinstance(fn, ast.FunctionDef) and fn.name in ("cmd_get", "cmd_fields")):
        continue
    for handler in [n for n in ast.walk(fn) if isinstance(n, ast.ExceptHandler)]:
        returns_one = any(
            isinstance(n, ast.Return) and isinstance(n.value, ast.Constant) and n.value.value == 1
            for n in ast.walk(handler)
        )
        names = {n.id for n in ast.walk(handler) if isinstance(n, ast.Name)}
        if returns_one and "TransportError" in ast.dump(handler):
            sys.exit(f"{fn.name}: a preflight TransportError must exit 3, not 1")
PY

echo "jira-refine smoke: OK"
