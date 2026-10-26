---
schema: 2
id: '{{nanoid}}'
date: '{{YYYY-MM-DD}}'
type: '{{one of the type enum in the scope CLAUDE.md}}'
summary: '{{one or two sentences, enough to skip opening the file}}'
attendees: []
tags: []
topics: []
entities: []
# source_file: attachments/<filename>          # binary-extracted notes only
# raw_file: raw/<id>.md                        # whenever the raw text is in the notes/raw/ sidecar
# transcript_corrections: [Shachi <- Saatchi]  # applied aliases, extracted sections only
open_questions: 0
resolved_questions: 0
deferred_tensions: 0
unpromoted_candidates: 0
# related: [extends::<note-id>]                # only on an explicit reference, never on topical similarity
---

## Notable Quotes

<!--
6-12 quotes, prioritizing surprising, contradictory, or unstated-assumption-revealing statements.
Anchor each with 4-6 verbatim words from the raw text. The snippet is what survives
a reflow; the line number is a convenience and optional, and counts lines in the
raw_file sidecar when the note has one.

1. "<quote>" — <speaker> (raw: "<4-6 verbatim words>" L<line>)
2. ...
-->

## Tensions

<!--
Places where speakers disagreed, hedged, or contradicted themselves or each other.
Unacknowledged is the disposition nobody in the room was tracking, and the one
you pay for. Every deferred tension names an open question in this note.

- [tension: deferred] <description> | stakes: <what breaks if this stays open> | open question: <slug>
- [tension: resolved] <description> | stakes: <clause> | resolved: <how it landed>
- [tension: unacknowledged] <description> | stakes: <clause>

A contradiction against an accepted record comes out of phase 2.5 and carries both
halves, so the disagreement can be settled without opening the record. Dismissing
one keeps the flag and adds the reason; it never gets deleted.

- [contradicts accepted: [[<record>|<label>]]] <what this input says> | claims: <what the record says>
- [contradicts accepted: [[<record>|<label>]]] <statement> | claims: <what the record says> | dismissed: <reason, and who decided>
-->

## Decisions

<!--
What got settled, and what got ruled out to settle it. The discarded alternatives
are the payload: six months on, they are what tell you whether the reason still
holds. A decision still being hedged goes to working-state, not here.

- [decision: two-way] <what was decided> | committed: @<name> | discarded: <alternatives, with the reason given at the time>
-->

## Stated Assumptions

<!-- Explicit, said out loud as fact. -->

## Unstated Assumptions

<!-- Implicit, inferred, or "agreed without discussion." -->

## Open Questions

<!--
An answerable question, not a topic. The slug is lowercase kebab, 2-5 words, and
identical across every note asking the same thing. Never invent a missing field:
@unknown is a true answer, a guessed resolver is not.

- [open question: <slug>] <question>? | resolver: @<name or unknown> | blocks: <decision, or informational> | default: <what happens if nobody answers>
- [open question resolved: <slug>] <question>? | resolved: <the answer, and who gave it>
-->

## Action Items / Memory Candidates

<!--
Action items:
- [ ] @<owner> (priority: high|medium|low) — <task> (raw: L<line>)

Memory candidates (inline, in the section where the triggering passage lives):
- [memory candidate: project] <claim>
- [memory candidate: client] <claim>
- [memory candidate: update existing [[<filename>|<short-name>]]] <amended claim>
- [journal candidate: <generalized pattern>]
-->

## Raw Content

<!-- Always last. A note with raw text sets raw_file and holds here only the pointer line from the "Raw Sidecar" section of machine-contracts.md; the verbatim original (text sources) or extracted text (binary sources) lives in notes/raw/<id>.md. A directly authored note has no raw text, so it leaves this section empty and carries no raw_file. -->
