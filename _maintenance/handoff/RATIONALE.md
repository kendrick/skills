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
| Outside git, PROJECT is the `project:` token, else the current folder; a canvas or inline header without the token leaves it out | local | [P] Prior art is the destination flags, whose stripping the token copies. A sandbox's working directory is a name the host picked, so on canvas and inline hosts it labeled the document with something unrelated to the work. The folder name still locates HANDOFF_DIR for writes and resumes, so `handoff inline <id>` resumes a file written from the same folder, while the header leaves it out where it could be a sandbox's. Inside git, ROOT keeps naming the project, so resume by id finds the same HANDOFF_DIR whatever ARGS said, and outside git the file pointer carries the token, so resume by id reaches the same HANDOFF_DIR. Asking was rejected because the inline caller runs with every tool denied. |
| Leave a `Source:` placeholder where the host exposes no session id | local | [P] Prior art is the `Session:` line it stands in for. The hosted chats expose neither an id nor their URL to the agent, so only the user can fill it, and a dropped line leaves no way back to the chat. |
| Choose the destination by durability, not by whether a write would succeed | local | Sandboxed hosts accept writes into containers that vanish with the session. The test is whether the user still has the file afterward. |
| Add a canvas destination, flagged by `md` or `markdown` | local | Long fenced markdown renders poorly in a chat transcript; a side-panel document is readable and copyable. It is also the only destination that reaches the user on hosts without a durable filesystem. |
| Add an `inline` destination that returns the document as the whole reply, rather than a new phase | local | [P] Prior art is the `md`/`markdown` flag in the row above, whose stripping and keep-the-word rules `inline` reuses. The phase decides what the document holds and the destination decides where it goes, so `inline` works with both write-session and write-prompt, and a caller that wants the document as text still decides what it holds. `inline` beats `md` when both appear because the caller is a program reading the reply, and a canvas would hide the document from it. Resume ignores the flag, since a resume ends in a brief for the user and has no document to return. The first caller is `kendrick/handoff-on-compact`, which runs the skill in a fork with every tool denied. |
| Accept a pasted document or an attached `.md` on resume | local | A canvas handoff has no filename to look up. All three sources feed one rebuild path. |
| Stop after restoring tasks and ask before working | local | harpb resumes straight into the in-progress task. The user cleared the session and may have changed their mind about what comes next, so the resumed session briefs them and hands control back. Only their invocation can waive the question; the document cannot, or an agent reads its own briefing as permission. |
| Add an optional `Recent Asks (Verbatim)` section that quotes the user's last 3–5 prompts | local | [P] Prior art is harpb's write-prompt mode, which puts the handoff's own prompt into the document word for word as its goal. This section extends that to the session's last few prompts. A summary softens the constraints in the user's own wording, so "only the README" comes out as "update the docs". The next session gets the wording itself, right after the Goal it backs up. The 3–5 cap keeps the section short, and the writer omits it when no prompt is worth quoting. A quoted prompt grants nothing on resume, for the reason the "Stop after restoring tasks and ask before working" row gives. |
| Add an `Open Questions` section and omit any section that would be empty | local | [P] Prior art is the template's own omission rules for `Unfinished Tasks` and `Recent Asks (Verbatim)`, which this generalizes. A chat with no task tool had nothing for `Unfinished Tasks` to copy, so undecided points were lost or filed under `Decisions & Gotchas`, where they read as settled. They stay out of `Unfinished Tasks` because resume recreates those as tasks, and a question waits on a person rather than on work. The resume brief names them in one line so the user sees them before saying go. |
| Mark the proposed names with 📍 for live work and ☑️ for parked work | local | The marks are what the eye catches first when scanning a row of windows, and Title Case reads faster there than a slug. Claude Code keeps both through its name sanitiser, which strips `\p{Cc}` and `\p{Cf}` only; U+FE0F is `Mn`, so `☑️` survives with its emoji presentation intact, and the 200-character cap leaves room to spare. |
| Offer a session name at both ends of the handoff | local | Hosts derive a session name from the project directory, so every session on one repo reads alike. An agent cannot rename its own session, so each end proposes a name and hands the user the command. The write side spends it on `/clear <name>`, which labels the outgoing session; a bare `/clear` would carry the finished work's name onto the session that picks the handoff up. |
| Keep the reviewed local merge in `template/SKILL.md`, then render `handoff/SKILL.md` | local | Raw upstream files cannot express the cross-harness decisions. The template preserves those decisions and lets the shipped file be checked for drift. |
| Use a Node maintenance core with Bash and PowerShell wrappers | local | Maintainers can run the same check on Windows, macOS, and Linux. |
| Keep `disable-model-invocation` as a Claude Code enhancement | local | Other hosts may not enforce it, so the skill body also explains when the workflow applies. |
| Keep delivery files separate from maintenance files | local | Installers should see the skill, not the update machinery or its history. |

Update this document whenever a sync changes one of these decisions. `PROVENANCE.md` records the run history and any deliberate local deviations.

## Deliberately Not Built

| Cut | Reason |
| --- | --- |
| Quoting the agent's answers in Recent Asks | An answer repeats what Done and In Progress already say. It can also carry an old approval such as "go" or "yes, push it", and a resumed session would read that as permission. That is the document granting what the "Stop after restoring tasks and ask before working" row reserves for the user's invocation. `tests/handoff-smoke.sh` refutes "prompts and answers", "prompts and replies", and "and your answers" in `handoff/SKILL.md`. |
| Naming a canvas or inline document's header after the working directory outside git (the folder still locates HANDOFF_DIR) | In a sandbox that folder belongs to the host, not the user, and harpb's `\|\| echo "$PWD"` is how a sync would restore it. `tests/handoff-smoke.sh` refutes both "fall back to the current working directory if not in a git repo" and `echo "$PWD"` in `handoff/SKILL.md`. |

## Known Limitations

On multi-user Linux, `/tmp` is shared, so `/tmp/agent-handoff/` may already belong to another user and the write fails. Left out of `SKILL.md` deliberately: macOS `$TMPDIR` is already per-user, and the mitigation costs a line to serve a case most users never reach. Add it if it bites.
