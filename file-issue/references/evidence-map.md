# Evidence Map

Every gate and default in the self-check traces to a claim here. Read this when a user challenges a rubric item, or when revising the skill.

Tiers: **[E]** measured, **[P]** practitioner consensus or official docs, **[C]** convention — plausible, unevidenced. Full sourcing lives in [`_docs/file-issue-research.md`](../../_docs/file-issue-research.md); question numbers below point into it.

## Gates

| Item | Claim | Tier | Where |
| --- | --- | --- | --- |
| Stranger test | 38.3% of SWE-bench samples were flagged as underspecified; filtering them roughly doubled the measured resolve rate. Separately, "incomplete information" is the #1 developer-reported problem with bug reports, at 74% severity. | [E] | Q6, Q1 |
| Runnable repro | Steps to reproduce rank first on developer importance (83%), and errors in those steps are the most severe problem developers report (79%). The gate enforces runnability, not presence, because a broken repro is worse than an absent one. | [E] | Q1 |
| Observed vs. expected, stated separately | Observed 33% and expected 22% on importance, at 2–3% reporter difficulty. Errors in observed behavior carry 48% severity. Cheapest high-value pair in the whole report. | [E] | Q1 |
| Error output where applicable | 57% developer importance. Reports with stack traces get fixed sooner across all three studied projects and are likelier to reach a FIXED resolution. | [E] | Q1 |
| ≥1 falsifiable acceptance criterion | Binary acceptance criteria are one of GitHub's three named elements of a well-scoped agent task. The measured quality attribute is testability and the absence of referential ambiguity — ambiguous pronouns show a strong negative effect on downstream model-building. | [P] gate, [E] mechanism | Q3, Q6 |
| Agent-readiness, agent-targeted issues | The only evidence tying issue text directly to outcome. Verification command and environment setup are what an agent needs that a colleague does not — a teammate reuses tacit local knowledge; an agent in an ephemeral sandbox has none. Single-interpretation phrasing matters because a human asks in standup and an agent commits to one guess. | [E]+[P] | Q6 |

## Defaults

Surfaced, never blocking.

| Item | Claim | Tier | Where |
| --- | --- | --- | --- |
| Ko-structured title | ~200,000 titles across five projects show a consistent shape: software entity, its inadequacy, and an execution context; ~95% of noun phrases named visible entities or user actions. The *structure* is [E]-described. The searchability and triage payoff is [C] — nobody has measured it. | [P], benefit [C] | Q4 |
| Non-goals | Shape Up: under-specified projects grow because nothing bounds them. Practitioner testimony only; no measured effect on scope creep or review churn. Doubles as a bound on an agent's change surface. | [P] | Q5 |
| Convention-matching labels | Conforming to a repo's detected template is [E]-backed. Which specific labels a project uses is its own convention. | [E] conformance, [C] specifics | Q9, Q7 |
| Environment metadata | Ranked near zero by developers: OS 4%, product 5%, component 3%, severity 0%. Cheap to collect, so collect it — but never hold an issue for it. Value is project-type dependent and rises for native and mobile. | [E], low | Q1 |

## Things Deliberately Not in the Rubric

| Not included | Why |
| --- | --- |
| Hard-block on suspected duplicates | Evidence-contradicted, not merely unsupported. Duplicates rank 10% on developer severity, carry information the original lacks, and improve automatic triage when merged rather than discarded. Discarding them also makes reporters stop supplying follow-up information. Surface and let the user decide. |
| A required acceptance-criteria notation | No controlled study compares Given/When/Then against checklist against prose on ambiguity, testability, or defect rates. The silence is the finding. The skill gates falsifiability and treats notation as style. |
| The "Gherkin catches 56% of requirements-phase defects" figure | Circulates widely, has no primary citation, originates in vendor marketing. Do not cite it. |
| Resolution speed as a quality proxy | Report quality and report lifetime are statistically independent (Spearman 0.002–0.068). A fast fix may just mean an urgent bug. |
| Severity and priority fields | 0% developer importance. Collect if a detected template asks; never add one. |

## Duplicate-Surfacing Signal Order

1. **Stack trace or error-signature overlap** — strongest structured signal by a distance. Call-stack clustering reaches F≈0.88 on real crash data, against 40–60% for earlier text-plus-trace methods. [E]
2. **Title and description text similarity** — the classic signal; modern systems are hybrid retrieval plus classifier. [E]
3. **Same component or area** — marginal. [E], weak

## Standing Caveats

- **Human findings, agent-plausible.** Bettenburg, Ko, and Hooimeijer all predate LLM agents. SWE-bench echoes the core result that underspecification hurts, but the specific rankings have not been validated against agent consumers. Every [E] item in Q1 and Q4 is human-validated and agent-plausible, not agent-proven.
- **Templates help, but not uniformly.** Presence correlates with faster resolution (effect size 0.59), yet some cohorts show reduced incoming volume and *longer* resolution after adoption. The net is positive; the mechanism is partly filtering.
- **The five-question Depth 1 cap is [C].** No study measures when a bug reporter abandons an interview. The number is calibrated from survey-length data — completion falls from ~83% at 1–3 questions to ~65% at 4–8 — plus the fact that the foundational bug-report survey was itself designed to a five-minute budget.
- **Open-source scope.** The bug-report findings explicitly disclaim transfer to closed-source projects, which have no patches and rarely surface stack traces.
