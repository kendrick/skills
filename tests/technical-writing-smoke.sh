#!/usr/bin/env bash
# Pin the technical-writing skill's load-bearing decisions. Most of these are
# refutes: the failure modes worth guarding are features the plan explicitly
# cut (unslop, disable-model-invocation, a router that enumerates its own
# steps), and a well-meaning edit is exactly how they come back.
#
# The `## Example` pins on the reference files are satisfied by sections
# harvested from real eval runs. Never stub one to turn this script green: a
# placeholder satisfies the pin while verifying nothing, which is what the
# `pending-harvest` refute below exists to catch.
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

# The trailing `return 0` matters: under `set -e`, a function ending on a
# failed grep aborts the script.
refute_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" && {
    echo "unexpected text in $file: $text" >&2
    exit 1
  }
  return 0
}

# --- Inventory ---------------------------------------------------------

require_file technical-writing/SKILL.md
require_file technical-writing/README.md
require_file technical-writing/references/commit-messages.md
require_file technical-writing/references/comments.md
require_file technical-writing/references/pr-descriptions.md
require_file technical-writing/references/readme.md
require_file technical-writing/references/review-correspondence.md
require_file _maintenance/technical-writing/PROVENANCE.md
require_file _maintenance/technical-writing/EVALS.md
require_file _maintenance/technical-writing/upstream/SKILL.md

# Top level ships exactly SKILL.md, README.md, and the references/ and
# scripts/ dirs—nothing else. A plain file count (like the other smoke
# tests use) would miss a stray directory, so compare the full listing.
#
# LC_ALL=C pins the collation, because the expected listing below is written in
# C order (uppercase before lowercase). Under a UTF-8 locale `sort` ignores case
# and puts `references` between README.md and SKILL.md, so the comparison failed
# on a correct directory for everyone whose shell was not in the C locale.
top_level="$(find technical-writing -maxdepth 1 -mindepth 1 | LC_ALL=C sort)"
expected_top_level=$'technical-writing/README.md\ntechnical-writing/SKILL.md\ntechnical-writing/references\ntechnical-writing/scripts'
[[ "$top_level" == "$expected_top_level" ]] || {
  echo "technical-writing/ must ship only SKILL.md, README.md, references/, and scripts/ at top level" >&2
  echo "found:" >&2
  echo "$top_level" >&2
  exit 1
}

# The deferred profile is a deliberate non-goal—the dispatch table falls
# back to the router's globals for this artifact type instead.
# pr-descriptions.md left this loop when its profile shipped, and readme.md
# followed when readme-coauthorship's polish step created the real need the
# fallback was waiting on; both are now pinned as required in the inventory
# above.
for f in technical-writing/references/api-reference.md; do
  [[ ! -e "$f" ]] || {
    echo "deferred profile shipped early, contradicting the dispatch table's fallback: $f" >&2
    exit 1
  }
done

# A second, separate loop (kept apart from the one above so this stays
# additions-only) for the three profiles the issue-body/release-notes/how-to
# rows point at. Same deal: the dispatch table falls back to globals until
# real need justifies writing these.
for f in technical-writing/references/issue-bodies.md technical-writing/references/release-notes.md technical-writing/references/how-to.md; do
  [[ ! -e "$f" ]] || {
    echo "deferred profile shipped early, contradicting the dispatch table's fallback: $f" >&2
    exit 1
  }
done

# --- SKILL.md decisions --------------------------------------------------

refute_text technical-writing/SKILL.md "disable-model-invocation"

# The description must not enumerate the step sequence: a description that
# summarizes a workflow becomes a shortcut the model takes instead of reading
# the body. Scoped to just the description line, since "Step 1" is a
# legitimate heading later in the file.
description_line="$(grep -m1 '^description:' technical-writing/SKILL.md)"
if [[ "$description_line" == *"Step 1"* ]]; then
  echo "SKILL.md description enumerates the step sequence (contains 'Step 1')" >&2
  exit 1
fi

require_text technical-writing/SKILL.md "never for anything addressed to a person: emails, DMs, and other messages"

# Upstream hard-depends on its `unslop` sibling. This skill ships publicly and
# names no auditor at all, so it must not acquire that dependency by any name.
refute_text technical-writing/SKILL.md "unslop"
refute_text technical-writing/SKILL.md "humanizer"

# One-way coupling: file-issue names technical-writing (the caller names the
# callee), never the reverse. A mutual reference would let an agent ping-pong
# between the two skills, so this router must never mention file-issue.
refute_text technical-writing/SKILL.md "file-issue"

# Same rule for readme-coauthorship, which also calls in via its polish step —
# but a whole-file refute can't work here, because the description legitimately
# names it once for boundary routing ("Authoring a whole README belongs to
# readme-coauthorship"). Pin the count at exactly one so the body stays silent.
rc_mentions="$(grep -o 'readme-coauthorship' technical-writing/SKILL.md | wc -l | tr -d ' ')"
[[ "$rc_mentions" == "1" ]] || {
  echo "technical-writing/SKILL.md must name readme-coauthorship exactly once (the description's boundary routing), found: $rc_mentions" >&2
  exit 1
}

# Step 2 must still name a concrete action. "Run an audit" with no formal
# invocation is how the step decays into a self-assessment that always passes.
require_text technical-writing/SKILL.md "**Run the prose audit.**"
require_text technical-writing/SKILL.md "invoke it formally via the Skill tool"
require_text technical-writing/SKILL.md "**Layer the house rules.**"
require_text technical-writing/SKILL.md "**Self-check.**"

# STE's one-thought rule alone drives drafts into runs of clipped sentences, so
# the join rule sits beside it. Losing it brings the staccato back silently.
require_text technical-writing/SKILL.md "Join short neighbors that share a subject or a cause"

# The skill ships to people who have neither humanizer nor the author's private
# ~/.claude files. The body may name them as the setup it was built against, but
# the description must not: a hardcoded personal path there reads as a hard
# requirement, and a stranger installing this would get a Step 2 they cannot
# finish and two dead paths into someone else's home directory.
for personal_path in "~/.claude/PROSE.md" "~/.claude/VOICE.md"; do
  if [[ "$description_line" == *"$personal_path"* ]]; then
    echo "SKILL.md description hardcodes a personal path, which strangers won't have: $personal_path" >&2
    exit 1
  fi
done

# The Step 2 self-check must carry only checks valid for every artifact type.
# Diátaxis/mode compliance is a profile concern — it's excluded from commits,
# PR descriptions, and changesets, so a mode check here would fail
# universality. Scoped to the Step 2 section only: "Diátaxis" appears
# legitimately elsewhere in the file (the layers section, the dispatch
# table), so a whole-file refute would be wrong.
step2_section="$(awk '/^## Step 2/{flag=1; print; next} /^## /{if (flag) exit} flag' technical-writing/SKILL.md)"
[[ -n "$step2_section" ]] || {
  echo "could not locate a '## Step 2' section in technical-writing/SKILL.md" >&2
  exit 1
}
for term in "Diátaxis" "Diataxis" "one mode"; do
  if grep -Fq -- "$term" <<<"$step2_section"; then
    echo "Step 2 self-check contains a mode-check term that belongs to profiles, not the router: $term" >&2
    exit 1
  fi
done

require_text technical-writing/SKILL.md "not yet written"

# Whole-row pins on the four new/changed dispatch rows: a reword must not be
# able to silently drop the globals-only fallback or grow a profile link
# before the profile exists.
require_text technical-writing/SKILL.md "| PR description | [references/pr-descriptions.md](references/pr-descriptions.md) | STE, Google, Global English — no Diátaxis |"
require_text technical-writing/SKILL.md "| Issue body, drafted or filed | not yet written — globals above | STE, Google, Global English |"
require_text technical-writing/SKILL.md "| Release notes, changelog, migration guide | not yet written — globals above | All four |"
require_text technical-writing/SKILL.md "| How-to guides, walkthroughs | not yet written — globals above | All four; how-to mode |"
require_text technical-writing/SKILL.md "| README, docs | [references/readme.md](references/readme.md) | All four; Diátaxis via the mode mapping |"

# The old combined row must be gone — proves the split happened rather than
# the new rows just sitting alongside a stale one.
refute_text technical-writing/SKILL.md "| README, guides, docs |"

# Same idea for the PR row: proves the fallback cell was replaced by the
# profile link, not that a linked row grew beside a stale globals-only one.
refute_text technical-writing/SKILL.md "| PR description | not yet written"

# And for the README row, when its profile shipped.
refute_text technical-writing/SKILL.md "| README, docs | not yet written"

# The review-correspondence row, pinned whole like its neighbours. #111 was
# filed because an agent writing nine pieces of review correspondence in one
# wave fell back to the PR-description row every time, so this row sits
# directly beneath that
# one: the nearest-row search that produced the wrong answer now lands one line
# above the right one, and the position is part of the fix rather than
# alphabetical accident.
require_text technical-writing/SKILL.md "| Review correspondence, a reply or a standalone PR comment | [references/review-correspondence.md](references/review-correspondence.md) | STE, Google, Global English — no Diátaxis |"

# #77 proposed this row as a fifth `not yet written — globals above` fallback,
# with no profile file. #111 supersedes it, and this refute is what keeps the
# superseded shape from arriving later as a "simpler" edit that drops the
# profile link and leaves the row looking answered.
refute_text technical-writing/SKILL.md "| Review correspondence, a reply or a standalone PR comment | not yet written"

# The layers section enumerates the artifacts Diátaxis skips, and the new row's
# Layers cell says "no Diátaxis". Left at three, the enumeration contradicts the
# table one section below it by omission, and a reader who trusts the prose over
# the table writes a mode-shaped reply. PROVENANCE.md restates this same set and
# moves with it.
require_text technical-writing/SKILL.md "commits, PR descriptions, review correspondence, and changesets have no document mode"

# The description is the trigger surface, and it excludes "anything addressed
# to a person" — which a reply to a reviewer is. #77 named this collision:
# without the carve-out the frontmatter suppresses the trigger for the exact
# artifact the new row exists to route, and the file contradicts itself. Both
# are pinned whole because both are what a "tighten the description" pass drops
# first, and because the existing pin on the exclusion clause above stays green
# either way.
require_text technical-writing/SKILL.md "answering a review finding"
require_text technical-writing/SKILL.md "Review correspondence is the exception—public developer prose hanging off a diff, and it dispatches here."

# --- Anti-drift pins on the verbatim CLAUDE.md migrations ---------------
# These passages are copied word-for-word from the user's ~/.claude/CLAUDE.md,
# so the skill and the config can't drift apart while both are live. Paraphrasing
# one is a defect even when the rewrite reads better — the copy's whole job is to
# match. Pin whole passages rather than a phrase from each: a sentence-fragment
# pin passes happily while the rest of the section is reworded around it, which
# is the drift it was supposed to catch.
#
# CLAUDE.md is a user-level file outside this repo, so the test can't diff
# against the source. These strings are the stand-in — update them only when
# CLAUDE.md itself changes, and update the profiles in the same pass.

require_text technical-writing/references/commit-messages.md "Commit messages should focus on the WHY just as much as on the WHAT. They should be just long enough to cover what's essential and no longer."
require_text technical-writing/references/commit-messages.md "Write commit messages in the voice and tone of a helpful technical writer who is also in a hurry; commonly-recognized abbreviations and acronyms are acceptable."
require_text technical-writing/references/commit-messages.md "Never add \`Co-Authored-By\` trailers or any other \"coauthored\" attribution to commit messages or PR descriptions."
require_text technical-writing/references/commit-messages.md "Never manually wrap lines in prose of any sort with hard returns. Let the terminal or git's own pager handle wrapping at display time."

# pr-descriptions.md carries the same two PR-scoped CLAUDE.md sentences that
# commit-messages.md does. The duplication is deliberate — a profile has to
# stand alone at dispatch, because the router sends a run to exactly one — so
# these pins are what keep the two copies saying the same thing.
require_text technical-writing/references/pr-descriptions.md "Never add \`Co-Authored-By\` trailers or any other \"coauthored\" attribution to commit messages or PR descriptions."
require_text technical-writing/references/pr-descriptions.md "Never manually wrap lines in prose of any sort with hard returns. Let the terminal or git's own pager handle wrapping at display time."

# The AI-footer rider is a synced pair the same way, but it originates here
# rather than in CLAUDE.md: the trailer rule bans the named trailer, and this
# extends it to the footers that show up in its place. Both profiles carry it
# word for word, appended after the trailer sentence so the pins above keep
# matching their substring.
ai_footer_rider="The same ban covers AI-attribution footers: no \"Generated with\" lines and no robot-emoji sign-offs, whatever the harness inserts by default."
require_text technical-writing/references/commit-messages.md "$ai_footer_rider"
require_text technical-writing/references/pr-descriptions.md "$ai_footer_rider"

require_text technical-writing/references/comments.md "Comment proactively, but only when the comment carries weight. Every comment should explain the WHY behind the code — the constraint that forced this shape, the past incident this guards against, the surprising invariant a reader might miss, the broader context the code lives inside."
require_text technical-writing/references/comments.md "Comments that explain WHAT the code does are worthless when the code is well-named. Comments that explain HOW the code works shouldn't be necessary if the code is written cleanly. The only comment worth writing is the one that explains something the code itself can't."
require_text technical-writing/references/comments.md "Write comments in the voice and tone of a helpful technical writer who is also in a hurry; commonly-recognized abbreviations and acronyms are acceptable."

# --- review-correspondence's own hard rules ------------------------------
# This profile carries NO verbatim CLAUDE.md passage, unlike the two above it.
# Both of CLAUDE.md's PR-scoped sentences name their own scope inside the
# sentence — "to commit messages or PR descriptions" — and a review reply is
# neither, so a verbatim third copy would ship a rule that is false of the file
# it sits in and would turn a two-copy sync into a three-way one whose third
# copy had to be hand-edited anyway. The rules are restated here in this
# artifact's scope, with this artifact's reason, and pinned as themselves.
require_text technical-writing/references/review-correspondence.md "Never sign a reply or a standalone comment."
require_text technical-writing/references/review-correspondence.md "Never hard-wrap the body."

# And the refute that pays for the decision: a well-meaning "sync these up"
# edit pasting the PR-scoped sentence in would look like an improvement and
# would silently create the third sync obligation the decision declines.
refute_text technical-writing/references/review-correspondence.md "to commit messages or PR descriptions"

# --- pr-descriptions change outline --------------------------------------
# The trigger is structural, and the nearest wrong rule is size ("outline the
# big PRs"). A writer keying on size outlines a forty-file rename and skips a
# one-call move, so the trigger and its size clause are pinned whole. Mermaid
# is the reason the outline defaults to fenced text: it renders only on the PR
# web page, and a repo that squashes with the PR body puts raw source in
# `git log`. Pin that sentence so nobody softens it into "renders best on GitHub".
require_text technical-writing/references/pr-descriptions.md "Add a change outline when the change alters a structure the reviewer has to hold in mind: a call path, a file layout, a data structure, a contract, or a component tree."
require_text technical-writing/references/pr-descriptions.md "The size of the change doesn't decide it: a one-call move gets an outline, and a rename across forty files gets none."
require_text technical-writing/references/pr-descriptions.md "A change outline is not the diff restatement the Content section rules out: it shows a structure the diff spreads across files, which prose can't."
require_text technical-writing/references/pr-descriptions.md "Mermaid renders only on GitHub's web page and shows as raw source everywhere else."

# What the outline idea was borrowed from (HumanLayer's visual-pr) and cut:
# its fixed headings, an HTML page for dense concepts, commit/push/open-PR
# steps, and its own task paths. Each string below is one cut, and a
# well-meaning edit would bring any of them back as "completeness". The last
# two name the cut itself: a bare `git push` or `.html` also trips on harmless
# prose, such as a file-tree outline naming `signup.html`.
refute_text technical-writing/references/pr-descriptions.md "## Why the change"
refute_text technical-writing/references/pr-descriptions.md "## Special things to note"
refute_text technical-writing/references/pr-descriptions.md ".humanlayer/tasks"
refute_text technical-writing/references/pr-descriptions.md "gh pr create"
refute_text technical-writing/references/pr-descriptions.md "HTML page"

require_text technical-writing/SKILL.md "testing disclosure, change outlines, squash-merge survival"
require_text technical-writing/README.md "testing disclosure, change outlines, squash-merge survival"

# --- Example-harvest pins -------------------------------------------------
# EXPECTED TO FAIL until the harvest step lands. The Example sections come
# from real eval runs later in the plan; do not stub them just to go green.

require_text technical-writing/references/commit-messages.md "## Example"
require_text technical-writing/references/comments.md "## Example"
require_text technical-writing/references/pr-descriptions.md "## Example"
require_text technical-writing/references/readme.md "## Example"
require_text technical-writing/references/review-correspondence.md "## Example"

# The README profile's two load-bearing structures: the per-section mode
# mapping (the reason the profile exists at all), and the existing-voice rule,
# pinned as a whole sentence because it's the line a well-meaning "tighten the
# register" edit would flatten first.
require_text technical-writing/references/readme.md "## Mode Mapping"
require_text technical-writing/references/readme.md "Where the README already carries an author's voice—emoji headers, first person, dry humor—that voice is the register: fix what reads two ways and leave how it sounds alone."

# The three rules #111's acceptance criteria name, each pinned whole. Every one
# of them is a sentence a "tighten this up" pass flattens into the paragraph
# around it, and the profile is worth nothing without all three.
require_text technical-writing/references/review-correspondence.md "The first sentence says where the reply landed."

# Two carve-outs a review found by reading the callers rather than this file.
# work-issue hard-codes the reply body for a queued row at
# references/triage.md:77 and routes it through this profile, and that body
# opens on "deferred:" rather than one of the four verdicts spelled out. An
# agent handed both documents could satisfy only one, so the rule names the
# caller's short form the scope disposition it is, and says not to read it
# as confirmation. The SHA rule had the matching gap pointed the other way:
# this profile supports a refused verdict and a standalone comment, and
# neither has a commit, so an unconditional "cite the SHA" sends the agent
# to HEAD for a locator that answers nothing.
require_text technical-writing/references/review-correspondence.md "A caller that fixes the opening outranks that"
require_text technical-writing/references/review-correspondence.md "states a scope disposition and not a correctness verdict"
require_text technical-writing/references/review-correspondence.md "have no commit to name, so they cite none"
require_text technical-writing/references/review-correspondence.md "Where the fix diverged from what the reviewer proposed, say so in the reply rather than leaving it in the diff."
require_text technical-writing/references/review-correspondence.md "A short SHA is the natural thing to hand a reviewer and the first thing to go stale."

# Diátaxis does not reach this artifact, so there is nothing to map. The section
# exists in readme.md and comments.md and is exactly the thing somebody adds to
# a profile that looks thin.
refute_text technical-writing/references/review-correspondence.md "## Mode Mapping"

# A placeholder stub must never ship and quietly satisfy the Example pins above.
# refute_text takes a single file, so this one's a direct recursive grep
# rather than the helper.
if grep -rFq -- "pending-harvest" technical-writing/; then
  echo "unexpected text under technical-writing/: pending-harvest" >&2
  exit 1
fi

# --- PROVENANCE pins -------------------------------------------------------

require_text _maintenance/technical-writing/PROVENANCE.md "## Deviations From Upstream"
require_text _maintenance/technical-writing/PROVENANCE.md "MIT, Copyright (c) 2026 Lauren Tan"

# --- Root README pin --------------------------------------------------

# The root README carries this skill's own install flag, in the map
# table's third column. The command form around it is pinned once, in
# repo-docs-smoke.sh, so this does not re-pin it twelve times.
require_text README.md "--skill technical-writing"

# --- lint-message.py ---------------------------------------------------
# One case per acceptance criterion and falsifier in #394. The cases collect
# failures instead of exiting on the first, so a run against a tree without
# the script lists every case it fails rather than stopping at one.
#
# The wrap falsifiers run in both directions on purpose. A line-length rule
# (the 72-column habit) flags the 200-character line and passes the two
# 30-character ones, and a newest-commit-only inference flips on the
# newest-bare case, so each wrong rule fails at least one case below.

lint="$repo_root/technical-writing/scripts/lint-message.py"
lint_tmp="$(mktemp -d)"
lint_tmp="$(cd "$lint_tmp" && pwd -P)"
trap 'rm -rf "$lint_tmp"' EXIT
lint_failures=0
lint_cwd="$repo_root"
lint_stdin=/dev/null

lint_fail() {
  echo "lint-message case failed: $1" >&2
  echo "  rc=$2 stdout: $(cat "$lint_tmp/out")" >&2
  echo "  stderr: $(cat "$lint_tmp/err")" >&2
  lint_failures=$((lint_failures + 1))
}

# lint_case NAME WANT_RC WANT_STDERR ARGS...: WANT_STDERR is a fixed string
# the stderr must hold, or empty. An exit-0 case also requires empty stderr.
lint_case() {
  local name="$1" want_rc="$2" want_err="$3"
  shift 3
  local rc=0
  (cd "$lint_cwd" && GIT_CEILING_DIRECTORIES="$lint_tmp" python3 "$lint" "$@" <"$lint_stdin") \
    >"$lint_tmp/out" 2>"$lint_tmp/err" || rc=$?
  if [[ "$rc" != "$want_rc" ]]; then
    lint_fail "$name (want exit $want_rc)" "$rc"
  elif [[ -n "$want_err" ]] && ! grep -Fq -- "$want_err" "$lint_tmp/err"; then
    lint_fail "$name (want stderr '$want_err')" "$rc"
  elif [[ "$want_rc" == 0 && -s "$lint_tmp/err" ]]; then
    lint_fail "$name (want empty stderr)" "$rc"
  fi
  return 0
}

msg() {
  local name="$1"
  shift
  printf '%s\n' "$@" >"$lint_tmp/$name.txt"
}

clean_subject="feat(lint): add a checker for the commit and PR hard rules"
clean_body="One unwrapped body paragraph saying why the change exists, on a single line."

# Trailers: each form alone in an otherwise clean message, at line 5.
msg clean "$clean_subject" "" "$clean_body"
lint_case "clean commit message" 0 "" commit "$lint_tmp/clean.txt" --convention conventional
msg coauthor "$clean_subject" "" "$clean_body" "" "co-AUTHORED-by: Someone <someone@example.com>"
lint_case "Co-Authored-By trailer, mixed case" 1 "line 5: Co-Authored-By trailer" commit "$lint_tmp/coauthor.txt" --convention conventional
msg generated "$clean_subject" "" "$clean_body" "" "Generated with a coding agent"
lint_case "Generated with footer" 1 'line 5: "Generated with" footer' commit "$lint_tmp/generated.txt" --convention conventional
msg robot "$clean_subject" "" "$clean_body" "" "🤖 signed off by the harness"
lint_case "robot-emoji sign-off" 1 "line 5: robot-emoji sign-off" commit "$lint_tmp/robot.txt" --convention conventional

# Hard wrap, in PR bodies so no subject rule fires.
msg wrapped "A paragraph that a writer broke across two lines" "by pressing return at the edge of their editor."
lint_case "two-line paragraph is a wrap" 1 "line 2: hard wrap" pr "$lint_tmp/wrapped.txt"
msg joined "A paragraph that a writer broke across two lines by pressing return at the edge of their editor."
lint_case "the same paragraph joined passes" 0 "" pr "$lint_tmp/joined.txt"
msg bulletwrap "- A list item that a writer broke across two lines" "  by indenting the rest under the bullet."
lint_case "wrapped list item is a wrap" 1 "line 2: hard wrap" pr "$lint_tmp/bulletwrap.txt"
msg short "Thirty characters on this line" "and thirty more on this line.."
lint_case "two 30-character lines are a wrap" 1 "line 2: hard wrap" pr "$lint_tmp/short.txt"
msg long "$(printf 'word %.0s' $(seq 1 40))"
lint_case "one 200-character line passes" 0 "" pr "$lint_tmp/long.txt"
msg bullets "- the first of two adjacent bullets" "- the second of two adjacent bullets"
lint_case "adjacent bullets pass" 0 "" pr "$lint_tmp/bullets.txt"
msg table "| column | other |" "| --- | --- |" "| a | b |"
lint_case "adjacent table rows pass" 0 "" pr "$lint_tmp/table.txt"
eighty="$(printf 'x%.0s' $(seq 1 80))"
msg fenced "Intro paragraph." "" '```' "$eighty" "$eighty" "$eighty" '```'
lint_case "fenced 80-column lines pass" 0 "" pr "$lint_tmp/fenced.txt"

# A heading or a closing fence is one line, so the text right under it starts
# a paragraph, and a block of git trailers is one trailer per line. The second
# line under each is checked as usual.
msg heading "## Summary" "Adds the thing."
lint_case "text right under a heading passes" 0 "" pr "$lint_tmp/heading.txt"
msg headingwrap "## Summary" "Adds the thing, in a paragraph that a writer" "broke across two lines."
lint_case "a wrap under a heading is still a wrap" 1 "line 3: hard wrap" pr "$lint_tmp/headingwrap.txt"
msg afterfence '```' "$eighty" '```' "Text right under the closing fence."
lint_case "text right under a closing fence passes" 0 "" pr "$lint_tmp/afterfence.txt"
# A three-backtick fence nested in a four-backtick one is content, not a closer.
msg nestedfence '````markdown' '```python' 'first = 1' 'second = 2' '```' '````'
lint_case "nested shorter fence stays inside the outer one" 0 "" pr "$lint_tmp/nestedfence.txt"
msg infofence '```' '``` not a closer' 'first = 1' 'second = 2' '```'
lint_case "a fence line with an info string does not close" 0 "" pr "$lint_tmp/infofence.txt"
msg tildefence '```' '~~~' 'first = 1' 'second = 2' '```'
lint_case "a tilde line does not close a backtick fence" 0 "" pr "$lint_tmp/tildefence.txt"
msg setexteq "Summary" "=======" "" "Adds validation."
lint_case "Setext = underline is not a wrap" 0 "" pr "$lint_tmp/setexteq.txt"
msg setextdash "Summary" "-------" "" "Adds validation."
lint_case "Setext - underline is not a wrap" 0 "" pr "$lint_tmp/setextdash.txt"
msg setextwrap "Summary" "=======" "Adds validation in a paragraph" "that a writer broke by hand."
lint_case "prose wrapped under a Setext heading is still a wrap" 1 "line 4: hard wrap" pr "$lint_tmp/setextwrap.txt"
msg listfence '- ```python' '  first = 1' '  second = 2' '  ```'
lint_case "a fence opened inside a list item holds its lines" 0 "" pr "$lint_tmp/listfence.txt"
msg codemarker '```' 'code line one' '- ```' 'still code a' 'more code b' '```'
lint_case "a list-marker fence line inside a fence is code" 0 "" pr "$lint_tmp/codemarker.txt"
msg inlineopen '- ```code``` inline start' 'prose that a writer broke' 'across two lines by hand.'
lint_case "a backtick opener with a backtick in its info string is not a fence" 1 "line 3: hard wrap" pr "$lint_tmp/inlineopen.txt"
msg breakstar "Adds validation." "" "***" "Checks existing messages."
lint_case "a *** break ends its block" 0 "" pr "$lint_tmp/breakstar.txt"
msg breakunder "Adds validation." "" "___" "Checks existing messages."
lint_case "a ___ break ends its block" 0 "" pr "$lint_tmp/breakunder.txt"
msg breakspaced "Adds validation." "" "* * *" "Checks existing messages."
lint_case "a spaced * * * break ends its block" 0 "" pr "$lint_tmp/breakspaced.txt"
msg breakwrap "Adds validation." "" "***" "Checks existing messages in a paragraph" "that a writer broke by hand."
lint_case "prose wrapped after a break is still a wrap" 1 "line 5: hard wrap" pr "$lint_tmp/breakwrap.txt"
msg bulletwrap2 "- A list item that a writer broke across two lines" "  by indenting the rest under the bullet." "" "- another item"
lint_case "a wrapped bullet is still a wrap beside the break rule" 1 "line 2: hard wrap" pr "$lint_tmp/bulletwrap2.txt"
# A prefix with nothing after it has no lowercase letter to fail, so it needs its own check.
msg emptydesc "feat: "
lint_case "conventional prefix with an empty description" 1 "empty description after the type prefix" commit "$lint_tmp/emptydesc.txt" --convention conventional
lint_case "PR title with an empty description" 1 "empty description after the type prefix" pr "$lint_tmp/joined.txt" --title "feat: " --convention conventional
msg trailers "$clean_subject" "" "$clean_body" "" "Refs: #394" "Signed-off-by: Someone <someone@example.com>"
lint_case "adjacent git trailers pass" 0 "" commit "$lint_tmp/trailers.txt" --convention conventional
msg trailerwrap "$clean_subject" "" "$clean_body" "" "Refs: #394" "and a sentence that wrapped under the trailer."
lint_case "prose wrapped under a trailer is a wrap" 1 "line 6: hard wrap" commit "$lint_tmp/trailerwrap.txt" --convention conventional

# Commit-only rules. Line 2 is reported once, as the missing blank line.
msg noblank "$clean_subject" "$clean_body"
lint_case "non-blank second line" 1 "line 2: no blank line after the subject" commit "$lint_tmp/noblank.txt" --convention conventional
if grep -Fq "hard wrap" "$lint_tmp/err"; then lint_fail "non-blank second line also reported as a wrap" 1; fi
msg period "$clean_subject." "" "$clean_body"
lint_case "subject ending in a period" 1 "line 1: subject ends in a period" commit "$lint_tmp/period.txt" --convention conventional

# Convention, set by flag.
msg upper "feat(x): Add thing"
lint_case "uppercase after the colon under conventional" 1 "line 1: uppercase letter after the type prefix" commit "$lint_tmp/upper.txt" --convention conventional
msg bare "Add thing"
lint_case "bare subject under bare" 0 "" commit "$lint_tmp/bare.txt" --convention bare
lint_stdin="$lint_tmp/bare.txt"
lint_case "bare subject read from stdin" 0 "" commit - --convention bare
lint_stdin=/dev/null
msg prefixed "feat: add thing"
lint_case "type prefix under bare" 1 "line 1: type prefix in a bare-imperative repo" commit "$lint_tmp/prefixed.txt" --convention bare
msg lower "add thing"
lint_case "lowercase first letter under bare" 1 "line 1: bare subject starts lowercase" commit "$lint_tmp/lower.txt" --convention bare
lint_case "PR title under the subject rules" 1 "title: uppercase letter after the type prefix" pr "$lint_tmp/joined.txt" --title "feat(x): Add thing" --convention conventional

# Length is a note: a 90-character subject prints one and still exits 0.
long_subject="feat(lint): $(printf 'a%.0s' $(seq 1 78))"
msg longsubject "$long_subject"
lint_case "90-character subject exits 0" 0 "" commit "$lint_tmp/longsubject.txt" --convention conventional
grep -q '^note:' "$lint_tmp/out" || lint_fail "90-character subject prints a note: line" 0

# Convention, inferred from the log. Subjects are written oldest first.
make_log_repo() {
  local dir="$lint_tmp/$1"
  shift
  mkdir -p "$dir"
  git -C "$dir" init -q
  local s
  for s in "$@"; do
    git -C "$dir" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null \
      commit -q --allow-empty -m "$s"
  done
}
conv() { local i; for i in $(seq 1 "$1"); do echo "feat(a): add thing $i"; done; }
bare() { local i; for i in $(seq 1 "$1"); do echo "Add thing $i"; done; }
probe="feat(lint): add a probe subject that clears the length floor"
msg probe "$probe"

# 7 of 12 Conventional, newest Conventional.
IFS=$'\n' read -r -d '' -a subjects < <(bare 5; conv 7) || true
make_log_repo seven "${subjects[@]}"
lint_cwd="$lint_tmp/seven"
lint_case "7 of 12 Conventional infers conventional" 0 "" commit "$lint_tmp/probe.txt" --log 12
lint_case "no flag behaves as --log 12" 0 "" commit "$lint_tmp/probe.txt"

# 6 of 12: one Conventional changed to bare, so the strict majority is gone.
IFS=$'\n' read -r -d '' -a subjects < <(bare 6; conv 6) || true
make_log_repo six "${subjects[@]}"
lint_cwd="$lint_tmp/six"
lint_case "6 of 12 Conventional infers bare" 1 "line 1: type prefix in a bare-imperative repo" commit "$lint_tmp/probe.txt" --log 12

# 7 of 12 Conventional with the newest bare: still conventional.
IFS=$'\n' read -r -d '' -a subjects < <(bare 4; conv 7; bare 1) || true
make_log_repo newestbare "${subjects[@]}"
lint_cwd="$lint_tmp/newestbare"
lint_case "newest bare at 7 of 12 still infers conventional" 0 "" commit "$lint_tmp/probe.txt" --log 12

# A repo with no commits has nothing to infer from.
mkdir -p "$lint_tmp/empty"
git -C "$lint_tmp/empty" init -q
lint_cwd="$lint_tmp/empty"
lint_case "--log in a repo with no commits exits 3" 3 "" commit "$lint_tmp/probe.txt" --log 12

# Outside any repository; GIT_CEILING_DIRECTORIES in lint_case keeps a
# parent repo from leaking in.
mkdir -p "$lint_tmp/norepo"
lint_cwd="$lint_tmp/norepo"
lint_case "--log outside a git repository exits 3" 3 "" commit "$lint_tmp/probe.txt" --log 12
lint_cwd="$repo_root"

# Usage errors and unreadable input exit 3, never argparse's default 2.
lint_case "unknown flag exits 3" 3 "" commit "$lint_tmp/bare.txt" --bogus
lint_case "--convention with --log exits 3" 3 "" commit "$lint_tmp/bare.txt" --convention bare --log 12
lint_case "missing file exits 3" 3 "" commit "$lint_tmp/does-not-exist.txt" --convention bare

if (( lint_failures > 0 )); then
  echo "$lint_failures lint-message case(s) failed" >&2
  exit 1
fi

# The script reports and never edits, and installs nothing; each cut is a
# Deliberately Not Built row in RATIONALE.md.
require_text technical-writing/scripts/lint-message.py "It reports and never edits."
refute_text technical-writing/scripts/lint-message.py "--fix"
refute_text technical-writing/scripts/lint-message.py "commit-msg"

require_text technical-writing/references/commit-messages.md "scripts/lint-message.py"
require_text technical-writing/references/pr-descriptions.md "scripts/lint-message.py"

# --- check-refs.py -------------------------------------------------------
# One case per acceptance criterion and falsifier in #401. Cases collect
# failures like lint_case does, so a run without the script lists every one.
#
# The shape rule is what the falsifiers perturb. Keyed on existence, a rule
# reports `git diff --name-only` and `owner/repo#12` too, so the clean-exit
# cases fail on it; keyed on nothing, `tests/no-such-smoke.sh` clears, so the
# exit-1 case fails on that. Inputs live under $lint_tmp/refs, which the one
# trap above already removes; a second trap would replace it.

refs="$repo_root/technical-writing/scripts/check-refs.py"
refs_tmp="$lint_tmp/refs"
mkdir -p "$refs_tmp"
refs_failures=0
refs_cwd="$repo_root"
refs_path="$PATH"
refs_py=python3
refs_stdin=/dev/null

refs_fail() {
  echo "check-refs case failed: $1" >&2
  echo "  rc=$2 stdout: $(cat "$refs_tmp/out")" >&2
  echo "  stderr: $(cat "$refs_tmp/err")" >&2
  refs_failures=$((refs_failures + 1))
}

# refs_case NAME WANT_RC WANT_STDERR ARGS...: same contract as lint_case.
refs_case() {
  local name="$1" want_rc="$2" want_err="$3"
  shift 3
  local rc=0
  (cd "$refs_cwd" && GIT_CEILING_DIRECTORIES="$lint_tmp" PATH="$refs_path" \
    "$refs_py" "$refs" "$@" <"$refs_stdin") >"$refs_tmp/out" 2>"$refs_tmp/err" || rc=$?
  if [[ "$rc" != "$want_rc" ]]; then
    refs_fail "$name (want exit $want_rc)" "$rc"
  elif [[ -n "$want_err" ]] && ! grep -Fq -- "$want_err" "$refs_tmp/err"; then
    refs_fail "$name (want stderr '$want_err')" "$rc"
  elif [[ "$want_rc" == 0 && -s "$refs_tmp/err" ]]; then
    refs_fail "$name (want empty stderr)" "$rc"
  fi
  return 0
}

# refs_text NAME TEXT...: write one input file, a line per argument.
refs_text() {
  local name="$1"
  shift
  printf '%s\n' "$@" >"$refs_tmp/$name.txt"
}

# The rule's key, perturbed both ways: a missing path is reported, the same
# shape naming a real file clears, and the two near-misses never are.
refs_text missing 'Run `tests/no-such-smoke.sh` first.'
refs_case "a missing path is reported" 1 'line 1: tests/no-such-smoke.sh' "$refs_tmp/missing.txt"
refs_text present 'Run `tests/file-issue-smoke.sh` first.'
refs_case "the same shape naming a real file clears" 0 "" "$refs_tmp/present.txt"
refs_text shape 'List them with `git diff --name-only` and cite `owner/repo#12`.' 'Also `a#b/c`, `a*b/c`, `a?b/c`, `<dir>/x.sh`, `https://example.com/x.html`.'
refs_case "whitespace, #, *, ?, <, and :// are never paths" 0 "" "$refs_tmp/shape.txt"
refs_text noslash 'The `name` and `v1` and `plain.` words are not paths.'
refs_case "a span with no slash and no extension is not a path" 0 "" "$refs_tmp/noslash.txt"
refs_text bare_path 'Run tests/no-such-smoke.sh or see technical-writing/no-such.md for more.'
refs_case "a bare path outside a code span is not checked" 0 "" "$refs_tmp/bare_path.txt"
refs_text dotslash 'See `./AGENTS.md` and `././tests/file-issue-smoke.sh`.'
refs_case "a leading ./ is dropped before lookup" 0 "" "$refs_tmp/dotslash.txt"
refs_text ext 'See `no-such-file.py`.'
refs_case "a bare filename with an extension is a path" 1 'line 1: no-such-file.py' "$refs_tmp/ext.txt"

refs_text suffix 'See `adversarial-review/references/trigger-table.md:46` and `adversarial-review/`.'
refs_case "a :line suffix is dropped and a directory resolves" 0 "" "$refs_tmp/suffix.txt"
refs_text suffixmissing 'See `adversarial-review/references/no-such.md:46`.'
refs_case "a :line suffix on a missing path is reported without the suffix" 1 'adversarial-review/references/no-such.md' "$refs_tmp/suffixmissing.txt"

refs_text fenced 'Intro.' '```' 'tests/no-such-smoke.sh' '`tests/no-such-smoke.sh`' '```' 'Done.'
refs_case "a path inside a fenced block is not checked" 0 "" "$refs_tmp/fenced.txt"
refs_text nestedfence '````markdown' '```' '`tests/no-such-smoke.sh`' '```' '`tests/also-missing.sh`' '````' 'Done.'
refs_case "a shorter fence nested in a longer one stays fenced" 0 "" "$refs_tmp/nestedfence.txt"
refs_text afterfence '```' 'code' '```' 'See `tests/no-such-smoke.sh`.'
refs_case "a path after the closing fence is checked again" 1 'line 4: tests/no-such-smoke.sh' "$refs_tmp/afterfence.txt"

refs_stdin="$refs_tmp/missing.txt"
refs_case "stdin works as -" 1 'tests/no-such-smoke.sh' -
refs_stdin=/dev/null

# Scratch repo: one tracked file, one untracked, one ignored, one directory.
scratch="$refs_tmp/repo"
mkdir -p "$scratch/sub"
git -C "$scratch" init -q
printf 'ignored.log\n' >"$scratch/.gitignore"
printf 'x\n' >"$scratch/tracked.txt"
printf 'x\n' >"$scratch/sub/a.txt"
git -C "$scratch" add .gitignore tracked.txt sub/a.txt
printf 'x\n' >"$scratch/new.txt"
printf 'x\n' >"$scratch/ignored.log"
refs_cwd="$scratch"
refs_text tracked 'See `tracked.txt`, `sub/`, and `sub/a.txt`.'
refs_case "tracked files and a directory resolve" 0 "" "$refs_tmp/tracked.txt"
refs_text untracked 'See `new.txt`.'
refs_case "an untracked, non-ignored file resolves" 0 "" "$refs_tmp/untracked.txt"
refs_text ignored 'See `ignored.log`.'
refs_case "an ignored file does not resolve, though it exists" 1 'line 1: ignored.log' "$refs_tmp/ignored.txt"
# Paths resolve from the top level of the repo, never from the cwd.
refs_cwd="$scratch/sub"
refs_case "paths resolve against the repo top level from a subdirectory" 0 "" "$refs_tmp/tracked.txt"
refs_cwd="$repo_root"

# The gh rules. A PATH holding only git proves the path checks never need gh;
# the stub below proves a run without --gh never calls it.
bin_nogh="$refs_tmp/bin-nogh"
mkdir -p "$bin_nogh"
ln -s "$(command -v git)" "$bin_nogh/git"
refs_py="$(python3 -c 'import sys; print(sys.executable)')"
if PATH="$bin_nogh:/usr/bin:/bin" command -v gh >/dev/null 2>&1; then
  echo "check-refs gh-absent cases cannot run: gh sits in /usr/bin or /bin on this machine" >&2
  refs_failures=$((refs_failures + 1))
else
  refs_path="$bin_nogh:/usr/bin:/bin"
  refs_case "gh absent from PATH, clean input, exit 0" 0 "" "$refs_tmp/present.txt"
  refs_case "gh absent from PATH, missing path, exit 1" 1 'tests/no-such-smoke.sh' "$refs_tmp/missing.txt"
  refs_text issues 'See #7 for the background.'
  refs_case "--gh with gh absent exits 3 rather than passing" 3 "" "$refs_tmp/issues.txt" --gh
  refs_path="$PATH"
fi

bin_stub="$refs_tmp/bin-stub"
mkdir -p "$bin_stub"
cat >"$bin_stub/gh" <<STUB
#!/bin/sh
echo "\$*" >>"$refs_tmp/gh-calls"
case "\$3" in
  7) exit 0 ;;
  8) echo "GraphQL: Could not resolve to an issue or pull request with the number of 8." >&2; exit 1 ;;
  *) echo "To get started with GitHub CLI, please run: gh auth login" >&2; exit 4 ;;
esac
STUB
chmod +x "$bin_stub/gh"
refs_path="$bin_stub:$PATH"
rm -f "$refs_tmp/gh-calls"
refs_case "without --gh the script never calls gh" 0 "" "$refs_tmp/issues.txt"
[[ ! -e "$refs_tmp/gh-calls" ]] || refs_fail "without --gh the script never calls gh (gh was called)" 0

refs_text bare 'Fixes #7 and #8, cross-ref owner/repo#9, abc#10, `#11`, and #7 again.' '```' '#12' '```'
refs_case "--gh reports only a bare #N that gh cannot find" 1 'line 1: #8' "$refs_tmp/bare.txt" --gh
if grep -Fq '#7' "$refs_tmp/err"; then refs_fail "--gh reports #7, which gh found" 1; fi
asked="$(sort -u "$refs_tmp/gh-calls" | tr '\n' ';')"
[[ "$asked" == "issue view 7;issue view 8;pr view 8;" ]] || refs_fail "--gh asks once per distinct bare number, got: $asked" 1
refs_text authfail 'See #13.'
refs_case "--gh exits 3 when gh fails for another reason" 3 "" "$refs_tmp/authfail.txt" --gh
refs_path="$PATH"

# A tracked name that isn't UTF-8 must not crash the lookup. A stub git stands
# in for the file, since APFS refuses to create one; every other subcommand
# goes to the real git.
bin_badgit="$refs_tmp/bin-badgit"
mkdir -p "$bin_badgit"
cat >"$bin_badgit/git" <<STUB
#!/bin/sh
case "\$1" in
  ls-files) printf 'bad\377.txt\0ok.txt\0' ;;
  *) exec "$(command -v git)" "\$@" ;;
esac
STUB
chmod +x "$bin_badgit/git"
refs_path="$bin_badgit:$PATH"
refs_text badname 'See `ok.txt` and `nope.txt`.'
refs_case "a non-UTF-8 tracked name doesn't crash the lookup" 1 'nope.txt does not resolve' "$refs_tmp/badname.txt"
if grep -Fq Traceback "$refs_tmp/err"; then refs_fail "a non-UTF-8 tracked name raised a traceback" 1; fi
if grep -Fq "ok.txt does not" "$refs_tmp/err"; then refs_fail "the name after a non-UTF-8 one was lost" 1; fi
refs_path="$PATH"

# Usage errors, unreadable input, and a cwd outside any repo exit 3, never 2.
refs_case "unknown flag exits 3" 3 "" "$refs_tmp/present.txt" --bogus
refs_case "missing file exits 3" 3 "" "$refs_tmp/does-not-exist.txt"
refs_case "no FILE exits 3" 3 ""
mkdir -p "$refs_tmp/norepo"
refs_cwd="$refs_tmp/norepo"
refs_case "outside any git repository exits 3" 3 "" "$refs_tmp/present.txt"
refs_cwd="$repo_root"
refs_py=python3

if (( refs_failures > 0 )); then
  echo "$refs_failures check-refs case(s) failed" >&2
  exit 1
fi

# The script reports and never edits; the cuts are Deliberately Not Built rows.
require_text technical-writing/scripts/check-refs.py "It reports and never edits."
refute_text technical-writing/scripts/check-refs.py "--fix"

# Step 2 names the script and says how far it reaches, since a writer who
# believes it checks symbols stops checking them.
require_text technical-writing/SKILL.md "scripts/check-refs.py"
require_text technical-writing/SKILL.md "checks code-span paths only"

# --- Size ceiling -----------------------------------------------------
# The self-imposed byte ceiling was raised from 6.5 KB to 7 KB when the new
# dispatch rows landed, then to 7.3 KB when the README profile's row and
# Further Reading bullet landed, then to 7.8 KB for the review-correspondence
# row and the two repairs it forced: the Diátaxis exclusion set gained a fourth
# artifact, and the description had to carve a review reply out of its own
# "addressed to a person" exclusion. Upstream is an 11,522-byte monolith; this
# router stays well under it because the profiles carry what's
# artifact-specific.
skill_size="$(wc -c < technical-writing/SKILL.md)"
(( skill_size <= 7800 )) || {
  echo "technical-writing/SKILL.md is $skill_size bytes, over the 7800-byte ceiling" >&2
  exit 1
}

# The frontmatter description has its own ceiling, separate from the file's.
# Claude Code caps it at 1024 characters and a skill over the cap does not
# load, which no content pin can see: this change grew the description to 1094
# and all sixteen suites stayed green, because the three checks above read what
# the description says and never how long it is. A skill that fails to load is
# the one defect where a green suite is actively misleading.
description_len="$(python3 - <<'PYEOF'
import io, re
t = io.open("technical-writing/SKILL.md", encoding="utf-8").read()
m = re.search(r'^description:\s*(.*?)(?=\n[a-z-]+:|\n---)', t, re.S | re.M)
print(len(m.group(1).strip()) if m else -1)
PYEOF
)"
(( description_len > 0 )) || {
  echo "could not read technical-writing/SKILL.md's description" >&2
  exit 1
}
(( description_len <= 1024 )) || {
  echo "technical-writing/SKILL.md description is $description_len characters, over the 1024-character cap; a skill over it does not load" >&2
  exit 1
}

echo "all pins passed"
