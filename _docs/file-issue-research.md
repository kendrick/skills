# Issue Authorship Research — Build Input for `create-issue` SKILL.md

Retrieval date for all web sources: 2026-08-05. Tier legend: **[E]** empirical (measured), **[P]** practitioner consensus / official docs / maintainer statements, **[C]** convention (plausible, unevidenced). Recency flag: findings on _human_ bug-report consumers predate LLM agents (pre-2022); do not assume transfer to _agent_ consumers unless noted. Footnote markers `[^n]` resolve to hyperlinked sources in the Bibliography.

---

## Q1 — Bug report elements (→ bug template + rubric)

Primary source: Bettenburg, Just, Schröter, Weiss, Premraj, Zimmermann, "What Makes a Good Bug Report?" FSE 2008[^1] (extended: Zimmermann et al., IEEE TSE 36(5):618–643, 2010[^2]). Survey of APACHE/ECLIPSE/MOZILLA: 872 developers + 1,354 reporters contacted; 466 responses (156 developer, 310 reporter); 130 consistent developer responses, 215 consistent reporter responses; 1,186 quality votes over 289 bug reports.[^1]

**Developer "importance" ranking** — conditional likelihood an item, once used, was named a top-3 most-helpful item (Table 2)[^1]:

| Item               | Importance (developers) | Reporter difficulty to provide |
| ------------------ | ----------------------- | ------------------------------ |
| Steps to reproduce | **83%**                 | 51% (hard)                     |
| Stack traces       | **57%**                 | 24%                            |
| Test cases         | **51%**                 | 75% (hardest item)             |
| Observed behavior  | 33%                     | 2% (easy)                      |
| Screenshots        | 26%                     | 8%                             |
| Expected behavior  | 22%                     | 3% (easy)                      |
| Code examples      | 14%                     | 43%                            |
| Summary            | 13%                     | 4%                             |
| Error reports      | 12%                     | 2%                             |
| Version            | 12%                     | 1%                             |
| Build information  | 8%                      | 3%                             |
| Product            | 5%                      | 0%                             |
| OS                 | 4%                      | 1%                             |
| Component          | 3%                      | 22%                            |
| Severity           | 0%                      | 5%                             |
| Hardware           | 0%                      | 1%                             |

- **[E]** Steps to reproduce, stack traces, and test cases are the three most useful items to developers; these are simultaneously the _hardest_ for reporters to provide → the core "information mismatch."[^1][^2]
- **[E]** The mismatch is quantified by Spearman correlation: what developers _use_ vs. what reporters _provide_ = 0.321; what developers _deem important_ vs. what reporters _provide_ = **−0.035** (essentially no alignment). But what developers deem important vs. what reporters _believe_ is important = **0.839** (strong). Interpretation: reporters know what matters but cannot supply it — a tooling/elicitation problem, not ignorance.[^1]
- **[E]** Most common developer-reported problem = **incomplete information (74% severity)**; most severe = **errors in steps to reproduce (79%)**. Direct quote: "The biggest causes of delay are not wrong information, but absent information." Other high-severity problems: errors in observed behavior (48%), test cases (38%), expected behavior (27%), too-long text (26%), stack traces (25%).[^1]
- **[E]** Mandatory metadata fields ranked low importance: product 5%, component 3%, OS 4%, hardware 0%, severity 0%. A MOZILLA developer: "product and usually even component information is irrelevant to me… most our bugs are usually found in all platforms." Authors caution low-importance items are "not totally irrelevant" (still needed to reproduce/triage).[^1]
- **[E]** Statistically-mined outcomes on 150,000 bugs (50,000 each project, Chi-Square/Kruskal-Wallis p<0.05): "Bug reports containing stack traces get fixed sooner" (all three projects); "Bug reports that are easier to read have lower lifetimes" (all three); "Including code samples… increases the chances of it getting fixed" (MOZILLA). Presence of stack traces significantly increased likelihood of a FIXED resolution.[^1]
- **[E]** Independent corroboration: Hooimeijer & Weimer (ASE 2007, FIREFOX, 27,000+ reports) — easy-to-read reports fixed faster; reports with attachments fixed _later_, reports with many comments fixed sooner.[^4]
- **[E]** Report quality (developer-rated) and report _lifetime_ are independent measures (Spearman 0.002–0.068): a fast-fixed bug is not necessarily high-quality (may be urgent), and vice versa. Do not treat resolution speed as a proxy for report quality.[^1]
- **[E]** CUEZILLA quality-scoring tool: trained on 289 developer-rated reports; features = itemizations, keyword completeness, code samples, stack traces, patches, screenshots, readability (7 measures incl. Flesch/Kincaid/SMOG). Perfect agreement with developers on 31–48% of reports (≈41% cited overall), 87–91% off-by-one. Models port across projects but best applied within-project.[^1]
- **[E]** Environment info matters conditionally: authors explicitly state findings apply to open-source; "we do not contend that they are transferable to closed-software projects (which have no patches and rarely stack traces)." Screenshots "often are helpful only for a subset of bugs, e.g., GUI errors." → environment/metadata value is project-type-dependent.[^1]
- **[E]** Observational scale study: 650,000+ reports across open-source trackers found "few fields influence the resolution time and that customized fields have little impact on it" — corroborates that most structured metadata fields are low-value for outcomes.[^42]

**Implication for the skill:** The bug template's evidence-ordered required fields are, in strict priority: (1) steps to reproduce, (2) stack trace / error output, (3) observed vs. expected behavior, (4) minimal reproducing test case/code if available. These four are the only [E]-backed rubric _gates_. Environment/version/component/OS are [P]/[C] defaults — collect them cheaply but never block on them, and make them conditional on project type (GUI → screenshot; native/closed-source → deprioritize stack-trace gating). "Incomplete information" being the #1 problem justifies a completeness check; "errors in steps to reproduce" being #1 severity justifies a _runnable-repro_ rubric item over a mere presence check. Do NOT use resolution-speed as a quality proxy in any rubric.

---

## Q2 — Duplicates (→ dupe-handling behavior, §5 write-guard)

Primary source: Bettenburg, Premraj, Zimmermann, Kim, "Duplicate Bug Reports Considered Harmful… Really?" ICSM 2008.[^3]

- **[E]** Survey finding: most developers have experienced duplicates but few consider them a serious problem — contradicting "popular wisdom." In the FSE 2008 survey, duplicates ranked only 10% severity among developer problems. Developer quote: "Duplicates are not really problems. They often add useful information."[^1][^3]
- **[E]** Duplicates carry _additional information_ the master lacks; the paper quantifies the added information and shows automatic triaging _improves_ when duplicate information is merged rather than discarded. Recommendation: merge duplicates, don't discard.[^3]
- **[E]** Base rates: ~30% of MOZILLA and ~20% of ECLIPSE reports were duplicates (Anvik et al., cited); as of April 2008 MOZILLA had 420,000+ and ECLIPSE 225,000+ reports. Later sources cite ~40% duplicate rates in some trackers.[^3][^43]
- **[E]** Discarding duplicates has a social cost: reporters "become reluctant to provide additional information once they see that a bug report has already been filed."[^38]
- **[E]** Duplicate-detection signals, by evidence strength: **stack-trace / call-stack similarity is the strongest structured signal.** ReBucket (Dang, Wu, Zhang, Zhang & Nobel, ICSE 2012) call-stack clustering, verbatim: "We evaluate ReBucket using crash data collected from five widely-used Microsoft products… On average, the F-measure obtained by ReBucket is about 0.88" (Purity 0.828–0.969, Inverse Purity 0.828–0.970). Earlier text+trace methods reached only 40–60% accuracy.[^6] TraceSim combined TF-IDF + Levenshtein on stack frames to outperform prefix-match/Brodie baselines.[^7] Textual (NLP/BM25F/topic-model/word-embedding) similarity on summary+description is the classic signal (Runeson et al., ICSE 2007); best modern systems are hybrid two-stage (vector retrieval → supervised classifier).[^43] Product/component fields add marginal signal.

**Implication for the skill:** "Block on likely dupe" is **NOT evidence-backed** — the evidence says duplicates are low-harm and information-additive. The write-guard should **surface likely duplicates and let the user decide** (link candidates, offer "add to existing as comment" vs. "file new"), never hard-block. Ranking of dupe-detection signals for the skill's surfacing heuristic: (1) stack-trace/error-signature overlap [E, strongest — ReBucket F≈0.88], (2) title/summary + description text similarity [E], (3) same component/area [E, weak]. If a new report has richer repro than a suspected master, explicitly recommend appending rather than closing.

---

## Q3 — Acceptance criteria format (→ all templates)

- **[E, absence]** **No controlled or empirical study compares acceptance-criteria _formats_ (Given/When/Then vs. checklist/rule-based vs. prose "definition of done") on ambiguity, testability, defect rates, or completion accuracy.** The BDD empirical base is small and non-experimental: a 2024 thematic synthesis compiled only 23 studies[^13]; the leading BDD-vs-TDD comparison is qualitative interviews and explicitly calls for the missing quantitative work ("Quantitative studies that measure metrics such as defect rates, delivery times… could provide more objective data")[^14]. The only "controlled experiment" in the BDD space (Wang & Wagner, XP 2018) tests STPA+BDD for _safety analysis_, not AC notation. Silence is the finding.
- **[E]** Adjacent requirements-quality experiment (Frattini et al., _Empirical Software Engineering_ 2024, n=25): ambiguous pronouns show a strong negative effect on downstream model-building; passive voice only minor. The broader literature finds ambiguity's downstream effect often "negligible" and the evidence "scarce."[^12] → The mechanism that measurably hurts is _referential ambiguity_, not prose-vs-structure per se.
- **[P]** Agile Alliance glossary: GWT is "a template intended to guide the writing of acceptance tests for a User Story" — (Given) context, (When) action, (Then) "a particular set of observable consequences should obtain." Explicitly tool-neutral: "it can also be used purely as a heuristic irrespective of any tool." **Makes NO defect-reduction or ambiguity-elimination claim and names NO tradeoff.**[^15]
- **[P]** Martin Fowler, "GivenWhenThen" (2013-08-21): developed by Daniel Terhorst-North & Chris Matts as part of BDD; a "reformulation of the Four-Phase Test pattern" (Meszaros: Setup/Exercise/Verify/Teardown) and Bill Wake's Arrange-Act-Assert. Usable "with any kind of tests," as code comments, or "to structure informal prose" — not Gherkin-bound.[^16] Fowler positions GWT as a restatement of pre-existing patterns, not a novel evidence-backed technique.
- **[P]** Practitioner "when to use each": GWT for behavior/workflows/user journeys; checklist for rules, validations, fields, permissions, and non-functional criteria (accessibility, performance, security). "There is no single format that works for every situation."[^39] BDD guides warn GWT becomes an anti-pattern when turned into "mini-requirements documents" or when it encodes implementation details in the Given ("Given the UserService returns a valid JWT" ✗ → "Given a logged-in user" ✓). Simpler stories: "a checklist is often faster and equally effective."[^39]
- **⚠️ Do not cite:** the circulating "Gherkin catches 56% of requirements-phase defects" stat[^40] has no primary citation and is marketing.

**Implication for the skill:** AC format is a **[C]/[P] style choice, not an [E] gate.** The rubric must label any "use Given/When/Then" item as _convention, not evidence._ Decision rule the skill can ship: **default to a falsifiable checklist of pass/fail conditions; escalate to Given/When/Then only when (a) the item describes multi-step stateful behavior / a user journey, (b) the team has BDD tooling (Cucumber/Behave/Playwright-BDD) that executes the scenarios, or (c) QA authors tests directly from AC.** For rules/validation/permissions/non-functional criteria, prefer checklist. The evidence-backed quality attribute to enforce is _testability/falsifiability and absence of referential ambiguity_ — not the notation. Every AC item must be binary-verifiable regardless of format.

---

## Q4 — Titles and searchability (→ rubric title item)

Primary source: Ko, Myers, Chau, "A Linguistic Analysis of How People Describe Software Problems," VL/HCC 2006 (≈200,000 bug-report titles across five projects).[^5]

- **[E]** Bug-report titles exhibit strong regularity: they generally name **a software entity or behavior, its inadequacy, and an execution context.** ~95% of noun phrases referred to visible software entities, physical devices, or user actions. Title structure was parseable at 89% accuracy. ~48% of titles contained an adjective (to qualify the entity or the inadequacy); context markers (when/after/if/during/while) signalled execution conditions.[^5]
- **[E]** Authors' design implication: this regularity means titles _could_ be captured in more structured forms — i.e., a good title = {entity/component} + {inadequacy/wrong behavior} + {context/trigger}.[^5]
- **[P/C]** No study measures title patterns' effect on searchability, duplicate-prevention, or triage speed directly. Practitioner convention: component/area prefixes (e.g., `[auth]`, `[BUG]`) and conventional-commit-style tags aid filtering; common guidance is "use a consistent structure: [Verb] [What] [Context]." Convention only.

**Implication for the skill:** The rubric title item is **[E]-informed but not [E]-gated on outcomes**: enforce the Ko structure — title must name the component/entity, the defective behavior, and (for bugs) the trigger context. This is defensible as [P] (grounded in an [E] descriptive study of how humans actually title problems), but the _searchability/triage-speed benefit_ itself is [C]. Component/tag prefixes are [C] convention — offer them as convention-matching (see Q7), not as evidence-based gates.

---

## Q5 — Scope statements and non-goals (→ feature template)

- **[P]** Shape Up (Ryan Singer, Basecamp, 2019). "Set Boundaries" and "Principles of Shaping" chapters: "under-specified projects naturally grow out of control because there's no boundary to define what's out of scope." "Shaped work indicates what not to do. It tells the team where to stop." The framework names an explicit **"No-gos"** element: "things that the solution explicitly will NOT include, preventing scope creep," plus "Rabbit holes" (out-of-scope risks).[^17]
- **[P]** Shape Up's "appetite" mechanism (fixed time budget, variable scope) is presented as the discipline that forces scope decisions; adopters report reduced scope creep. These are practitioner testimonials, **not measured** — no controlled study links a "non-goals" section to reduced churn/misimplementation.[^17]
- **[C]** RFC/design-doc templates (IETF RFC style, Google design docs) conventionally include "Non-goals" / "Out of scope" sections; widely adopted but unevidenced as to churn reduction.

**Implication for the skill:** A **Non-goals / Out-of-scope section is [P], not [E].** Include it in the feature and spec templates as a default with the strongest practitioner rationale (Shape Up: boundaries prevent uncontrolled growth), but the rubric must label the item "convention, not evidence." For agent-consumed issues this doubles as a guardrail (see Q6): explicit non-goals bound the agent's change surface. Recommend it especially where appetite/scope is fixed.

---

## Q6 — Agent-readiness (→ agent-readiness rubric item; THE DIFFERENTIATOR)

Primary sources: GitHub Copilot cloud-agent docs[^18]; OpenAI SWE-bench Verified[^8] and follow-ups[^9][^10][^11]; Anthropic/Claude Code guidance[^19][^20].

**GitHub's own definition of a well-scoped agent task [P]** — "An ideal task includes: A clear description of the problem to be solved or the work required; Complete acceptance criteria on what a good solution looks like (for example, should there be unit tests?); Directions about which files need to be changed." GitHub adds: "think of the issue you assign to Copilot as a prompt… Consider whether the issue description is likely to work as an AI prompt." Semantic code search means "even if you don't specify exact file paths… the agent can often discover the right code on its own" — so file pointers help but are not strictly mandatory.[^18]

**Tasks GitHub says to give agents vs. keep [P]:** good for agents = bug fixes, UI tweaks, improving test coverage, docs, accessibility, tech debt. Keep for humans = broadly-scoped/cross-repo refactors, deep-domain or heavy-business-logic tasks, production-critical/security/PII/auth, incident response, and **ambiguous/open-ended tasks "lacking clear definition."**[^18]

**Environment as a first-class agent input [P]:** Copilot runs in an ephemeral GitHub Actions environment; "If Copilot is able to build, test and validate its changes in its own development environment, it is more likely to produce good pull requests." Repos should supply `.github/copilot-instructions.md` (build/test/validate commands, conventions), path-specific `*.instructions.md`, and `copilot-setup-steps.yml` to pre-install deps ("Copilot can discover and install… via trial and error - but this can be slow and unreliable, given the non-deterministic nature of… (LLMs)"). Copilot also reads `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.[^18]

**SWE-bench: underspecification is a measured failure mode [E]:** OpenAI's SWE-bench Verified (2024), 93 professional developers annotating 1,699 samples (three annotators each), yielding 500 verified tasks. Verbatim: "We see that 38.3% of samples were flagged for underspecified problem statements, and 61.1% were flagged for unit tests that may unfairly mark valid solutions as incorrect. Overall, our annotation process resulted in 68.3% of SWE-bench samples being filtered out." And: "We found that GPT-4o's performance on the best-performing scaffold reaches 33.2% on SWE-bench Verified, more than doubling its score of 16% on the original SWE-bench." — i.e., the original benchmark _underestimated_ agents largely because tasks were underspecified or mis-graded.[^8]

- **[E]** Solution leakage: SWE-Bench+ found 37 SWE-bench Verified instances contained the solution directly in the issue description/discussion; filtering suspicious fixes dropped SWE-Agent+GPT-4's Verified resolution from 22.4% to 10.0%.[^10] → issue text materially determines measured success, and leakage/over-specification distorts it.
- **[E]** OpenAI (2025, "Why SWE-bench Verified no longer measures frontier coding capabilities"), verbatim: "Many task statements were underspecified, which could lead to multiple valid interpretations - while the tests only covered a specific one. Depending on setup of the environment (for example Linux vs Windows, or the python version), some tests could spuriously fail."[^9] → both task spec _and_ environment reproducibility gate agent success.
- **[E]** SWE-bench Verified encoded **Issue Clarity** as an explicit graded label (0–3); SWE-rebench fine-tuned a model to predict Test-Patch Correctness, Task Complexity, and Issue Clarity — i.e., "issue clarity" is now a formalized, model-scored dimension.[^11]

**Claude / Claude Code guidance [P]:** "Claude responds well to clear, explicit instructions" and "follows explicit instructions more reliably than vague preferences." Anthropic's specificity principle: "Claude can infer intent, but it can't read minds. Specificity leads to better alignment."[^19] Instruction-fragility calibration ("narrow bridge with cliffs" → exact commands / low freedom, e.g. DB migrations in exact sequence; "open field" → general direction / high freedom, e.g. code reviews). Be explicit about **how tests are run** ("Run: `npm test -- --testPathPattern=<filename>`") to avoid costly full-suite runs.[^20] Avoid abstract directives ("write clean code" carries "zero signal… Copilot cannot operationalize them"); watch instruction/codebase contradictions (agent will interpolate).[^21]

**Concrete agent-readiness element list (synthesized [P]+[E]):**

| Element                                                               | Why an agent needs it (that a human colleague may not)                                  | Tier    | Src        |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | ------- | ---------- |
| Explicit, unambiguous problem statement (single valid interpretation) | Underspecification measurably lowers resolve rate; agent can't hallway-ask              | [E]     | [^8][^9]   |
| Complete, binary acceptance criteria incl. "are tests required?"      | GitHub's named ideal-task element                                                       | [P]     | [^18]      |
| Verification command (exact build/test/lint invocation)               | Agent runs in ephemeral env; must self-validate; targeted test cmd avoids cost          | [P]     | [^18][^20] |
| Environment/setup (deps, versions, `copilot-setup-steps.yml`)         | Env non-reproducibility causes spurious failures; trial-and-error install is unreliable | [E]+[P] | [^9][^18]  |
| File/module pointers (paths or clear component names)                 | GitHub names it; semantic search can substitute but pointers reduce search error        | [P]     | [^18]      |
| Explicit done-criteria / definition of done                           | Agent has no implicit "good enough" prior                                               | [P]     | [^18]      |
| Non-goals / scope boundaries                                          | Bounds the change surface; prevents over-broad edits                                    | [P]     | [^17]      |
| Enough spec, but no solution leakage                                  | Over- and under-specification both distort outcomes                                     | [E]     | [^10]      |
| Repo-level `copilot-instructions.md` / `AGENTS.md` conventions        | Supplies build/test/style the agent would otherwise infer wrongly                       | [P]     | [^18][^21] |

**Implication for the skill:** Agent-readiness is the differentiator and rests on the **only [E] evidence in this domain that directly ties issue text to outcome** (SWE-bench underspecification: 38.3% of samples underspecified, and filtering them roughly doubled the measured resolve rate). The agent-readiness rubric item should be a hard gate for agent-targeted issues and require: (1) single-interpretation problem statement, (2) binary acceptance criteria, (3) a runnable verification command, (4) environment/setup pointers, (5) file/module hints, (6) explicit done-criteria, (7) non-goals. Items 1–4 are [E]/[P]-strong; treat 5–7 as [P] defaults. What an agent needs that a human doesn't: the _verification command_ and _environment setup_ (a human colleague reuses tacit local knowledge; a cold agent in an ephemeral sandbox does not) and _single-interpretation phrasing_ (a human asks in standup; a cold agent commits to one guess).

---

## Q7 — Issue type taxonomy (→ §2 built-in templates)

- **[P]** Linear ships exactly four issue types — **Bug, Feature, Improvement, Chore** — non-extensible, non-renamable, by design ("You cannot add a fifth type. You cannot rename them"), explicitly to prevent "Jira sprawl."[^23] Linear's conceptual model: the Issue is "the fundamental unit of work… bugs, feature work, follow-up tasks, or internal requests."[^22]
- **[P]** GitHub default issue-form templates ship Bug Report and Feature Request as the canonical two; "BugReport was the most numerous" issue-report-template category across 1,084,300 projects studied.[^25]
- **[P]** Jira/Oracle-style trackers use Task, Defect(Bug), Feature(Enhancement), Epic. Oracle Visual Builder: Task ("an action is required"), Defect ("a bug or fault," default type), Feature ("new feature or enhancement"), Epic ("cannot be completed in one sprint… contains sub-issues").[^24]
- **[C]** "Spike" (time-boxed research/investigation task) is an Agile/XP convention widely used but not a first-class type in Linear or GitHub defaults.

**Implication for the skill:** The four-template set **bug / feature / task / spike is validated for bug and feature (both [P], universal) and task (Linear "Chore" / Jira "Task", [P]).** "Spike" is **[C]** — a real and useful convention but not vendor-canonical; keep it, labeled convention. Recommendation: ship the four but note that "improvement/enhancement" is often folded into feature (Linear splits them; GitHub/Jira fold them) — the skill should map enhancement→feature unless a project's existing labels distinguish them. Amendment: consider making "task" the catch-all (covering chore/tech-debt) and "spike" explicitly time-boxed with a research question as its done-criterion.

---

## Q8 — Interview burden (→ depth governor calibration)

- **[E, adjacent]** Survey-methodology literature (labeled adjacent — about survey respondents, not bug reporters): completion rate falls sharply with length. Survicate dataset of 267,564 responses: "1–3 questions: 83.34% completion rate · 4–8 questions: 65.15% · 9–14 questions: 56.28% · 15+ questions: 41.94%."[^33] A _separate_ Survicate study (n=1,793 surveys) found "Micro-surveys with one question only have an average completion rate of 85.7% – the highest of any question-count group in the entire dataset."[^34] (Note: these are two distinct datasets, not one.) SurveyMonkey/Zoho/Kantar: abandonment spikes 5–20% once a survey passes the **7–8 minute** mark; a >25-min survey loses 3× the respondents of a <5-min one.[^35] Galesic & Bosnjak (2009) and Revilla & Ochoa (2017): longer surveys increase dropout and degrade per-answer data quality (fatigue → careless answers).[^41]
- **[E]** Bettenburg 2008 itself was designed around a **five-minute completion budget** ("we would much appreciate five minutes of your time") explicitly to protect response rate — a direct precedent that even expert respondents are budgeted at ~5 minutes. Consistency-check discard rates (16.7% developer, 30.6% reporter responses inconsistent) show careless/fatigued answering is real even in short instruments.[^1]
- **[E/P]** Guided vs. free-text reporting: BURT (ICSE 2023) — interactive chatbot that guides reporters through observed behavior, expected behavior, and steps-to-reproduce with instant quality verification — found users rated the guidance and clarifications useful and easy to use; premise is that static forms "offer limited guidance… and do not provide feedback."[^36] FeedAIde context-aware follow-up questions produced higher expert-rated Observed Behavior (1.50/2) and Steps-to-Reproduce completeness than a traditional free-text field, where users submitted terse entries like "App crash when Concierge was called."[^37] → structured, _adaptive_ prompting improves quality vs. free text; both tools emphasize minimal, targeted questioning over exhaustive forms.

**Implication for the skill:** No direct evidence exists on "how many clarifying questions before a bug reporter abandons," so this is calibrated from adjacent survey data ([E, adjacent]) plus Bettenburg's 5-minute design precedent. The **3–5 question Depth-1 budget is defensible**: it sits well below the 7–8 minute / ~8-question inflection where completion (drops from ~65% at 4–8 questions toward ~42% at 15+) and answer-quality degrade. Recommendation: cap Depth-1 at ≤5 targeted questions, front-load the highest-[E]-value asks (steps-to-reproduce, then stack trace/error, then expected-vs-actual), and make each question adaptive/skippable (BURT/FeedAIde pattern) rather than a fixed long form. Label the specific "3–5" number as [C] calibrated-from-adjacent-evidence.

---

## Q9 — Templates and issue forms (→ §1 detection ladder)

- **[E]** Template presence measurably improves outcomes. Bilkent study (ACM TOSEM 2024; 100 projects, 350 templates, 1.9M+ issues): issues created when a template exists are "statistically resolved faster (p-value 0.00, effect size 0.59)" and draw fewer comments; **when YAML issue _forms_ are used, time-to-resolution, number of reopenings, and discussion length all significantly decrease** vs. plain Markdown templates. 99/100 projects used templates; 85% of surveyed maintainers viewed them positively. Reported resolution-time contrast: 381.02 days → 103.18 days for projects with templates.[^26]
- **[E]** Li et al. (JSS 2023, "A first look at bug report templates on GitHub"): bug reports written using templates "are resolved more quickly and have higher comment coverage."[^27] Adoption of issue-report templates associated with increased project productivity (IEEE 2024, 1,084,300 projects).[^25] Counter-nuance: Li et al. (802 projects, 2020) found that after template adoption, monthly incoming issue/PR _volume decreases_ and issues can show _longer resolution duration_ in some cohorts — i.e., templates filter volume and may change the mix; effects are not uniformly positive across every metric.[^28] Flag this tension in the skill's rationale.
- **[P]** GitHub issue-forms YAML mechanics: forms live in `/.github/ISSUE_TEMPLATE/*.yml`; a form is a YAML array of body elements.[^29] Element `type`s: **`markdown`** (display-only, not submitted), **`textarea`**, **`input`** (single-line), **`dropdown`**, **`checkboxes`**. Each element has `attributes` (label, description, placeholder, value, options, render — e.g. `render: shell` for code blocks) and `validations` (notably `required: true/false`).[^30] Top-level keys: `name`, `description`, `title` (default title prefix), `labels`, `assignees`, `body`. When submitted, responses are converted to Markdown into the issue body. Constraint: `id` is not permitted on some element types at body level (documented user-reported schema quirk).[^31] Issue forms are **not supported for pull requests.** Schema is officially labeled beta/subject to change.[^29]
- **[P]** Config/fallback: `.github/ISSUE_TEMPLATE/config.yml` controls the chooser (`blank_issues_enabled`, `contact_links`). Org-level fallback: a repo named `.github` supplies default community health files (incl. issue templates) to all org repos lacking their own — so template resolution is repo → org `.github` repo.[^29]
- **[P]** `gh` CLI: `gh issue create` supports `--template <name>` to select a template file, plus `--title/--body/--label/--assignee`.[^32]

**Implication for the skill:** Template/form _presence_ is one of the few **[E]-backed** interventions — the §1 detection ladder should detect existing `.github/ISSUE_TEMPLATE` forms and conform to them (evidence favors YAML forms > Markdown templates > none; effect size 0.59 for faster resolution). The skill must parse the exact schema above (five element types, `validations.required`, `render: shell`, top-level `labels`/`assignees`/`title`), respect the repo→org-`.github` fallback, and use `gh issue create --template` for creation. Flag the beta-schema caveat and the `id`-placement quirk. Note the volume/duration counter-nuance so the RATIONALE doesn't overclaim templates as uniformly positive.

---

## Rubric Derivation Table

| Candidate rubric item                                                     | Supporting finding(s)                                                                                                                       | Tier                                | Src            | Keep/Cut recommendation                                                                                   |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------- |
| **Stranger test** (issue understandable with no tacit context)            | SWE-bench underspecification (38.3%) measurably lowers agent resolve rate; Bettenburg "incomplete information" = #1 developer problem (74%) | [E]                                 | [^8][^1]       | **Keep as gate.** Strongest for agent-targeted issues.                                                    |
| **Runnable repro** (steps that actually reproduce)                        | Steps-to-reproduce = #1 developer importance (83%); "errors in steps to reproduce" = #1 severity (79%)                                      | [E]                                 | [^1]           | **Keep as hard gate** for bugs. Enforce runnability, not mere presence.                                   |
| **Expected-vs-actual**                                                    | Observed 33% + expected 22% importance; both cheap for reporters (2–3% difficulty); errors in observed behavior = 48% severity              | [E]                                 | [^1]           | **Keep as gate** for bugs. Low reporter cost, high value.                                                 |
| **Stack trace / error output**                                            | 57% developer importance; presence → faster fix & higher FIXED likelihood (all 3 projects)                                                  | [E]                                 | [^1]           | **Keep as gate where applicable** (project-type conditional; less relevant for closed-source / GUI-only). |
| **Falsifiable AC** (binary pass/fail)                                     | GitHub agent ideal-task element; testability is the [E]-relevant attribute (referential ambiguity hurts); format itself unevidenced         | [P] (format = [C])                  | [^18][^12]     | **Keep as gate** on _falsifiability_; label _format_ (GWT vs checklist) "convention, not evidence."       |
| **Non-goals / scope boundaries**                                          | Shape Up "no-gos"; bounds agent change surface                                                                                              | [P]                                 | [^17]          | **Keep as default**, label "convention, not evidence."                                                    |
| **Searchable title** ({component}+{inadequacy}+{context})                 | Ko et al. 2006 title structure ([E] descriptive); searchability/triage benefit unmeasured                                                   | [P] (benefit = [C])                 | [^5]           | **Keep**; enforce structure as [P], label the searchability payoff [C].                                   |
| **Convention-matching labels** (match repo/org taxonomy)                  | Template/form conformance → faster resolution ([E]); label taxonomies are vendor convention                                                 | [E] conforming; [C] specific labels | [^26][^22]     | **Keep**; conform to detected templates ([E]); specific labels [C].                                       |
| **Agent-readiness** (verification cmd, env, file pointers, done-criteria) | SWE-bench underspecification [E]; GitHub/Anthropic task guidance [P]                                                                        | [E]+[P]                             | [^8][^18][^19] | **Keep as gate for agent-targeted issues.** The differentiator.                                           |
| **Environment/version metadata**                                          | Low developer importance (OS 4%, product 5%, component 3%); project-type-dependent value                                                    | [E] (low)                           | [^1][^42]      | **Keep as non-blocking default**; never gate; conditional on project type.                                |
| **Duplicate block**                                                       | Duplicates low-harm & information-additive ([E])                                                                                            | [E] contra                          | [^3][^1]       | **Cut hard-block**; replace with surface-and-decide.                                                      |

---

## Template Consequences (evidence-ordered section lists)

**Bug template** (ordered by Q1 developer-importance[^1]):

1. Title — {component} + {wrong behavior} + {trigger} (Ko structure[^5]) — [P]
2. Steps to reproduce (runnable) — [E, gate][^1]
3. Observed vs. expected behavior — [E, gate][^1]
4. Stack trace / error output — [E, gate where applicable][^1]
5. Minimal reproducing test case / code — [E, high value, high reporter cost → optional][^1]
6. Environment (OS/version/component) — [E-low, non-blocking, project-conditional][^1][^42]
7. Screenshots — [E, GUI-bugs only][^1]
8. (Agent-targeted only) verification command + file pointers — [E/P][^8][^18]

**Feature template:**

1. Title — [P]
2. Problem / user need — [P]
3. Proposed solution / behavior — [P]
4. Acceptance criteria (falsifiable; checklist default, GWT if stateful behavior + BDD tooling) — [P][^15][^16], format [C]
5. Non-goals / out-of-scope — [P][^17]
6. (Agent-targeted) file/module pointers, done-criteria, verification — [E/P][^18]

**Task template:** title; goal/outcome; falsifiable done-criteria; scope/non-goals; (agent) verification cmd + file pointers. Catch-all for chore/tech-debt. [P][^22][^24]

**Spike template:** title; the research question (the done-criterion); time-box/appetite[^17]; expected deliverable (decision/doc/prototype); explicit "no production code" non-goal. [C] (convention).

---

## Gaps Register (explicit debt for RATIONALE.md)

1. **AC format outcomes.** No controlled study compares GWT vs. checklist vs. prose on ambiguity/testability/defect rates. Skill ships checklist-default as [C]/[P] decision rule; revisit if a controlled study appears.
2. **Title patterns → searchability/triage speed.** Ko 2006[^5] describes title structure [E] but no study measures the downstream searchability/dedup/triage benefit. Title-rubric benefit is [C].
3. **Non-goals → churn reduction.** Only practitioner testimony (Shape Up[^17]); no measured effect on scope creep/review churn/misimplementation.
4. **Clarifying-question abandonment threshold for bug reporters specifically.** Calibrated only from adjacent survey-length data[^33][^35] + Bettenburg's 5-min design[^1]; no direct study. "3–5 questions" is [C].
5. **Transfer of pre-2022 human-consumer findings to agent consumers.** Bettenburg/Ko/Hooimeijer predate LLM agents; their rankings (steps-to-reproduce, stack traces) plausibly transfer (SWE-bench echoes "underspecification hurts"[^8]) but this is not directly validated. Flag every Q1/Q4 [E] item as human-validated, agent-plausible.
6. **Spike as a first-class type.** Not vendor-canonical (absent from Linear's fixed four[^23] and GitHub defaults[^25]); [C].
7. **Template volume/duration counter-effect.** Some studies show templates reduce incoming volume and can lengthen resolution in certain cohorts[^28]; the net effect is positive but not uniform — RATIONALE should not overclaim.
8. **Environment-info value by project type.** Bettenburg explicitly limits findings to open-source[^1]; closed-source/native/mobile value of stack traces/patches is under-evidenced.

---

## Bibliography

### [E] Empirical

[^1]: Bettenburg, N., Just, S., Schröter, A., Weiss, C., Premraj, R., Zimmermann, T. "What Makes a Good Bug Report?" _FSE 2008_, pp. 308–318. DOI [10.1145/1453101.1453146](https://doi.org/10.1145/1453101.1453146) · [PDF](https://thomas-zimmermann.com/publications/files/bettenburg-fse-2008.pdf)

[^2]: Zimmermann, T., Premraj, R., Bettenburg, N., Just, S., Schröter, A., Weiss, C. "What Makes a Good Bug Report?" _IEEE TSE_ 36(5):618–643, 2010. DOI [10.1109/TSE.2010.63](https://doi.org/10.1109/TSE.2010.63)

[^3]: Bettenburg, N., Premraj, R., Zimmermann, T., Kim, S. "Duplicate Bug Reports Considered Harmful… Really?" _ICSM 2008_, pp. 337–345. DOI [10.1109/ICSM.2008.4658082](https://doi.org/10.1109/ICSM.2008.4658082)

[^4]: Hooimeijer, P., Weimer, W. "Modeling Bug Report Quality." _ASE 2007_, pp. 34–43. DOI [10.1145/1321631.1321639](https://doi.org/10.1145/1321631.1321639)

[^5]: Ko, A.J., Myers, B.A., Chau, D.H. "A Linguistic Analysis of How People Describe Software Problems." _VL/HCC 2006_, pp. 127–134. DOI [10.1109/VLHCC.2006.3](https://doi.org/10.1109/VLHCC.2006.3) · [IEEE Xplore](https://ieeexplore.ieee.org/document/1698774/) · [PDF](https://faculty.washington.edu/ajko/papers/Ko2006LinguisticsOfBugReports.pdf)

[^6]: Dang, Y., Wu, R., Zhang, H., Zhang, D., Nobel, P. "ReBucket: A Method for Clustering Duplicate Crash Reports Based on Call Stack Similarity." _ICSE 2012_. DOI [10.1109/ICSE.2012.6227111](https://doi.org/10.1109/ICSE.2012.6227111) · [PDF](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/07/rebucket-icse2012.pdf)

[^7]: Vasiliev, R., et al. "TraceSim: A Method for Calculating Stack Trace Similarity." arXiv:2009.12590, 2020. <https://arxiv.org/abs/2009.12590>

[^8]: OpenAI. "Introducing SWE-bench Verified." 2024. <https://openai.com/index/introducing-swe-bench-verified/>

[^9]: OpenAI. "Why SWE-bench Verified no longer measures frontier coding capabilities." 2025. <https://openai.com/index/why-swe-bench-verified-no-longer-measures-frontier-coding-capabilities/>

[^10]: Aleithan, R., et al. "SWE-Bench+: Enhanced Coding Benchmark for LLMs." arXiv:2410.06992, 2024. <https://arxiv.org/abs/2410.06992>

[^11]: Badertdinov, I., et al. "SWE-rebench: An Automated Pipeline for Task Collection and Decontaminated Evaluation of Software Engineering Agents." arXiv:2505.20411, 2025. <https://arxiv.org/abs/2505.20411>

[^12]: Frattini, J., et al. "Applying Bayesian data analysis for causal inference about requirements quality: a controlled experiment." _Empirical Software Engineering_, 2024. DOI [10.1007/s10664-024-10582-1](https://doi.org/10.1007/s10664-024-10582-1)

[^13]: Arredondo-Reyes, et al. "Analysis of Behavior-Driven Development: A Thematic Synthesis." _Programming and Computer Software_ 50(8):701–713, 2024. DOI [10.1134/S0361768824700713](https://doi.org/10.1134/S0361768824700713)

[^14]: Cui, J. "A Comparative Study on the Impact of Test-Driven Development (TDD) and Behavior-Driven Development (BDD) on Enterprise Software Delivery Effectiveness." arXiv:2411.04141, 2024. <https://arxiv.org/abs/2411.04141>

[^25]: "Empirical Study on GitHub Issue Report Templates." _IEEE_, 2024 (1,084,300 projects). <https://ieeexplore.ieee.org/document/10633301/>

[^26]: "An Empirical Analysis of Issue Templates on GitHub." _ACM TOSEM_, 2024. DOI [10.1145/3643673](https://doi.org/10.1145/3643673) · [Bilkent record](https://repository.bilkent.edu.tr/items/827062a2-fe0a-4566-9fea-4311b0266d6f) · [full text PDF](https://repository.bilkent.edu.tr/server/api/core/bitstreams/6f3affd5-571e-42e0-a6c2-952cf35c1bf2/content)

[^27]: Li, Z., et al. "A first look at bug report templates on GitHub." _Journal of Systems and Software_ 202, 2023. DOI [10.1016/j.jss.2023.111709](https://doi.org/10.1016/j.jss.2023.111709)

[^28]: Li, Z., et al. Issue-template adoption effects across 802 projects, 2020. [Bilkent companion record](https://repository.bilkent.edu.tr/items/a0c0b7c6-621e-4ca8-b17f-2843dfa072bf)

[^33]: Survicate. "Survey Completion Rate" (267,564 responses). <https://survicate.com/blog/survey-completion-rate/>

[^34]: Survicate. "How Many Questions Should Surveys Have?" (n=1,793 surveys). <https://survicate.com/blog/how-many-questions-should-surveys-have/>

[^35]: SurveyMonkey. "How Long Should a Survey Be? Insights and Best Practices." <https://www.surveymonkey.com/curiosity/survey_completion_times/>

[^36]: Song, Y., et al. "BURT: A Chatbot for Interactive Bug Reporting." _ICSE 2023_. [PDF](https://www.cs.wm.edu/~denys/pubs/23-icse23-burt-2.pdf) · [arXiv:2302.06050](https://arxiv.org/abs/2302.06050)

[^37]: "FeedAIde: Guiding App Users to Submit Rich Feedback Reports by Asking Context-Aware Follow-Up Questions." arXiv:2603.04244, 2026. <https://arxiv.org/abs/2603.04244>

[^41]: Galesic, M. & Bosnjak, M. "Effects of Questionnaire Length on Participation and Indicators of Response Quality." _Public Opinion Quarterly_ 73(2), 2009. DOI [10.1093/poq/nfp031](https://doi.org/10.1093/poq/nfp031) · Revilla, M. & Ochoa, C. "Ideal and Maximum Length for a Web Survey." _International Journal of Market Research_ 59(5), 2017. DOI [10.2501/IJMR-2017-039](https://doi.org/10.2501/IJMR-2017-039)

[^42]: Large-scale field-usage study of 650,000+ issue reports across open-source trackers (few fields influence resolution time; custom fields have little impact). Primary venue **not confirmed** — surfaced via [Semantic Scholar](https://www.semanticscholar.org/); treat as weaker corroboration of [^1].

[^43]: Duplicate bug report detection survey (hybrid retrieval + classifier state of the art; ~40% duplicate rates cited). _MDPI_, 2026. Exact record **not confirmed**; <https://www.mdpi.com/>

### [P] Practitioner / official docs

[^15]: Agile Alliance. "What is Given–When–Then?" Glossary, pub. 2015-12-17, mod. 2023-10-18. <https://agilealliance.org/glossary/given-when-then/>

[^16]: Fowler, M. "GivenWhenThen." 2013-08-21. <https://martinfowler.com/bliki/GivenWhenThen.html>

[^17]: Singer, R. _Shape Up: Stop Running in Circles and Ship Work that Matters._ Basecamp, 2019. <https://basecamp.com/shapeup> (see "Principles of Shaping" and "Set Boundaries")

[^18]: GitHub Docs. "Best practices for using GitHub Copilot to work on tasks." <https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/best-practices-for-using-copilot-to-work-on-tasks>

[^19]: Anthropic. "Prompting best practices." Claude Platform Docs. <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices>

[^20]: "Custom Instructions." Claude Code Best Practices (community guide). <https://muhammadusmangm.github.io/claude-code-best-practices/guides/custom-instructions/> · see also [CLAUDE.md best-practices guide](https://github.com/danielithomas/chealth/blob/main/docs/guide-claude-md-best-practices.md)

[^21]: "AI Coding Best Practices for GitHub Copilot (2026)." <https://cursor-alternatives.com/blog/ai-coding-best-practices-for-github-copilot/>

[^22]: Linear. "Concepts." Linear Docs. <https://linear.app/docs/conceptual-model>

[^23]: "Linear Review — Features, Pricing & Alternatives" (documents the fixed four issue types). <https://workflowautomation.net/reviews/linear>

[^24]: Oracle. "Work with Issues" — Visual Builder Studio docs (issue types: Task, Defect, Feature, Epic). <https://docs.oracle.com/en/cloud/paas/visual-builder/>

[^29]: GitHub Docs. "Syntax for issue forms." <https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms>

[^30]: GitHub Docs. "Syntax for GitHub's form schema." <https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema>

[^31]: github/docs issue #9004 — `id` placement quirk in the issue-form schema. <https://github.com/github/docs/issues/9004>

[^32]: GitHub CLI Manual. `gh issue create`. <https://cli.github.com/manual/gh_issue_create>

[^38]: Zimmermann, T. "The Value of Duplicate Bug Reports," in Oram, A. & Wilson, G. (eds.), _Making Software: What Really Works, and Why We Believe It_, ch. 24. O'Reilly, 2010. <https://www.oreilly.com/library/view/making-software/9780596808310/>

### [C]-primary (convention)

[^39]: Practitioner AC-format guidance: [Wazobia — Acceptance Criteria Formats](https://wazobia.tech/blog/acceptance-criteria-formats) · [Parallel — Given-When-Then Acceptance Criteria](https://www.parallelhq.com/blog/given-when-then-acceptance-criteria) · [Nora — Acceptance Criteria for User Stories](https://www.noratemplate.com/post/acceptance-criteria-for-user-stories)

[^40]: TestQuality. "How to Write Effective Gherkin Acceptance Criteria." <https://testquality.com/how-to-write-effective-gherkin-acceptance-criteria/> — ⚠️ source of the uncited "56% of requirements-phase defects" claim; **do not cite as evidence.**

Additional unlinked conventions: IETF RFC-style and Google design-doc "Non-goals" sections; Conventional Commits–style title prefixes; Agile/XP "spike" as a time-boxed research task.

---

### Link-integrity notes

- DOI links (`doi.org/…`) are constructed from DOIs stated in the sources and resolve to publisher pages; several sit behind paywalls (IEEE, ACM, Elsevier, Springer).
- Footnotes [^42] and [^43] point to search surfaces rather than confirmed primary records — these two claims are the weakest-sourced in the document and are flagged as such at the point of use.
- Footnotes [^2], [^4], [^24], [^27], [^28], [^38], and [^41] were reconstructed from DOI/publisher conventions rather than retrieved URLs; verify before citing externally.
