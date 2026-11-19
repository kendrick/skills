#!/usr/bin/env bash
# Pin _maintenance/work-issue/measure-load.py against a fixture skill whose
# sizes are known by construction: SKILL.md is concatenated from piece files,
# so every expected number is `wc -c` of a piece or arithmetic on those, never
# anything the script computed. The token path runs against a 127.0.0.1 stub;
# no case reaches the network. Case 12 pins the real SKILL.md's shape only.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Overridable so the scratch-copy falsifiers can run this suite on a mutant.
script="${MEASURE_LOAD:-_maintenance/work-issue/measure-load.py}"
tmp="$(mktemp -d)"
stub_pid=""
cleanup() { [[ -n "$stub_pid" ]] && { kill "$stub_pid"; wait "$stub_pid"; } 2>/dev/null || true; rm -rf "$tmp"; }
trap cleanup EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
# Cases 1-5 read one output, so they report every miss rather than stopping at the
# first: a mutant that breaks Adopt or the fence rule must show up in case 2 and 4 too.
soft_failures=0
soft() { echo "FAIL: $1" >&2; soft_failures=$((soft_failures + 1)); }
sz() { wc -c < "$1" | tr -d ' '; }
filler() { head -c "$1" /dev/zero | tr '\0' x; echo; }

p="$tmp/pieces"
mkdir -p "$p"
printf -- '---\nname: fx\n---\n' > "$p/fm"
printf '# fx\nresolve block\nglobal rules\n' > "$p/pre"
for k in 0 1 2 3 4 5 6 7 8; do
  { printf '## Step %s — Name%s\n' "$k" "$k"; filler $(( (k + 1) * 100 )); } > "$p/step$k"
done
# Step 4 holds a sub-heading and a fenced example heading; neither may split a unit.
printf '### Sub\n```\n## Step 9 — fake\n```\n' >> "$p/step4"
{ printf '## Adopt — enter at Step 6\n'; filler 250; } > "$p/adopt"
{ printf '## Where a Run Stops\n'; filler 120; } > "$p/stops"
{ printf '## Resume\n'; filler 130; } > "$p/resume"
cat > "$p/further" <<'FR'
## Further Reading

- [references/resume.md](references/resume.md) — read at Step 0 for the gather block
- [references/worker-prompt.md](references/worker-prompt.md) — read at Steps 2 and 7 to build the preamble
- [references/redteam.md](references/redteam.md) — read at Step 4 to run the reproducer
- [references/triage.md](references/triage.md) — read at Steps 6 and 8 to answer threads
FR

# build <dir> <piece>... : a fixture skill with the standard four references.
build() {
  local d="$1"; shift
  mkdir -p "$d/references"
  local f; : > "$d/SKILL.md"
  for f in "$@"; do cat "$p/$f" >> "$d/SKILL.md"; done
  head -c 4000 /dev/zero | tr '\0' x > "$d/references/resume.md"
  head -c 300 /dev/zero | tr '\0' x > "$d/references/worker-prompt.md"
  head -c 500 /dev/zero | tr '\0' x > "$d/references/redteam.md"
  head -c 700 /dev/zero | tr '\0' x > "$d/references/triage.md"
}
all=(fm pre step0 adopt step1 step2 step3 step4 step5 step6 step7 step8 stops resume further)
fx="$tmp/fx"
build "$fx" "${all[@]}"

# 1. unit rows
out="$tmp/bytes.out"
python3 "$script" --skill-dir "$fx" > "$out" || fail "case 1: bytes run on the fixture exited non-zero"
[[ "$(head -1 "$out")" == "measure-load: bytes over $fx" ]] || fail "case 1: first line was not 'measure-load: bytes over $fx'"
for k in 0 1 2 3 4 5 6 7 8; do
  grep -qxF "| SKILL.md: Step $k — Name$k | Step $k | $(sz "$p/step$k") |" "$out" || soft "case 1: no row for Step $k with piece size $(sz "$p/step$k")"
done
grep -qxF "| SKILL.md: Adopt — enter at Step 6 | adopted runs | $(sz "$p/adopt") |" "$out" || soft "case 1: Adopt row not tagged 'adopted runs' at its size"
grep -qxF "| references/resume.md | always | 4000 |" "$out" || soft "case 1: resume.md row not 'always' at 4000"
grep -qxF "| references/worker-prompt.md | Steps 2, 7 | 300 |" "$out" || soft "case 1: worker-prompt.md row not 'Steps 2, 7' at 300"

# 2. phase rows, from piece sizes
skill=$(sz "$fx/SKILL.md")
always=0
for f in fm pre stops resume further; do always=$(( always + $(sz "$p/$f") )); done
extra=(0 0 300 0 500 0 700 300 700)   # refs a phase reads besides resume.md
savings=()
for k in 0 1 2 3 4 5 6 7 8; do
  today=$(( skill + 4000 + ${extra[$k]} ))
  only=$(( always + $(sz "$p/step$k") + 4000 + ${extra[$k]} ))
  pct=$(awk -v t="$today" -v o="$only" 'BEGIN{printf "%.1f", 100*(t-o)/t}')
  grep -qxF "| $k | $today | $only | $pct% |" "$out" || soft "case 2: phase $k row expected '| $k | $today | $only | $pct% |'"
  savings+=( $(( today - only )) )
done

# 3. SKILL.md unit rows cover every byte once
sum=$(grep '^| SKILL.md: ' "$out" | awk -F'|' '{s += $4} END {print s}')
[[ "$sum" == "$skill" ]] || soft "case 3: SKILL.md rows sum to $sum, file is $skill"

# 4. fenced and sub headings stay inside Step 4
grep -qxF "| SKILL.md: Step 4 — Name4 | Step 4 | $(sz "$p/step4") |" "$out" || soft "case 4: Step 4 row is not piece 4's size"
! grep -q 'Step 9' "$out" || soft "case 4: a fenced '## Step 9' heading became a row"

# 5. median
want=$(printf '%s\n' "${savings[@]}" | sort -n | sed -n 5p)
grep -qxF "median saving (phases 0-8): $want" "$out" || soft "case 5: expected 'median saving (phases 0-8): $want'"

[[ $soft_failures == 0 ]] || fail "cases 1-5: $soft_failures assertion(s) failed"

# 6. missing step
build "$tmp/no5" fm pre step0 adopt step1 step2 step3 step4 step6 step7 step8 stops resume further
rc=0; python3 "$script" --skill-dir "$tmp/no5" >/dev/null 2>"$tmp/err" || rc=$?
[[ $rc == 1 ]] || fail "case 6: missing Step 5 exited $rc, expected 1"
grep -qF 'expected one "## Step 5" heading, found 0' "$tmp/err" || fail "case 6: stderr lacks 'expected one \"## Step 5\" heading, found 0'"

# 7. duplicated step
build "$tmp/dup3" fm pre step0 adopt step1 step2 step3 step3 step4 step5 step6 step7 step8 stops resume further
rc=0; python3 "$script" --skill-dir "$tmp/dup3" >/dev/null 2>"$tmp/err" || rc=$?
[[ $rc == 1 ]] || fail "case 7: duplicate Step 3 exited $rc, expected 1"
grep -qF 'expected one "## Step 3" heading, found 2' "$tmp/err" || fail "case 7: stderr lacks 'expected one \"## Step 3\" heading, found 2'"

# 8. untagged reference
build "$tmp/untagged" "${all[@]}"
echo extra > "$tmp/untagged/references/extra.md"
rc=0; python3 "$script" --skill-dir "$tmp/untagged" >/dev/null 2>"$tmp/err" || rc=$?
[[ $rc == 1 ]] || fail "case 8: untagged reference exited $rc, expected 1"
grep -qF 'references/extra.md: untagged' "$tmp/err" || fail "case 8: stderr lacks 'references/extra.md: untagged'"

# 9. token mode with no credential
rc=0; env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL python3 "$script" --skill-dir "$fx" --count tokens >"$tmp/o9" 2>"$tmp/err" || rc=$?
[[ $rc == 3 ]] || fail "case 9: token mode with no credential exited $rc, expected 3"
grep -q '^measure-load: count_tokens:' "$tmp/err" || fail "case 9: stderr lacks a 'measure-load: count_tokens:' line"
[[ ! -s "$tmp/o9" ]] || fail "case 9: stdout was not empty, so a table printed without a count"

# 10-11. token stub
cat > "$tmp/stub.py" <<'PY'
import http.server, json, sys

class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["content-length"])))
        ok = (self.path == "/v1/messages/count_tokens"
              and self.headers.get("x-api-key") == "test"
              and self.headers.get("anthropic-version") == "2026-10-21"
              and body.get("model") == "claude-opus-5-5")
        out = json.dumps({"input_tokens": len(body["messages"][0]["content"].encode()) + 3} if ok else {"error": "bad"}).encode()
        self.send_response(200 if ok else 400)
        self.send_header("content-length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)
    def log_message(self, *a):
        pass

s = http.server.HTTPServer(("127.0.0.1", 0), H)
open(sys.argv[1], "w").write(str(s.server_port))
s.serve_forever()
PY
python3 "$tmp/stub.py" "$tmp/port" &
stub_pid=$!
for _ in $(seq 50); do [[ -s "$tmp/port" ]] && break; sleep 0.1; done
[[ -s "$tmp/port" ]] || fail "case 10: the token stub never wrote its port"
base="http://127.0.0.1:$(cat "$tmp/port")"

rc=0; ANTHROPIC_BASE_URL="$base" ANTHROPIC_API_KEY=test python3 "$script" --skill-dir "$fx" --count tokens >"$tmp/tok.out" 2>"$tmp/err" || rc=$?
[[ $rc == 0 ]] || fail "case 10: token run against the stub exited $rc: $(cat "$tmp/err")"
[[ "$(head -1 "$tmp/tok.out")" == "measure-load: tokens (model claude-opus-5-5) over $fx" ]] || fail "case 10: first line was not 'measure-load: tokens (model claude-opus-5-5) over $fx'"
grep -qxF "| references/resume.md | always | 3999 |" "$tmp/tok.out" || fail "case 10: resume row expected 3999 (4000 + 3 - (1 + 3))"

rc=0; ANTHROPIC_BASE_URL="$base" ANTHROPIC_API_KEY=test python3 "$script" --skill-dir "$fx" --count tokens --model other-model >/dev/null 2>"$tmp/err" || rc=$?
[[ $rc == 3 ]] || fail "case 11: a 400 from count_tokens exited $rc, expected 3"

# 12. real tree: shape only
python3 "$script" --count bytes > "$tmp/real.out" || fail "case 12: the real work-issue did not measure"
[[ "$(grep -cE '^\| [0-8] \| ' "$tmp/real.out")" == 9 ]] || fail "case 12: expected nine phase rows for the real work-issue"

echo "work-issue measure-load smoke: OK"
