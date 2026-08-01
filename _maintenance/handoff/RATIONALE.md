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
| Rebuild tasks through whatever task or plan tool the host exposes | local | The workflow runs in Claude Code, Codex, and Copilot without depending on one host's task API. |
| Store handoffs in the OS temp directory, not the repository | local, converging with mattpocock | A handoff is session scratch, not a project artifact. Temp storage keeps it out of diffs and ignore rules, and the OS reclaims it. |
| Namespace temp storage by the project directory name, with no hash suffix | local | Handoffs from different projects stay separate and resume matching stays scoped, while the path stays readable and navigable. Two same-named repositories sharing a folder is an accepted limitation: filenames are datetime-first, so nothing overwrites, and an ambiguous resume already lists its matches. |
| Choose the destination by durability, not by whether a write would succeed | local | Sandboxed hosts accept writes into containers that vanish with the session. The test is whether the user still has the file afterward. |
| Add a canvas destination, flagged by `md` or `markdown` | local | Long fenced markdown renders poorly in a chat transcript; a side-panel document is readable and copyable. It is also the only destination that reaches the user on hosts without a durable filesystem. |
| Accept a pasted document or an attached `.md` on resume | local | A canvas handoff has no filename to look up. All three sources feed one rebuild path. |
| Stop after restoring tasks and ask before working | local | harpb resumes straight into the in-progress task. The user cleared the session and may have changed their mind about what comes next, so the resumed session briefs them and hands control back. Only their invocation can waive the question; the document cannot, or an agent reads its own briefing as permission. |
| Keep the reviewed local merge in `template/SKILL.md`, then render `handoff/SKILL.md` | local | Raw upstream files cannot express the cross-harness decisions. The template preserves those decisions and lets the shipped file be checked for drift. |
| Use a Node maintenance core with Bash and PowerShell wrappers | local | Maintainers can run the same check on Windows, macOS, and Linux. |
| Keep `disable-model-invocation` as a Claude Code enhancement | local | Other hosts may not enforce it, so the skill body also explains when the workflow applies. |
| Keep delivery files separate from maintenance files | local | Installers should see the skill, not the update machinery or its history. |

Update this document whenever a sync changes one of these decisions. `PROVENANCE.md` records the run history and any deliberate local deviations.

## Known Limitations

On multi-user Linux, `/tmp` is shared, so `/tmp/agent-handoff/` may already belong to another user and the write fails. Left out of `SKILL.md` deliberately: macOS `$TMPDIR` is already per-user, and the mitigation costs a line to serve a case most users never reach. Add it if it bites.
