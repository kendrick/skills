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

## Frontmatter

A block of `key: value` lines bracketed by two lines that are exactly `---`, opening on line 1. Values are unquoted and single-line. Nine keys, all required:

| Key | Value |
|---|---|
| `skill` | Always `jira-refine` |
| `schema` | Always `1` |
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

Eight `###` sections, in this order, every one present even when its body is empty:

1. `### Context`
2. `### Acceptance criteria`
3. `### Out of scope`
4. `### Dependencies`
5. `### Goal`
6. `### Open questions`
7. `### Provenance`
8. `### Source excerpt`

The first six are the **content sections**, filled from the excerpt. Provenance and Source excerpt are script-filled.

Line shapes, by section:

| Section | Body |
|---|---|
| Context | Prose lines. No anchor required |
| Acceptance criteria | `- [ ] ` then the criterion, then an anchor |
| Out of scope | `- ` bullets. No anchor required |
| Dependencies | `- ` then a key, then optional gloss, then an anchor |
| Goal | One prose line ending in an anchor |
| Open questions | `- ` bullets, including every `not discussed` line. No anchor required |
| Provenance | Three bullets, in order: `- source: `, `- session: `, `- segment: `. `source` and `session` equal the frontmatter values |
| Source excerpt | One non-empty fenced block, `text` language tag, holding the segment's transcript lines verbatim |

A dependency key matches the entry-key pattern, has a prefix in `projects`, differs from the entry's own key, and either appears in that entry's `mentions:` or carries an anchor.

## Anchors

Every non-empty line under Acceptance criteria, Dependencies, and Goal ends in an anchor. The anchor matches, at end of line:

```
\(raw: "([^"]{1,120})" (\d\d:\d\d:\d\d|L\d+)\)
```

The captured snippet is four to six verbatim words and is authoritative: `validate` fails the line unless the snippet appears, whitespace-normalized, inside that entry's Source excerpt. `L<n>` names a line number and is legal only for a plain-text transcript that carries no timestamps.

## Not-discussed lines

An empty content section carries a matching line under Open questions:

```
- not discussed: <section>
```

`<section>` is one of the six content-section headings, lowercased exactly: `context`, `acceptance criteria`, `out of scope`, `dependencies`, `goal`, `open questions`. Each content section has either a body or a `not discussed` line, never both and never neither.

## Summary

`## Summary` carries four `###` subsections, in this order, each present even when empty:

1. `### Spike candidates`
2. `### Mentioned in passing`
3. `### Gaps to file`
4. `### Apply log`

Reconcile appends a `#### <YYYY-MM-DDTHH:MM:SS>` block under `### Apply log`, one per apply run.
