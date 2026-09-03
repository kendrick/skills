# Web App Implementation Plan

This plan demonstrates a valid wave structure with parallel tasks in wave 1 and serialized tasks across waves.

## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
| --- | --- | --- | --- | --- | --- |
| 0 | Initialize schema | src/schema/ | haiku | Schema types defined | |
| 1 | Implement auth | src/auth/ | sonnet | Login/signup working | do not loosen an existing assertion |
| 1 | Implement users | src/users/ | opus | CRUD endpoints done | |
| 1 | Write documentation | docs/guides/, docs/api/ | fable | All major features documented | |
| 2 | Add auth tests | src/auth/tests/ | haiku | All auth scenarios covered | |
