# Render Fixture Plan

A valid Waves table for render-prompt.py: the `api` row's Done when holds an escaped pipe, and the `ui` row's Constraints cell is empty.

## Waves

| Wave | Task | Files owned | Model | Done when | Constraints |
|---|---|---|---|---|---|
| 0 | add-schema | src/schema/ | sonnet | schema types defined | |
| 1 | api | src/api/server.py, src/api/routes.py | sonnet | `pytest -q \| tail -1` prints a pass line | do not edit an existing test |
| 1 | ui | src/ui/ | haiku | the page renders | |
