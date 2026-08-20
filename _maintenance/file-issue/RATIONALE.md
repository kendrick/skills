# file-issue Skill Rationale

## Why This Skill Exists

Every issue-authoring tool on the market checks structure: did you fill the template, did you pass the gate. None of them check content: whether the reproduction actually runs, whether the acceptance criteria can fail, whether the scope has an edge. Structure compliance is cheap to verify and nearly worthless on its own, because a perfectly shaped issue with a prose gesture where the repro should be still costs a developer the same round trip.

That gap is the whole skill. The gates are content gates, and every one of them traces to a measured finding rather than to taste.

## Where the Evidence Comes From

[`_docs/file-issue-research.md`](../../_docs/file-issue-research.md) is the build input, a tiered survey ([E] measured, [P] practitioner, [C] convention) covering bug-report elements, duplicates, acceptance-criteria formats, titles, scope statements, agent-readiness, type taxonomies, interview burden, and templates. Its Rubric Derivation Table carries keep/cut verdicts per candidate item, and its Gaps Register was written as debt for this document. The rows below marked with a Q-number resolve into it.

The research also killed one feature and one statistic before either reached the skill. Both are recorded below.

## Decision Ledger

| Decision | Source | Reason |
| --- | --- | --- |
| Content gates, not structure compliance | local | Structure is what competitors already check. A well-shaped issue with an unrunnable repro passes every structure gate and still costs a round trip. |
| Named `file-issue`, not `create-issue` | local | "File an issue" is what people actually say, so it hits the auto-trigger surface more often. It also matches the research doc's filename. |
| Hard boundary against `to-tickets` in the description | local | `to-tickets` overlaps this trigger surface and does the opposite job of slicing a settled spec into many linked tickets. Without an explicit exclusion, one skill fires when the other was wanted. |
| No epic or tracking template | local | Multi-issue decomposition belongs to `to-tickets`, and its blocking-edges model is a better shape than epic-with-task-list anyway. Half-building it here would produce a worse version of something that exists. If it ever lands, it lands as edges. |
| Detection runs per invocation; no setup or config skill | local | mattpocock's run-once `setup-*` pattern assumes a repo you own and will configure. Consulting work happens in repos you saw for the first time this morning, so the ladder has to work cold or it does not work. |
| Duplicates surfaced, never blocked | Q2 | Evidence-contradicted, not merely unsupported. Duplicates rank 10% on developer severity, carry information the original lacks, and improve automatic triage when merged. Discarding them also teaches reporters to stop supplying follow-up detail. |
| Agent-readiness is a gate, and the differentiator | Q6 | The only evidence tying issue text directly to outcome: 38.3% of SWE-bench samples were flagged underspecified, and filtering them roughly doubled the measured resolve rate. What an agent needs beyond what a colleague needs is the verification command, the environment, and single-interpretation phrasing. |
| Verify the ready-for-agent label instead of applying it | local | `to-tickets` applies its label at publish. A label that is always applied carries no information; gating it on the rubric makes it mean something. |
| Acceptance criteria default to a checklist; GWT only on escalation | Q3 | No controlled study compares AC formats on ambiguity, testability, or defect rates. The silence is the finding. Falsifiability is what the evidence supports, so that is what gets gated and the notation stays style. |
| Elicit lives inline in `SKILL.md` | local | It runs on nearly every non-trivial invocation. Core-path logic behind a "go read file X" indirection is exactly the pattern that costs a run its coherence. Written to a stated interface contract so it stays liftable. The promotion path is to cut the section into its own file and add frontmatter, and the trigger is a second consumer (spec writing, workshop prep). Until then it stays put. |
| No runtime delegation to an external interrogation skill | local | The depth governor is the differentiator and `/grill-me` has none, because it is relentless by design. Injected steering competes with an already-loaded skill body and loses. And it would put a runtime dependency on an externally-maintained repo that a client machine may not have. Composition happens at the escape hatch instead, which is a clean sequential boundary. |
| Every question must name an empty slot | local | It makes the anti-annoyance promise checkable rather than aspirational. A question with no named gap is a question that should not have been asked. |
| Depth 1 caps at five questions | Q8, [C] | Calibrated from survey-length data, not measured on bug reporters: completion falls from ~83% at one to three questions to ~65% at four to eight, and the foundational bug-report survey was itself designed to a five-minute budget. |
| Templates in `assets/`, not `references/` | local | They are output material, and exactly one is read per run. Same split `inbox-to-memory` uses. |
| Detection always harvests; only Depth 2 probes code | local | The verification command and file pointers come from the repo, not from the user, so asking for them would burn questions on facts already on disk. Deeper source exploration is Depth 2's alone, because it costs real time and the skill's job is authoring an issue, not performing the engineering analysis. |
| Escape hatch at ≥7 criteria or ≥4 components | local, uncalibrated | Deliberately loose. Either condition alone fires. A false escape is more annoying than a slightly oversized issue, so this errs toward finishing the job. |
| Four types: bug, feature, task, spike | Q7 | Bug and feature are universal across GitHub, Linear, and Jira. Task absorbs chore and tech debt, matching Linear's "Chore", Jira's "Task". Spike is convention, kept for the reason below. |
| Spike kept despite not being vendor-canonical | Q7, [C] | Absent from Linear's fixed four and GitHub's defaults, but time-boxed research genuinely is a different shape of work with a different done-criterion. The template says so and tells you to file it as a task where the repo has no room for it. |
| Issue forms rank above Markdown templates | Q9 | Not taste. Across 100 projects and 1.9M+ issues, YAML forms specifically reduced time-to-resolution, reopenings, and discussion length relative to Markdown templates. |
| Preflight `gh auth status`, fail loud | local | A rendered draft looks like a filed issue. Silently degrading is how someone believes they reported a bug they did not report. |
| Creation only, never edit, close, or triage | local | Those are different jobs with different risk profiles. A skill that can close issues needs guards this one does not have. |
| Prose pass delegates to `technical-writing`; the interview still never delegates | local | The interview carries the depth governor, judgment this skill owns and loses the moment another skill runs it. The prose pass has no governor to lose—it is a mechanical audit, and where the sibling skill is missing the run degrades to shipping the draft unchanged, not to a broken one. `technical-writing` also owns the downstream prose-auditor invocation, so file-issue routes to one skill instead of two. |

## What the Research Removed

- **Blocking on suspected duplicates.** A plausible feature, cut because the evidence points the other way (Q2).
- **The "Gherkin catches 56% of requirements-phase defects" figure.** Circulates widely, has no primary citation, originates in vendor marketing. Explicitly excluded (Q3).
- **Resolution speed as a quality proxy.** Report quality and report lifetime are statistically independent, so a fast fix may just mean an urgent bug (Q1).
- **Severity and priority fields.** Zero developer importance. Collected when a detected template asks; never added (Q1).

## Known Limitations

- **The escape-hatch numbers are a first guess.** Nothing calibrates ≥7 criteria or ≥4 components. They need real use before they mean anything.
- **Human evidence, agent-plausible.** Bettenburg, Ko, and Hooimeijer all predate LLM agents. SWE-bench echoes the core underspecification result, but the specific element rankings have not been validated against agent consumers.
- **Templates help, but not uniformly.** Presence correlates with faster resolution at effect size 0.59, yet some cohorts show reduced incoming volume and *longer* resolution after adoption. The net is positive and the mechanism is partly filtering. Do not overclaim it.
- **Open-source scope.** The bug-report findings explicitly disclaim transfer to closed-source projects, which have no patches and rarely surface stack traces. The skill's project-type conditionals on error output are the mitigation.
- **GitHub only.** Detection, creation, and duplicate search all assume `gh`. Linear and Jira would each need their own reference file and their own creation path. Left out until someone needs it.
- **No multi-issue path at all.** Deliberate, but it means a user who wanted decomposition gets a recommendation instead of a result. The escape hatch hands over the interview output so the work is not lost.
- **The prose pass is a flat cost, not an opt-in one.** At Depth 1 and above on a machine with both skills installed, every run now pays a dispatch to `technical-writing` plus whatever auditor round trip that skill performs. If that proves annoying in practice, the fix is a future opt-out flag, not a weaker step.
