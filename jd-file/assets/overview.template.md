---
type: overview
status: active
started: {{YYYY-MM-DD}}
target:
closed:
stakeholders:
tags:
  - overview
---

# {{AC.ID}} {{Label}}

> [!info] This ID's purpose lives in the register, not here.
> `00.01 JDex` carries the purpose clause. Restating it below would be a second
> copy that drifts. If you can't remember what this ID admits, read the register.

**Next action:** {{next action, or leave blank for the user}}

## Context

- 

## Log

- **{{YYYY-MM-DD}}** — created

## Rollups

> [!note] The lists below need the Dataview plugin.
> Without it they render as code blocks. Everything above works everywhere.

### Notes in this ID

```dataview
LIST
WHERE startswith(file.folder, this.file.folder)
  AND file.path != this.file.path
SORT file.mtime DESC
```

### Open tasks in this ID

```dataview
TASK
WHERE !completed
  AND startswith(file.folder, this.file.folder)
SORT due ASC
GROUP BY file.link
```

### Decisions in this ID

```dataview
TABLE date, status
FROM #decision
WHERE startswith(file.folder, this.file.folder)
SORT date DESC
```
