# Scope decisions

How to propose `project`, `client`, or `journal` scope when flagging a memory or journal candidate during phase 3 of the process mode.

The proposed scope token goes into the candidate flag (`[memory candidate: project]`, `[memory candidate: client]`). The user reviews at sign-off and overrides if your proposal is wrong. After crystallization the scope is sticky — no auto-promotion.

## Signals and their suggested scope

| Signal | Suggested scope |
|---|---|
| Fact bound to a single project's deliverable, contract, or technical decision | **project** |
| Subject named is a project-specific artifact (a deliverable, a contract clause, a pilot dataset) | **project** |
| Stakeholder relationship that holds across the client's projects (org chart, reporting line, communication style) | **client** |
| Environmental fact that applies to multiple of the client's engagements (tech platform, policy, IT environment) | **client** |
| Subject entity has already been referenced in 2+ projects' notes at this client | **client** |
| Comms cadence, decision-making process, or operating rhythm that applies broadly | **client** |
| Pattern that generalizes beyond this client — methodology, consulting craft, RFP defense, hypercare risk patterns | **journal** |
| Content uses generalizing language ("always", "every client", "we should", "this generalizes", "in general") | **journal** |
| Speaker is reflecting on the work rather than discussing it ("looking back...", "the lesson here is...") | **journal** |

## Conflict resolution

When signals conflict, suggest the **narrowest** scope. Project is the floor. Client and journal scope require positive evidence — recurrence, generalization, or explicit signals.

The reason: an over-narrow scope is easy to fix (the user just says "actually that's client" at sign-off). An over-broad scope creates noise in the wrong place and is harder to retract.

## Checking cross-project recurrence

Before suggesting client scope based on "subject already referenced in 2+ projects," verify by grepping the client root:

```bash
grep -l -r "<subject>" "<client-root>"/{pursuits,projects}/*/notes/
```

Two or more hits in distinct project directories triggers the heuristic. One hit is just *this* project.

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

Then re-render any inbound wiki-links. The skill explicitly does *not* offer auto-promotion in v1 — the audit cost of "did this record always live here?" outweighs the convenience. If this becomes painful, v2 can add a guarded `promote --from project --to client <record-id>` mode.

## Cross-scope references are fine

A project's notes can wiki-link to a client-scope record. A client record can list project note ids in `source_refs`. The record's *home* (which `_memory/` directory it lives in) is what defines its scope — not its references.

This matters for the "client fact referenced by every project" case: the record lives at the client root once, and every project's notes link to it. No duplication.
