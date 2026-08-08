# Constitution: inbox-to-memory — link-check v1 notes (#32)

The job is one behavioral change and the prose that has to stop contradicting it. `lint-scope.sh` drops v1 files in pass one, before `check_links` ever sees them, so a wiki link that resolves nowhere is reported in a v2 note and passes silently in a v1 one. Eight passages across four files describe the old behavior, and one of them disagrees with the code today, before anything in this job is touched.

The count moved three times while this document was being audited: from the issue's four, to five, to six, to eight. The fifth came from grepping the claim's phrasing, the sixth from reading for the lint's vocabulary instead, and the last two from dropping the predicate all three of those searches shared. That is the standing lesson of this job. An enumeration inherited from a spec is a starting point rather than a boundary, and re-deriving one is not enough if you never question the category it enumerates over.

Everything below is measured against the shipped tree, not against a worker's account of it.

## Baseline

Recorded from the tree at `59c363f` before any work started, by running each check listed here. A clause that cites a number cites one of these.

- `yq` is on PATH at `/opt/homebrew/bin/yq`; the lint aborts with exit 2 without it.
- All three suites exit 0: `tests/inbox-to-memory-smoke.sh`, `tests/file-issue-smoke.sh`, `tests/handoff-smoke.sh`.
- Ten opted-in scopes live under `tests/fixtures/inbox-to-memory/`. Only `broken` reports failures (19). Every other scope reports `failures: 0`.
- Exactly three wiki links exist in v1 files anywhere in the fixtures, all in `evals/contradiction-amend`, and **all three resolve by filename**. No fixture exercises the ten-character id fallback on a v1 file, which is why C-2 builds its own scope rather than trusting the fixtures to cover it.
- **In the agent's own shell, `grep` is not `grep`,** and its output order is not stable. Claude Code installs a `grep` shell function in its zsh snapshot that execs `ugrep`; `grep -l '^schema: 2' notes/*.md | head -1` returned four different notes across thirty runs there — `atlas-freeze-check` ×13, `atlas-dry-run-prep` ×8, `atlas-runbook-review` ×6, `atlas-freeze-exceptions` ×3. Inside `bash script.sh` that function does not exist, `command -v grep` is `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD), and the same selector returned one file 10 times out of 10. So **`lint-scope.sh` and the smoke suite are not exposed to this at all**, and no script should be rewritten to work around it. It reaches exactly one place: a checker runs the spec's reproduction as agent-shell commands, where the wrapper is live, so the v2 note the reproduction selects varies between runs. C-1 therefore asserts on the link target and never on a filename. C-2, C-3, C-5, and C-6 avoid the wrapper outright, by using `ls` or no grep at all. C-4 does pipe lint output through `grep -E`, and is safe by neutralization rather than avoidance: the `| sort` immediately after makes order irrelevant before `diff` ever sees the stream.

## Clauses

### C-1: a broken link in a v1 note gets reported

- **text**: When a wiki link in a v1 note's body resolves to no file in scope — neither by filename nor by its trailing ten-character id — `lint-scope.sh` prints a `link-broken` line naming that note, counts it in `failures:`, and exits nonzero. The file's schema generation has no bearing on the outcome.
- **check**: run the reproduction from `.agent-guild/state/spec.md` under "Steps to Reproduce", with its two closing lint invocations amended to surface their exit status, since a shell block otherwise reports only the last command's code:

  ```bash
  bash inbox-to-memory/scripts/lint-scope.sh "$S/v1"; echo "v1 exit=$?"
  bash inbox-to-memory/scripts/lint-scope.sh "$S/v2"; echo "v2 exit=$?"
  ```

  Each scope must print a line containing ``link-broken: `this-target-does-not-exist-AAAAAAAAAA` ``, and both must report `exit=1`. Assert on that target string and never on the reporting note's filename — the reproduction selects its v2 note with `grep -l … | head -1`, which is not order-stable here (see Baseline), so the filename legitimately varies between runs.
- **severity**: blocker
- **failing example**: the tree as it stands. The v1 scope prints `failures: 0` at `v1 exit=0` while the v2 scope prints its `link-broken` line at `v2 exit=1`, on the same injected link.

### C-2: a v1 link that resolves stays silent, including by id alone

- **text**: A v1 note whose links all resolve produces no `link-broken`, whether each target matches a filename or matches only through the trailing ten-character id fallback at `lint-scope.sh:376-377`.
- **check**:

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/old-only/. "$S/"
  N="$(ls "$S"/notes/*.md | head -1)"
  python3 - "$N" <<'PY'
  import sys
  p = sys.argv[1]; t = open(p).read(); i = t.find("## Raw Content")
  open(p, "w").write(t[:i] + "\nBy name [[one-vendor-per-region-G2k65qG3Nc]], by id only [[was-renamed-away-G2k65qG3Nc]].\n" + t[i:])
  PY
  bash inbox-to-memory/scripts/lint-scope.sh "$S"; echo "exit=$?"; rm -rf "$S"
  ```

  Must print `failures: 0` and `exit=0`. `_memory/decisions/one-vendor-per-region-G2k65qG3Nc.md` is the file both links reach; the second target names no file, so only the id path can resolve it.
- **severity**: blocker
- **failing example**: an implementation that resolves v1 targets by filename only. `[[was-renamed-away-G2k65qG3Nc]]` is then reported broken even though `one-vendor-per-region-G2k65qG3Nc.md` sits in the scope.

### C-3: `check_links` is the only check a v1 file gets

- **text**: For a file carrying no `schema` key, `check_links` is the only check that runs against it. `check_frontmatter`, `check_tokens`, `check_open_questions`, `check_tensions`, `check_contradictions`, `check_decisions`, `check_anchors`, `check_counts`, and the open-question-resolution loop at `lint-scope.sh:458-461` all continue to skip it, and the file contributes nothing to the scope-wide open-slug set that feeds that loop and the `RECURRING` report.
- **check**:

  ```bash
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/old-only/. "$S/"
  N="$(ls "$S"/notes/*.md | head -1)"
  python3 - "$N" <<'PY'
  import sys
  p = sys.argv[1]; t = open(p).read(); i = t.find("## Raw Content")
  open(p, "w").write(t[:i] + "\n[invented token: x] not in the grammar table.\n[open question: never-opened-anywhere] a question.\n[open question resolved: opened-by-nobody] and its answer.\n[tension: bogus-state] not resolved, deferred, or unacknowledged.\n[contradicts accepted: nothing] naming no record and no claim.\n[decision: sideways] neither one-way nor two-way, and no discarded alternatives.\n(raw: line 12)\n" + t[i:])
  PY
  bash inbox-to-memory/scripts/lint-scope.sh "$S"; echo "exit=$?"; rm -rf "$S"
  ```

  Must print `failures: 0` and `exit=0`. A v1 note predates the token grammar, the anchor rule, and the four derived count keys, and `references/machine-contracts.md:7` scopes all of them to v2 on its face. The injected block is built so every one of the six body-grammar checks has something to catch: routing this note into pass two makes it fail `token-grammar`, `open-question-fields`, `tension-fields`, `contradiction-fields`, `decision-fields`, and `anchor-form` simultaneously. That is deliberate. The six live inside one atomic `if ! has_v1_body` block at `:444-451`, so a check that relied on `check_tokens` alone would cover the other five only by inference.

  The open-slug half of this clause needs its own scope, because a v1 file that quietly joins the scope-wide slug set passes the check above while suppressing a real failure elsewhere:

  ```bash
  inject() { python3 - "$1" "$2" <<'PY'
  import sys
  p, line = sys.argv[1], sys.argv[2]; t = open(p).read(); i = t.find("## Raw Content")
  open(p, "w").write(t[:i] + "\n" + line + "\n" + t[i:])
  PY
  }
  S="$(mktemp -d)"; cp -R tests/fixtures/inbox-to-memory/mixed/. "$S/"
  V1=""; V2=""
  for f in $(ls "$S"/notes/*.md); do
    if awk 'NR==1{if($0=="---"){i=1;next}else exit} i&&$0=="---"{exit} i&&/^schema:/{f=1;exit} END{exit(f?0:1)}' "$f"; then
      [ -z "$V2" ] && V2="$f"
    else
      [ -z "$V1" ] && V1="$f"
    fi
  done
  inject "$V1" "[open question: v1-only-slug] opened in a v1 note."
  inject "$V2" "[open question resolved: v1-only-slug] and resolved in a v2 one."
  bash inbox-to-memory/scripts/lint-scope.sh "$S"; rm -rf "$S"
  ```

  Must print ``open-question-resolution: `v1-only-slug` is resolved here but never opened anywhere in scope``. Assert on that line, not on the `failures:` count — the injected resolution token also moves the v2 note's `resolved_questions` key, so stock reports two failures and only one of them is the one under test.
- **severity**: blocker
- **failing example**: two implementations fail this, and neither is caught by anything else in the constitution. Routing v1 files through pass two without a guard turns `old-only` from `failures: 0` into `failures: 14` — `frontmatter-single-line` ×4, `derived-counts` ×8, `anchor-form` ×2 — on files that were legal a moment earlier. Harvesting v1 bodies into the open-slug set while otherwise leaving them alone is quieter and worse: the scope above drops to `failures: 1`, the `open-question-resolution` line disappears, and a slug resolved in a v2 note with no v2 note ever opening it now reads as settled.

### C-4: nothing else about the lint's output moves

- **text**: Across every opted-in scope under `tests/fixtures/inbox-to-memory/`, the `v1 files:`, `v2 files:`, `total files:`, and `failures:` lines and the set of `RECURRING` lines are identical to what the same scopes produce at `HEAD`.
- **check**:

  ```bash
  BASE="$(mktemp -d)"; git worktree add -q --detach "$BASE" HEAD
  gen() { for d in $(find "$1/tests/fixtures/inbox-to-memory" -type d -name _inbox | sed 's|/_inbox$||' | sort); do
    echo "--- ${d#$1/}"
    bash "$1/inbox-to-memory/scripts/lint-scope.sh" "$d" 2>&1 | grep -E '^(RECURRING|v1 files|v2 files|total files|failures)' | sort
  done; }
  diff <(gen "$BASE") <(gen "$PWD"); echo "diff=$?"
  git worktree remove --force "$BASE"
  ```

  Must print `diff=0` and no diff body. `HEAD` is the pre-fix tree because nothing in this job commits, so the comparison re-derives its own baseline instead of trusting a number typed into this document. It holds at `diff=0` rather than showing new failures only because no v1 fixture link is broken — see the Baseline above.
- **severity**: blocker
- **failing example**: counting v1 files as v2 to get them into pass two. `old-only` then reads `v1 files: 0` and `v2 files: 4`, and the diff shows it even if every check somehow still passed.

### C-5: the suites stay green

- **text**: `bash tests/inbox-to-memory-smoke.sh`, `bash tests/file-issue-smoke.sh`, and `bash tests/handoff-smoke.sh` each exit 0.
- **check**: `for s in tests/inbox-to-memory-smoke.sh tests/file-issue-smoke.sh tests/handoff-smoke.sh; do bash "$s" >/dev/null || echo "FAIL $s"; done` — no output.
- **severity**: blocker
- **failing example**: a new smoke case that injects its link into `tests/fixtures/inbox-to-memory/old-only` in place rather than into a scratch copy. The fixture-hash guard at `tests/inbox-to-memory-smoke.sh:1229` then aborts the run.

### C-6: the diff touches five files and no others

- **text**: The working tree's changes are confined to `inbox-to-memory/scripts/lint-scope.sh`, `inbox-to-memory/references/machine-contracts.md`, `inbox-to-memory/references/migration.md`, `inbox-to-memory/SKILL.md`, and `tests/inbox-to-memory-smoke.sh`.
- **check**: `python3 .agent-guild/scripts/check-diff-scope.py inbox-to-memory/scripts/lint-scope.sh inbox-to-memory/references/machine-contracts.md inbox-to-memory/references/migration.md inbox-to-memory/SKILL.md tests/inbox-to-memory-smoke.sh` (exit 0). Live guild state is gitignored at `.gitignore:7-8` and never appears in the diff; `check-diff-scope.py` also permits `.agent-guild/state/` unconditionally, so that path is excluded twice over.
- **severity**: blocker
- **failing example**: a new fixture directory added under `tests/fixtures/inbox-to-memory/` to hold the v1 link cases. C-7 wants those built at runtime in scratch, and a checked-in fixture would also move C-4's baseline.

### C-7: the new smoke coverage actually pins the behavior

- **text**: `tests/inbox-to-memory-smoke.sh` gains assertions for four cases: a broken link in a v1 note is reported as `link-broken`; a v1 link resolving by filename is not; a v1 link resolving only by the ten-character id is not; and a v1 note carrying an unregistered token, an unopened resolution slug, a malformed tension, a malformed contradiction, a malformed decision, and a bare `(raw:` anchor still passes — the same six-way injection C-3 uses, so that all six body-grammar checks have something to catch rather than one standing in for the rest. Each case's scope is built with `mktemp -d` and the file's existing helpers, and each new scratch path appears in an `EXIT` trap that also carries every path from the trap before it. Two scopes satisfy this clause: case one must produce a failure, and cases two through four must not, so those three can share a single passing scope.
- **check**: checker-judgment: read the added assertions and name, for each of the four cases, the line that asserts it and the specific string it requires or refutes; then walk **every** `EXIT` trap the job adds, in order, confirming each carries every path from the trap immediately preceding it, and confirm the last one additionally carries every scratch path the job itself creates. Both halves are needed: checking only the final trap would let an added trap drop a path that a later added trap restores, which leaves the file complete at the end and still leaking on an early exit in between — the same shape as #30. Read the existing trap at `:1203` to establish the baseline the job's first added trap must carry forward; judge only the traps the job itself adds. The file's existing trap chain has two pre-existing gaps — `$overrun_scope` from `:195` and `$tpl_scope` from `:345` never reach the final trap at `:1203` — and repairing those is out of scope, so a check demanding the final trap list all 18 of the file's scratch paths would be unsatisfiable without work the non-goals forbid.
- **severity**: major
- **failing example**: one added case asserting only that the suite still exits 0, with nothing naming `link-broken` on a v1 note — which passes today, before the fix exists. Or a new scope whose trap lists only itself, dropping the accumulated paths the way `:293` does.

### C-8: every prose claim about v1 linting is true of the shipped code

- **text**: Eight locations describe what the lint does, and each must describe the code as shipped. Six state which checks a v1 file receives: `lint-scope.sh:441-443` (whose "and counts" half is wrong whatever else changes, since a v1 note carries none of the four derived count keys for a counts check to compare), `lint-scope.sh:10-12` ("Nothing here ever flags a v1 file"), `references/machine-contracts.md:7` ("the lint never flags them"), `SKILL.md:428` (the same claim again), `references/migration.md:11` ("V1 files are legal forever and the lint never flags them, so nothing forces this"), and `references/machine-contracts.md:13-21` — the generation table together with the sentence beneath it, "Links and derived counts are checked in all three of the rows the lint touches."

  The sixth is the hardest and the most important. It is the doc twin of `:441-443`, the same sentence in a different register, and it is **already false today**: pre-fix, links are exactly what the lint does not check on a v1 file, so that sentence states the contract the code violates. Its "derived counts" half is false for row one and always was, which is verbatim the "and counts" defect this clause already requires be fixed at `:441-443` — repairing one and leaving the other keeps the error standing in the document the comment points at. The table is part of the location, not context for it: its columns are Frontmatter contract and Body grammar, row one reads `not checked | not checked`, and there is no Links column, so after the fix the document's most authoritative artifact about generations still answers "what does the lint do to a v1 file" with "nothing." Note also that `:7` and `:21` contradict each other in that file right now, which is why repairing `:7` alone would ship a document internally inconsistent about counts.

  Two more describe what the **script** does rather than what a v1 file receives, and T-001 falsified both: `lint-scope.sh:2-3` ("Walk one opted-in scope and check every v2 note and record") and `lint-scope.sh:414-415` ("Pass one classifies and caches each v2 body"). The lint now checks v1 files too, and pass one now caches v1 bodies as well.

  The fourth and fifth locations were both missed by earlier audit rounds because the enumeration was inherited from the issue and never re-derived. The fifth was found by grepping the claim's phrasing; the sixth could not have been, since it makes the same claim inverted, and it was found only by reading every sentence containing "lint" across the skill. The seventh and eighth were missed by all of that, because every sweep searched for passages describing *what a v1 file receives*, a predicate lifted from this clause's own framing. They were found by a checker reading past its clause list, and confirmed by re-sweeping every comment in the file that describes *what the script does*. Each of the first six must still say which checks a v1 file receives; the last two must describe the script's actual behavior. Deleting the claim is not repairing it: a file that stops stating its own v1 contract is harder to check against next time, not easier.
- **check**: checker-judgment: for each of the eight locations, quote the shipped sentence and name the line of `lint-scope.sh` that decides it. A location fails if the named line makes the sentence **false**, or if no line can be tied to the sentence at all. Tie-ability alone is not the bar — a confidently-cited line under a sentence that misdescribes it is the exact defect this clause exists to catch.

  **Location six needs a second limb, because the first one cannot reach it.** That location is a table plus a sentence, and a sentence-shaped rubric passes it by quoting `:21`, tying it to the v1 routing line, finding it true, and never looking at the table — which is the one artifact the clause text calls load-bearing. So additionally apply the reader test directly: read the generation table as shipped, with nothing else in view, and state what the lint checks on a file carrying no `schema` key. If that answer is "nothing," or cannot be given from the table alone, location six fails however well the sentence beneath it reads. This tests the outcome and not the form — a Links column, a footnote, and a reworked caption all pass it if a reader can learn the answer, and none passes if they cannot.
- **severity**: blocker
- **failing example**: `:441-443` reworded correctly while `:10-12` still opens the file with "Nothing here ever flags a v1 file" — the same disagreement between code and its stated contract that this issue exists to close, moved twenty lines up.

### C-9: nothing widens beyond links

- **text**: The only behavioral change is that files with no `schema` key now reach `check_links`. No check is added, no existing check changes what it accepts or rejects on a v2 file, and no check **other than `check_links`** newly applies to a v1 file.
- **check**: checker-judgment: read `git diff -- inbox-to-memory/scripts/lint-scope.sh` and account for every changed line as either the v1 routing change, the comment rewrite C-8 requires, or a mechanical consequence of the two.
- **severity**: blocker
- **failing example**: a `derived-counts` check taught to skip absent keys so it can run on v1 too. The issue rules that out by name, and there are no count keys on a v1 note to compare against.

### C-10: the reworded prose reads like the file it lives in

- **text**: Each rewritten comment and doc sentence carries the reason alongside the rule, the way the surrounding prose does. The originals explain *why* links stay on and *why* body grammar does not; the replacements explain why the shipped split is the right one. No rewritten passage introduces a bolded inline header with a colon, and any em dash it uses is chained directly to the text on both sides rather than wrapped in spaces.
- **check**: checker-judgment: read each rewritten passage against the three or four paragraphs around it and name any sentence that states a rule with no reason attached, that reads in a register the surrounding file does not use, or that breaks either of the two typographic rules above. The checker cannot invoke the `humanizer` skill — it has no Skill tool — so this clause judges the shipped prose, and running that skill is the executing worker's obligation, stated in its task.
- **severity**: major
- **failing example**: replacing `:441-443` with "Skip the body grammar checks for v1 files. Links run on everything." Accurate, and it drops the reasoning the original comment existed to carry, which is what let this defect be recognized as a defect in the first place.

## Protected content

None. No tagline, quotation, or legal copy ships in this job, so there is no passages manifest and no clause points at `check-protected.py`.

## Non-goals

- Token grammar on v1 files. The exclusion is deliberate and documented at `references/machine-contracts.md:65`.
- A counts check for v1 files. A v1 note carries none of the four derived count keys, so the repair there is to the comment's wording, not to behavior.
- The body-grammar checks behind `has_v1_body`. They are correct as they stand. The spec calls them "the four body-grammar checks" at its Out of Scope heading; the gate at `:444-451` actually wraps six — `check_tokens`, `check_open_questions`, `check_tensions`, `check_contradictions`, `check_decisions`, and `check_anchors`. All six are out of scope. The count in the issue is wrong and is not worth propagating.
- Any general v1 linting pass. C-9 is the clause that holds this line.
- Issues #30 (the broken `EXIT` trap chain at `tests/inbox-to-memory-smoke.sh:293`) and #31. C-7 requires new traps to follow the file's accumulator convention; it does not ask anyone to repair the existing break.
- Real link breakage this change surfaces in a live vault. The first run against real notes is a report on accumulated drift, not damage the fix caused.
- Committing, pushing, or closing the issue. The user pushes by hand.
