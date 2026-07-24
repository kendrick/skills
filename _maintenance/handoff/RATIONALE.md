# Handoff Skill Rationale

## Why This Skill Exists

Conversation compaction and session boundaries can lose task detail and intent. A handoff file captures the open tasks and the state that belongs with them. It is never automatic because the user decides when to hand off, just as they decide when to commit or deploy.

## Why These Upstreams Are Merged

harpb provides the write and resume loop: three phases, sortable filenames, task restoration, and a template that includes verification. It also carries internal repository rules that do not belong in a public skill. mattpocock supplies two useful constraints: link to existing artifacts instead of copying them, and tell the next session which skills may help. It does not describe how a later session reads and resumes the handoff.

## Decision Ledger

| Decision | Source | Reason |
| --- | --- | --- |
| Three write and resume phases, sortable names, task restoration, and verification | harpb | They make the handoff usable at both ends. |
| Link to existing artifacts and suggest follow-on skills | mattpocock | The document stays short without hiding useful context. |
| Remove the dev-root exception and repeated root-resolution blocks | local | Those rules are private to harpb's environment and add noise. |
| Store handoffs in `.agents/handoff/` and rebuild tasks through the host's available tool | local | The workflow can run in Claude Code, Codex, and Copilot without depending on one host's storage or task API. |
| Keep the reviewed local merge in `template/SKILL.md`, then render `handoff/SKILL.md` | local | Raw upstream files cannot express the cross-harness decisions. The template preserves those decisions and lets the shipped file be checked for drift. |
| Use a Node maintenance core with Bash and PowerShell wrappers | local | Maintainers can run the same check on Windows, macOS, and Linux. |
| Keep `disable-model-invocation` as a Claude Code enhancement | local | Other hosts may not enforce it, so the skill body also explains when the workflow applies. |
| Keep delivery files separate from maintenance files | local | Installers should see the skill, not the update machinery or its history. |

Update this document whenever a sync changes one of these decisions. `PROVENANCE.md` records the run history and any deliberate local deviations.
