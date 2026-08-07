Implemented in 151e07c95b94bce68154d858b98fd950b3a3f5ea, "Check new inputs against accepted memory before grooming them" (2026-08-06, on `inbox-to-memory-v2`). Verified criterion by criterion against the tree rather than taken from the commit message.

**The contradiction flag is registered in the token grammar with its grep.** `references/machine-contracts.md:74` carries the row: `[contradicts accepted: [[<file>|<label>]]] <statement>` matched by `grep -F '[contradicts accepted:'`. The relation vocabulary at `:53` lists `contradicts` alongside `confirms`, `extends`, and `introduces`. Pinned by the suite at `tests/inbox-to-memory-smoke.sh:288` and `:524`.

**The new phase is documented without renumbering phases 3 through 6.** Phase 2.5, "Check Against Accepted Memory," sits at `SKILL.md:53`. Phases 3, 4, 5, and 6 are still at 81, 128, 136, and 170 under their original numbers, so every scaffold and note pointing at a phase number still points at the same thing.

**Entity extraction normalizes through the alias table before any lookup.** `SKILL.md:62`, and it names the failure it exists to prevent: without normalization "Shachi" and "Saatchi" search as two people, which produces a clean no-conflict report on a scope that has the conflict.

**A run over the mixed fixture stays inside five body reads per input.** `SKILL.md:67` states the budget and makes it binding rather than aspirational, with the overflow path at `:186` requiring the phase 6 report to name what went unread. `tests/inbox-to-memory-smoke.sh:238-243` guards it from the other side: the suite fails if the mixed fixture ever grows enough records that five reads stops being a meaningful bound. See the caveat below.

**A flag round-trips through sign-off into an update-existing amendment.** The amend path is at `SKILL.md:162`, feeding the update-existing promotion at `:151-153`. Fixture `tests/fixtures/inbox-to-memory/mixed/notes/2026-02-17-atlas-freeze-exceptions-SDy5SGVwfu.md` carries a completed round trip, asserted at `tests/inbox-to-memory-smoke.sh:221-225`: the note lints clean, and both ends are present, the amendment that became `|memory — updated]]` and the dismissal that kept its flag.

**A dismissed flag remains in the note.** `SKILL.md:166` and `machine-contracts.md:107` both state it, and `unpromoted_candidates` at `machine-contracts.md:132` counts contradiction flags carrying no `dismissed:`. The suite proves the rule rather than assuming it: `:227-232` copies the mixed fixture, strips the `dismissed:` field, and asserts the same note then reports two outstanding contradictions instead of one. That is the assertion doing real work, not arithmetic that happens to line up.

Negative control shipped alongside: `tests/fixtures/inbox-to-memory/broken/notes/2026-03-18-contradiction-no-claims-19UymDD7Rt.md` is a contradiction missing its `claims:` half, and `tests/inbox-to-memory-smoke.sh:182` requires it to fail with `contradiction-fields:`.

## One caveat, carried to #17

The read budget is the only criterion whose verification stops at the documentation. `tests/inbox-to-memory-smoke.sh:511-512` pins the prose in `SKILL.md` with `require_text`, and the fixture guard keeps the budget meaningful, but nothing checks that a run actually made five reads or fewer. It cannot: the budget is a rule an agent follows by reading a doc and choosing to obey it.

That is exactly the class of behavior #17 exists to evaluate, and it is now one more concrete scenario for that suite to cover. Recording it here so the gap is on the record rather than implied by a green suite.

Leaving this open rather than closing by hand: `151e07c` carries `Closes #14` and is not yet on `origin/main`, so the merge will close it. #7 through #13, #15, and #16 are all in the same state.
