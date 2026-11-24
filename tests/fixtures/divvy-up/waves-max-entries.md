# Entry-count Falsifier

Wave 1 holds three tasks that own five paths between them. `--max` counts tasks, so `--max 3` passes. A cap that counted owned entries would fail it.

## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
| --- | --- | --- | --- | --- | --- |
| 0 | Initialize schema | src/schema/ | haiku | Schema types defined | |
| 1 | Implement auth | src/auth/, src/session/ | sonnet | Login works | |
| 1 | Implement users | src/users/, src/profiles/ | opus | CRUD works | |
| 1 | Write documentation | docs/ | haiku | Features documented | |
