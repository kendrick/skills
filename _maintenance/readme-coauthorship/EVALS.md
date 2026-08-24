# readme-coauthorship Evals

Scenarios for the technical-writing polish step, written when the step landed. The older steps have no scenarios yet; add them when a change touches them, not before.

Per scenario, record `passed` plus verbatim `evidence` for each row. The rows are deliberately binary—anything that needs a judgment call is a badly specified expectation, not a hard grading problem.

*Runner note, all scenarios: invoking a skill through the Skill tool loads the published copy under `~/.agents/skills/`, never this working tree. Either publish first or tell the runner to read the repo's `readme-coauthorship/SKILL.md` and follow that, and say which one you did. A run that skips this choice measures the previous release while appearing to test the change.*

### 1. Polish — technical-writing installed

**Prompt:** "autopilot, write a readme for this repo"
**Repo:** any small fixture repo with a manifest and no README, `technical-writing` installed

| Expect | Pass condition |
| --- | --- |
| Dispatch | `technical-writing` invoked via the Skill tool, visible in the transcript—not merely narrated as done |
| Profile | Its dispatch table routes to `references/readme.md`, read fresh |
| Ordering | Draft written (Step 4), then polish (Step 5), then the 13-item validation (Step 6) runs on the post-polish text |
| No reach-past | readme-coauthorship invokes no prose auditor directly; if one fires, it fires from inside `technical-writing` |
| Structure preserved | Funnel order, section set, and every badge, command, and path byte-identical before and after the pass |
| Pre-pass copy | The draft as it left Step 4 was kept, so the row above is checkable rather than asserted |

Fails if the pass reorders sections, drops or adds a harvested fact, runs after validation, or reaches past technical-writing to an auditor.

**Run of 2026-08-23, first full pipeline run, enhance posture against this repo's root README.** Every row passed except Dispatch, which failed by this scenario's own standard: the session had formally invoked `technical-writing` hours earlier for a different artifact, and the run dispatched off that already-loaded router instead of making a fresh Skill call at polish time. The audit itself was real—the README profile produced two committed fixes (a reader-address correction in the intro, an overlong sentence split in a blurb)—and ordering, structure preservation, and no-reach-past all held. The finding: a warm session rationalizes skipping the re-dispatch precisely because the router is in context, while a cold session can't take that shortcut, so the gap only opens where a transcript looks most compliant. Step 5 now pins the dispatch to polish time, and the smoke test pins the sentence.

**Run of 2026-08-23, profile-side harvest, against `readme-coauthorship/README.md` in this repo.** Ran as an audit of an existing README rather than a fresh draft, to produce the README profile's `## Example` section. The mode mapping fired twice: a question-form lead inside the Install section ("Prefer to manage it by hand?") rewrote to condition-first imperative, and the install command's deviation from the sibling convention was flagged under the profile's Hard Rules rather than silently rewritten, then fixed as its own change once the repo confirmed the convention. The warm Why This Exists section survived untouched. No structural change, no badge or claim added or dropped.

### 2. Polish — technical-writing absent

**Prompt:** "autopilot, write a readme for this repo"
**Repo:** same fixture, no `technical-writing` skill installed

| Expect | Pass condition |
| --- | --- |
| Completion | Run reaches validation and the wrap-up—no error, no stall |
| Absence framing | The missing skill is named as absent, not narrated as an audit that ran |
| Draft | Identical to what Step 4 wrote |
| Voice gate | Validation items 12–13 still run and still gate the voice |

Fails if the missing skill blocks the run, or if the transcript claims a polish pass happened.

*Runner note: technical-writing is installed on the author's machine, so producing the "absent" environment needs a scratch skills directory or the installed skill temporarily renamed.*

### 3. Enhance posture, both installed

**Prompt:** "improve the readme" against a fixture README with a distinctive author voice—emoji headers, first person, dry humor—plus one stale command
**Repo:** fixture with that README and a manifest contradicting the stale command, `technical-writing` installed

| Expect | Pass condition |
| --- | --- |
| Live passages | Survive byte-identical through Step 4 and the polish—the pass touches only what Step 4 rewrote |
| Voice | The profile's existing-voice rule holds: rewritten passages match the author's register, not the default warmth |
| Stale command | Fixed via the Step 3 audit trail, with the sentence around it kept |
| Clarity | At least one genuine ambiguity (a dangling "this", a misplaced "only") may be fixed inside a rewritten passage without a register change |

Fails if the polish rewrites a passage Step 4 preserved, or if the output reads flattened—the author's voice replaced by generic warmth is a failure even when every fact survives.
