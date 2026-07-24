# handoff

Write a handoff file before `/clear`, then restore its unfinished work in a fresh Claude Code session.

## Install

Install this skill from the repository with the `skills` CLI:

```bash
npx skills add kendrick/skills --skill handoff
```

## Use It

`handoff` is user-invoked. Type it in Claude Code when you want to move work to a fresh session.

### Hand Off the Current Session

```text
/handoff
```

The skill writes the document in `.claude/handoff/`, then prints the command to run after `/clear`.

### Hand Off One Task

```text
/handoff convert the sitelink probes to validation scenarios
```

The prompt becomes the handoff goal. The file contains only the task and context needed to complete it.

### Resume Work

```text
/handoff 2026-07-24-1530
```

You can use a unique partial ID instead of the full filename. In a fresh session, bare `/handoff` resumes the most recent handoff.

## What the Handoff Keeps

Each handoff starts with unfinished tasks, then records the goal, completed work, next action, relevant paths, decisions, suggested skills, and verification commands. It links to plans, issues, ADRs, commits, and diffs rather than copying them.

See [SKILL.md](SKILL.md) for the complete behavior and document template.

## Maintain It

Upstream snapshots and the drift check live outside the shipped skill in [`_maintenance/handoff/`](../_maintenance/handoff/).

Run the check from any directory in the repository:

```bash
bash _maintenance/handoff/sync-upstream.sh
```

It prints `No upstream changes` for unchanged sources. When an upstream changes, it prints a diff and exits nonzero so the merge can be reviewed.

## More

- [Repository README](../README.md) — install the full collection and read contribution guidance.
- [MIT License](../LICENSE)
