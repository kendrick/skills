# Staging File Grammar

Read this when writing, editing, or validating a `.refine.md` staging file. `scripts/segment.py` emits a skeleton that already conforms; `scripts/check-staging.py validate` enforces every rule here and `check-staging.py entries` reads the shape defined here into the entry JSON that [`tracker-contract.md`](tracker-contract.md) specifies.

Two invariants hold across the whole file:

- **Every value is single-line.** A value ends at its newline. There are no continuation lines and no wrapped values.
- **Fenced blocks are opaque.** A scan enters a ```` ``` ```` fence, skips to its close, and reads nothing inside as structure. The Source excerpt is raw transcript and will contain lines that look like headers, key-value lines, and anchors.

## Shape

````
---
skill: jira-refine
schema: 1
source: refinement-2026-09-07.vtt
source_path: /abs/path/refinement-2026-09-07.vtt
session: 2026-09-07
label: refined-2026-09-07
config: /abs/path/jira-refine.toml
projects: [PROJ, PLAT]
generated: 2026-09-07T15:02:11
---

## PROJ-412

status: staged
segment: 00:12:04 - 00:19:40
duration: 7m36s
words: 1140
revisited: 0
mentions: [PROJ-398, PLAT-77]

### Context
The nightly export times out for the largest customers.

### Acceptance criteria
- [ ] Export completes for a 50k-row report without a timeout (raw: "fifty thousand rows without timing out" 00:13:10)

### Out of scope

### Dependencies
- PROJ-398 (raw: "can't start until three ninety eight lands" 00:14:02)

### Goal

### Open questions
- not discussed: out of scope
- not discussed: goal

### Provenance
- source: refinement-2026-09-07.vtt
- session: 2026-09-07
- segment: 00:12:04 - 00:19:40

### Source excerpt
```text
[00:12:04] Dan: Okay, PROJ dash four twelve. So the export thing.
```

## Summary

### Spike candidates

### Mentioned in passing

### Gaps to file

### Apply log
````

That example is schema 1. A schema-2 file differs in three places: the frontmatter reads `schema: 2`, every entry carries a `### Labels` section between Goal and Open questions, and Open questions gains one `- not discussed: labels/<family>` line per family nobody named. A schema-2 entry might read:

```
### Goal

### Labels
- cap-export-timeouts (raw: "this is the nightly export work" 00:12:31)

### Open questions
- not discussed: out of scope
- not discussed: goal
- not discussed: labels/outcome
```

## Frontmatter

A block of `key: value` lines bracketed by two lines that are exactly `---`, opening on line 1. Values are unquoted and single-line. Nine keys, all required:

| Key | Value |
|---|---|
| `skill` | Always `jira-refine` |
| `schema` | `1`, or `2` when the config declares at least one `[label_families]` family. A file at `2` is validated against that config; see "Labels" below. Any other value fails with `schema is '<v>', expected '1' or '2'` |
| `source` | Basename of the transcript |
| `source_path` | Absolute path to the transcript |
| `session` | `YYYY-MM-DD`, the session date |
| `label` | The config's `label_prefix` followed by `session`, e.g. `refined-2026-09-07` |
| `config` | Absolute path to the config that was read |
| `projects` | Key list, `[PROJ, PLAT]` — bare, comma-space separated, `[]` when empty |
| `generated` | Local `YYYY-MM-DDTHH:MM:SS`, no timezone suffix |

A file with no frontmatter fences is unreadable rather than invalid: `validate` exits 3.

## Entry region

Every `##` header from the frontmatter to `## Summary` opens an entry. `## Summary` closes the entry region; nothing after it is an entry.

An entry header is `^## <KEY>$`, where `<KEY>` matches `[A-Z][A-Z0-9]+-[0-9]+` and its prefix appears in the frontmatter's `projects`. No key appears twice.

### Key-value lines

Between the entry header and its first `###` sits a block of `key: value` lines. `status:` is the only line `validate` requires; the rest are written by `segment.py` and carried forward, or added at reconcile.

| Key | Written by | Legal values |
|---|---|---|
| `status` | `segment.py`, then the human, then reconcile | `staged`, `approved`, `skipped`, `applied`, `conflict` |
| `segment` | `segment.py` | `HH:MM:SS - HH:MM:SS`, or `L<n> - L<n>` for a transcript with no timestamps |
| `duration` | `segment.py` | `<m>m<s>s`, e.g. `7m36s`; empty for a transcript with no timestamps |
| `words` | `segment.py` | Integer |
| `revisited` | `segment.py` | Integer, the count of times the key reopened after its first segment closed |
| `mentions` | `segment.py` | Key list, `[PROJ-398, PLAT-77]`; `[]` when empty. A missing line reads as `[]` |
| `on_conflict` | The human, by hand | `append`, `replace` |
| `applied` | Reconcile | `YYYY-MM-DDTHH:MM:SS` |
| `conflict` | Reconcile | Free single-line reason |

`status: applied` requires an `applied:` line. `status: conflict` requires a `conflict:` line.

### Status lifecycle

`segment.py` writes `staged` on every entry. The human flips each one to `approved` or `skipped` in an editor; apply mode pushes `approved` and nothing else. Reconcile writes `applied` on a clean push and `conflict` on a refused one. A `conflict` entry retries by having `on_conflict:` set and `status:` flipped back to `approved`.

## Sections

Eight `###` sections on schema 1 and nine on schema 2, in this order, every one present even when its body is empty:

1. `### Context`
2. `### Acceptance criteria`
3. `### Out of scope`
4. `### Dependencies`
5. `### Goal`
6. `### Labels` (schema 2 only)
7. `### Open questions`
8. `### Provenance`
9. `### Source excerpt`

The six **content sections** are Context, Acceptance criteria, Out of scope, Dependencies, Goal, and Open questions, all filled from the excerpt. Labels comes from the excerpt too, but it is not a content section: its gaps are tracked per family rather than per section, as "Labels" below describes. Provenance and Source excerpt are script-filled.

Line shapes, by section:

| Section | Body |
|---|---|
| Context | Prose lines. No anchor required |
| Acceptance criteria | `- [ ] ` then the criterion, then an anchor |
| Out of scope | `- ` bullets. No anchor required |
| Dependencies | `- ` then a key, then optional gloss, then an anchor |
| Goal | One prose line ending in an anchor |
| Labels | `- <label>`, then an anchor. Schema 2 only |
| Open questions | `- ` bullets, including every `not discussed` line. No anchor required |
| Provenance | Three bullets, in order: `- source: `, `- session: `, `- segment: `. `source` and `session` equal the frontmatter values |
| Source excerpt | One non-empty fenced block, `text` language tag, holding the segment's transcript lines verbatim |

A dependency key matches the entry-key pattern, has a prefix in `projects`, differs from the entry's own key, and either appears in that entry's `mentions:` or carries an anchor.

## Anchors

Every non-empty line under Acceptance criteria, Dependencies, Goal, and Labels ends in an anchor. The anchor matches, at end of line:

```
\(raw: "([^"]{1,120})" (\d\d:\d\d:\d\d|L\d+)\)
```

The captured snippet is four to ten verbatim words and is authoritative: `validate` fails the line unless the snippet appears, whitespace-normalized, inside that entry's Source excerpt. The floor exists because a snippet short enough to match anywhere in the excerpt cannot locate anything. `L<n>` names a line number and is legal only for a plain-text transcript that carries no timestamps.

A clock coordinate is checked against the excerpt, not just for shape. `validate` groups the excerpt into turns — each one starting at a `[HH:MM:SS]` line and running to the next — and fails the anchor unless the coordinate names a turn that actually appears there and the snippet appears, whitespace-normalized, inside that turn's own text. A snippet that wraps across lines still matches, because a turn is joined before comparing; a snippet that would have to span two turns does not, since that would quote two speakers as one. This closes the gap a shape-only check leaves open: a coordinate with the right shape but the wrong value — a timestamp that never occurs, or one borrowed from a different line than the one holding the quote — used to pass. `L<n>` gets no such check: an untimed excerpt carries no line labels of its own, and `L<n>` names a line in the source transcript, which `validate` never reads.

## Labels

A schema-2 file's frontmatter `config:` names the config that declares the label families. `validate` reads it with `tomllib` on schema 2 and only there, so a schema-1 file validates with no config in reach. On schema 2, a `config:` that is missing or not an absolute path is a frontmatter problem, exit 1, and so is a config that declares no families. A config that cannot be read or fails the load-time checks below exits 3.

The config shape, one table per family:

```toml
[label_families.capability]
max = 1
[label_families.capability.labels]
cap-export-timeouts = ["export timeout", "the nightly export"]
cap-safari-tiles = ["safari tiles", "the dashboard tiles"]
```

`max` is optional and, when present, a positive integer; a family without it has no cap. Each label maps to the phrases the room says for it. The config fails to load, exit 3, on a family with no labels, a label with no phrases, a phrase that is not a string or is empty or whitespace, a `max` that is not an integer (`max = true` included) or is below 1, or one label declared in two families.

Each line under `### Labels` is:

```
- <label> (raw: "<four to ten verbatim words>" HH:MM:SS)
```

The anchor is checked exactly as a Goal anchor is, excerpt presence and turn clock included. One check follows it: the snippet, casefolded and whitespace-normalized, has to contain one of that label's configured phrases, normalized the same way, as a substring. Only label lines go under `### Labels`. A family's `- not discussed: labels/<family>` line goes under `### Open questions` with the other not-discussed lines; under Labels it fails as a label line with no anchor.

`validate` reports one problem per line of stderr, each prefixed `entry <KEY>: `:

| Problem | Message |
|---|---|
| A label line with no valid anchor | `Labels line has no valid anchor: …`, as for any anchored section |
| A label line that is not a `- ` bullet | `Labels line does not start with '- ': …` |
| A label no declared family lists | `Labels label '<x>' is not declared in any label family` |
| A snippet holding none of the label's phrases | `Labels anchor snippet '<s>' holds none of the phrases configured for '<label>'` |
| A label listed twice in one entry | `Labels lists '<x>' twice` |
| More labels from one family than its `max` | `Labels has <n> labels from family '<f>', max is <m>` |
| A family with both a label and its not-discussed line | `Labels family '<f>' has both a label and a not-discussed line` |
| A family with neither | `Labels family '<f>' has neither a label nor a not-discussed line` |

## Not-discussed lines

An empty content section carries a matching line under Open questions:

```
- not discussed: <section>
```

`<section>` is one of the six content-section headings, lowercased exactly: `context`, `acceptance criteria`, `out of scope`, `dependencies`, `goal`, `open questions`. Each content section has either a body or a `not discussed` line, never both and never neither.

On schema 2, `<section>` may also be `labels/<family>`, one per declared family. Labels takes no section-level `not discussed: labels` line, because the per-family lines already account for an empty section. `segment.py` writes one `labels/<family>` line per family, in config order, after the six section lines.

## Summary

`## Summary` carries four `###` subsections, in this order, each present even when empty:

1. `### Spike candidates`
2. `### Mentioned in passing`
3. `### Gaps to file`
4. `### Apply log`

Reconcile appends a `#### <YYYY-MM-DDTHH:MM:SS>` block under `### Apply log`, one per apply run.
