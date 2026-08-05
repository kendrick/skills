---
name: file-issue
description: "File one GitHub issue: a bug report, feature request, task, or spike, created with `gh`. Use when the user wants to file or open an issue, report a bug, request a feature, write up a chore or a spike, turn a half-formed complaint into something tracked, or write an issue a coding agent can pick up cold. Files exactly one issue: to slice a spec or plan into many linked tickets, use to-tickets instead. Never edits, closes, triages, or ranks existing issues."
argument-hint: '[what the issue is about | --deep | --fast | --dry-run]'
---

# file-issue

Write one issue a **stranger** can act on: no conversation context, no tacit knowledge of the codebase, no chance to ask a follow-up question. That stranger is often a coding agent, which is the same test with a harder bar. Structure is the easy half and most tooling stops there — every gate in Step 6 is a content gate.

Where a step names a shell command, treat it as the intent and use your native shell or file tools. `gh` executes anything that touches GitHub.

Resolve once per invocation:

- **ASK** — the text following the invocation. (Claude Code exposes this as `$ARGUMENTS`; on other agents it is the rest of the user's message.) When ASK is empty, the issue comes from the conversation so far; name which part you took it from before drafting, so a wrong read is cheap to correct.
- **Flags**, stripped from ASK before anything else reads it: `--deep` pins Depth 2, `--fast` pins Depth 0, `--dry-run` renders and never posts, `--yolo` skips the confirmation.

## Step 1 — Detect and Harvest

Mechanical, no judgment, before any question.

Preflight `gh auth status`. Missing or unauthenticated → say so plainly and continue in dry-run only. A rendered draft must never read as a filed issue.

Template ladder, first hit wins:

1. `.github/ISSUE_TEMPLATE/*.yml` — issue forms. Read [references/issue-forms.md](references/issue-forms.md) and fill the declared fields.
2. `.github/ISSUE_TEMPLATE/*.md` — legacy templates. Same handling.
3. `ISSUE_TEMPLATE/` at the repo root, then the org-level `.github` repo, which supplies defaults to every repo lacking its own.
4. Nothing found → this skill's own templates in `assets/`.

The detected template's sections are the issue's sections, exactly. If the repo asks for four, the issue has four — a repo's own conventions outrank anything you would invent.

Harvest at the same time. This is where the agent-readiness gate gets its answers without spending a question on them:

| Source | Facts |
| --- | --- |
| `gh issue list --limit 10 --state all` | label taxonomy, title prefixes, task-list use, whether issues get assigned to agents |
| `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md` | build, test, and convention commands |
| Manifest scripts (`package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) | the exact verification command |
| `.github/workflows/`, `CODEOWNERS` | repo complexity |
| `git shortlog -sne --since='90 days ago'` | contributor count |

**Done when:** the template source is named and every harvest row holds a concrete value or an explicit `absent`.

## Step 2 — Assign Depth

Arithmetic, announced, overridable in one word.

| Depth | Fires when |
| --- | --- |
| **0** | Mechanical, single site, no behavior change — typo, dead link, dependency bump, comment fix. |
| **1** | Everything not caught by 0 or 2. The default. |
| **2** | Any one of: a breaking change; the ask names two or more components; it touches auth, security, or PII; the issue is destined for a coding agent; the repo has `CODEOWNERS` or ≥5 contributors in the last 90 days. |

Repo complexity sets a floor rather than a ceiling. A solo repo with no CI and no templates caps at Depth 1 unless the user forces higher. A repo with `CODEOWNERS` never runs Depth 0 on anything but a genuine typo.

Pick the issue type on the same signals: a defect in existing behavior → bug; new or changed capability → feature; anything else that ships → task; a question to answer rather than work to do → spike. Map "enhancement" and "improvement" to feature unless the repo's labels distinguish them.

Announce the result in one line — `Depth 1 — 4 gaps to fill.` — then keep going. The announcement is the user's correction point.

Depth 2 additionally earns a targeted code probe: locate the component the ask names and capture real file paths. Those paths become the issue's file pointers, and they sharpen every question that follows.

**Done when:** depth and issue type are both fixed, and the depth line has been said out loud.

## Step 3 — Elicit

**In:** the chosen template's slot list, each slot marked filled or empty; the depth ceiling.
**Out:** the same list, where every slot holds a value, an explicit `n/a — <reason>`, or `unknown — asked, declined`. No blanks.
**Exit:** the moment the rubric in Step 6 becomes satisfiable. Not when a question budget runs out.

Depth 0 asks nothing. Draft straight from ASK.

Depth 1 asks at most five questions, and only against slots the ask left empty. Treat five as a ceiling, not a target. Depth 2 keeps going past the rubric into edge cases, failure modes, non-goals, and how you would know this was done wrong.

Rules that hold at every depth:

- One question at a time. Batched questions read as a form, and forms get form-quality answers.
- Every question names the empty slot it fills. No named gap, no question.
- Front-load by evidence value: steps to reproduce first, then error output, then observed-versus-expected. Reproduction steps are what developers rank highest and what reporters find hardest to supply, so ask for the expensive thing while attention is highest.
- Every question is skippable. A declined answer resolves its slot to `unknown` and the interview moves on.
- Never re-ask what Step 1 harvested. The verification command comes from the manifest, not from the user.

Run the interview yourself. Delegating it to an external interrogation skill loses the depth governor, which is the whole point, and a client repo may not have that skill installed anyway.

**Done when:** every slot is a value, an `n/a`, or an `unknown`.

## Step 4 — Stop If This Is a Spec

Some asks are not one issue. Check before drafting:

- **≥7 independent acceptance criteria**, or
- **≥4 distinct components** named across the answers.

Either one alone fires. On a fire, stop at a recommendation: name the spec path (`/to-spec` then `/to-tickets` where installed, otherwise write a spec first and come back per slice) and hand over what the interview already produced so none of it is wasted. Neither compress the ask into one bloated issue nor start decomposing it here.

**Done when:** the ask is confirmed to be a single issue, or the handoff has been offered and nothing has been posted.

## Step 5 — Draft

Fill the detected template. With no template, read exactly one file from `assets/` — `bug`, `feature`, `task`, or `spike` — and keep its section order, which reflects measured developer importance rather than convention.

Strip the templates' HTML comments; they are authoring guidance and do not belong in a posted issue. Drop any heading whose slot resolved to `n/a` — an empty heading is worse than an absent one.

Title follows {component} + {wrong behavior} + {trigger}, matching whatever prefix convention the harvest observed. Acceptance criteria default to a falsifiable checklist; escalate to Given/When/Then only for multi-step stateful behavior in a repo whose tooling actually executes scenarios.

**Done when:** a complete issue body exists, with no placeholders and no orphaned headings.

## Step 6 — Self-Check

Gates block. Defaults get surfaced and never block.

Gates:

1. **Stranger test** — a stranger can act on this draft with no follow-up question available.
2. **Runnable reproduction** — commands or clicks a stranger can follow on a clean checkout, not prose gestures. Bugs only.
3. **Observed and expected stated separately.** Bugs only.
4. **Error output** where the failure produces any. Bugs only; drop it for silent visual defects rather than padding.
5. **At least one falsifiable acceptance criterion.** All types. A criterion a reviewer cannot fail is not one.
6. **Agent-readiness**, when the issue is agent-targeted: single-interpretation problem statement, binary criteria, a runnable verification command, environment pointers, file hints, explicit done-criteria, non-goals.

Defaults: non-goals when scope is ambiguous; Ko-structured title; labels matching observed repo convention; environment metadata.

Say which items are convention rather than evidence as you surface them, so a user overriding one knows what they are overriding. [references/evidence-map.md](references/evidence-map.md) carries the traceability.

A failing gate means fix the draft, or ask the single question that closes it. Never quietly downgrade a gate to a warning.

Where the repo's label taxonomy has a ready-for-agent-style label, apply it only after gate 6 passes. The label should mean something.

**Done when:** every gate passes and every unmet default has been named.

## Step 7 — Write Guard

Check for duplicates first, with `gh search issues` against the title terms and any error signature. Rank candidates by error-signature overlap, then title and description similarity, then shared component.

Surface what you find and let the user choose: comment on the existing issue, or file new. Never block — duplicates routinely carry information the original lacks, and refusing them teaches reporters to stop contributing. When the new draft has a better reproduction than the suspected original, say so and recommend appending.

Then render the full issue as markdown, show it, and wait for explicit confirmation before `gh issue create`. `--dry-run` renders and stops. `--yolo` skips the confirmation but not the self-check.

Creation only. Never edit, close, relabel, or reassign an existing issue; when that is what the user wants, say that this skill does not do it.

**Done when:** the issue URL has been reported, or the draft has been rendered under `--dry-run`, or the user chose to comment on an existing issue instead.

## Further Reading

- [references/issue-forms.md](references/issue-forms.md) — issue-form YAML schema, template resolution order, `gh issue create` mechanics
- [references/evidence-map.md](references/evidence-map.md) — every gate and default traced to its claim and evidence tier
- [assets/](assets/) — `bug`, `feature`, `task`, and `spike` bodies, used only when the repo has no template of its own
