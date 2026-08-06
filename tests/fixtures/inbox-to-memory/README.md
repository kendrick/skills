# inbox-to-memory Lint Fixtures

Three scopes the lint runs against, driven by [`tests/inbox-to-memory-smoke.sh`](../../inbox-to-memory-smoke.sh). They are checked in rather than generated because the compatibility guarantees they encode are about files that already exist on someone's disk, and a generator would only ever produce files that match today's understanding of the old format.

- `old-only/` — the pre-v2 world: no `schema` key, block-style YAML lists, `related` as a nested mapping, bare line-ref anchors. Nothing here is ever migrated in place by a test; if a run modifies these files, the run is the bug.
- `mixed/` — both generations in one scope. This is the state the whole compatibility constraint exists to protect, and it is the default fixture for any check that claims to leave v1 files alone. Note `2026-01-13-atlas-cutover-readiness-JJuYgImRWn.md` is v2-shaped in every visible respect but carries no `schema` key, and it has to keep classifying as v1.
- `broken/` — one planted defect per file, so the failure count is a real assertion. A check that starts firing twice, or firing on the wrong file, shows up as arithmetic rather than washing out against a file that was already failing for another reason. The single memory record here is the exception: it exists so a contradiction flag has something accepted to point at, and it carries no defect.
- `journal-v1/` — one pre-v2 journal entry, which is the only place the nested `scope`/`path`/`note_id` source reference appears. The migrator flattens it to a compound string, and this is the fixture that proves it, including the report line for the `scope` sub-field the compound form has no room for.

Migration tests copy a fixture to a temp directory first. Nothing under `tests/fixtures/` is ever migrated in place: if a run modifies a checked-in fixture, the run is the bug.

The mixed scope also carries two open-question slugs that recur across three notes each. One gets named out loud in the third note and becomes a deferred tension; the other goes unnoticed and becomes an unacknowledged one. Both branches of the recurrence rule need a fixture, because the interesting half is the branch where nobody in the room was tracking it.

The scopes are deliberately small. Every file here has to be readable in full while someone is debugging a failing assertion, so a fixture that grows past a screen has stopped doing its job.
