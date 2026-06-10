# Scope decisions

How to propose `project`, `client`, or `journal` scope when flagging a memory or journal candidate during phase 3 of the process mode.

The proposed scope token goes into the candidate flag (`[memory candidate: project]`, `[memory candidate: client]`). The user reviews at sign-off and overrides if your proposal is wrong. After crystallization the scope is sticky — no auto-promotion.

## Signals and their suggested scope

| Signal                                                                                                            | Suggested scope |
| ----------------------------------------------------------------------------------------------------------------- | --------------- |
| Fact bound to a single project's deliverable, contract, or technical decision                                     | **project**     |
| Subject named is a project-specific artifact (a deliverable, a contract clause, a pilot dataset)                  | **project**     |
| Stakeholder relationship that holds across the client's projects (org chart, reporting line, communication style) | **client**      |
| Environmental fact that applies to multiple of the client's engagements (tech platform, policy, IT environment)   | **client**      |
| Subject entity has already been referenced in 2+ projects' notes at this client                                   | **client**      |
| Comms cadence, decision-making process, or operating rhythm that applies broadly                                  | **client**      |
| Pattern that generalizes beyond this client — methodology, consulting craft, RFP defense, hypercare risk patterns | **journal**     |
| Content uses generalizing language ("always", "every client", "we should", "this generalizes", "in general")      | **journal**     |
| Speaker is reflecting on the work rather than discussing it ("looking back...", "the lesson here is...")          | **journal**     |

## Conflict resolution

When signals conflict, suggest the **narrowest** scope. Project is the floor. Client and journal scope require positive evidence — recurrence, generalization, or explicit signals.

The reason: an over-narrow scope is easy to fix (the user just says "actually that's client" at sign-off). An over-broad scope creates noise in the wrong place and is harder to retract.

## Checking cross-project recurrence

Before suggesting client scope based on "subject already referenced in 2+ projects," verify by grepping the client root:

```bash
grep -l -r "<subject>" "<client-root>"/{pursuits,projects}/*/notes/
```

Two or more hits in distinct project directories triggers the heuristic. One hit is just _this_ project.

## What never goes to journal

The journal is for portable patterns, not client gossip or methodology speculation. Do not propose journal scope for:

- Single-instance observations ("Andrew was frustrated today") — that's project or client context, depending.
- Anything bound to a specific person, deal, or deliverable.
- Anything that wouldn't make sense to read 18 months from now without remembering the source.

If the source moment is too specific to generalize, leave the `[journal candidate: ...]` flag in place but mark it as "considered, not crystallized" by not promoting it at sign-off. The flag itself is useful provenance.

## Post-crystallization moves

If a project record later turns out to belong at client scope (or vice versa), move it by hand:

```bash
mv <source-path>/<record>.md <target-path>/
```

Then re-render any inbound wiki-links. The skill explicitly does _not_ offer auto-promotion in v1 — the audit cost of "did this record always live here?" outweighs the convenience. If this becomes painful, v2 can add a guarded `promote --from project --to client <record-id>` mode.

## Cross-scope references are fine

A project's notes can wiki-link to a client-scope record. A client record can list project note ids in `source_refs`. The record's _home_ (which `_memory/` directory it lives in) is what defines its scope — not its references.

This matters for the "client fact referenced by every project" case: the record lives at the client root once, and every project's notes link to it. No duplication.

## working-state.md, `_memory/`, and `patterns-journal/` are different homes

A scaffolded project has three places candidate-shaped content can live, and choosing wrong creates duplication or invisibility. The split:

- **`working-state.md`** is the narrative layer. Decisions in motion, open questions, active hypotheses. Updated each session. Content here is fluid — it shifts as discovery unfolds.
- **`_memory/`** is the structured layer. Crystallized decisions, stable facts, standing rules. Queryable via Glob/Grep. Content here is durable — once a record lands, it stays (with `status` transitions) rather than getting rewritten.
- **`patterns-journal/journal.md`** is the engagement-internal staging ground for cross-cutting observations that *might* generalize. Reverse-chronological. Loose, tagged. Promoted to the cross-client journal only after a deliberate weekly review.

When proposing a memory candidate during inbox grooming:

- If the decision is still in flight (the user is talking it through, not announcing it as done), don't crystallize. Suggest it lands in `working-state.md` instead. Phrase the candidate as `[working-state candidate: this is in motion, leave in working-state]` so the user knows you considered crystallization and decided against.
- If the claim is durable and specific to this client, propose `[memory candidate: project|client]` per the table above.
- If the observation might generalize beyond this client, propose `[journal candidate: <pattern>]`. This routes to the cross-client journal at sign-off — fast path.
- If the observation is interesting but not yet pattern-shaped (one data point, not three), there's no candidate flag. The user can hand-log it to `patterns-journal/journal.md` with `#pattern-emerging`. The patterns journal is a slower path: it accumulates observations the user reviews weekly, with promotion to the cross-client journal happening only after deliberate review.

The two paths to the cross-client journal:

```
inbox grooming → [journal candidate: ...] flag → user sign-off → cross-client journal entry
                                                                      ↑
patterns-journal/journal.md → weekly review → deliberate promotion ───┘
```

Both end up in the same place. The inline flag is for moments where the generalization is immediately obvious. The journal is for slow-cooked patterns that need accumulation before promotion is honest.

## When to crystallize vs leave in working-state

The hardest call. A signal that something is ready to crystallize from `working-state.md` into `_memory/decisions/`:

- The decision is referenced unchanged in two or more sessions after it was made.
- A different session decision builds on it (treats it as settled).
- The user describes it externally to someone else as "we decided X."

A signal it's not ready:

- The user is still using hedging language ("we're leaning toward...", "the working assumption is...").
- The rationale is still evolving session-over-session.
- The decision is contingent on a discovery that hasn't happened yet.

When in doubt, leave it in working-state. Crystallizing prematurely creates churn — the record gets `status: superseded` quickly, and the supersession chain grows noise.
