# Handoff

Carry unfinished work into a fresh coding-agent session without relying on a conversation summary.

## Install

Install this skill from the repository with the `skills` CLI:

```bash
npx skills add kendrick/skills --skill handoff
```

## Start a Handoff

Invoke `handoff` before you clear a session or move to a new one. It writes a short document to a project-scoped folder in your OS temp directory. That document holds the next task, open work, decisions, and verification steps.

Use the invocation your coding agent supports:

| Coding Agent                 | Invocation                                                                          |
| ---------------------------- | ----------------------------------------------------------------------------------- |
| Claude Code                  | `/handoff`                                                                          |
| Codex                        | `$handoff`                                                                          |
| GitHub Copilot CLI           | Ask it to use the `/handoff` skill.                                                 |
| Claude or ChatGPT on the web | Ask for a handoff once the skill's instructions are in the conversation or project. |

For example, in Claude Code:

```text
/handoff
```

The response gives you the exact handoff ID to use next:

```text
Handoff written: /var/folders/9k/…/T/agent-handoff/skills/2026-07-24-1530-sitelink-probes.md
Clear this session, then invoke: handoff 2026-07-24-1530-sitelink-probes
(Temp storage: your OS may sweep this file eventually.)
```

## Hand Off One Task

Add a prompt after the invocation when only one piece of work needs to move forward:

```text
/handoff convert the sitelink probes to validation scenarios
```

The prompt becomes the goal and first unfinished task. The handoff keeps only the context needed to finish it.

## Hand Off to a Document

Add `md` or `markdown` and the handoff opens beside the chat as a document (a Claude artifact, a ChatGPT canvas) instead of landing on disk:

```text
/handoff md
/handoff md convert the sitelink probes to validation scenarios
```

Long technical markdown reads cleanly in a panel and copies out whole, where a fenced block in a chat transcript tends to break up. This is also the default on hosts without a durable filesystem of your own, like Claude or ChatGPT on the web. Those hosts run in a sandbox that gets discarded when the session ends, so a file written there would be gone by the time you looked for it.

## Resume Work

In the fresh session, invoke the skill with the datetime prefix or any unique part of the filename:

```text
/handoff 2026-07-24-1530
```

You can also paste the handoff document into the message, or attach the `.md`. All three sources rebuild the same state, so a handoff written to a canvas on the web resumes just as well as one on disk.

Use the matching invocation form for Codex or Copilot. A bare invocation in a fresh session resumes the newest handoff. When several files match, the skill lists them and asks you to choose.

Resuming does not start the work. Whichever source you use, the skill reads the document, rebuilds your unfinished tasks, and then stops for your answer:

```text
Resumed from 2026-07-24-1530-sitelink-probes.md — 4 tasks restored.

Goal: convert the sitelink probes to validation scenarios.
Done: probe harness extracted, 12 fixtures ported.
Next up: wire the scenario runner into the CI matrix.

Start on "wire the scenario runner into the CI matrix"?
```

You get the state back and still decide what happens next, which matters because you cleared the session and may have moved on since. To skip the question, say so in the invocation itself:

```text
/handoff 2026-07-24-1530 and get going
```

## Where Handoffs Live

| OS          | Location                                                       |
| ----------- | -------------------------------------------------------------- |
| macOS       | `$TMPDIR/agent-handoff/<project>/`                             |
| Linux, WSL2 | `/tmp/agent-handoff/<project>/` (the Linux side, not `/mnt/c`) |
| Windows     | `%TEMP%\agent-handoff\<project>\`                              |

`<project>` is your repository's folder name, so handoffs from different projects stay apart.

## What Goes in a Handoff

Each handoff begins with unfinished tasks. It then records the goal, completed work, next action, relevant paths, decisions, helpful skills, and verification commands. It links to plans, issues, ADRs, commits, and diffs instead of copying them.

See [SKILL.md](SKILL.md) for the full workflow and document template.

## Gotchas

Temp directories get swept. Your OS clears them on its own schedule, so resume within a session or two, or copy the file somewhere you keep things.

`md` writes nothing to disk. The document lives in the panel, so copy it out or leave the panel open until you have resumed from it.

Handoffs written before this skill moved to temp storage are still in `.agents/handoff/` inside each project. Resume by ID will not find them; paste one in instead, and move or delete the folder at your leisure.

## Maintainers

The reviewed source and upstream snapshots live in [`_maintenance/handoff/`](../_maintenance/handoff/). Use the Node 18+ workflow there to check upstream drift and render the shipped skill:

```bash
node _maintenance/handoff/sync-upstream.mjs --check
node _maintenance/handoff/sync-upstream.mjs --write
```

The check prints a diff and exits nonzero when an upstream snapshot or generated file differs. Update the canonical template deliberately, then render it.

To verify this skill on its own, from the repository root:

```bash
bash tests/handoff-smoke.sh
```

It confirms `handoff/` still ships only SKILL.md and README.md, that the shipped skill matches the canonical template byte for byte, and that the load-bearing strings survived. Set `HANDOFF_VERIFY_UPSTREAM=1` to re-fetch both upstreams as part of the run.

## More

- [Repository README](../README.md) — install the full collection and read contribution guidance.
- [MIT License](../LICENSE)
