## Problem

`strip` writes `None` on an emptied Blocked by line, which `check-relationships.py` reads as CONTRADICTED. Seen on #207 and kendrick/skills#257; the thread is at https://github.com/kendrick/skills/pull/179#discussion_r2.

```
python3 scripts/link-issues.py strip --issue <URL> --plan plan.json --result result.json
```

## For a Coding Agent

- **Verify with:** run `bash tests/file-issue-smoke.sh` from the repo root.

## Acceptance Criteria

- [ ] An emptied agent-targeted Blocked by line reads `set as native links`.
- [ ] A line that still holds an entry is left alone.
