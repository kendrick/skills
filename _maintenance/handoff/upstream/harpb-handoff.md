---
description: Write or resume a session hand-off document (open tasks + a tight context narrative) so you can /clear and continue in a fresh, low-context session instead of /compact. No arg → hand off the whole session (in a fresh session with no work yet, resume the LATEST handoff instead); free text → hand off one task; a handoff id (datetime-slug-session) → resume that hand-off.
argument-hint: "[handoff id to resume | a prompt to hand off | empty for the whole session]"
---

# Handoff: clear context, resume from a document

Three phases, detected from the argument. The hand-off **document** is the source
of truth — `/handoff` writes it before `/clear`, then reads it after.

Argument: $ARGUMENTS

**Filename convention (all write modes):** `<YYYY-MM-DD-HHMM>-<slug>-<session-id>.md` —
datetime prefix first (so files sort chronologically and `ls` reads as a timeline), then
a short kebab-case **context slug** describing what the plan/work is about (e.g.
`extraction-persistent-browser-profile-`), then the session id. The slug makes the file
findable without opening it; pick it from the main unfinished task or the session's theme.

- **Write — session** (no arg) — the whole current session is ending. Write a
  hand-off doc (open tasks at the top, context narrative below) to
  `.claude/handoff/<datetime>-<context-slug>-<session-id>.md`, then print the
  `/handoff <datetime>-<context-slug>-<session-id>` line.
- **Write — prompt** (free-text arg, e.g. `/handoff convert the sitelink probes`) —
  hand off **one piece of work**, not the session. The arg is the prompt/goal; the
  doc bundles the prompt verbatim + only the context needed to execute it, at
  `.claude/handoff/<datetime>-<prompt-slug>-<session-id>.md`, then prints the
  `/handoff <datetime>-<prompt-slug>-<session-id>` line.
- **Resume** (an arg that starts with a datetime or session-id) — read that
  hand-off doc, recreate its tasks via `TaskCreate`, absorb the context, and
  continue.

## Why /handoff and not /compact

`/compact` summarizes the whole conversation into the next session — it spends
tokens and the summary often loses task fidelity and intent. `/handoff` instead
writes a small, deliberate document (the open tasks + a tight narrative of where
things stand), so after `/clear` the fresh session starts near-empty and rebuilds
exactly the state that matters by reading one file. It's `/refresh` plus a written
context narrative, persisted as a real file you can also read yourself.

## Detecting the phase

If `$ARGUMENTS` **starts with** a `YYYY-MM-DD-HHMM` datetime (current convention) or a
bare UUID (8-4-4-4-12 hex — legacy files), it's resume (the arg is a handoff filename).
Empty → write-session. Any other text → write-prompt (the text is the prompt).

```bash
if [[ "$ARGUMENTS" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}- ]] ||
   [[ "$ARGUMENTS" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(-.*)?$ ]]; then
  PHASE=resume
elif [[ -z "$ARGUMENTS" ]]; then
  PHASE=write-session   # …unless the session is fresh — see below
else
  PHASE=write-prompt
fi
```

**No-arg at the START of a session = resume the latest handoff.** A bare `/handoff`
only means "write" when there's a session worth handing off. If the current session
is fresh — no work done yet: empty in-context task list, no files edited, the
conversation effectively just started — there is nothing to write, so treat it as
"resume the most recent handoff": pick the newest file (the datetime prefix makes
this a plain sort), tell the user which one you're resuming, and run the Resume
phase on it.

```bash
LATEST="$(ls "$ROOT/.claude/handoff/" | sort | tail -1)"
```

The handoff folder is the **project's** `.claude/handoff/` — the git repo root,
falling back to `$PWD`. **Exception — dev-root service repos:** inside a
`dev-root/repos/<service>` repo (supersonic, morannon, bifrost, scrooge,
proton-stream, …), the service repo's own git root is *not* the project — the
handoff belongs in the **dev-root workspace** (`.claude/handoff/` that sits next
to `repos/`), so every service's handoffs live in one place and resume works from
any repo. Detection: the git root's parent dir is named `repos` and its
grandparent has a `.claude/` dir.

```bash
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
# In a dev-root/repos/<svc> repo, hand off to the dev-root workspace, not the service repo.
if [[ "$(basename "$(dirname "$REPO_ROOT")")" == "repos" && -d "$(dirname "$(dirname "$REPO_ROOT")")/.claude" ]]; then
  ROOT="$(dirname "$(dirname "$REPO_ROOT")")"
else
  ROOT="$REPO_ROOT"
fi
HANDOFF_DIR="$ROOT/.claude/handoff"
```

## Write — session (no arg)

Goal: capture everything the next session needs in one file, then point the user at it.

1. Resolve the datetime, session id, context slug, and the handoff dir. The
   **context slug** is a short kebab-case description of what the plan/session is
   about — pick it yourself from the main unfinished task (or the session theme),
   e.g. `extraction-persistent-browser-profile`:

   ```bash
   REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
   # dev-root/repos/<svc> → hand off to the dev-root workspace (see "handoff folder" above)
   if [[ "$(basename "$(dirname "$REPO_ROOT")")" == "repos" && -d "$(dirname "$(dirname "$REPO_ROOT")")/.claude" ]]; then ROOT="$(dirname "$(dirname "$REPO_ROOT")")"; else ROOT="$REPO_ROOT"; fi
   mkdir -p "$ROOT/.claude/handoff"
   DATETIME="$(date '+%Y-%m-%d-%H%M')"
   SLUG="<context-slug you chose>"
   echo "file: $ROOT/.claude/handoff/$DATETIME-$SLUG-$CLAUDE_CODE_SESSION_ID.md"
   ```

   `$CLAUDE_CODE_SESSION_ID` is exported by Claude Code for every session — use it
   directly, no script. (If it's somehow empty, fall back to the most-recently
   modified `*.jsonl` in `~/.claude/projects/<encoded-cwd>/`, where `<encoded-cwd>`
   is the cwd with `/` → `-`.)

2. **Write the document** at
   `$ROOT/.claude/handoff/<datetime>-<context-slug>-<session-id>.md` using the
   template below. Pull the open tasks straight from your in-context TaskList — the
   pending + in_progress ones — and write the narrative from your own memory of the
   session. Be concrete: name the files/paths, the decisions, and the exact next
   step, so the fresh session needs nothing but this file.

3. Print the resume pointer and stop (don't keep working — the point is to clear):

   ```bash
   Handoff written: <path>
   Run /clear, then: /handoff <datetime>-<context-slug>-<session-id>
   ```

## Write — prompt (free-text arg)

Goal: hand off **one task** — the prompt — to a fresh session, bundling only the
context that task needs. This is for spinning a focused piece of work out of a
big session: `/handoff convert the sitelink probes to validation scenarios`.

1. Slugify the prompt (short kebab-case) and resolve the file:

   ```bash
   REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
   # dev-root/repos/<svc> → hand off to the dev-root workspace (see "handoff folder" above)
   if [[ "$(basename "$(dirname "$REPO_ROOT")")" == "repos" && -d "$(dirname "$(dirname "$REPO_ROOT")")/.claude" ]]; then ROOT="$(dirname "$(dirname "$REPO_ROOT")")"; else ROOT="$REPO_ROOT"; fi
   mkdir -p "$ROOT/.claude/handoff"
   DATETIME="$(date '+%Y-%m-%d-%H%M')"
   SLUG="$(printf '%s' "$ARGUMENTS" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//' | cut -c1-40)"
   echo "file: $ROOT/.claude/handoff/$DATETIME-$SLUG-$CLAUDE_CODE_SESSION_ID.md"
   ```

   The `-<slug>-` in the middle lets several prompt-handoffs from one session coexist.

2. **Write the document** at `<datetime>-<slug>-<session-id>.md` with the prompt-scoped
   template below: the prompt **verbatim** as the goal, the prompt as the single
   top task (plus any genuinely-related open task), and a Context section holding
   **only what's needed to do this prompt** — the relevant files, the decisions and
   gotchas that bear on it, and where things stand. Leave out the rest of the
   session. If a source doc exists (a plan/EDD/probe folder), link it rather than
   inline it.

3. Print the pointer and stop:

   ```bash
   Handoff written: <path>
   Run /clear, then: /handoff <datetime>-<slug>-<session-id>
   ```

## Resume (datetime-prefixed arg)

Goal: rebuild state from the document and continue.

1. Read the doc:

   ```bash
   REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
   # dev-root/repos/<svc> → hand off to the dev-root workspace (see "handoff folder" above)
   if [[ "$(basename "$(dirname "$REPO_ROOT")")" == "repos" && -d "$(dirname "$(dirname "$REPO_ROOT")")/.claude" ]]; then ROOT="$(dirname "$(dirname "$REPO_ROOT")")"; else ROOT="$REPO_ROOT"; fi
   cat "$ROOT/.claude/handoff/${ARGUMENTS%.md}.md"
   ```

   If it's missing, say so and list what's there: `ls "$ROOT/.claude/handoff/"`. A
   partial arg (just the datetime, or just the session id) is fine — glob for it:
   `ls "$ROOT/.claude/handoff/"*"$ARGUMENTS"*.md` and take the single match (ask if
   several).

2. For each task under **Unfinished tasks**, call `TaskCreate` (parallel — one
   message, multiple tool calls), preserving the subject + description verbatim.
   Then `TaskUpdate` the one marked `in_progress` back to `in_progress`.

3. Read the **Context** section to reload intent + state. Tell the user one line:
   `Resumed from handoff <session-id> — N tasks restored. Continuing: <subject>.`
   Then pick up the in-progress task (or the first pending one) and keep going.

## The handoff document

Unfinished tasks first (so they're unmissable), context below. Omit the tasks
section if there are none.

```markdown
# Handoff — <session-id>
<YYYY-MM-DD HH:MM TZ> · <project / branch>

## Unfinished tasks
1. [in_progress] <subject> — <what it is / the activeForm>
2. [pending] <subject> — <description>
3. [pending] <subject> — <description>

## Context

**Goal.** <what this session set out to do, in a sentence or two.>

**Done.** <what's finished + verified — bullet the concrete changes, with file paths.>

**In progress / next.** <the exact next step for the in-progress task — where you
were, what's half-done, what to do next.>

**Key files & paths.** <the files touched or central to the work — relative paths.>

**Decisions & gotchas.** <choices made and why; traps the next session must know
(a non-obvious convention, a flaky step, a "don't do X" you learned the hard way).>

**How to verify.** <the command(s) to typecheck / test / run, so the next session
can confirm it didn't break anything.>
```

## Notes

- Hand-off docs are per-session scratch. They accumulate in `.claude/handoff/`; the
  user prunes old ones (or gitignores the folder) — don't auto-delete them.
- Filenames are `<YYYY-MM-DD-HHMM>-<slug>-<session-id>.md` — datetime first so the
  folder sorts chronologically (and "latest" is `sort | tail -1`), slug so you can tell
  what each handoff is about at a glance, session id last for traceability.
  Legacy bare-`<session-id>.md` and `<datetime>-<session-id>-<slug>.md` files still
  resolve via the resume glob.
- Keep the narrative tight — this is a pointer to rebuild state, not a transcript.
  If the work is large, link to the plan/EDD/scratch files instead of inlining them.
