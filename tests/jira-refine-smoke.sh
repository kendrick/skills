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

# --- The unterminated-block conflict. Issue #94. ----------------------------
# A begin sentinel with no matching end used to claim the rest of the
# description as its own body, so the second apply spliced over every
# reviewer edit below it and still reported applied. Jira Cloud loses the end
# sentinel on its own when a block's last section is a bullet list, so an
# issue reaches this shape without anyone touching the file by hand.

put_description() {  # <key> <file holding the description text to seed>
  python3 -c '
import json, os, sys, urllib.request
key, path = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    text = f.read()
site = os.environ["JIRA_REFINE_TEST_SITE"]
payload = json.dumps({"fields": {"description": text}}).encode("utf-8")
request = urllib.request.Request(
    f"{site}/rest/api/2/issue/{key}", data=payload, method="PUT"
)
request.add_header("Content-Type", "application/json")
urllib.request.urlopen(request).read()
' "$1" "$2"
}

# A normal splice over an intact block must still leave text below it alone.
# Reseed a well-formed block with a reviewer line under it, change the entry,
# and reapply: the fix that stopped guessing at a missing sentinel must not
# start treating every block as suspect.
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/proj-412-intact.json"
python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    description = json.load(f)["fields"]["description"]
with open(sys.argv[2], "w", encoding="utf-8") as f:
    f.write(description + "\nA reviewer added this note after the block.\n")
' "$tmp/proj-412-intact.json" "$tmp/seed-intact.txt"
put_description PROJ-412 "$tmp/seed-intact.txt"

python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as src, open(sys.argv[2], "w", encoding="utf-8") as out:
    for line in src:
        entry = json.loads(line)
        if entry["key"] == "PROJ-412":
            entry["fields"]["context"] = "A different context, so the block actually has to change."
            out.write(json.dumps(entry) + "\n")
' "$tmp/entries.jsonl" "$tmp/intact-changed.jsonl"

python3 "$apply" update --config "$config" \
  < "$tmp/intact-changed.jsonl" > "$tmp/intact.json" 2>/dev/null || {
  echo "an intact block's splice should still exit 0" >&2
  exit 1
}
grep -Fq '"description": "applied"' "$tmp/intact.json" || {
  echo "a changed entry over an intact block should report the description applied" >&2
  exit 1
}
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/proj-412-after-intact.json"
python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    description = json.load(f)["fields"]["description"]
if "A different context, so the block actually has to change." not in description:
    sys.exit("the splice never landed the new block content")
if "A reviewer added this note after the block." not in description:
    sys.exit("text below an intact block must survive a normal splice")
' "$tmp/proj-412-after-intact.json" || exit 1

# A missing end sentinel refuses instead of guessing. Strip the sentinel, add
# a reviewer line, and reapply the same entry unchanged: the run must
# conflict, name the sentinel and `restore` as the way out, and leave the
# description exactly as seeded. Byte-identity is the assertion FRW-758
# needed and never had.
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/proj-412-for-unterminated.json"
python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    description = json.load(f)["fields"]["description"]
lines = description.splitlines()
# Truncate at the first end sentinel rather than assume it is the last line:
# an earlier case in this suite may have left reviewer text of its own below
# the block, and this case wants the block on its own, unterminated.
try:
    end = next(i for i, line in enumerate(lines) if line.strip() == "h6. jira-refine end")
except StopIteration:
    sys.exit("PROJ-412 should carry a terminated block to build the unterminated case from")
unterminated = "\n".join(lines[:end]) + "\nA reviewer edit that must not be discarded.\n"
with open(sys.argv[2], "w", encoding="utf-8") as f:
    f.write(unterminated)
' "$tmp/proj-412-for-unterminated.json" "$tmp/seed-unterminated.txt" || exit 1
put_description PROJ-412 "$tmp/seed-unterminated.txt"

python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as src, open(sys.argv[2], "w", encoding="utf-8") as out:
    for line in src:
        entry = json.loads(line)
        if entry["key"] == "PROJ-412":
            out.write(json.dumps(entry) + "\n")
' "$tmp/entries.jsonl" "$tmp/unterminated-entry.jsonl"

set +e
python3 "$apply" update --config "$config" \
  < "$tmp/unterminated-entry.jsonl" > "$tmp/unterminated.json" 2> "$tmp/unterminated.err"
unterminated_status=$?
set -e
[[ "$unterminated_status" == 1 ]] || {
  echo "an unterminated block should exit 1, got $unterminated_status" >&2
  exit 1
}
grep -Fq '"description": "conflict"' "$tmp/unterminated.json" || {
  echo "an unterminated block should report the description a conflict" >&2
  exit 1
}
grep -Fq "no end sentinel" "$tmp/unterminated.json" || {
  echo "the conflict reason should name the missing end sentinel" >&2
  exit 1
}
grep -Fq "restore" "$tmp/unterminated.json" || {
  echo "the conflict reason should tell the human to restore the end line" >&2
  exit 1
}
grep -Fq "h6. jira-refine end" "$tmp/unterminated.json" || {
  echo "the conflict reason should interpolate the END_LINE constant" >&2
  exit 1
}
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/proj-412-after-unterminated.json"
python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    seeded = f.read()
with open(sys.argv[2], encoding="utf-8") as f:
    after = json.load(f)["fields"]["description"]
if after != seeded:
    sys.exit(
        "an unterminated block must come back byte-identical to what was seeded:\n"
        f"seeded: {seeded!r}\nafter:  {after!r}"
    )
' "$tmp/seed-unterminated.txt" "$tmp/proj-412-after-unterminated.json" || exit 1

# `on_conflict: append` is still the way out of an unterminated block. The
# stale block and the reviewer text below it both have to survive; only a
# new block gets added after them.
put_description PROJ-412 "$tmp/seed-unterminated.txt"

python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as src, open(sys.argv[2], "w", encoding="utf-8") as out:
    for line in src:
        entry = json.loads(line)
        if entry["key"] == "PROJ-412":
            entry["on_conflict"] = "append"
            out.write(json.dumps(entry) + "\n")
' "$tmp/entries.jsonl" "$tmp/unterminated-append.jsonl"

python3 "$apply" update --config "$config" \
  < "$tmp/unterminated-append.jsonl" > "$tmp/unterminated-append.json" 2>/dev/null || {
  echo "on_conflict: append should resolve an unterminated block and exit 0" >&2
  exit 1
}
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/proj-412-after-append.json"
python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    description = json.load(f)["fields"]["description"]
if "A reviewer edit that must not be discarded." not in description:
    sys.exit("on_conflict: append destroyed the reviewer text below the stale block")
if description.count("h6. jira-refine begin") != 2:
    sys.exit("on_conflict: append should keep the stale begin line and add a new block")
' "$tmp/proj-412-after-append.json" || exit 1

# Applying again over what `append` just built must not undo it. The append
# leaves a stale unterminated block, the reviewer text, and a whole new block;
# scanning for an end from the first begin reaches the SECOND block's end, and
# pairing them hands splice_block one span covering all three. That reported
# `applied` and destroyed the reviewer text — the exact loss this guard exists
# to stop, arriving through the recovery documented for it. Applying once
# never sees it, which is why this case reruns.
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/proj-412-before-reapply.json"
set +e
python3 "$apply" update --config "$config" \
  < "$tmp/unterminated-entry.jsonl" > "$tmp/reapply.json" 2> "$tmp/reapply.err"
reapply_status=$?
set -e
[[ "$reapply_status" == 1 ]] || {
  echo "re-applying after an append should conflict, got exit $reapply_status" >&2
  exit 1
}
grep -Fq '"description": "conflict"' "$tmp/reapply.json" || {
  echo "the stale begin left by an append must still read as unterminated" >&2
  exit 1
}
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/proj-412-after-reapply.json"
python3 -c '
import json, sys
def description(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)["fields"]["description"]
before, after = description(sys.argv[1]), description(sys.argv[2])
if after != before:
    sys.exit("re-applying after an append rewrote the description:\n"
             f"before: {before!r}\nafter:  {after!r}")
if "A reviewer edit that must not be discarded." not in after:
    sys.exit("re-applying after an append destroyed the reviewer text")
' "$tmp/proj-412-before-reapply.json" "$tmp/proj-412-after-reapply.json" || exit 1

# An entry that keeps `on_conflict: append` must converge like any other. The
# same-source branch is what has always made a second append a no-op, and an
# unterminated block holds that branch shut forever, so without a check of its
# own the append path would add one more copy of the same block on every run
# and rule 8 would not hold. The earlier rerun above drops `on_conflict`, so it
# exercises a different input and cannot see this.
put_description PROJ-412 "$tmp/seed-unterminated.txt"
python3 "$apply" update --config "$config" \
  < "$tmp/unterminated-append.jsonl" > /dev/null 2>&1 || {
  echo "the first append over an unterminated block should exit 0" >&2
  exit 1
}
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/append-once.json"
append_writes_before="$(log_lines "$rest_log")"
python3 "$apply" update --config "$config" \
  < "$tmp/unterminated-append.jsonl" > "$tmp/append-twice.json" 2> "$tmp/append-twice.err" || {
  echo "a second append over the same input should exit 0" >&2
  exit 1
}
[[ "$(log_lines "$rest_log")" == "$append_writes_before" ]] || {
  echo "a second append must write nothing; the description would grow a block per run" >&2
  exit 1
}
grep -Fq '"description": "already-present"' "$tmp/append-twice.json" || {
  echo "a second append should report the block already present:" >&2
  cat "$tmp/append-twice.json" >&2
  exit 1
}
python3 "$apply" get PROJ-412 --config "$config" > "$tmp/append-twice-issue.json"
python3 -c '
import json, sys
def description(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)["fields"]["description"]
once, twice = description(sys.argv[1]), description(sys.argv[2])
if once != twice:
    sys.exit("a second append rewrote the description")
found = twice.count("h6. jira-refine begin")
if found != 2:
    sys.exit(f"append should leave exactly two begin lines, found {found}")
' "$tmp/append-once.json" "$tmp/append-twice-issue.json" || exit 1

# Pure pins on find_blocks, no fake required: a terminated block reports a
# real line number for its end, and an unterminated one reports None. Every
# conflict check above depends on that shape holding, so a change here fails
# loudly instead of drifting quietly into a wrong guess.
python3 - "$apply" <<'PY' || exit 1
import importlib.util
import sys

path = sys.argv[1]
spec = importlib.util.spec_from_file_location("jira_apply", path)
jira_apply = importlib.util.module_from_spec(spec)
spec.loader.exec_module(jira_apply)

terminated = jira_apply.find_blocks(
    "h6. jira-refine begin | session 2026-08-30 | source x\ntext\nh6. jira-refine end\n"
)
if len(terminated) != 1 or not isinstance(terminated[0][1], int):
    sys.exit(f"a terminated block should report an integer end, got {terminated}")

unterminated = jira_apply.find_blocks(
    "h6. jira-refine begin | session 2026-08-30 | source x\ntext with no end line\n"
)
if len(unterminated) != 1 or unterminated[0][1] is not None:
    sys.exit(f"an unterminated block should report end=None, got {unterminated}")
PY

# The refutes pin the cut mechanism; the require pins the contract line it
# would have violated. RATIONALE.md's Deliberately Not Built table records
# the cut.
refute_text jira-refine/scripts/jira-apply.py "Claiming to the end of the description"
refute_text jira-refine/scripts/jira-apply.py "end = len(lines) - 1"
require_text jira-refine/references/tracker-contract.md "no end sentinel"

# --- Extra fields on create (REST). -----------------------------------------
# A board whose filter tests a field the create never sent hides the ticket it
# just made: real, correct, reported applied, and absent from the backlog. Every
# case below drives the real create path, because the whole failure was a report
# that said `applied` while the field was null.

create_entry() {  # <summary> [extra_fields JSON]
  python3 -c '
import json, sys
entry = {"project": "PROJ", "issue_type": "Task", "summary": sys.argv[1],
         "fields": {"context": "Seeded by the smoke test.", "acceptance_criteria": [],
                    "out_of_scope": "", "dependencies": [], "goal": None,
                    "open_questions": [], "provenance": "source: smoke"},
         "parent": None, "blocked_by": [], "label": "refined-2026-09-07"}
if len(sys.argv) > 2 and sys.argv[2]:
    entry["extra_fields"] = json.loads(sys.argv[2])
print(json.dumps(entry))
' "$1" "${2:-}"
}

# What the POST actually carried, not what the report claimed about it: the bug
# was a report saying `applied` over a null field.
created_field() {  # <log> <field id>
  python3 -c '
import json, sys
posts = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
created = [p for p in posts if p.get("path") == "issue" and p.get("method") == "POST"]
if not created:
    sys.exit("no POST issue reached the fake")
print(created[-1]["body"]["fields"].get(sys.argv[2], ""))
' "$1" "$2"
}

# The declared value rides along with no entry saying so, because the field a
# board filters on is a property of the run, not of one ticket.
create_entry "Team from the config" > "$tmp/create-default.jsonl"
python3 "$apply" create --config "$config" \
  < "$tmp/create-default.jsonl" > "$tmp/create-default.json" 2>/dev/null || {
  echo "a create declaring a mappable extra field should exit 0" >&2
  exit 1
}
grep -Fq '"extra_fields": {"team": "applied"}' "$tmp/create-default.json" || {
  echo "the create report should mark the declared extra field applied:" >&2
  cat "$tmp/create-default.json" >&2
  exit 1
}
sent="$(created_field "$rest_log" customfield_10001)" || exit 1
[[ "$sent" == "team-a" ]] || {
  echo "the created issue carried customfield_10001='$sent', expected 'team-a'" >&2
  exit 1
}

# An entry naming the same field overrides the config's value for that ticket.
create_entry "Team from the entry" '{"team": "team-b"}' > "$tmp/create-override.jsonl"
python3 "$apply" create --config "$config" \
  < "$tmp/create-override.jsonl" > /dev/null 2>&1 || {
  echo "a create overriding an extra field should exit 0" >&2
  exit 1
}
sent="$(created_field "$rest_log" customfield_10001)" || exit 1
[[ "$sent" == "team-b" ]] || {
  echo "an entry override should win: got '$sent', expected 'team-b'" >&2
  exit 1
}

# The refusal, and the reason it is a refusal rather than a fallback. An extra
# field has nowhere to fall, and create has no idempotency rule: creating the
# ticket anyway would put an invisible one on the tracker AND leave the rerun
# that fixes the config making a duplicate. Nothing may reach the tracker here.
before_refusal="$(log_lines "$rest_log")"
create_entry "Undeclared field" '{"sprint": "42"}' > "$tmp/create-undeclared.jsonl"
set +e
python3 "$apply" create --config "$config" \
  < "$tmp/create-undeclared.jsonl" > "$tmp/create-undeclared.json" 2> "$tmp/create-undeclared.err"
undeclared_status=$?
set -e
[[ "$undeclared_status" == 1 ]] || {
  echo "an undeclared extra field should exit 1, got $undeclared_status" >&2
  exit 1
}
[[ "$(log_lines "$rest_log")" == "$before_refusal" ]] || {
  echo "a refused create must not reach the tracker at all" >&2
  exit 1
}
grep -Fq '"description": "skipped"' "$tmp/create-undeclared.json" || {
  echo "a refused create should report the description skipped, not applied" >&2
  exit 1
}
# `"fallback": null` is the load-bearing half: `entry_failed` exits 1 on an
# unmapped field that took no fallback, and a fallback string here would make
# this case pass while the ticket went out without its field.
grep -Fq '{"field": "sprint", "fallback": null}' "$tmp/create-undeclared.json" || {
  echo "an unmapped extra field must claim no fallback:" >&2
  cat "$tmp/create-undeclared.json" >&2
  exit 1
}
grep -Fq "which no [extra_fields.sprint] in the config declares" "$tmp/create-undeclared.json" || {
  echo "the conflict should name the undeclared field and where to declare it" >&2
  exit 1
}
# The field that DID map still never landed, because the create it would have
# ridden on never went. Reporting it `applied` would name a field on an issue
# that does not exist.
grep -Fq '"team": "skipped"' "$tmp/create-undeclared.json" || {
  echo "a mappable extra field on a refused create should report skipped" >&2
  exit 1
}

# A create dry run plans the extra field and sends nothing, same as every other
# dry run: the plan the user approves has to be the plan that runs.
before_dry="$(log_lines "$rest_log")"
python3 "$apply" create --config "$config" --dry-run \
  < "$tmp/create-default.jsonl" > "$tmp/create-dry.json" 2>/dev/null || {
  echo "a create dry run should exit 0" >&2
  exit 1
}
[[ "$(log_lines "$rest_log")" == "$before_dry" ]] || {
  echo "a create --dry-run must write nothing" >&2
  exit 1
}
grep -Fq '"key": null' "$tmp/create-dry.json" || {
  echo "a create dry run reports a null key, per the contract" >&2
  exit 1
}
grep -Fq '"extra_fields": {"team": "applied"}' "$tmp/create-dry.json" || {
  echo "a create dry run should plan the extra field the real run would send" >&2
  exit 1
}

# `update` edits issues that already carry their fields. Accepting the key and
# dropping it would report a field as landed that no code path ever wrote.
set +e
python3 -c '
import json
print(json.dumps({"key": "PROJ-412", "fields": {}, "extra_fields": {"team": "x"}}))
' | python3 "$apply" update --config "$config" > /dev/null 2> "$tmp/update-extra.err"
update_extra_status=$?
set -e
[[ "$update_extra_status" == 3 ]] || {
  echo "extra_fields on an update entry should exit 3, got $update_extra_status" >&2
  exit 1
}
grep -Fq "extra_fields is create-only" "$tmp/update-extra.err" || {
  echo "the rejection should say extra_fields is create-only:" >&2
  cat "$tmp/update-extra.err" >&2
  exit 1
}

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
# in its own config. Every half is already in the fixture config — `goal` and
# `goal_cli_name` under [fields], and an `id`/`cli_name` pair per
# [extra_fields.*] table; deriving the map from there rather than restating the
# pairs keeps a config edit from silently splitting a write key from its read
# key, which is the shape of the bug this leg exists to catch.
export FAKE_JIRA_CUSTOM_FIELDS="$(python3 -c '
import json, sys, tomllib
with open(sys.argv[1], "rb") as f:
    cfg = tomllib.load(f)
fields = cfg.get("fields") or {}
name = (fields.get("goal_cli_name") or "").strip()
field_id = (fields.get("goal") or "").strip()
if not name or not field_id:
    sys.exit("the fixture config must set both fields.goal and fields.goal_cli_name")
declared = {name: field_id}
extra = cfg.get("extra_fields") or {}
if not extra:
    sys.exit("the fixture config must declare at least one [extra_fields.*] table")
for key, declaration in extra.items():
    cli_name = (declaration.get("cli_name") or "").strip()
    ident = (declaration.get("id") or "").strip()
    if not cli_name or not ident:
        sys.exit(f"extra_fields.{key} must set both id and cli_name")
    declared[cli_name] = ident
print(json.dumps(declared))
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

# --- Extra fields on create (jira-cli). -------------------------------------
# The CLI writes a custom field by its declared NAME and the raw API returns it
# by id. That split is where the field silently lands on the wrong key, so this
# leg checks both ends: the argument that went out, and the id it reads back on.

create_entry "Team over the CLI" > "$tmp/cli-create.jsonl"
python3 "$apply" create --config "$config" --transport jira-cli \
  < "$tmp/cli-create.jsonl" > "$tmp/cli-create.json" 2>/dev/null || {
  echo "a jira-cli create with a mappable extra field should exit 0" >&2
  exit 1
}
python3 - "$cli_log" <<'PY' || exit 1
import json, sys
creates = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
creates = [c for c in creates if c.get("command") == "issue create"]
if not creates:
    sys.exit("no `issue create` reached the CLI fake")
args = creates[-1]["args"]
if "--custom" not in args or "Team=team-a" not in args:
    sys.exit(f"the create should have sent --custom Team=team-a; got {args!r}")
PY
cli_created_key="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["key"])
' "$tmp/cli-create.json")"
python3 "$apply" get "$cli_created_key" --config "$config" --transport jira-cli \
  > "$tmp/cli-created.json" 2>/dev/null || {
  echo "the issue the CLI create reported should be readable back" >&2
  exit 1
}
python3 - "$tmp/cli-created.json" <<'PY' || exit 1
import json, sys
fields = json.load(open(sys.argv[1], encoding="utf-8"))["fields"]
# Written by name, read by id. A fake or a transport that stored it under the
# literal name would leave this empty while every report still said `applied`.
if fields.get("customfield_10001") != "team-a":
    sys.exit(f"the created issue reads back customfield_10001="
             f"{fields.get('customfield_10001')!r}, expected 'team-a'")
PY

# `--custom` writes by name, so a jira-cli run with no `cli_name` has no way to
# name the field. Refusing beats creating a ticket the board will not show.
before_nocli="$(log_lines "$cli_log")"
grep -v '^cli_name = "Team"$' "$config" > "$tmp/no-cli-name.toml"
set +e
python3 "$apply" create --config "$tmp/no-cli-name.toml" --transport jira-cli \
  < "$tmp/cli-create.jsonl" > "$tmp/cli-nocli.json" 2>/dev/null
nocli_status=$?
set -e
[[ "$nocli_status" == 1 ]] || {
  echo "a jira-cli create with no cli_name should exit 1, got $nocli_status" >&2
  exit 1
}
[[ "$(log_lines "$cli_log")" == "$before_nocli" ]] || {
  echo "a create refused for a missing cli_name must not reach the tracker" >&2
  exit 1
}
grep -Fq "no cli_name, which jira-cli writes by" "$tmp/cli-nocli.json" || {
  echo "the refusal should name cli_name as the missing piece:" >&2
  cat "$tmp/cli-nocli.json" >&2
  exit 1
}

# --- The extra_fields config table. -----------------------------------------
# Loud rather than lenient, unlike [fields] and [auth], which a wrong shape
# merely empties. Those two have a documented description-block fallback, so a
# dropped table still gets the content to Jira. A dropped [extra_fields.team]
# creates tickets missing the field the board filters on — the original bug,
# reintroduced by a typo nobody sees.
bad_extra_config() {  # <toml body> <expected message fragment>
  {
    echo 'projects = ["PROJ"]'
    echo 'site = "http://127.0.0.1:1"'
    printf '%s\n' "$1"
  } > "$tmp/bad-extra.toml"
  set +e
  python3 "$apply" get PROJ-412 --config "$tmp/bad-extra.toml" > /dev/null 2> "$tmp/bad-extra.err"
  local status=$?
  set -e
  [[ "$status" == 3 ]] || {
    echo "a malformed [extra_fields] should exit 3, got $status for: $1" >&2
    exit 1
  }
  grep -Fq "$2" "$tmp/bad-extra.err" || {
    echo "the message should name the problem '$2'; got: $(cat "$tmp/bad-extra.err")" >&2
    exit 1
  }
}
bad_extra_config 'extra_fields = "nope"' "must be a table of tables"
bad_extra_config '[extra_fields]
team = "flat"' "must be a table with id, cli_name, and value"
bad_extra_config '[extra_fields.team]
id = 10001' "must be a string"
# A misspelled setting is the whole failure mode in miniature: `idd` would leave
# `id` empty, and a lenient read would create invisible tickets forever.
bad_extra_config '[extra_fields.team]
idd = "customfield_10001"' "has no setting"

# Two declarations that resolve to one field. Both write paths are last-one-wins
# and neither says so: a REST create builds one flat `fields` dict, and a
# jira-cli create repeats `--custom name=value`. The worst case is `id =
# "description"`, which sends the extra field's value in place of the rendered
# block while the report still reads `description=applied` — the same silent
# shape the extra-field table exists to close, arriving through the config.
bad_extra_config '[fields]
goal = "customfield_10057"

[extra_fields.team]
id = "description"
value = "ERASED"' "which is a field every create already writes"
bad_extra_config '[extra_fields.team]
id = "summary"
value = "x"' "which is a field every create already writes"
bad_extra_config '[fields]
goal = "customfield_10057"

[extra_fields.team]
id = "customfield_10057"
value = "x"' "the same field as fields.goal"
bad_extra_config '[extra_fields.a]
id = "customfield_10099"
value = "1"

[extra_fields.b]
id = "customfield_10099"
value = "2"' "already declared by extra_fields.a"
# The jira-cli namespace is checked on a rest run and vice versa, because
# `--transport` overrides the config at the command line: a config validated
# only for the active transport would pass here and silently drop a field the
# moment somebody switched.
bad_extra_config '[fields]
goal_cli_name = "Goal"

[extra_fields.team]
cli_name = "Goal"
value = "x"' "the same field as fields.goal_cli_name"
bad_extra_config '[extra_fields.a]
cli_name = "Dup"
value = "1"

[extra_fields.b]
cli_name = "Dup"
value = "2"' "already declared by extra_fields.a"

# A field declared for one transport only leaves the other half empty, and two
# empty halves collide with nothing. Rejecting this would make a rest-only
# config impossible to write.
{
  echo 'projects = ["PROJ"]'
  echo 'site = "http://127.0.0.1:1"'
  printf '%s\n' '[extra_fields.a]
id = "customfield_10001"
value = "1"

[extra_fields.b]
cli_name = "OnlyCli"
value = "2"'
} > "$tmp/half-declared.toml"
set +e
python3 "$apply" get PROJ-412 --config "$tmp/half-declared.toml" > /dev/null 2> "$tmp/half-declared.err"
set -e
# The exit code cannot tell the two apart: `get` against this deliberately dead
# site exits 3 whether the config was rejected or merely unreachable. The
# message is what separates them, so getting past config parsing means no
# extra_fields complaint on stderr.
grep -Fq "config: extra_fields" "$tmp/half-declared.err" && {
  echo "a field declared for one transport only should load, but was rejected:" >&2
  cat "$tmp/half-declared.err" >&2
  exit 1
}

# The reserved set and the payload must not drift. A field added to
# `create_issue`'s dict without a matching entry in CREATE_PAYLOAD_FIELDS
# becomes overwritable again, silently, and no other assertion here would say so.
python3 - "$apply" <<'PY' || exit 1
import ast, sys
tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
reserved = None
for node in ast.walk(tree):
    if isinstance(node, ast.Assign) and any(
        isinstance(t, ast.Name) and t.id == "CREATE_PAYLOAD_FIELDS" for t in node.targets
    ):
        reserved = {e.value for e in ast.walk(node.value) if isinstance(e, ast.Constant)}
if reserved is None:
    sys.exit("CREATE_PAYLOAD_FIELDS is gone; nothing pins the reserved create fields")
rest = next(
    n for n in ast.walk(tree)
    if isinstance(n, ast.ClassDef) and n.name == "RestTransport"
)
create = next(
    n for n in ast.walk(rest)
    if isinstance(n, ast.FunctionDef) and n.name == "create_issue"
)
written = set()
for node in ast.walk(create):
    if not isinstance(node, ast.Assign):
        continue
    for target in node.targets:
        # `fields = {...}`: only this dict's own keys, never a nested one like
        # the `{"key": ...}` a project or parent is wrapped in.
        if (isinstance(target, ast.Name) and target.id == "fields"
                and isinstance(node.value, ast.Dict)):
            written |= {
                k.value for k in node.value.keys if isinstance(k, ast.Constant)
            }
        # `fields["x"] = ...`; a computed subscript is an extra field or the
        # goal, both of which the collision check already governs.
        if (isinstance(target, ast.Subscript)
                and isinstance(target.value, ast.Name)
                and target.value.id == "fields"
                and isinstance(target.slice, ast.Constant)):
            written.add(target.slice.value)
missing = sorted(w for w in written if w not in reserved)
if missing:
    sys.exit(f"create_issue writes {missing} which CREATE_PAYLOAD_FIELDS does not reserve; "
             "an extra field could overwrite them")
PY

# Nothing infers a team from the project. On a project shared by several teams
# that would file one team's work onto another team's board — worse than
# invisibility, and the reason the field is declared per run instead.
refute_text jira-refine/scripts/jira-apply.py "customfield_10001"
require_text jira-refine/references/tracker-contract.md "extra_fields"
require_text jira-refine/assets/jira-refine.example.toml "[extra_fields.team]"

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
