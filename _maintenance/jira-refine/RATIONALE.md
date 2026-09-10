# jira-refine—rationale

Evidence tiers: **[E]** measured or observed in a real run, **[P]** practitioner reasoning from prior art, **[C]** convention inherited from this repo or its neighbors.

## Where This Came From

Five sources:

- **inbox-to-memory**—transcript intake, the never-alter-the-words rule, the snippet-authoritative anchor, "a missing field is reported and never filled in," the per-candidate gate, and rewriting the promoted line after the fact. Nothing is vendored: its collapser is VTT-only awk, and segmenting VTT, SRT, and plain text needs a Python parser this skill builds new. The patterns are cited and reimplemented in spirit, not copied.
- **file-issue**—the write guard, render-then-confirm, `--dry-run`, the creation-only boundary, and the task template shape reused for gap tickets. Its own ledger already said Jira "would need its own reference file and creation path. Left out until someone needs it." That row is why the write layer is built here, from scratch, rather than retrofitted into `file-issue`.
- **divvy-up and `check-waves.py`**—the validator convention (exit 0 pass, 1 semantic failure with one line per problem on stderr, 3 usage or unreadable input), the hard stop on a failed validation, the shape line printed as the point where a human corrects course, and reports that repeat the input back verbatim rather than summarizing it.
- **jd-file's `resolve_vault.py`**—the first-hit-wins config ladder, confirmed by successfully parsing a candidate rather than merely finding a file at that path.
- **The user's own spoken-key session protocol**—how a live refinement session actually says a project key and its aliases out loud, which is what `segment.py`'s boundary and alias rules are built to recognize.

## Decision Ledger

| # | Decision | Why | Tier |
|---|---|---|---|
| 1 | User-invoked only (`disable-model-invocation: true`) | A misfire lands in a client's Jira; a miss costs the user one word. Same asymmetry as `adversarial-review`, `handoff`, and `divvy-up`. | [P] |
| 2 | Two modes joined only by a file on disk | Stage mode and apply mode share no state but the staging file, so an editor edit between them counts for as much as either script does, and nothing reaches Jira without a file a human has actually opened. | [P] |
| 3 | Per-entry `status:` as the approval gate | Refinement produces several tickets per session at once; a single file-level approval would push a gap alongside a ticket the human hasn't looked at yet. | [P] |
| 4 | Segmentation and the staging skeleton live in a script; filling each entry's content stays prose | A script can reliably find turns and boundaries; deciding what counts as a stated acceptance criterion is judgment, and this repo keeps judgment in prose rather than encoding it. | [C] |
| 5 | `jira-apply.py`'s contract is JSON in, JSON out, with no markdown or wiki text on the input side | Keeping the wire format structured lets `plan_ops` stay a pure function of `entry`, `issue`, and `cfg`, testable with no tracker in reach. | [P] |
| 6 | `/rest/api/2` wiki markup, never Atlassian Document Format | ADF is a second renderer this skill would need to keep in sync with the same idempotency rules; v2 wiki markup is the one target until a real client needs v3. | [P] |
| 7 | A sentinel block, replaced in place on a matching `source`, conflicting on anything else unless `on_conflict` is set | Idempotency needs a marker that survives a round-trip and a way to tell "the same push again" from "someone else's text." Auto-merging into unmarked prose would guess at intent no rule can recover. | [P] |
| 8 | Dependencies are `Blocks` links with the dependency outward and this issue inward, presence checked by type, direction, and key together | Any looser check—key alone, or either direction—reports a link as present when it links the wrong way, or misses one that already exists under a different link type. | [P] |
| 9 | Project keys and their spoken forms come from `projects` and `[spoken_aliases]` in config, never a hardcoded or user-authored regex | A session names its projects, not its regexes; letting the config carry a raw pattern reopens the same failure mode `divvy-up` closed by keeping ownership paths literal rather than glob-based. | [C] |
| 10 | The config ladder (`$JIRA_REFINE_CONFIG`, then `./jira-refine.toml`, then `~/.config/jira-refine/config.toml`) resolves on the first file that parses, not the first that exists | An unparseable file at a higher-priority path would otherwise stop the whole ladder instead of falling through, the same failure `resolve_vault.py` closes. | [C] |
| 11 | The anchor's quoted snippet is authoritative; `validate` fails a line unless that snippet appears in the entry's own excerpt | A reader can't otherwise tell an invented acceptance criterion from a quoted one, and the check has to run against the transcript, not against the reviewer's trust. | [P] |
| 12 | `plan_ops(entry, issue, cfg)` is pure, behind a `Transport` interface with `RestTransport` and `JiraCliTransport` | Planning what to write has to be testable without a live Jira; a transport class keeps the two op tables (REST and jira-cli) from leaking into the planning logic. | [P] |
| 13 | `long` and `revisited` are arithmetic on segment stats; `circular` is a human reading of the same anchors | Duration and revisit counts are facts a script can compute once; whether a reopened topic actually went in circles needs a person looking at what was said each time. | [P] |
| 14 | Gap tickets are drafted in `file-issue`'s own task shape, with a ready-to-run ASK where `file-issue` can currently write | A draft that already matches the target skill's input shape turns a summary bullet into something the user can paste, without this skill filing anything itself. | [P] |
| 15 | Field discovery (`jira-apply.py fields --name goal`) prints candidates; the id lands in config only after the user picks | The Goal custom field id is site-specific and reading it wrong silently sends Goal to the wrong field forever; a human has to confirm it once. | [P] |
| 16 | Apply mode always dry-runs and asks once before a real push; no `--yolo` | The one moment this skill can irreversibly touch a client's tracker is apply mode's write step, so it is also the one moment that always stops for confirmation. | [P] |
| 17 | `- not discussed: <section>` is a literal line the validator cross-checks against every empty content section | A blank section and a section nobody discussed look identical unless the file says which one it is; the validator enforces that every empty section says so, and only that. | [P] |
| 18 | The session date comes from a flag or the transcript's filename, never from file mtime | A transcript copied, synced, or re-saved carries a new mtime that has nothing to do with when the session happened, and a wrong date lands in the Jira label and every provenance block. | [P] |
| 19 | Config is TOML, read with `tomllib`, gated on the Python 3.11 floor | `tomllib` is standard library only from 3.11 onward, which is what keeps every script in this skill copy-in portable per the repo's stdlib-only rule. | [C] |
| 20 | Stage mode never touches `jira-apply.py` or the network | The one file that knows Jira exists is `jira-apply.py`; a user can run every step of stage mode with no Jira credentials configured at all, because there is nothing in that path that needs them. | [P] |
| 21 | The write layer's authoritative copy lives in `jira-refine`, and the follow-up PR vendors it into `file-issue` byte-identically | This skill exercises everything—`update` and `create`, all eight idempotency rules, both transports—while `file-issue` will only ever need `create`. The repo's rule is one authoritative copy fixed upstream first, the same shape `scaffold_digest.py` and `paths_overlap` already hold. | [C] |
| 22 | `jira-refine` never calls `file-issue` to apply an update, and never will | `file-issue` is creation-only by its own rule, and a skill lands alone: a write path reached through a sibling breaks the moment that sibling isn't installed, unlike a prose convention, which degrades safely. | [C] |
| 23 | The jira-cli op table's `create_link` reads `link_type` from config instead of a hardcoded `"Blocks"` | Both transports plan against the same config key, so switching transports never changes which link type a dependency creates. | [P] |
| 24 | Anchors are stripped when an entry crosses from the staging file into the tracker-contract JSON | The anchor is bookkeeping for the human reviewing the file; once an entry is approved, traceability into Jira runs through the Provenance block and the `refined-<session>` label instead of a raw transcript quote. | [P] |
| 25 | A create sends the fields `[extra_fields]` declares, per run, with a per-entry override | A board filtering on a Team field hides every ticket created without one—observed live on FRW-765, four tickets reported `applied` and absent from the backlog. The field belongs to the run rather than the ticket, so the config carries the value and an entry overrides it only where one ticket differs. | [E] |
| 26 | An extra field the run cannot map refuses the create outright, where an unmapped Goal falls into the description block | The block can hold prose, not a field id or a select option, so there is no fallback to take. `create` is also the one op with no idempotency rule: creating the ticket anyway would hide it on the board and turn the rerun that fixes the config into a duplicate. Refusing leaves nothing to clean up. | [P] |
| 27 | `[extra_fields]` is validated strictly at load, unlike `[fields]` and `[auth]`, which a wrong shape empties | Those two have a documented description-block fallback, so a dropped table still gets its content to Jira. This one has none, so a misspelled setting would silently recreate the invisible-ticket bug the table exists to close. | [P] |
| 28 | Two `[extra_fields]` declarations resolving to one Jira field exit 3, including a collision with a core create field or with `fields.goal` | Both write paths are last-one-wins and silent: a REST create builds one flat `fields` dict, so `id = "description"` replaces the rendered block while the report still says `description: applied`. Caught in review of the change that added the table. | [E] |

## Deliberately Not Built

| Cut | Why |
|---|---|
| Adapters for other trackers | Nobody has asked for a second tracker yet, and `file-issue`'s own ledger already deferred Jira until someone needed it. Same discipline here: build the one tracker in front of you deeply, generalize when a second one is real. |
| Auto-approve or `--yolo` | `status: approved` is the only gate between a transcript and a client's tracker. A flag that skips it removes the review the whole two-mode split exists to enforce. |
| Auto-creating gap tickets | A gap ticket is drafted from a passing mention that was never interviewed. `file-issue` exists to run that interview; creating the ticket straight from the transcript would skip it. |
| ADF / API v3 | v2 wiki markup is the one rendering path this skill's idempotency rules are proven against. A second format needs its own sentinel and its own byte-comparison rule, not a toggle on the existing one. |
| Merging into a human-written description | Idempotency rule 3 treats non-block text with no block as a conflict unless `on_conflict` is set. Merging into someone else's prose automatically is exactly the guess that rule exists to avoid. |
| Cross-ticket duplicate detection | Each entry validates and applies against its own excerpt. The transcript already said which tickets it discussed; scanning the rest of the tracker for lookalikes answers a question nobody in the room asked. |
| Hardcoded or regex key pattern | The pattern is derived from `projects` and `[spoken_aliases]` at run time. A fixed or user-authored regex would need hand-editing for every new project a session adds, and fail silently when nobody remembers to. |
| Hydrating Jira state at stage time | `jira-apply.py` is the only file that knows Jira exists. Reading the tracker during staging would mean stage mode needs credentials before there's anything approved to push. |
| `jira-apply.py` writing the staging file | The staging file is the human's review artifact. A script that reads entries and writes reports has no business also rewriting the approvals it was handed. |
| Inferring a team or board field from the project | A project shared by several teams has no single right answer, so a guess files one team's work onto another team's board. That is a worse failure than the invisibility it would be fixing, and it is invisible in the same way: the report says `applied` either way. |
| Extra fields on `update` | `update` edits issues that already carry their fields, so the key would name a write with no path behind it. `read_entries` rejects it at exit 3 rather than dropping it, because a dropped key reads on the report as a field that landed. |
| Transitions, assignees, sprints, estimates, comments | The seven-field template holds what a transcript states. None of these five is something a spoken session states; adding write paths for them multiplies the idempotency rules for fields the template doesn't hold. |
| A `mark` verb for status flipping | Status flips happen by hand, in an editor, per the staging file's own lifecycle. A verb that flips it programmatically reopens the auto-approve risk cut above, through a side door. |
| Broadening `file-issue` into a `manage-issue` that both creates and edits | `file-issue`'s entire body is a create-time interview with gates that grade a freshly drafted body; editing shares none of that sequence. Widening a model-invoked description to cover closing and relabelling would raise the cost of a misfire on a skill whose own ledger says it lacks the guards for it. The repo already split this way once, as `jd-file` and `jd-audit`. |

## Known Limitations

- Rows 25 and 28 are the only `[E]` rows here, and it was measured by the bug rather than by a scenario: a live run created four tickets nobody could find, and a review harness erased a rendered block through a colliding field id. Every other row stays `[P]` or `[C]` until a run recorded in `EVALS.md` bumps it.
- Number-word parsing covers English 0–9999 only.
- An extra field's value is a string on both transports, because `jira issue create --custom name=value` carries nothing else. A field wanting a number, a list, or an option object has no path here.
- The jira-cli transport can't discover fields at all, `--custom` on edit is undocumented so Goal may fall back to the description block even when `goal_cli_name` is set, and its flags are pinned by the fixture shim rather than by every jira-cli release.
- A hand-deleted sentinel makes the next apply report a conflict. That's the correct outcome, not a bug: the block is the only record that a push already happened.
- A Goal that's really an epic link, not a custom field, needs its own config entry; nothing detects that case automatically.
- Jira's roughly 32,767-character description cap is unhandled beyond surfacing whatever error the API returns.
- A ticket refined in two separate sessions conflicts by design, because the two sources don't match.
- Diarization errors in the transcript propagate straight into the anchors that quote it.
- Until the follow-up PR lands, `file-issue` still writes only to GitHub, so a Jira gap ticket is a draft the user files by hand rather than a one-line handoff.
