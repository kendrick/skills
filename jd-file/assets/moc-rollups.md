<!-- Paste into a category's map file, OUTSIDE the generated begin/end markers.
     The block computes at render what the generated table must not store: vault-local
     facts that change constantly. moc-stale never reads it (it has no markers).
     "touched" is each Overview note's own mtime. jd-file's Log appends keep it
     current for skill filings; hand-edits elsewhere in the ID don't move it. -->

## Rollups

> [!note] The table below needs the Dataview plugin.
> Without the plugin it renders as a code block. The generated map above works everywhere.

```dataview
TABLE WITHOUT ID
  regexreplace(file.folder, ".*/", "") AS ID,
  status,
  dateformat(file.mtime, "yyyy-MM-dd") AS touched
WHERE startswith(file.folder, this.file.folder)
  AND file.name = "Overview"
SORT file.folder ASC
```
