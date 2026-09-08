# The Seven Fields

Read this while filling an entry from its Source excerpt. The template is a set of slots the transcript fills or leaves empty, and an empty slot is written down as empty.

One rule governs all seven: **only what the room stated goes in.** Stated means a participant said it in this entry's excerpt, and the excerpt is the whole evidence base — not the ticket's title, not the rest of the session, not what the feature obviously ought to do. A slot the room never reached stays empty and gets its `- not discussed: <section>` line under Open questions. That line is the deliverable for a gap; a plausible sentence written in its place is the failure this skill exists to prevent, because a reader cannot tell an invented acceptance criterion from a quoted one.

[`staging-format.md`](staging-format.md) owns the line shapes and the anchor regex. [`tracker-contract.md`](tracker-contract.md) owns where each field lands in Jira and what happens when the mapping is missing — read the fate of a field there, and nowhere else.

## Context

What the ticket is about and why it came up: the problem, the customer, the situation the room described. Prose, not bullets.

Stated: the room described a problem or a situation. Paraphrasing is fine here — this is the one field whose job is to be readable rather than quotable, so it carries no anchor.

## Acceptance criteria

The outcomes that make the ticket done, one per line, each anchored to the words that produced it.

Stated: someone named a condition, a number, a behavior, or a case. **Describe outcomes, not implementation.** Where the room only discussed implementation — a table, a queue, a library — write the outcome that implementation serves and quote the implementation itself under Open questions, where a reader can see it was the room's idea and not a decision this file made.

Never derive a criterion. A criterion that follows logically from what was said is still not something anyone said, and the anchor requirement is the check: a line with no four-to-six-word snippet behind it in this excerpt does not belong in this section.

## Out of scope

What the room ruled out, one bullet each.

Stated: someone drew a boundary — "not this release", "we're not touching X", "that's a separate ticket". Silence about a topic is not a boundary, so a topic nobody mentioned belongs nowhere in this section.

## Dependencies

Other issues this one waits on, one key per line, anchored.

Stated: the key appears in the entry's `mentions:` list, or a participant made an explicit blocked-by statement about it. A key someone said in passing while discussing something else is a mention, not a dependency; the blocking has to have been claimed out loud. A dependency becomes a real Jira issue link, so a wrong one costs somebody a conversation.

## Goal

The product outcome this ticket serves, one anchored line.

Stated: a product owner named a goal. A goal inferred from the acceptance criteria is not stated, and neither is an engineer's guess about why the work matters. This field is empty far more often than it is filled.

## Open questions

Everything the room left hanging, one bullet each: unresolved questions, decisions deferred, the implementation quoted out of Acceptance criteria, and every `- not discussed: <section>` line.

Stated: the question was asked and went unanswered, or the room explicitly deferred. The `not discussed` lines are mechanical rather than judged — one per empty content section, always.

## Provenance

Where this entry came from: source, session, segment. `segment.py` writes it and it is not edited by hand. Its values are checked against the frontmatter, so an edit here fails validation rather than travelling to Jira.
