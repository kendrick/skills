# Handoff Skill Rationale

## Why This Skill Exists

`/compact` spends context summarizing an entire conversation, and it can lose the task detail and intent that matter when work resumes. A handoff file captures the open tasks and the state that belongs with them. It is never automatic because choosing when to hand off is the user's decision, like choosing when to commit or deploy.

## Why These Upstreams Are Merged

harpb provides the write and resume loop: three phases, sortable filenames, task restoration, and a template that includes verification. It also carries internal repository rules that do not belong in a public skill. mattpocock supplies two useful constraints: link to existing artifacts instead of copying them, and tell the next session which skills may help. It does not describe how a later session reads and resumes the handoff.

## Decision Ledger

| Decision | Source | Reason |
| --- | --- | --- |
| Three write and resume phases, sortable names, task restoration, and verification | harpb | They make the handoff usable at both ends. |
| Link to existing artifacts and suggest follow-on skills | mattpocock | The document stays short without hiding useful context. |
| Remove the dev-root exception and repeated root-resolution blocks | local | Those rules are private to harpb's environment and add noise. |
| Ship a skill with `disable-model-invocation` instead of a command file | local | One installable artifact works with `npx skills`, stays user-invoked, and adds no trigger context. |
| Keep delivery files separate from maintenance files | local | Installers should see the skill, not the update machinery or its history. |

Update this document whenever a sync changes one of these decisions. `PROVENANCE.md` records the run history and any deliberate local deviations.
