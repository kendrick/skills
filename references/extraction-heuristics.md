# Extraction heuristics

What to pull out of an inbox file when grooming it. Applied during phase 2 of the process mode.

These heuristics adapt patterns from the user's prior `transcript-to-knowledge-base` skill, collapsed into one groomed note rather than four.

## Notable Quotes

Pull 6-12 quotes per file. Skew the selection toward statements that are:

- **Surprising** — revealed information the speaker didn't have to share, or contradicted what you'd expect from their role.
- **Emotionally charged** — frustration, enthusiasm, hesitation. Often signals an unstated assumption or unspoken constraint.
- **Self-contradicting** — the speaker said the opposite earlier in the same session, or hedged immediately after asserting something.
- **Unstated-assumption-revealing** — the line only makes sense if you assume X, and X was never said out loud.
- **Decisional** — a moment where the conversation pivoted, an option was discarded, or someone committed.

What to skip: throat-clearing, scheduling logistics, polite pleasantries, repeated phrasing of the same point. A quote that just summarizes what was said elsewhere has no extra value.

Format each quote with the speaker and a line ref back to Raw Content:

```
1. "We just don't have headcount to support a third pillar." — Andrew (raw: L142)
```

## Tensions

A tension is any place where the conversation wasn't aligned:

- Two participants explicitly disagreed.
- One participant hedged (then walked back) or contradicted themselves.
- Stated agreement masked unspoken misalignment (look for "yeah but" or topic-changes after a hard question).

Document each tension as one bullet with the participants and a line ref:

```
- Andrew wants Phase 1 scoped tighter; Anece wants more pilot coverage in scope. (raw: L201-L218)
```

If a tension was resolved in-session, note the resolution. If it was deferred, that's an Open Question.

## Stated vs Unstated Assumptions

**Stated**: someone said it out loud as fact. ("We agreed last week the platform is Databricks.")

**Unstated**: nobody said it, but the conversation only works if everyone believed it. ("Andrew kept assuming all 15 models would fit one MDM pattern — never asked, but his recommendations all presupposed it.")

Stated assumptions are easy to verify later. Unstated assumptions are where projects go sideways. Surface them with attribution if possible, otherwise generically:

```
## Unstated Assumptions

- Everyone in the room assumes the SAP migration is on the same timeline as the Atlas pilot. Never said, but every scope discussion presumed it.
```

## Action Items

Capture with:

- **Owner**: who, by name. If unclear, mark `@unknown` and treat as an Open Question.
- **Priority**: high (blocks other work), medium (needs to happen this sprint), low (eventually).
- **Source ref**: line in Raw Content where the item was committed.

```
- [ ] @Andrew (priority: high) — share the EDO Operating Architect chart by EOD Friday (raw: L312)
```

If an action item was implied but not committed, phrase it as an Open Question, not an Action Item.

## Cross-note relationships

If the content explicitly references — or implicitly extends — a known note in the same scope, tag the relation:

- **confirms** — this note re-validates a claim from the referenced note.
- **contradicts** — this note's content disagrees with the referenced note (worth surfacing as a Tension too).
- **extends** — adds new information to a topic the referenced note introduced.
- **introduces** — this is the first time a topic is documented (no prior reference exists).

Add the relation to frontmatter:

```yaml
related:
  - note_id: bStpwliejr
    relation: extends
```

Only populate `related` when the content makes the link explicit. Don't speculate.

## Stopping rule

If a section is empty after honest extraction, leave it empty rather than padding. A note with no Tensions is fine. A note with no Notable Quotes probably wasn't worth grooming as a transcript and may be better written as a freeform note.
