# inbox-to-memory Lint Fixtures

Three scopes the lint runs against, driven by [`tests/inbox-to-memory-smoke.sh`](../../inbox-to-memory-smoke.sh). They are checked in rather than generated because the compatibility guarantees they encode are about files that already exist on someone's disk, and a generator would only ever produce files that match today's understanding of the old format.

- `old-only/` — the pre-v2 world: no `schema` key, block-style YAML lists, `related` as a nested mapping, bare line-ref anchors. Nothing here is ever migrated in place by a test; if a run modifies these files, the run is the bug.
- `mixed/` — both generations in one scope. This is the state the whole compatibility constraint exists to protect, and it is the default fixture for any check that claims to leave v1 files alone. Note `2026-01-13-atlas-cutover-readiness-JJuYgImRWn.md` is v2-shaped in every visible respect but carries no `schema` key, and it has to keep classifying as v1.
- `broken/` — reserved for planted defects, one file per defect so each failure can be named individually. Currently empty of them: the lint has no correctness checks yet.

The scopes are deliberately small. Every file here has to be readable in full while someone is debugging a failing assertion, so a fixture that grows past a screen has stopped doing its job.
