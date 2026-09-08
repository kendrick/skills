# Tracker Contract

Read this when implementing or debugging `scripts/jira-apply.py`, when an apply run reports something other than `applied`, or when deciding where a template field lands in Jira. It is the only file in this skill that knows Jira exists.

`jira-apply.py` is one file that imports nothing from a sibling script and nothing from a sibling skill. **The write layer never routes through another skill.** A skill lands alone, so a write path reached through a sibling breaks whenever that sibling is absent — unlike a prose convention, which degrades safely. That is also why the follow-up that gives `file-issue` a Jira create path vendors this file byte-identically rather than calling it.

```
jira-apply.py {get KEY | fields --name TEXT | update | create}
              --config PATH [--transport rest|jira-cli] [--dry-run] [--report PATH]
```

`update` and `create` read entries on stdin and write a report on stdout. `plan_ops(entry, issue, cfg)` is a pure function, so every planning rule below is testable with no tracker in reach.

## Input: one entry per line on stdin

`check-staging.py entries` emits exactly this shape, one JSON object per line.

For `update`:

```json
{"key": "PROJ-412",
 "status": "approved",
 "on_conflict": null,
 "session": "2026-09-07",
 "source": "refinement-2026-09-07.vtt",
 "label": "refined-2026-09-07",
 "fields": {"context": "",
            "acceptance_criteria": [],
            "out_of_scope": "",
            "dependencies": [],
            "goal": null,
            "open_questions": [],
            "provenance": ""},
 "not_discussed": []}
```

For `create`:

```json
{"project": "PROJ",
 "issue_type": "Task",
 "summary": "",
 "fields": {"...": "same seven keys"},
 "parent": null,
 "blocked_by": [],
 "label": "refined-2026-09-07"}
```

Field types and provenance:

| Key | Type | Holds |
|---|---|---|
| `key` | string | The entry's issue key |
| `status` | string | Always `approved` in practice; `entries --status approved` is the filter |
| `on_conflict` | string or null | `append`, `replace`, or null when the human set nothing |
| `session`, `source`, `label` | string | Copied from the staging frontmatter |
| `fields.context`, `fields.out_of_scope`, `fields.provenance` | string | The section body, empty string when the section is empty |
| `fields.acceptance_criteria`, `fields.open_questions` | array of string | One entry per bullet |
| `fields.dependencies` | array of string | Issue keys only |
| `fields.goal` | string or null | Null when the section is empty |
| `not_discussed` | array of string | Lowercased section names, carried for reporting; it does not affect the rendered block |
| `parent`, `blocked_by` | string, array of string | `create` only |

**Anchors are stripped at this boundary.** A staging line's trailing `(raw: "…" HH:MM:SS)` is bookkeeping for the human reviewing the file, and every string above is the line text with its list marker and its anchor removed and whitespace trimmed. Traceability into Jira runs through Provenance and the `refined-<session>` label instead.

## Output: one report line per entry on stdout

```json
{"key": "PROJ-412",
 "transport": "rest",
 "dry_run": false,
 "description": "applied|already-present|conflict|skipped",
 "links": [{"key": "PROJ-398", "result": "applied|already-present|missing-issue"}],
 "label": "applied|already-present|unmapped",
 "goal": "applied|already-present|conflict|unmapped",
 "unmapped": [{"field": "goal", "fallback": "description block"}],
 "conflict": null,
 "writes": 0}
```

- `description: skipped` means no write was attempted, because reading the issue failed or the entry was abandoned before its description op ran.
- `conflict` is null or a single-line reason, and it is the entry-level verdict; a per-field conflict also shows on that field.
- `goal: conflict` means the value did not reach the field — Jira holds a different one, or the write failed — and the entry-level `conflict` says which. A failed goal write never appears in `unmapped`: the block was rendered before the failure, so it carries no `Goal:` line to claim.
- `writes` counts mutations actually sent — HTTP writes under `rest`, subprocess invocations that mutate under `jira-cli`. A dry run always reports `0`.
- On a `create` dry run, `key` is null.

`--report PATH` writes the same lines to a file as well as stdout.

Stderr carries one human line per entry and then totals:

```
PROJ-412  description=applied  links=1/1  label=applied  goal=unmapped  writes=3
2 applied, 1 conflict, 0 missing-issue, 5 writes
```

## Exit codes

| Code | When |
|---|---|
| 0 | Every field on every entry reported `applied` or `already-present`, or reported `unmapped` and took its fallback. An unmapped field that landed in the description block is a success: the shipped config leaves `fields.goal` unset, so treating that as a failure would exit 1 on every ordinary run |
| 1 | Any `conflict`, `missing-issue`, unmapped-without-fallback, or failed write. The report is still complete: a failure is recorded and the entry continues |
| 3 | Config missing or unparseable, unknown transport, missing credentials, missing `site`, absent `jira` binary, or a Python below the 3.11 `tomllib` floor. The message names the floor |

A dry run applies the same codes to the outcomes it planned.

## Per-field fallback table

This table is the single authoritative statement of where each template field lands. `ticket-template.md` describes what each field holds and points here for its fate.

| Field | Jira mapping | Fallback when the concept is missing |
|---|---|---|
| Context, Out of scope, Open questions | sections inside the description block | description block (always) |
| Acceptance criteria | `*` bullets in the block (wiki has no checkbox) | description block |
| Dependencies | issue links, `link_type` (default `Blocks`), this issue inward | `Depends on: KEY, KEY` line inside the block; reported `unmapped`. An explicitly empty `link_type` is the only signal that selects this fallback. An absent key still means `Blocks`, because `plan_ops` is pure and nothing else about link support is knowable before the block is rendered |
| Goal | custom field `fields.goal` | `Goal: …` line inside the block; reported `unmapped`. Plan time only: the line goes in while the block is still being rendered, so a write that fails afterwards reports `conflict` instead |
| Provenance | last section of the block + label `refined-<session>` | block only; label reported `unmapped` |

## The description block

Rendering is a pure function of the entry, so identical entries produce identical bytes — which is what makes rule 2 below a byte comparison. Sections with no content are omitted.

```
h6. jira-refine begin | session 2026-09-07 | source refinement-2026-09-07.vtt
h5. Context
The nightly export times out for the largest customers.
h5. Acceptance criteria
* Export completes for a 50k-row report without a timeout
h5. Out of scope
Depends on: PROJ-398, PLAT-77
Goal: Large customers stop filing export tickets.
h5. Open questions
* not discussed: out of scope
h5. Provenance
source: refinement-2026-09-07.vtt, session: 2026-09-07, segment: 00:12:04 - 00:19:40
h6. jira-refine end
```

`Depends on:` appears only when links are unmapped, and `Goal:` only when `fields.goal` is unset — each on its own line after Out of scope, in that order. Provenance is always the last section before the closing sentinel.

### Two readings the implementation settled

A section heading is emitted when the section has a body **or** carries a fallback line, and omitted only when it has neither. `Out of scope` with no content still appears when a `Depends on:` or `Goal:` fallback line lands under it, which is what the worked example above shows.

Under the jira-cli transport a Goal is mapped only when both `fields.goal` and `fields.goal_cli_name` are set. The first reads the current value and the second writes by name; without the read, rule 8 cannot hold, since a field whose value cannot be fetched cannot be reported `already-present` on a second run.

## Idempotency rules

1. The block is bracketed by `h6. jira-refine begin | session <date> | source <name>` and `h6. jira-refine end`. `h6.` survives a v2 round-trip; `{{ }}` and `[ ]` are wiki macros and do not, which is why the sentinel is a heading and not a macro.
2. An existing block with the same `source` is replaced in place: `applied` when the bytes differ, `already-present` when they are identical, and zero writes when they are identical.
3. An existing block from a different `source`, or non-block text with no block at all, is a `conflict` unless `on_conflict` is set. `append` keeps the existing text and adds the block after it. `replace` removes every jira-refine block and writes only the new one.
4. An empty description — null, whitespace, or holding only a stale same-source block — is written.
5. Links read `fields.issuelinks`. Dependency D of X is present when X's list holds an entry with `type.name == link_type` and `inwardIssue.key == D` (D blocks X: D outward, X inward). Create the link only when it is absent. A D that is not on the tracker reports `missing-issue`, performs no write, and exits 1.
6. Labels are added only when absent, by PUTting the union of the existing labels and the new one.
7. Goal is written when the custom field is empty or already equal. A different non-empty value is a `conflict` on that field alone; the rest of the entry still applies. A write that fails is the same verdict for the same reason — the value is not on the field — and rerunning once the config is fixed is safe, because rule 8 holds.
8. A second run over the same input performs zero writes and reports `already-present` everywhere. The smoke test asserts this on both transports.

## Operations per transport

| Op | REST (`/rest/api/2`, urllib, basic auth) | jira-cli |
|---|---|---|
| get_issue | `GET issue/{key}?fields=summary,description,labels,issuelinks,<goal id>` | `jira issue view KEY --raw` |
| update_description | `PUT issue/{key}` `{"fields":{"description":text}}` | `jira issue edit KEY -b "<text>" --no-input` |
| add_labels | `PUT issue/{key}` `{"fields":{"labels":[union]}}` | `jira issue edit KEY --label L --no-input` |
| set_field | `PUT issue/{key}` `{"fields":{id:value}}` | `jira issue edit KEY --custom name=value --no-input` |
| create_link | `POST issueLink` `{type:{name},inwardIssue:{key:X},outwardIssue:{key:D}}` | `jira issue link D X "<link_type>"` |
| create_issue | `POST issue` | `jira issue create -pPROJ -tTask -s"…" -b"…" -lL --no-input`, key parsed from the output |
| list_fields | `GET field`, filtered by name substring, printing id / name / schema.type | exits 1 with `field discovery needs the rest transport` |

`--custom` is documented on create, and jira-cli requires custom fields to be declared in its own config. The two ways a Goal misses the field split on timing. An unset `fields.goal` or `fields.goal_cli_name` is known while the block is still being rendered: report `unmapped` and put the `Goal:` line in the block. An edit that fails at write time is past that point — the block went out without the line, so there is no fallback to claim — and reports `conflict` on the goal, with the error in the entry-level `conflict`.

## Auth

REST needs `site` plus the two environment variables named under `[auth]` by the keys `email_env` and `token_env`, defaulting to `JIRA_EMAIL` and `JIRA_API_TOKEN`, combined into an `Authorization: Basic` header. The config holds the variable names; the environment holds the values. jira-cli carries its own config and reads `JIRA_API_TOKEN`; preflight it with `jira me`.

`site` expands `${ENV}` so a test can point the same config at a fake. Credentials never land in the config file or in a report.

## Field-name map to file-issue

The follow-up that vendors this file into `file-issue` maps the template onto its issue shape:

| This skill | file-issue |
|---|---|
| Context | What and Why / Problem |
| Acceptance criteria | Acceptance Criteria |
| Out of scope | Non-Goals |
| Dependencies | Blocked by |
| Goal | Parent when the goal is an epic, else a Goal line |
| Open questions | none |
| Provenance | Parent |
