<!-- Paste into a category's map file, OUTSIDE the generated begin/end markers.
     The block computes at render what the generated table must not store: vault-local
     facts that change constantly. moc-stale never reads it (it has no markers).
     status reads from each ID's README.md, the [status] anchor note -- adjust
     file.name if your vault anchors elsewhere. The depth guard keeps nested
     READMEs (memory scaffolds run deep) out of the rows. -->

## Rollups

> [!note] The table below needs the Dataview plugin.
> Without the plugin it renders as a code block. The generated map above works everywhere.

```dataview
TABLE WITHOUT ID
  regexreplace(file.folder, ".*/", "") AS ID,
  status,
  dateformat(file.mtime, "yyyy-MM-dd") AS touched
WHERE startswith(file.folder, this.file.folder)
  AND file.name = "README"
  AND length(split(file.folder, "/")) = length(split(this.file.folder, "/")) + 1
SORT file.folder ASC
```
