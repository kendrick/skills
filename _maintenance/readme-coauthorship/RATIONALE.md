# readme-coauthorship Skill Rationale

## Scope of This Ledger

The skill predates this repo's rationale convention, so the ledger starts where the convention caught up with it: the technical-writing polish step. Decisions from the original build live in [`_docs/readme-coauthorship-research.md`](../../_docs/readme-coauthorship-research.md) and are not restated here. Rows marked `local` are calls made for this repo; rows marked `eval` trace to a failure or finding from a real run.

## Decision Ledger

| Decision | Source | Reason |
| --- | --- | --- |
| Polish is a dedicated step between Generate and Validate, not a Validate item | local | Validation has to check the post-polish text, or the 13-item pass certifies a draft that a later rewrite then un-certifies. A dedicated step also keeps the soft dependency's or-branch Done-when legible, which a checklist item can't carry. Same placement logic as `file-issue`'s Step 7. |
| Soft dependency on `technical-writing`, degradation named in the step | local | This skill ships publicly and the sibling may not be installed. The step says what absence means—the draft stands, no error, no stall—so a runner without the sibling behaves exactly like the pre-polish release. `technical-writing` owns any downstream prose auditor, so this skill routes to one skill, not two. |
| Validate items 12–13 kept unchanged despite overlapping the polish pass | local | They are the only voice gate when `technical-writing` is absent, and a cheap re-check when it's present. Cutting them would turn the soft dependency hard by another name. |
| Anti-slop rules stay duplicated in `readme-craft.md` | local | They overlap what a prose auditor catches, and that's the point: they are the only-this-skill-installed fallback. Same deliberate-duplication reasoning as `technical-writing`'s verbatim CLAUDE.md copies—a profile has to stand alone. |
| Voice preservation splits across the boundary | local | "An existing author's voice is the register" lives in `technical-writing`'s README profile, because register gating is that skill's mechanism and the rule must hold for callers this skill never meets. "Passages Step 4 preserved verbatim stay verbatim" lives here, because posture is this skill's axis and the profile has no concept of it. Complementary, not duplicated. |
| The skill relationship is called a polish pass, never a companion | local | "Companions" is taken: Step 7 uses it for the AGENTS.md / llms.txt artifacts. Reusing the word for a skill dependency would give one term two referents in the same file. |
| One-way coupling, enforced by both smoke tests | local | This skill names `technical-writing`; the reverse direction stays silent outside `technical-writing`'s own description, where one boundary-routing mention predates this change. A mutual runtime reference is how two skills ping-pong a draft between them. |

## Known Limitations

- **The polish pass is a flat cost.** Every run on a machine with both skills installed pays a dispatch to `technical-writing` plus whatever auditor round trip that skill performs. If that proves annoying in practice, the fix is a future opt-out flag, not a weaker step.
- **The ledger is young.** Everything before the polish step is documented only in the research doc, so a future edit to the older steps has no decision row to check itself against. Rows get added as decisions get revisited, not backfilled speculatively.
