---
schema: 2
id: '{{nanoid}}'
memory_type: PolicyRule
title: '{{Title, usually imperative}}'
status: '{{proposed | accepted}}'
date: '{{YYYY-MM-DD}}'
# effective_from: '{{YYYY-MM-DD}}'
# effective_to: null
last_confirmed: '{{YYYY-MM-DD}}'
source_refs: ['{{note-id}}']
applies_to: []
owners: []
tags: []
related: []
# supersedes: <id-of-old-rule>
# superseded_by: null
---

# {{title}}

## Rule Statement

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

## Known Exceptions

<!-- Wiki-links to any Exception records that have been formally granted, e.g. [[exception-id|short-name]]. -->
