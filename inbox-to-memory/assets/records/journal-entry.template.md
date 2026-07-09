---
id: { { nanoid } }
memory_type: Journal
title: '{{Pattern, not source. "Hypercare scope by deliverable, not calendar"}}'
status: current
date: { { YYYY-MM-DD } }
themes: []
applies_to: []
source_refs:
  - scope: { { pursuit | project | client } }
    path: { { relative path from vault root to the source note } }
    note_id: { { nanoid } }
related: []
# supersedes:
# superseded_by:
---

# {{title}}

<!--
Free-form prose. One section. The point is to capture the pattern as you would explain it
to yourself six months from now, or to a peer who hasn't seen the source. Aim for the
generalized claim, not a recap of the conversation that triggered it.
-->

{{body}}

## Source Moment

<!--
Optional. Quote the triggering passage with a back-link to the source note.
Helps future-you remember where the pattern came from without having to chase it down.
-->

> {{quote}}

— from [[{{source-note-filename}}|{{source-note-title}}]] ({{date}})
