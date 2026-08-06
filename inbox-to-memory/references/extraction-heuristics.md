# Extraction Heuristics

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

Each tension carries stakes and a disposition:

```
- [tension: deferred] Andrew wants Phase 1 scoped tighter; Anece wants more pilot coverage. | stakes: the pilot either proves the pattern or proves nothing, and nobody has said which | open question: phase-one-scope
```

Stakes are one clause naming what breaks if this goes unresolved. Without them, tensions get ranked by how heated the exchange was rather than by what they cost, and the quiet ones lose every time.

The disposition is `resolved`, `deferred`, or `unacknowledged`.

**Unacknowledged is the highest-value class.** A tension everyone named and deliberately parked renders identically in prose to one nobody in the room noticed, and the second kind is the one you pay for. If the disagreement is real but nobody in the transcript treats it as a disagreement, that is unacknowledged, and saying so is most of the value of writing it down.

A deferred tension names a matching open question in the same note, one to one. Deferring something should open a thread rather than end one. A resolved tension records how it landed inline.

## Contradictions Against Memory

A tension is disagreement inside the room. A contradiction is disagreement with something the scope already agreed to and wrote down, which is why it needs memory read first (phase 2.5) and gets its own flag:

```
- [contradicts accepted: [[freeze-window-owned-by-ops-ocPwdpeY0a|freeze window ownership]]] Priya said the delivery lead signs off on freeze exceptions now. | claims: exceptions are Ops' call and always have been
```

Flag it only when the statements can't both be true. Three things get mistaken for contradictions and none of them are:

- **Newer detail on the same claim.** The record says exceptions are Ops' call; someone adds that Ops routes them through a delivery lead first. That's an amendment waiting to happen rather than a conflict, and flagging it as one lands in the same place anyway, a step later.
- **Different subjects wearing the same word.** Half the false positives here are vocabulary. Two people saying "region" about the same system are frequently discussing two different boundaries.
- **Someone being wrong out loud.** A participant misremembering what was agreed is worth a note, not a challenge to the record. The room's memory is what the record is for.

Write `claims:` from the record's own words. Paraphrasing it into your summary of the new statement is how two positions that never disagreed end up looking incompatible.

Nothing gets flagged against a `proposed` record. Disagreeing with something nobody has agreed to yet is just the discussion that produces it.

## Decisions

A quote that settles something is a decision, not just a good quote. When you pull a decisional quote into Notable Quotes, write the decision itself here too:

```
- [decision: two-way] Freeze end date is fixed at 2026-02-28. | committed: @Marcus Dell | discarded: waiting for the Q1 close to confirm, on the grounds that the written Finance date already is the confirmation
```

Record what got ruled out and the reason someone gave at the time. Everything else about a decision is recoverable from the transcript; the discarded alternatives are not, and they are what tell you six months later whether the reason still holds.

Mark reversibility honestly. `two-way` is a decision you can walk back in a conversation. `one-way` is one you can only walk back with a migration, a renegotiation, or an apology.

**A decision that is still hedged does not belong here.** "Leaning toward," "probably," and "unless someone objects" are working-state, not settled fact. Route them to `working-state.md` per [scope-decisions.md](scope-decisions.md). Writing a hedge down as a decision is how a room's tentative direction becomes something nobody feels able to reopen.

## Open Questions

An open question is a contract, not a topic. Each one carries a resolver, what it blocks, and a default naming what happens if nobody ever answers:

```
- [open question: phase-one-scope] Does Phase 1 include the pilot's second cohort? | resolver: @Anece | blocks: the Phase 1 SOW | default: the SOW ships with the wider scope and the margin absorbs it
```

Phrase it as **an answerable question, not a topic**. "Pilot scope" is a topic and you can never tell whether it closed. "Does Phase 1 include the second cohort?" is answerable, and an answer visibly ends it.

The `blocks` field separates idle curiosity from something holding up work. When nothing is waiting on it, say `informational` rather than inventing a dependency.

The `default` field is the forcing function. A question with no stated consequence drifts, and the consequence is usually the thing that gets someone to answer.

The slug is lowercase kebab, two to five words, and identical in every note asking the same question. That stability is what makes recurrence visible: the fourth time it comes up, you can see it is the fourth time and bring a number to whoever can close it.

Never invent a missing field. `@unknown` is a true answer; a guessed resolver sends someone to chase a person who was never going to answer.

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

## Cross-note Relationships

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

## Stopping Rule

If a section is empty after honest extraction, leave it empty rather than padding. A note with no Tensions is fine. A note with no Notable Quotes probably wasn't worth grooming as a transcript and may be better written as a freeform note.
