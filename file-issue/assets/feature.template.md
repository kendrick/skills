<!--
Feature template. The ordering enforces one rule above all: the problem gets
stated before any solution. A feature request that opens with the solution has
already thrown away the information a reviewer needs to evaluate it.

[gate] sections block the write guard. Strip every HTML comment before
rendering the draft.
-->

# <title>

<!--
Name the capability and who it serves. Match any title prefix convention the
harvest observed.
-->

## Problem

<!--
[gate] What is broken, missing, or expensive today — in terms of the person
hitting it, not the implementation. Who hits it, how often, what they do
instead right now.

If this section reads like a description of the solution, it is not done.
-->

## Proposed Behavior

<!--
What the system should do once this exists. Behavior, not design — unless the
implementation is genuinely constrained, in which case say why.
-->

## Acceptance Criteria

<!--
[gate] At least one, and every one binary. "Works well" and "is performant" are
not criteria; a reviewer cannot fail them.

Checklist is the default. No study compares acceptance-criteria formats on
ambiguity, testability, or defect rates — the notation is convention, the
falsifiability is what the evidence actually supports.

Escalate to Given/When/Then only when the criterion describes multi-step
stateful behavior or a user journey, AND the repo has tooling that executes the
scenarios (Cucumber, Behave, Playwright-BDD). For rules, validation,
permissions, and non-functional criteria, checklist wins on speed.

Keep referential ambiguity out — that is the mechanism measured to hurt
downstream. "It should reject them" leaves both pronouns open.
-->

- [ ]
- [ ]

## Non-Goals

<!--
[default, convention] Practitioner-backed (Shape Up's "no-gos"), not measured.
Under-specified work grows because nothing defines where it stops.

Include it whenever scope is ambiguous or the issue is agent-targeted, where it
doubles as a bound on the change surface. Drop the heading when the scope is
genuinely self-evident.
-->

## For a Coding Agent

<!--
Include only when the issue will be assigned to a coding agent — then every
line is a gate. Underspecification is the measured failure mode: 38.3% of
SWE-bench samples were flagged underspecified, and filtering them roughly
doubled the measured resolve rate.

Enough spec to act, not so much that the solution is dictated — leakage
distorts outcomes in the other direction.
-->

- **Verify with:** <the exact command>
- **Setup:** <deps, versions, env vars, or the file that documents them>
- **Start here:** <file and module paths>
- **Done when:** <binary condition, including whether tests are required>
- **Out of scope:** <what not to touch>
