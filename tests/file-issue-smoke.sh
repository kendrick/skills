#!/usr/bin/env bash
# Pin the file-issue skill's load-bearing behavior. Most of these are refutes:
# the failure modes worth guarding are features the research explicitly cut,
# and a well-meaning edit is exactly how they come back.
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

expect_rc() {
  local want="$1"
  local got="$2"
  local what="$3"
  [[ "$got" == "$want" ]] || {
    echo "$what: expected exit $want, got $got" >&2
    exit 1
  }
}

# Counts lines, so "exactly one mutation" catches a duplicate send that a
# plain require_text would wave through.
require_count() {
  local file="$1"
  local text="$2"
  local want="$3"
  local got
  got="$(grep -Fc -- "$text" "$file" || true)"
  [[ "$got" == "$want" ]] || {
    echo "expected $want line(s) in $file containing: $text (got $got)" >&2
    exit 1
  }
}

# Reads the field the way link-issues.py's own consumer does, as parsed JSON,
# so a formatting change in the output can't fake or break the check.
require_json() {
  local file="$1"
  local expr="$2"
  local want="$3"
  local got
  got="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(json.dumps(eval(sys.argv[2])))' "$file" "$expr")"
  [[ "$got" == "$want" ]] || {
    echo "$file: $expr is $got, expected $want" >&2
    exit 1
  }
}

require_file file-issue/SKILL.md
require_file file-issue/README.md
require_file file-issue/references/issue-forms.md
require_file file-issue/references/evidence-map.md
require_file file-issue/assets/bug.template.md
require_file file-issue/assets/feature.template.md
require_file file-issue/assets/task.template.md
require_file file-issue/assets/spike.template.md
require_file _maintenance/file-issue/RATIONALE.md
require_file _maintenance/file-issue/EVALS.md
require_file _docs/file-issue-research.md

[[ "$(find file-issue -maxdepth 1 -type f | wc -l | tr -d ' ')" == "2" ]] || {
  echo "file-issue/ must ship only SKILL.md and README.md at top level" >&2
  exit 1
}

# Frontmatter. The to-tickets exclusion is what keeps two skills with adjacent
# trigger surfaces from firing on each other's work.
require_text file-issue/SKILL.md "name: file-issue"
require_text file-issue/SKILL.md "use to-tickets instead"
require_text file-issue/SKILL.md "Never edits, closes, triages, or ranks existing issues."

# The description must not enumerate the step sequence. A description that
# summarizes a workflow becomes a shortcut the model takes instead of reading
# the body, which is how a multi-stage skill silently collapses to one stage.
refute_text file-issue/SKILL.md "description: \"Step 1"

# Depth governor. Without the ladder the skill interrogates every ask equally,
# which is the failure the whole design exists to avoid.
require_text file-issue/SKILL.md "## Step 2 — Assign Depth"
require_text file-issue/SKILL.md "\`--deep\` pins Depth 2, \`--fast\` pins Depth 0"
require_text file-issue/SKILL.md "Depth 1 — 4 gaps to fill."
require_text file-issue/SKILL.md "Every question names the empty slot it fills."

# The verification-command harvest falls through past manifests (#25). A repo
# whose test surface is shell scripts—this one—must yield its smoke command
# mechanically, not by inference from a directory the table never mentions.
require_text file-issue/SKILL.md "no manifest → runnable scripts under \`tests/\` or \`scripts/\`"
require_text file-issue/SKILL.md "\`absent\` is the answer only after every rung misses"

# The solo-repo cap scopes to the repo-shape trigger (#18). Three Depth 2
# triggers are properties of the ask and one of the workflow; the shape of the
# tree must not talk them back down, or an agent-destined ask in a solo repo
# loses the code probe on exactly the issues that need file pointers.
require_text file-issue/SKILL.md "only when repo complexity was the sole Depth 2 trigger"
refute_text file-issue/SKILL.md "caps at Depth 1 unless the user forces higher"

# Elicit stays inline and stays contract-shaped. Both halves matter: inline is
# the decision, the contract is what keeps it extractable later.
require_text file-issue/SKILL.md "## Step 3 — Elicit"
require_text file-issue/SKILL.md "**Exit:** the moment the rubric in Step 6 becomes satisfiable."
refute_text file-issue/SKILL.md "references/elicit"

# Step 3's front-loading order splits by issue type (#23). The bug order is
# measured and stays as is; the feature order is convention—collisions between
# stated rules rank first because that is where a spec is genuinely incomplete
# rather than merely terse. Pinning both keeps an edit to one from silently
# taking the other with it.
require_text file-issue/SKILL.md "steps to reproduce first, then error output, then observed-versus-expected"
require_text file-issue/SKILL.md "collisions between stated rules first, then unstated behavior at boundaries"
require_text file-issue/references/evidence-map.md "Surfaced by one real run of the skill; nothing measures it. | [C] |"

# No runtime delegation to an external interrogation skill.
refute_text file-issue/SKILL.md "/grill-me"
refute_text file-issue/SKILL.md "grill-with-docs"

# Prose pass: a soft dependency on technical-writing that degrades to current
# behavior when absent. A step, not a gate — no evidence-map row. It must not
# weaken the no-delegation rule above: technical-writing owns any downstream
# prose auditor, so file-issue never names one directly.
require_text file-issue/SKILL.md "## Step 7 — Polish"
require_text file-issue/SKILL.md "## Step 8 — Write Guard"
require_text file-issue/SKILL.md "invoke it via the Skill tool on the drafted issue body"
require_text file-issue/SKILL.md "ship the draft unchanged"
require_text file-issue/SKILL.md "Depth 0 skips this step"
refute_text file-issue/SKILL.md "humanizer"

# The size check anchors on properties the drafting agent cannot move by
# rephrasing (#22): components and context fit. The criteria count is a smell
# that forces the fit question, never a trigger — eight criteria collapse to
# six on a rephrase, so a count trigger measured the write-up, not the work.
require_text file-issue/SKILL.md "**≥4 distinct components**"
require_text file-issue/SKILL.md "**the work does not fit one fresh context**"
require_text file-issue/SKILL.md "smell that forces the fit question, never a trigger"
refute_text file-issue/SKILL.md "≥7 independent acceptance criteria"

# Duplicates are surfaced, never blocked. This is the evidence-contradicted
# feature most likely to get "fixed" back in by someone who assumes blocking is
# the responsible default.
require_text file-issue/SKILL.md "Surface what you find and let the user choose"
require_text file-issue/SKILL.md "Never block"

# Write guard and scope.
require_text file-issue/SKILL.md "wait for explicit confirmation before \`gh issue create\`"
require_text file-issue/SKILL.md "\`--dry-run\` renders and stops."
require_text file-issue/SKILL.md "Creation only."
require_text file-issue/SKILL.md "gh auth status"

# No epic or tracking template — multi-issue decomposition is to-tickets' job.
[[ ! -e file-issue/assets/epic.template.md ]] || {
  echo "epic template is deliberately out of scope; see the RATIONALE ledger" >&2
  exit 1
}

# Gate 6's verify-alone condition (#24). An agent-targeted issue whose
# verification command does not exercise the change lets the agent finish,
# fail to verify, and report done regardless; the only exit is a declared
# blocker or a named later issue. The gate stays conditioned on agent-targeted,
# so issues that are not stay unaffected, and the Depth 2 probe carries the
# prefactor question that makes the condition passable.
require_text file-issue/SKILL.md "**Agent-readiness**, when the issue is agent-targeted"
require_text file-issue/SKILL.md "exercise the change, not merely pass beside it"
require_text file-issue/SKILL.md "declaring its prerequisite as a blocker, or by naming the issue where verification lands"
require_text file-issue/SKILL.md "what preparatory change would make the work small and verifiable on its own"

# The derived-rule gate (#110). A ticket that introduces a derived value ships
# the rule for deriving it. Stated in prose, that rule can key on the wrong thing
# and still read correctly: one provenance ticket cost four reclassifications
# across four modules before anyone caught it. Six strings hold the gate: the
# heading, the trigger in the ticket's own language, both halves of the
# two-outcome property that makes the gate a demand for a falsifier rather than
# for more precision, and the two fences that keep the gate off every acceptance
# criterion and off the test itself. The second half gets its own line because a
# reword drops that half first, and it is the only half asserting a non-effect.
# Without it the gate reads as a request to tighten a sentence.
require_text file-issue/SKILL.md "**Falsifier for a derived rule**"
require_text file-issue/SKILL.md '"is", "counts as", or "should be marked"'
require_text file-issue/SKILL.md "most plausible wrong neighbor: perturb what the rule keys on"
require_text file-issue/SKILL.md "perturb the nearest thing the rule could have keyed on instead and the value has to stay put"
require_text file-issue/SKILL.md "Acceptance criteria observe the value and this gate reaches the rule behind it"
require_text file-issue/SKILL.md "rather than a rewrite or the test itself"

# Step 7 may reword a falsifier but never disarm it. Disarming by reword already
# shipped once for acceptance criteria: Step 7's protected list omitted them, a
# reword slipped through (EVALS scenario 7), and naming them closed the hole. A
# falsifier left to the generic "every fact the gates passed" clause reopens that
# hole, because the half a reword drops is the non-effect half.
require_text file-issue/SKILL.md "both outcomes it asserts survive the pass"

# Gate 7 is the only gate a draft cannot close by itself: inventing the
# falsifier is the thing it exists to prevent, so "fix the draft" is not a
# remedy available to it. That makes Step 3's "Depth 0 asks nothing"
# load-bearing where it never was for gates 1-6, which can all be satisfied by
# drafting. Both halves are pinned because dropping either one leaves the
# document telling an agent at Depth 0 to do two incompatible things, and a
# review found exactly that gap before these lines existed.
require_text file-issue/SKILL.md "its question gets asked even at Depth 0 where nothing else is"
require_text file-issue/SKILL.md "the one question a Depth 0 run can still put is a gate 7 failure at Step 6"

# The README publishes the --fast contract to humans, and it promised "No
# questions at all" until gate 7 earned an exception. A reader who takes the
# README at its word and gets interrogated has been misled by the artifact
# that sets the expectation, so the exception is pinned on both sides of the
# document boundary. Found by a reviewer reading the README against a SKILL.md
# fix that had swept everywhere except here.
require_text file-issue/README.md "The one question that still reaches you is gate 7's"

# Depth 1's five-question ceiling had the same collision as Depth 0's silence,
# and it predates both: gate 7 shipped with a question-only remedy and no
# accounting against either budget. The answer is the same one, so five is the
# interview budget and a gate failure is not an interview question. Pinned on
# both the skill and the README, because the README is where a human reads the
# cap and believes it.
require_text file-issue/SKILL.md "A gate 7 failure at Step 6 sits outside that count"
require_text file-issue/README.md "plus gate 7's if the body states a derived rule nothing could falsify"

# The template carries the gate's drafting counterpart. Without that prompt, a
# drafter first meets the gate at Step 6 with the body already written, which
# forces the rewrite the gate exists to avoid.
require_text file-issue/assets/feature.template.md "state the rule as a property and name the check that would fail it"

# Parent and Blocked-by slots (#19). A prerequisite smuggled into prose sends
# an agent to run a file another ticket has yet to create, so every template
# carries both slots, Blocked by resolves to references or an explicit "None"
# rather than a blank, and gate 6 checks named artifacts against the repo.
for f in file-issue/assets/bug.template.md file-issue/assets/feature.template.md file-issue/assets/task.template.md file-issue/assets/spike.template.md; do
  require_text "$f" "**Parent:**"
  require_text "$f" "**Blocked by:**"
  require_text "$f" 'states "None" outright'
  require_text "$f" "drop the line"
done
require_text file-issue/SKILL.md "fails unless that artifact is declared on the Blocked by line"

# Native-first slots (#175), pinned in the prose. Entries resolve before the
# render, every entry is filed as text, links go out once `gh issue create`
# prints the URL (addSubIssue and addBlockedBy both need the new issue's
# node), and only then does `strip` remove the entries whose link landed. The
# creation-only rule admits exactly three kinds of write, each naming the new
# issue, named so a fourth kind can't ride in on "linking".
require_text file-issue/SKILL.md "Resolve every Parent and Blocked by entry before"
require_text file-issue/SKILL.md "A Parent in a repository another owner holds is always one of those"
require_text file-issue/SKILL.md "An entry the viewer lacks permission to link is another"
require_text file-issue/SKILL.md "link-issues.py resolve"
require_text file-issue/SKILL.md "link-issues.py link"
require_text file-issue/SKILL.md "slot entries only"
require_text file-issue/SKILL.md "admits exactly three kinds of write"
require_text file-issue/SKILL.md "one \`addBlockedBy\` per blocker"
require_text file-issue/SKILL.md "link-issues.py strip"
require_text file-issue/SKILL.md "removes only the entries whose link landed"
require_text file-issue/SKILL.md "addSubIssue"
require_text file-issue/SKILL.md "addBlockedBy"
require_text file-issue/SKILL.md "the links it will set beside the rendered body"
require_text file-issue/SKILL.md "\`link --dry-run\` with no \`--issue\`"
require_text file-issue/SKILL.md "every link was set or reported with its retry command"
require_text file-issue/SKILL.md "the linked entries were stripped from the body or the strip was reported with its retry command"
require_text file-issue/SKILL.md "\`strip\` still runs and, finding nothing linked, writes nothing"
require_text file-issue/SKILL.md "lands on the Blocked by line as text"
require_text file-issue/SKILL.md "links the new issue to its parent and blockers"
# A failed link is reported with its retry command and its text stays in the
# body. Writing the failure back into the body is the edit the creation-only
# rule exists to forbid (Deliberately Not Built): the one body write removes
# entries whose link landed and never adds a reference back. The only text it
# writes is the `None` an emptied agent-targeted Blocked by line gets.
refute_text file-issue/SKILL.md "edit the body to add"
refute_text file-issue/SKILL.md "add it back as text"
# The phrases above can be reworded around; the command can't. A body edit
# outside `strip` takes `gh issue edit`.
refute_text file-issue/SKILL.md "gh issue edit"
require_text file-issue/SKILL.md "never adds a reference back"
for f in file-issue/assets/bug.template.md file-issue/assets/feature.template.md file-issue/assets/task.template.md file-issue/assets/spike.template.md; do
  require_text "$f" "becomes a native link"
  require_text "$f" "anything else stays as text"
done
require_text file-issue/references/issue-forms.md "capture it for \`link-issues.py link\`"
require_text file-issue/references/evidence-map.md "Native link first, text fallback"
require_text file-issue/README.md "└── link-issues.py"
require_text file-issue/README.md "links the new issue to its parent and blockers"
require_text _maintenance/file-issue/RATIONALE.md "Parent and Blocked by link natively when they name an issue"
require_text _maintenance/file-issue/RATIONALE.md "\`--issue\` is optional only under \`--dry-run\`"
require_text _maintenance/file-issue/RATIONALE.md "## Deliberately Not Built"
require_text _maintenance/file-issue/RATIONALE.md "Editing the issue body after creation to add a failed link back as text"
require_text _maintenance/file-issue/RATIONALE.md "text leaves the body only after its link has landed"
require_text _maintenance/file-issue/RATIONALE.md "Linking is github.com-only"
refute_text _maintenance/file-issue/RATIONALE.md "blocking stays text, never GitHub-native"
require_text _maintenance/file-issue/EVALS.md "### 10. Native links"

# Native links (#175), pinned at the wire. A fake gh answers only canned
# nodes and logs every call, so these check the mutations that actually went
# out, not what the script meant to send.
link_tmp="$(mktemp -d)"
trap 'rm -rf "$link_tmp"' EXIT
cp tests/fixtures/file-issue/fake-gh "$link_tmp/gh"
chmod +x "$link_tmp/gh"
export FAKE_GH_LOG="$link_tmp/gh.log"
run_link() {
  PATH="$link_tmp:$PATH" python3 file-issue/scripts/link-issues.py "$@"
}
new_issue=https://github.com/o/r/issues/40

# An existing issue in each slot resolves to its node and is linked by exactly
# one mutation each, in the direction GitHub expects (criteria 1-2).
: > "$FAKE_GH_LOG"
rc=0; run_link resolve --repo o/r --parent '#12' --blocked-by '#7' > "$link_tmp/plan.json" || rc=$?
expect_rc 0 "$rc" "resolve #12 / #7"
require_json "$link_tmp/plan.json" 'd["parent"]["node"]' '"I_12"'
require_json "$link_tmp/plan.json" '[b["node"] for b in d["blocked_by"]]' '["I_7"]'
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/plan.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link #12 / #7"
require_count "$FAKE_GH_LOG" "addSubIssue" 1
require_count "$FAKE_GH_LOG" 'addSubIssue(input:{issueId:"I_12",subIssueId:"I_40"})' 1
require_count "$FAKE_GH_LOG" "addBlockedBy" 1
require_count "$FAKE_GH_LOG" 'addBlockedBy(input:{issueId:"I_40",blockingIssueId:"I_7"})' 1
require_text "$link_tmp/out" "linked parent #12"
require_text "$link_tmp/out" "linked blocked-by #7"

# The other two parse forms reach the same nodes.
rc=0; run_link resolve --repo o/r --parent 'o/r#12' --blocked-by https://github.com/o/r/issues/7 > "$link_tmp/forms.json" || rc=$?
expect_rc 0 "$rc" "resolve owner/repo#N and issue URL"
require_json "$link_tmp/forms.json" 'd["parent"]["node"]' '"I_12"'
require_json "$link_tmp/forms.json" '[b["node"] for b in d["blocked_by"]]' '["I_7"]'

# A Parent held by another owner stays text, and resolve never looks it up:
# GitHub's add-sub-issue contract requires the sub-issue and its parent to
# share an owner (docs.github.com/en/rest/issues/sub-issues#add-sub-issue), so
# a resolved cross-owner parent would leave the body and then fail to link
# with nothing to retry. Blockers carry no such rule and are still looked up.
: > "$FAKE_GH_LOG"
rc=0; run_link resolve --repo o/r --parent 'x/y#12' --blocked-by 'x/y#7' > "$link_tmp/xowner.json" || rc=$?
expect_rc 0 "$rc" "resolve a cross-owner parent"
require_json "$link_tmp/xowner.json" 'd["parent"]["node"]' 'null'
require_json "$link_tmp/xowner.json" '"owned by x" in d["parent"]["reason"] and "sub-issue" in d["parent"]["reason"]' 'true'
require_count "$FAKE_GH_LOG" 'issue(number:12)' 0
require_count "$FAKE_GH_LOG" 'repository(owner:"x",name:"y"){issue(number:7)' 1
# The same rule holds when the cross-owner parent arrives as an issue URL.
: > "$FAKE_GH_LOG"
rc=0; run_link resolve --repo o/r --parent https://github.com/x/y/issues/12 > "$link_tmp/xowner-url.json" || rc=$?
expect_rc 0 "$rc" "resolve a cross-owner parent given as a URL"
require_json "$link_tmp/xowner-url.json" 'd["parent"]["node"]' 'null'
require_json "$link_tmp/xowner-url.json" '"owned by x" in d["parent"]["reason"]' 'true'
require_count "$FAKE_GH_LOG" 'issue(number:12)' 0
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/xowner.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link a plan whose parent is cross-owner"
require_count "$FAKE_GH_LOG" "addSubIssue" 0
# Same owner, other repo, still resolves, and the owner comparison ignores
# case because GitHub logins do.
rc=0; run_link resolve --repo O/r --parent 'o/other#12' > "$link_tmp/sameowner.json" || rc=$?
expect_rc 0 "$rc" "resolve a same-owner other-repo parent"
require_json "$link_tmp/sameowner.json" 'd["parent"]["node"]' '"I_12"'

# Link writes need permissions that issue creation does not: addBlockedBy
# needs TRIAGE or higher on the repo the issue is filed into, and addSubIssue
# needs WRITE or higher on the parent's repo. An entry the viewer cannot link
# stays text, because the retry command cannot grant the permission, and a
# permission the script cannot read counts as missing.
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_PERMS="o/r=READ" run_link resolve --repo o/r --parent '#12' --blocked-by '#7' > "$link_tmp/perm-read.json" || rc=$?
expect_rc 0 "$rc" "resolve with READ on the home repo"
require_json "$link_tmp/perm-read.json" 'd["parent"]["node"]' 'null'
require_json "$link_tmp/perm-read.json" '"WRITE" in d["parent"]["reason"] and "READ" in d["parent"]["reason"]' 'true'
require_json "$link_tmp/perm-read.json" '[b["node"] for b in d["blocked_by"]]' '[null]'
require_json "$link_tmp/perm-read.json" '"TRIAGE" in d["blocked_by"][0]["reason"] and "READ" in d["blocked_by"][0]["reason"]' 'true'
require_count "$FAKE_GH_LOG" 'issue(number:7)' 0
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/perm-read.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link a plan resolved under READ"
require_count "$FAKE_GH_LOG" "mutation" 0
# TRIAGE on the parent's repo is enough for a dependency but not a sub-issue.
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_PERMS="o/other=TRIAGE" run_link resolve --repo o/r --parent 'o/other#12' --blocked-by '#7' > "$link_tmp/perm-triage.json" || rc=$?
expect_rc 0 "$rc" "resolve with TRIAGE on the parent repo"
require_json "$link_tmp/perm-triage.json" 'd["parent"]["node"]' 'null'
require_json "$link_tmp/perm-triage.json" '"TRIAGE" in d["parent"]["reason"]' 'true'
require_json "$link_tmp/perm-triage.json" '[b["node"] for b in d["blocked_by"]]' '["I_7"]'
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/perm-triage.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link a plan whose parent repo is TRIAGE"
require_count "$FAKE_GH_LOG" "addSubIssue" 0
require_count "$FAKE_GH_LOG" "addBlockedBy" 1
# TRIAGE at home plus WRITE on the parent repo links both.
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_PERMS="o/r=TRIAGE,o/other=WRITE" run_link resolve --repo o/r --parent 'o/other#12' --blocked-by '#7' > "$link_tmp/perm-ok.json" || rc=$?
expect_rc 0 "$rc" "resolve with TRIAGE at home and WRITE on the parent repo"
require_json "$link_tmp/perm-ok.json" 'd["parent"]["node"]' '"I_12"'
require_json "$link_tmp/perm-ok.json" '[b["node"] for b in d["blocked_by"]]' '["I_7"]'
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/perm-ok.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link a plan resolved under TRIAGE and WRITE"
require_count "$FAKE_GH_LOG" "addSubIssue" 1
require_count "$FAKE_GH_LOG" "addBlockedBy" 1
# A permission the script cannot read is a missing one.
rc=0; FAKE_GH_PERMS="o/r=null" run_link resolve --repo o/r --parent '#12' --blocked-by '#7' > "$link_tmp/perm-null.json" || rc=$?
expect_rc 0 "$rc" "resolve with an unreadable home permission"
require_json "$link_tmp/perm-null.json" 'd["parent"]["node"]' 'null'
require_json "$link_tmp/perm-null.json" '[b["node"] for b in d["blocked_by"]]' '[null]'

# A path, a discussion URL, a pull request, and a missing number all stay
# text: no node, a reason, and no mutation (criteria 3-4).
rc=0; run_link resolve --repo o/r --parent https://github.com/o/r/discussions/3 --blocked-by docs/new-spec.md --blocked-by '#99' > "$link_tmp/text.json" || rc=$?
expect_rc 0 "$rc" "resolve non-issue entries"
require_json "$link_tmp/text.json" 'd["parent"]["node"]' 'null'
require_json "$link_tmp/text.json" '[b["node"] for b in d["blocked_by"]]' '[null, null]'
require_json "$link_tmp/text.json" 'all(e["reason"] for e in [d["parent"]] + d["blocked_by"])' 'true'
rc=0; run_link resolve --repo o/r --parent '#5' > "$link_tmp/pr.json" || rc=$?
expect_rc 0 "$rc" "resolve a pull request number"
require_json "$link_tmp/pr.json" 'd["parent"]["node"]' 'null'
for plan in text pr; do
  : > "$FAKE_GH_LOG"
  rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/$plan.json" > "$link_tmp/out" || rc=$?
  expect_rc 0 "$rc" "link $plan plan"
  require_count "$FAKE_GH_LOG" "mutation" 0
done

# --dry-run names each link and sends nothing (criterion 6).
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/plan.json" --dry-run > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link --dry-run"
require_text "$link_tmp/out" "would link parent #12"
require_text "$link_tmp/out" "would link blocked-by #7"
require_count "$FAKE_GH_LOG" "addSubIssue" 0
require_count "$FAKE_GH_LOG" "addBlockedBy" 0
# Before creation there's no new issue to look up, so --dry-run without
# --issue prints a <new> placeholder and sends nothing at all, lookups included.
: > "$FAKE_GH_LOG"
rc=0; run_link link --plan "$link_tmp/plan.json" --dry-run > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link --dry-run without --issue"
require_text "$link_tmp/out" "would link parent #12"
require_text "$link_tmp/out" 'subIssueId:"<new>"'
require_count "$FAKE_GH_LOG" "mutation" 0
require_count "$FAKE_GH_LOG" "issue(number:40)" 0
# Outside a dry run the new issue is required.
rc=0; run_link link --plan "$link_tmp/plan.json" > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "link without --issue or --dry-run"

# A failed link is named with its error and a retry command, and the links
# around it still go out (criterion 7).
cat > "$link_tmp/fail.json" <<'JSON'
{"repo": "o/r",
 "parent": {"entry": "#12", "number": 12, "repo": "o/r", "node": "I_12"},
 "blocked_by": [{"entry": "#66", "number": 66, "repo": "o/r", "node": "I_FAIL"},
                {"entry": "#7", "number": 7, "repo": "o/r", "node": "I_7"}]}
JSON
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/fail.json" > "$link_tmp/out" || rc=$?
expect_rc 1 "$rc" "link with a failing blocker"
require_text "$link_tmp/out" "FAILED blocked-by #66: GraphQL: Could not resolve to a node"
require_text "$link_tmp/out" "  retry: gh api graphql -f query='mutation{addBlockedBy(input:{issueId:\"I_40\",blockingIssueId:\"I_FAIL\"}){issue{number}}}'"
require_text "$link_tmp/out" "linked parent #12"
require_text "$link_tmp/out" "linked blocked-by #7"
require_count "$FAKE_GH_LOG" 'addBlockedBy(input:{issueId:"I_40",blockingIssueId:"I_7"})' 1

# Strip after link (#175, PR #179 rounds 1-3). Every entry is rendered as
# text, the issue is created, the links go out, and only then does `strip`
# remove the entries whose link landed, in one updateIssue. A link that fails
# for any reason leaves its text where it was, so no failure route is lossy.
body_a="$link_tmp/body-a.md"
cat > "$body_a" <<'MD'
# Title

**Parent:** #12

**Blocked by:** #7

## Problem

See #7 and #12 in the old trace.
MD
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/plan.json" --out "$link_tmp/res-a.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link with --out"
require_json "$link_tmp/res-a.json" 'sorted(l["kind"] for l in d["linked"])' '["blocked-by", "parent"]'
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_a" run_link strip --issue "$new_issue" --plan "$link_tmp/plan.json" --result "$link_tmp/res-a.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "strip after every link landed"
require_count "$FAKE_GH_LOG" "updateIssue" 1
refute_text "$FAKE_GH_LOG.body" "**Parent:**"
refute_text "$FAKE_GH_LOG.body" "**Blocked by:**"
require_text "$FAKE_GH_LOG.body" "See #7 and #12 in the old trace."
require_text "$FAKE_GH_LOG.body" "# Title"
# Agent-targeted keeps an explicit None where the list emptied.
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_a" run_link strip --issue "$new_issue" --plan "$link_tmp/plan.json" --result "$link_tmp/res-a.json" --agent-targeted > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "strip, agent-targeted"
require_text "$FAKE_GH_LOG.body" "**Blocked by:** None"
refute_text "$FAKE_GH_LOG.body" "**Parent:**"
# One blocker fails: its text stays on the line, the linked entries leave.
body_b="$link_tmp/body-b.md"
cat > "$body_b" <<'MD'
**Parent:** #12

**Blocked by:** #66, #7

Body text.
MD
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/fail.json" --out "$link_tmp/res-b.json" > "$link_tmp/out" || rc=$?
expect_rc 1 "$rc" "link with a failing blocker and --out"
require_json "$link_tmp/res-b.json" '[l["entry"] for l in d["failed"]]' '["#66"]'
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_b" run_link strip --issue "$new_issue" --plan "$link_tmp/fail.json" --result "$link_tmp/res-b.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "strip after a partial link"
require_count "$FAKE_GH_LOG" "updateIssue" 1
require_text "$FAKE_GH_LOG.body" "**Blocked by:** #66"
refute_text "$FAKE_GH_LOG.body" "#7"
refute_text "$FAKE_GH_LOG.body" "**Parent:**"
require_text "$FAKE_GH_LOG.body" "Body text."
# Nothing linked: no body write at all.
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/text.json" --out "$link_tmp/res-c.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link a text-only plan with --out"
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_a" run_link strip --issue "$new_issue" --plan "$link_tmp/text.json" --result "$link_tmp/res-c.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "strip with nothing linked"
require_count "$FAKE_GH_LOG" "updateIssue" 0
require_count "$FAKE_GH_LOG" "id body" 0
# A failed strip write leaves the body as filed, and the retry re-runs strip
# itself, which re-fetches the body: a replayed snapshot would overwrite any
# edit made between the failure and the retry.
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_a" FAKE_GH_UPDATE_FAIL=1 run_link strip --issue "$new_issue" --plan "$link_tmp/plan.json" --result "$link_tmp/res-a.json" --agent-targeted > "$link_tmp/out" || rc=$?
expect_rc 1 "$rc" "strip whose write fails"
require_text "$link_tmp/out" "FAILED strip"
require_text "$link_tmp/out" "retry: python3 "
require_text "$link_tmp/out" "link-issues.py strip --issue $new_issue --plan $link_tmp/plan.json --result $link_tmp/res-a.json --agent-targeted"
refute_text "$link_tmp/out" "body=@"
# A Parent line is removed only when its text is exactly the linked entry, a
# slot line inside a code fence is never touched, and a quoted slot line is
# left alone.
body_c="$link_tmp/body-c.md"
cat > "$body_c" <<'MD'
**Parent:** #12 — the auth epic, see thread

**Blocked by:** #7

```
**Blocked by:** #7
**Parent:** #12
```

~~~
**Blocked by:** #7
~~~

> **Blocked by:** #7
MD
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_c" run_link strip --issue "$new_issue" --plan "$link_tmp/plan.json" --result "$link_tmp/res-a.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "strip around commentary, fences, and quotes"
require_count "$FAKE_GH_LOG" "updateIssue" 1
require_text "$FAKE_GH_LOG.body" "**Parent:** #12 — the auth epic, see thread"
require_count "$FAKE_GH_LOG.body" "**Blocked by:** #7" 3
require_count "$FAKE_GH_LOG.body" "**Parent:** #12" 2
require_text "$FAKE_GH_LOG.body" "> **Blocked by:** #7"
# A fence closes only on a run of the same character at least as long as the
# opener (CommonMark), so a 4-backtick fence wrapping a 3-backtick line, or a
# ~~~~ fence wrapping ~~~, keeps the slot line inside it.
body_d="$link_tmp/body-d.md"
cat > "$body_d" <<'MD'
**Blocked by:** #7

````
```
**Blocked by:** #7
````

~~~~
~~~
**Blocked by:** #7
~~~~
MD
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_d" run_link strip --issue "$new_issue" --plan "$link_tmp/plan.json" --result "$link_tmp/res-a.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "strip around nested fences"
require_count "$FAKE_GH_LOG" "updateIssue" 1
require_count "$FAKE_GH_LOG.body" "**Blocked by:** #7" 2
require_count "$FAKE_GH_LOG.body" '````' 2
require_count "$FAKE_GH_LOG.body" '~~~~' 2
# A GitHub Enterprise URL: link exits 3 before sending anything, the result
# records nothing linked, and strip writes nothing, so every entry survives
# as text. Linking is github.com-only (Known Limitations).
: > "$FAKE_GH_LOG"
rc=0; run_link link --issue https://github.example.com/o/r/issues/40 --plan "$link_tmp/plan.json" --out "$link_tmp/res-ghe.json" > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "link on an enterprise URL"
require_count "$FAKE_GH_LOG" "mutation" 0
require_json "$link_tmp/res-ghe.json" 'd["linked"]' '[]'
: > "$FAKE_GH_LOG"
rc=0; FAKE_GH_BODY="$body_a" run_link strip --issue "$new_issue" --plan "$link_tmp/plan.json" --result "$link_tmp/res-ghe.json" > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "strip after an enterprise link"
require_count "$FAKE_GH_LOG" "updateIssue" 0
# --dry-run on link names the strip it would do beside the links.
rc=0; run_link link --plan "$link_tmp/plan.json" --dry-run > "$link_tmp/out" || rc=$?
expect_rc 0 "$rc" "link --dry-run names the strip"
require_text "$link_tmp/out" "would strip parent #12"
require_text "$link_tmp/out" "would strip blocked-by #7"

# Usage errors and an unresolvable new issue exit 3, not argparse's 2.
rc=0; run_link > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "no subcommand"
# A plan entry with a node but no entry text would be dereferenced by link
# and strip; it is refused up front rather than left to a traceback.
printf '{"repo":"o/r","blocked_by":[{"node":"I_7"}]}' > "$link_tmp/bad.json"
rc=0; run_link link --plan "$link_tmp/bad.json" --dry-run > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "plan entry with a node and no entry"
rc=0; run_link resolve --bogus > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "unknown flag"
rc=0; run_link link --issue "$new_issue" > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "link without --plan"
rc=0; run_link link --issue "$new_issue" --plan "$link_tmp/missing.json" > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "unreadable plan"
rc=0; run_link link --issue https://github.com/o/r/issues/41 --plan "$link_tmp/plan.json" > /dev/null 2>&1 || rc=$?
expect_rc 3 "$rc" "new issue with no node"

# Every gate in the self-check needs a row in the evidence map, or the tiering
# claim in the README is false.
require_text file-issue/references/evidence-map.md "Stranger test"
require_text file-issue/references/evidence-map.md "Runnable repro"
require_text file-issue/references/evidence-map.md "Agent-readiness"
require_text file-issue/references/evidence-map.md "Falsifier for a derived rule"
# The verify-alone row is practitioner-backed, not measured, and must say so.
require_text file-issue/references/evidence-map.md "Verify-alone, agent-targeted issues"
# The existing-artifact row is convention, not measured, and must say so.
require_text file-issue/references/evidence-map.md "Requiring the artifact on the Blocked by line makes the prerequisite recoverable by the one audience that cannot ask. Dependency links are universal tracker practice; nothing measures them. | [C] |"
require_text file-issue/references/evidence-map.md "practitioner consensus and \`to-tickets\`' central rule; no study measures its effect on agent outcomes. | [P] |"
# The derived-rule row is convention from one run, not measured, and must say so.
require_text file-issue/references/evidence-map.md "Found by one real run (#110); nothing measures whether naming the falsifier changes outcomes. | [C] |"
require_text file-issue/references/evidence-map.md "Things Deliberately Not in the Rubric"

# The uncited Gherkin statistic is marketing. It may appear only in the evidence
# map's do-not-cite row, never in anything the skill reads or emits.
for f in file-issue/SKILL.md file-issue/README.md file-issue/assets/*.md file-issue/references/issue-forms.md; do
  refute_text "$f" "56%"
done
require_text file-issue/references/evidence-map.md "Do not cite it."

require_text _maintenance/file-issue/RATIONALE.md "## Decision Ledger"
require_text _maintenance/file-issue/RATIONALE.md "## Known Limitations"
# The root README carries this skill's own install flag, in the map
# table's third column. The command form around it is pinned once, in
# repo-docs-smoke.sh, so this does not re-pin it twelve times.
require_text README.md "--skill file-issue"
