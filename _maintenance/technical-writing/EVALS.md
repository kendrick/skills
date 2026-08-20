# technical-writing Evals

This repo has no eval harness and no CI, so these scenarios run manually and deliberately—someone sits down, runs the prompt, and reads the transcript. Method follows `skill-creator`: run each scenario prompt twice, once with the skill loaded and once without, and grade the delta.

## Fixtures

- **This repo with a real staged change** — scenario 1's fixture is the technical-writing skill's own files, staged as an ordinary commit-in-progress. No synthetic diff; the commit under test is the one that ships this skill.
- **`_maintenance/databricks-api/tools/refresh.sh`** — the mixed-comment fixture. Eight WHAT-restating banner comments at lines 19, 26, 76, 124, 178, 213, 368, and 421 (`# --- bash version guard ---`, `# --- helpers ---`, and so on—section dividers that repeat what the following code already announces), plus a strong WHY block at lines 78–84 explaining a two-hops/shared-directory-name footgun: `MAINT_DIR` and `REPO_ROOT` share a folder name one level up, so a single `..` would resolve back into the maintenance directory instead of failing, and the script would silently scan itself for domains.
- **`adversarial-review/scripts/check-territories.py`** — near-pure WHY comments. The precision control: a passing run touches nothing in this file.

## Scenarios

### 1. Commit message — full flow fires

**Prompt:** "commit this," with a real change staged.
**Repo:** this one.

| Expect | Pass condition |
| --- | --- |
| Profile read | `references/commit-messages.md` is read before drafting, not recalled from memory |
| Subject | Matches this repo's Conventional Commits log form |
| Body | WHY-leading prose, no hard wraps |
| Trailer | No `Co-Authored-By` |
| Audit | The prose audit runs; where humanizer is installed, formally invoked via the Skill tool |
| House rules | Read fresh and applied over the audit, `~/.claude/PROSE.md` on the author's machines |

Fails if the message is drafted from memory of the profile, or the audit is skipped or performed "informally."

Grade this delta carefully: the without-skill arm still runs under CLAUDE.md's ambient commit rules and humanizer mandate, so what it measures is marginal value over existing config, not over a naive baseline.

**Run of 2026-08-20.** Both arms produced a subject matching the repo's log form and neither added a trailer, which is the ambient rules earning their keep. The body separated them: the without arm hard-wrapped at 74 columns and then said in a side note that the message shouldn't be wrapped, while the with arm wrote it unwrapped. The with arm's audit also traded a pair of em dashes for parentheses under PROSE.md's §14 amendment. The pair is harvested into `references/commit-messages.md`'s `## Example`.

### 2. Comment pass — flag WHAT, keep WHY, invent nothing

**Prompt:** "review the comments in `_maintenance/databricks-api/tools/refresh.sh`"—run read-only ("don't edit yet"), so the proving run stays non-destructive.
**Repo:** this one.

| Expect | Pass condition |
| --- | --- |
| Recall | The eight WHAT-restating banner comments get flagged |
| Precision | The WHY block at lines 78–84 survives untouched |
| Restraint | No new comments invented where the code already speaks |
| Control | Same prompt on `adversarial-review/scripts/check-territories.py`—a passing run changes nothing |

Fails if the lines 78–84 WHY block is rewritten or deleted, or comments are added.

This scenario's output feeds `references/comments.md`'s `## Example` section—the flagged rewrite and the preserved WHY block are harvested from whatever this run actually produces, not invented separately.

**Run of 2026-08-20.** Passed on all four rows. All eight banners were flagged for deletion, the lines 78–84 block survived untouched, and the control file came back with nothing to change.

Two things the run surfaced that the rows don't cover. The header block at lines 6–16 is stale: it documents three modes and the script has four, missing `--refetch-broken`, which has its own function and its own `usage()` entry. That is a live defect in `refresh.sh` rather than a finding about this skill, and it is worth fixing on its own.

The run also proposed one new comment, on the bare `JINA_SLEEP=3` at line 90, which brushes against the restraint row. Judged a pass: restraint forbids commenting where the code already speaks, and an unexplained constant paced against a remote API says nothing about why it exists. The run flagged its own "rate limit" reasoning as inferred rather than confirmed, which is the behavior the profile wants when the why is not in the file. Worth watching on later runs, since the same latitude is how invented comments would creep in.

**The delta, against the without arm.** Recall is where the two separated, and completely. The without arm kept all eight banners, reasoning that they are "purely organizational, used consistently throughout, cheap to keep in sync"; the with arm deleted all eight as naming the code beneath them and claiming nothing else. That single disagreement is most of what this profile buys, and the without arm's reasoning is a coherent position rather than a blunder, which is worth remembering before treating a future keep-the-banners run as an obvious failure.

Precision did not separate them: both preserved the lines 78–84 block and both left the control file alone, so the profile's contribution there is insurance rather than improvement. Both also caught the stale header and both proposed the `JINA_SLEEP` comment, so neither is skill-attributable.

The without arm won one exchange outright. It caught that line 148's comment misattributes its own effect, claiming the awk beneath it strips a trailing blank line when that awk only filters the pixel line and the block at 150–152 does the blank-line work. The with arm kept 148 and missed the error. Reading a comment against what the code actually does is a check this profile states but does not yet make anyone perform, and that gap is the most useful thing this scenario has produced so far.

### 3. Trigger scoping — stays silent

Two fresh sessions.
**Prompt A:** a plain coding question ("why does this zsh glob not match dotfiles?").
**Prompt B:** "draft an email to my landlord about the deposit."

Two boundary prompts run alongside them, because the nearest rival skills are the ones that produce a bad fire rather than a bad silence.
**Prompt C:** "commit this." **Prompt D:** "write a README for this package." **Prompt E:** "review this PR description before I post it."

| Expect | Pass condition |
| --- | --- |
| Prompt A | The skill does not fire |
| Prompt B | The skill does not fire, and the VOICE.md process engages instead |
| Prompt C | The skill fires |
| Prompt D | The skill does not fire; readme-coauthorship owns authoring a README |
| Prompt E | The skill fires |

Fails if the skill loads on A or B, or stays silent on C or E. Description tuning on a miss is in scope for this change—record the miss and the tuned wording here.

**Run of 2026-08-20, judged from the descriptions alone.** A, B, C, and E all landed as intended. D was the miss. The first sentence listed "READMEs" bare, in the same breath as the artifact types the skill fully owns, so a trigger match on the word "README" hit before the readme-coauthorship carve-out at the end of the description could walk it back. A shallow scan fires; only a full read stays silent.

The fix, applied: drop the bare "READMEs" from the opening list and qualify it in place as "the prose inside a README that someone has already structured", then restate the hand-off as scope rather than as a trailing correction ("Authoring a new README end to end belongs to readme-coauthorship"). Intended fires on C and E are untouched, since both match on "commit message" and "describing a PR" rather than on the README clause.

**Re-run of 2026-08-20, after the portability rewrite.** The description was rewritten again to strip the hardcoded `~/.claude/VOICE.md` and `~/.claude/PROSE.md` paths, which put prompt B's carve-out at risk: it had been holding partly on a concrete routing target that a stranger's machine will not have. All five prompts still landed as intended.

The carve-out survives on two guards that never depended on the filename. The exclusion is unconditional on its face, "never for anything addressed to a person: emails, DMs, and other messages", with no grammar making it contingent on the reader owning that voice process. And the affirmative trigger list never reaches personal correspondence, so an email fails to match the positive scope before the exclusion is even needed.

One hazard noted and deliberately left alone: naming the excluded nouns means the literal word "emails" sits in the description, and a shallow keyword match could read it as a positive signal. That predates both rewrites and is inherent to describing an exclusion by naming what it excludes. Rewording it to avoid the noun would trade a clear exclusion for a vague one, which is the worse failure.

### 4. Portability — no auditor, no house rules

The skill ships publicly, so most installs will have neither `humanizer` nor any house prose file. Step 2 names both as the binding it was built against rather than requiring them, and this scenario is what keeps that honest.

**Prompt:** "write a commit message for this change."
**Repo:** any repo on a machine with no `humanizer` skill installed and no house prose rules defined.

| Expect | Pass condition |
| --- | --- |
| Completion | Step 2 finishes on the self-check alone; the run does not stall waiting for a tool that isn't there |
| Honesty | The absent auditor is named as absent, not silently skipped and not reported as having run |
| No dead paths | Nothing instructs the user to read a file under someone else's home directory |
| Still useful | The layers, the dispatch, and the profile all do their work without the audit |

Fails if the run treats the missing auditor as a blocker, invents an audit it did not perform, or tells the user to open `~/.claude/PROSE.md` on a machine that has no such file.

## Grading

Record passed/failed with verbatim evidence per row. On scenarios 1 and 2, watch the with/without delta specifically: a capable model without the skill still writes a plausible commit message but tends to hard-wrap it or add a Co-Authored-By trailer, and an unguided comment pass tends to "improve" healthy WHY comments—rewording lines 78–84 into something shorter and losing the two-hops footgun in the process, which is the exact failure the skill exists to prevent.
