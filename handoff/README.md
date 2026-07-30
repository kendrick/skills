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

| Coding Agent | Invocation |
| --- | --- |
| Claude Code | `/handoff` |
| Codex | `$handoff` |
| GitHub Copilot CLI | Ask it to use the `/handoff` skill. |

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

## Where Handoffs Live

| OS | Location |
| --- | --- |
| macOS | `$TMPDIR/agent-handoff/<project>/` |
| Linux, WSL2 | `/tmp/agent-handoff/<project>/` (the Linux side, not `/mnt/c`) |
| Windows | `%TEMP%\agent-handoff\<project>\` |

`<project>` is your repository's folder name, so handoffs from different projects stay apart. Your OS clears temp files on its own schedule. Resume within the session or two you meant to, or copy the file somewhere you keep things.

## Hand Off One Task

Add a prompt after the invocation when only one piece of work needs to move forward:

```text
/handoff convert the sitelink probes to validation scenarios
```

The prompt becomes the goal and first unfinished task. The handoff keeps only the context needed to finish it.

## Resume Work

In the fresh session, invoke the skill with the datetime prefix or any unique part of the filename:

```text
/handoff 2026-07-24-1530
```

Use the matching invocation form for Codex or Copilot. A bare invocation in a fresh session resumes the newest handoff. When several files match, the skill lists them and asks you to choose.

## What Goes in the File

Each handoff begins with unfinished tasks. It then records the goal, completed work, next action, relevant paths, decisions, helpful skills, and verification commands. It links to plans, issues, ADRs, commits, and diffs instead of copying them.

Handoff files are yours to keep, prune, or ignore. Earlier versions of this skill wrote them to `.agents/handoff/` inside each project; those are still there, and you can move or delete them at your leisure.

See [SKILL.md](SKILL.md) for the full workflow and document template.

## Maintainers

The reviewed source and upstream snapshots live in [`_maintenance/handoff/`](../_maintenance/handoff/). Use the Node 18+ workflow there to check upstream drift and render the shipped skill:

```bash
node _maintenance/handoff/sync-upstream.mjs --check
node _maintenance/handoff/sync-upstream.mjs --write
```

The check prints a diff and exits nonzero when an upstream snapshot or generated file differs. Update the canonical template deliberately, then render it.

## More

- [Repository README](../README.md) — install the full collection and read contribution guidance.
- [MIT License](../LICENSE)
