# Handoff Provenance

| Fetch date | Run | harpb | mattpocock |
| --- | --- | --- | --- |
| 2026-07-24 | Initial snapshot | Gist revision `2d08a2c47b6fe2443547061fe18494528eafa793`, updated `2026-07-24T04:32:29Z`; <https://gist.githubusercontent.com/harpb/3f4ff1899db04a0957c66634ca549292/raw/handoff.md> | Commit `386d4ff719a7c420ad1454232d0436b01f1b8c17`; <https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/handoff/SKILL.md> |

## Deviations From Upstream

The local template keeps the upstream write and resume loop but makes these deliberate changes:

- It stores handoff files in the OS temp directory, namespaced by project (`<TMP>/agent-handoff/<project-slug>/`), and uses each host's task or plan mechanism when available.
- Storage now converges with mattpocock's "Save to the temporary directory of the user's OS - not the current workspace", which the initial merge rejected in favour of a repository folder. The template arrived at the same place independently, on durability and cleanliness grounds rather than by adopting upstream.
- It adds a canvas destination for hosts with no durable filesystem, and accepts a pasted document or an attached `.md` on resume. Neither upstream describes a non-filesystem host.
- It adds an `inline` destination that returns the document as the whole reply, for a program that runs the skill and keeps what comes back. Both upstreams always write a file.
- Resume stops after restoring tasks and asks before doing any work. harpb ends its resume phase with "pick up the in-progress task (or the first pending one) and keep going"; do not carry that sentence back in on a sync. `tests/handoff-smoke.sh` fails if it returns.
- It adds an optional `Recent Asks (Verbatim)` section that quotes the user's last few prompts word for word. harpb's write-prompt mode quotes only the prompt the handoff is for. Neither upstream quotes the session's earlier prompts.
- It adds an `Open Questions` section and omits any section that would be empty. harpb omits only the tasks section, and neither upstream has a place for undecided points.
- Both ends of the handoff offer the user a session name, which neither upstream does. Both assume the session at hand is the only one open.
- Outside git it takes the project name from a `project:` token rather than the working directory harpb falls back to (`|| echo "$PWD"`), and it leaves a `Source:` line where the host has no session id. Neither upstream describes either.
- It removes harpb's repository-specific exceptions and service names.
- It keeps the merged skill in `template/SKILL.md`; `sync-upstream.mjs --write` emits the shipped `handoff/SKILL.md` only after upstream checks pass.

Record later differences from either upstream here before updating snapshots or the template.
