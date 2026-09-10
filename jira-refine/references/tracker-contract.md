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
 "label": "refined-2026-09-07",
 "extra_fields": {"team": "1b4b76c3-..."}}
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
| `extra_fields` | object of string to string | `create` only, and optional. Overrides the value of a field the config declares; see "Extra fields on create". On an `update` entry it exits 3 |

**Anchors are stripped at this boundary.** A staging line's trailing `(raw: "…" HH:MM:SS)` is bookkeeping for the human reviewing the file, and every string above is the line text with its list marker and its anchor removed and whitespace trimmed. Traceability into Jira runs through Provenance and the `refined-<session>` label instead.

## Output: one report line per entry on stdout

```json
{"key": "PROJ-412",
 "transport": "rest",
 "dry_run": false,
 "description": "applied|already-present|conflict|skipped",
 "links": [{"key": "PROJ-398", "result": "applied|already-present|missing-issue"}],
 "label": "applied|already-present|unmapped",
 "goal": "applied|already-present|conflict|skipped|unmapped",
 "extra_fields": {"team": "applied|skipped|unmapped|conflict"},
 "unmapped": [{"field": "goal", "fallback": "description block"}],
 "conflict": null,
 "writes": 0}
```

- `description: skipped` means no write was attempted, because reading the issue failed or the entry was abandoned before its description op ran.
- `conflict` is null or a single-line reason, and it is the entry-level verdict; a per-field conflict also shows on that field.
- `goal: conflict` means the value did not reach the field — Jira holds a different one, or the write failed — and the entry-level `conflict` says which. A failed goal write never appears in `unmapped`: the block was rendered before the failure, so it carries no `Goal:` line to claim.
- A refused `create` reports every field it would have written as `skipped`, the same word `description` takes, because the entry was abandoned before any write. A `goal` or an extra field left reading `applied` would name a field on a ticket nobody created, and no `unmapped` entry claims a description-block fallback, since no block was written.
- `extra_fields` is empty on every `update`. On a `create` it carries one verdict per field the config declares or the entry names: `skipped` means the create was refused, so the field landed nowhere; `conflict` means the create itself failed.
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
| 1 | Any `conflict`, `missing-issue`, unmapped-without-fallback, or failed write. An extra field the config cannot map lands here, since it has no fallback to take. The report is still complete: a failure is recorded and the entry continues |
| 3 | Config missing or unparseable, unknown transport, missing credentials, missing `site`, absent `jira` binary, a Python below the 3.11 `tomllib` floor, or the tracker itself unreachable or refusing to answer at preflight — see "Preflight versus the apply loop" below. The message names the floor |

A dry run applies the same codes to the outcomes it planned.

### Preflight versus the apply loop

`get` and `fields` exist to be run before `update` or `create`, so a tracker that will not answer them has to fail loud rather than look like an ordinary result. A `TransportError` reaching either command — a dead `site`, a refused connection, an HTTP error with no 404 to read as an answer — exits 3, the same code as a bad config: neither command has a report to degrade into, so there is nothing safer to do than stop. That is distinct from the request actually landing and coming back negative: `get` on a key nobody created still exits 1, and `fields` finding no match for the given text still exits 1, because both are real answers from a tracker that responded.

Inside `update` and `create`, the same kind of failure reports instead of stopping: reading an issue is per-entry, so one entry's transport error becomes that entry's `conflict` while the run continues on to the rest of stdin — a partial apply still owes the human a report of what it did. A write op that fails mid-loop is recorded the same way, against the field it was writing. Exit 3 belongs to preflight, where nothing has been attempted yet and stopping costs nothing; exit 1 belongs to the loop, where entries after the failure still deserve their own verdicts.

## Per-field fallback table

This table is the single authoritative statement of where each template field lands. `ticket-template.md` describes what each field holds and points here for its fate.

| Field | Jira mapping | Fallback when the concept is missing |
|---|---|---|
| Context, Out of scope, Open questions | sections inside the description block | description block (always) |
| Acceptance criteria | `*` bullets in the block (wiki has no checkbox) | description block |
| Dependencies | issue links, `link_type` (default `Blocks`), this issue inward | `Depends on: KEY, KEY` line inside the block; reported `unmapped`. An explicitly empty `link_type` is the only signal that selects this fallback. An absent key still means `Blocks`, because `plan_ops` is pure and nothing else about link support is knowable before the block is rendered |
| Goal | custom field `fields.goal` | `Goal: …` line inside the block; reported `unmapped`. Plan time only: the line goes in while the block is still being rendered, so a write that fails afterwards reports `conflict` instead |
| Provenance | last section of the block + label `refined-<session>` | block only; label reported `unmapped` |
| Extra fields (`create` only) | the field id each `[extra_fields.<name>]` declares | none. The create is refused; see below |

## Extra fields on create

A Jira project shared by several teams gives each team a board whose filter tests a field the ticket has to carry — `project in (10777) AND cf[10001] in (1b4b76c3-...)` for Advanced Roadmaps' Team field. A ticket created without that field is on the tracker, correct in every field this contract otherwise covers, and absent from the backlog its team reads.

`[extra_fields.<name>]` in the config declares one such field, and every `create` sends all of them:

```toml
[extra_fields.team]
id = "customfield_10001"
cli_name = "Team"
value = "1b4b76c3-..."
```

`id` is what `rest` writes by, `cli_name` what `jira issue create --custom name=value` writes by, and `value` what every create sends. A create entry's own `extra_fields` object overrides the value for that one ticket; the config's `value` covers every other. Values are strings on both sides, because `--custom name=value` carries nothing else.

Two declarations may not resolve to one field. An `id` that names a field every create already writes — `project`, `issuetype`, `summary`, `description`, `labels`, `parent` — or that repeats `fields.goal` or another extra field's `id`, exits 3; so does a `cli_name` repeating `fields.goal_cli_name` or another extra field's `cli_name`. Both write paths are last-one-wins and neither says so: a REST create builds one flat `fields` dict, so `id = "description"` would send the extra field's value in place of the rendered block while the report still read `description: applied`, and a jira-cli create repeats `--custom name=value`. Both namespaces are checked whatever transport the run uses, because `--transport` overrides the config at the command line. A field declaring only one half, for one transport, collides with nothing.

The config table is validated strictly, unlike `[fields]` and `[auth]`, which a wrong shape merely empties. Those two have a description-block fallback, so a dropped table still gets its content to Jira. This one has none, so a misspelled setting would silently create the invisible tickets it exists to prevent: a non-table value, an unknown setting, or a non-string `id`, `cli_name`, or `value` exits 3 naming the key.

**An extra field the run cannot map refuses the create.** No value from either side, no `id` under `rest`, no `cli_name` under `jira-cli`, or a name the entry gives that no `[extra_fields.<name>]` declares: the entry plans no ops at all, reports `description: skipped`, an `unmapped` item carrying `"fallback": null`, and a `conflict` naming the field. Every field that did map reports `skipped`, because the create it would have ridden on never went.

That is the opposite of Goal's behavior, and the asymmetry is the point. A Goal falls into the description block, so its content still reaches Jira and the next run replaces the same block. An extra field's value is a field id or a select option rather than prose, so the block cannot hold it — and `create` is the one operation with no idempotency rule, so a ticket made without the field would both hide on the board and turn the rerun that fixes the config into a duplicate. Refusing leaves nothing to clean up.

Nothing infers a field from the project. On a shared project, guessing a team files one team's work onto another team's board, which is worse than filing it nowhere.

`update` rejects the `extra_fields` key at exit 3. It edits issues that already carry their fields, so the key means the caller expected a write this command has no path for, and dropping it silently would read on the report as a field that landed.

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
3. An existing block from a different `source`, or non-block text with no block at all, is a `conflict` unless `on_conflict` is set. `append` keeps the existing text and adds the block after it. `replace` removes every jira-refine block and writes only the new one. A block with no end sentinel gets the same verdict, whatever removed it—a hand-deleted sentinel, or Jira Cloud folding the heading into the block's last bullet on a round trip (issue #93). `find_blocks` marks it with `end: None` instead of a line number, and `plan_description` refuses it the same way it refuses an unmatched source: `(None, "conflict", reason)`, unless `on_conflict` is `append` or `replace`. Its extent is unknowable, so claiming the rest of the description as its body would silently overwrite whatever a human wrote below it. The reason names the missing sentinel through the `END_LINE` constant rather than hardcoded text, and tells the human to restore the line or set `on_conflict`. An entry whose field body carries a line shaped like either sentinel is refused before anything is sent, on both `update` and `create`, because the rendered block would read back as two blocks and no scanning rule separates that from a stale block with one appended after it. The refusal names the line and asks for it to be reworded; escaping it would rewrite what a person wrote. A begin sentinel is unterminated whenever the next sentinel below it is another begin, not only when no end line exists at all—`append` leaves precisely that shape, and pairing the stale begin with the appended block's end would splice over both and everything between them on the following apply.
4. An empty description — null, whitespace, or holding only a stale same-source block — is written.
5. Links read `fields.issuelinks`. Dependency D of X is present when X's list holds an entry with `type.name == link_type` and `inwardIssue.key == D` (D blocks X: D outward, X inward). Create the link only when it is absent. A D that is not on the tracker reports `missing-issue`, performs no write, and exits 1.
6. Labels are added only when absent, by PUTting the union of the existing labels and the new one.
7. Goal is written when the custom field is empty or already equal. A different non-empty value is a `conflict` on that field alone; the rest of the entry still applies. A write that fails is the same verdict for the same reason — the value is not on the field — and rerunning once the config is fixed is safe, because rule 8 holds.
8. A second run over the same input performs zero writes and reports `already-present` everywhere. The smoke test asserts this on both transports. `append` holds this on its own rather than through rule 2: an entry that keeps `on_conflict: append` reports `already-present` once a terminated block already carries the same bytes, because an unterminated block stays in the description and never lets rule 2's in-place replacement take over.

## Operations per transport

| Op | REST (`/rest/api/2`, urllib, basic auth) | jira-cli |
|---|---|---|
| get_issue | `GET issue/{key}?fields=summary,description,labels,issuelinks,<goal id>` | `jira issue view KEY --raw` |
| update_description | `PUT issue/{key}` `{"fields":{"description":text}}` | `jira issue edit KEY -b "<text>" --no-input` |
| add_labels | `PUT issue/{key}` `{"fields":{"labels":[union]}}` | `jira issue edit KEY --label L --no-input` |
| set_field | `PUT issue/{key}` `{"fields":{id:value}}` | `jira issue edit KEY --custom name=value --no-input` |
| create_link | `POST issueLink` `{type:{name},inwardIssue:{key:X},outwardIssue:{key:D}}` | `jira issue link D X "<link_type>"` |
| create_issue | `POST issue`, extra fields as `fields[id]` | `jira issue create -pPROJ -tTask -s"…" -b"…" -lL --no-input`, one `--custom name=value` per extra field, key parsed from the output |
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
