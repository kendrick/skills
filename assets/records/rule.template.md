---
id: { { nanoid } }
memory_type: Rule
title: '{{Title — usually imperative}}'
status: { { proposed | accepted } }
date: { { YYYY-MM-DD } }
# effective_from: YYYY-MM-DD
# effective_to: YYYY-MM-DD | null
source_refs: [{ { note-id } }]
applies_to: []
owners: []
tags: []
related: []
# supersedes:
# superseded_by:
---

# {{title}}

## Rule statement

<!-- Exact text of the rule. Short, declarative, testable when possible. -->

## Enforcement

{{required | recommended | advisory}}

<!--
- required: violations should block work or trigger escalation.
- recommended: violations should be flagged but not blocking.
- advisory: guidance; no enforcement mechanism.
-->

## Rationale

<!-- Why this rule exists. The incident, constraint, or stakeholder ask that motivated it. -->

## Known exceptions

<!-- In lightweight mode there is no separate Exception type. List exceptions inline here as bullets: scope, justification, who approved, expiry. If an exception is substantive enough to deserve its own record, write it as a Decision whose decision question is "should we deviate from this rule for <scope>?" and link it here. -->
