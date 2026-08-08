# inbox-to-memory Evals

Scenario suite for the judgment half of the skill, which is everything the lint cannot reach: contradiction handling, chronic open questions, scope proposal, and what a Tier 2 summary is allowed to say. Method follows `skill-creator`, and the `file-issue` suite next door — for each scenario, run the same prompt twice, once with the skill loaded and once without, and grade the delta. The no-skill baseline is the step that tells you whether the skill taught anything.

Every run happens in a scratch copy. Nothing in this suite writes to the repo.

## Fixtures

Four, all under `tests/fixtures/inbox-to-memory/evals/`. Nothing is ever run there — a scenario runs against the copy `eval-scope.sh` prints.

- **`contradiction-amend`** — Larkspur Supply, refund controls. An `accepted` Rule record putting a $500 approval-code threshold on every refund, a `superseded` Context record, a `proposed` Decision, and one inbox transcript that walks into all three. Two prior notes.
- **`unacknowledged-tension`** — Meridian Freight's Dockside pilot at the Bexley Road terminal. Four prior notes, two open-question slugs live in all four, one of them named out loud in the inbox transcript and one of them never mentioned.
- **`scope-tiers`** — Calderwood Mutual. A client root with `projects/claims-intake/` and `pursuits/underwriting-assist/` beneath it, four inbox inputs spread across three opted-in scope roots, and a client `CLAUDE.md` declaring lightweight memory mode.
- **`tier2-summary-entities`** — a v1 Kestrel cutover scope, two notes and two records. A transcript mishearing, a locked cutover date, and a four-hour rebuild figure all sit below `## Raw Content`, where the Tier 2 extract does not reach.

## Running a scenario

`eval-scope.sh` takes a fixture name, copies that fixture into a fresh scratch directory outside the repo, and prints the path:

```bash
staged="$(bash _maintenance/inbox-to-memory/eval-scope.sh contradiction-amend)"
```

Then, per scenario:

1. Stage a copy. `cd` to the directory the scenario names inside it, load the skill, and paste the scenario's prompt verbatim.
2. Grade the pass-condition table against what that copy holds when the run stops.
3. Stage a **second** copy. `cd` to the same place and run the same prompt with the skill unloaded.
4. Grade the scenario's baseline expectation against the second copy.
5. Record both in the Grading table.

Steps 1 and 3 each call `eval-scope.sh` again, so the two runs never share a directory. Phase 4 deletes every text source from `_inbox/` on its way past, and a baseline pointed at the with-skill copy finds an empty queue and grades nothing.

Phase 5 is gated, so a scenario that grades a crystallized record needs you to approve the candidates it names at the sign-off prompt, and only those.

## Scenarios

### 1. Contradiction round trip — flag, sign-off, amend

**Fixture:** `contradiction-amend`
**Run from:** the staged root
**Prompt:** "process the inbox"

At the phase 5 gate, approve the amend outcome for the contradiction. Approve nothing else.

| Expect | Pass condition |
| --- | --- |
| Phase 2.5 flag | `[contradicts accepted: [[refund-approval-code-ypAes5QNas\|<label>]]]`, inline on the passage where Nadia puts $912 back on a card out of the claims console |
| Both halves | The statement says the credit took no approval code; `claims:` carries the record's own claim, that no refund over $500 leaves a store without one |
| The `superseded` record | No flag against `receipt-barcode-lookup-Qj2vTy_2pZ`, though the $38 hose fitting came back with no receipt and was refunded off a card lookup |
| The `proposed` record | No flag against `self-checkout-refunds-DPtlHN4Ut4`, though 118 and 042 both switched self-checkout refunds on when the 4/6 build landed |
| Line after sign-off | Rewritten to `[[refund-approval-code-ypAes5QNas\|memory — updated]]` |
| `source_refs` | The groomed note's `id` appended to the Rule record's, alongside `vC8nfl6HWd` |
| Amended body | The new passage carries `(added YYYY-MM-DD, <note-id>)` naming the groomed note, and the record's `date:` still reads `2026-02-24` |

Without the skill: nothing reads `_memory/` before writing, so `refund-approval-code-ypAes5QNas` is never named anywhere in the output and the $912 credit lands as a bullet about how the desk works. Diff the Rule record at the end of that run and it is byte-identical — `source_refs: [vC8nfl6HWd]`, no `(added ...)` passage, `status: accepted` untouched.

Detection alone is not the round trip. The expensive failure is a note that flags the conflict perfectly, followed by a sign-off that writes a second Rule record beside the first and leaves the scope holding two accepted rules about the same threshold.

### 2. Unacknowledged tension, and the slug somebody named out loud

**Fixture:** `unacknowledged-tension`
**Run from:** the staged root
**Prompt:** "process the inbox"

| Expect | Pass condition |
| --- | --- |
| `after-hours-gate-cover` | `[tension: unacknowledged]` in the groomed note, carrying its `stakes:` field |
| Its arithmetic | Reported as open across four prior notes under `notes/`, not as something this meeting raised |
| `noshow-charge-authority` | Carried forward as `[open question: noshow-charge-authority]` and **not** flagged as a tension — Terry stops the meeting to name it, which is the exemption |
| `kiosk-print-fallback` | No tension. It reached two notes, and `[open question resolved: kiosk-print-fallback]` closed it on 2026-04-08 |
| Prior notes | All four files under `notes/` are byte-identical after the run |

Without the skill: nothing greps `notes/` for slugs already in play, so expect Terry's stoppage written up as this meeting's news, under a risks or blockers heading of the model's own choosing, with no count attached and no prior note named. Expect `after-hours-gate-cover` to be absent from the output entirely — nobody in this transcript mentions who staffs the gate past 18:00, and the only trace of it is in four files the baseline never opens.

The negative case is the whole point. A model that has learned to escalate chronic questions flags both slugs, because both have sat open for four notes, and the one Terry spent the meeting on is the one that least needs escalating by arithmetic.

### 3. Scope proposal at three tiers, and the tiebreak

**Fixture:** `scope-tiers`
**Prompt:** "process the inbox"
**Run from:** three scope roots inside the staged copy, one run each — the client root, then `projects/claims-intake/`, then `pursuits/underwriting-assist/`. Phase 1 walks up from cwd to the nearest opted-in directory, so each root's `_inbox/` needs its own run. The claims-intake run grooms two inputs.

| Expect | Pass condition |
| --- | --- |
| `2026-05-11-calderwood-governance-sync.md` | `[memory candidate: client]` on the review board's rhythm — fortnightly on alternate Tuesdays, papers closing ten working days out |
| The evidence behind it | `grep -l -r "Nadia Okonjo" "<client-root>"/{pursuits,projects}/*/notes/` returns files in both project directories, so the recurrence heuristic has something under it |
| `2026-05-07-fnol-without-policy-number.md` | `[memory candidate: project]` on Fieldnote opening a notice with a null policy link and issuing a provisional claim reference on submit |
| `2026-05-08-discovery-retro-source-system-owner.md` | `[journal candidate: ...]` on the source-system owner as a named attendee rather than a reviewer. No scope token — journal candidates take none |
| `2026-05-12-fieldnote-cutover-date.md` | `[memory candidate: project]` on the boundary Dermot Sayer draws, that release management rules a date unsafe and the funding function picks among the safe ones. Not `[memory candidate: client]` |
| Why project wins it | The same grep on `Dermot Sayer` returns claims-intake and nothing else. One project is just this project, so the org-chart reading has no recurrence behind it and the narrowest scope takes it |

Without the skill: expect four write-ups carrying no candidate flag anywhere in them — no `[memory candidate: project]`, no `[memory candidate: client]`, no `[journal candidate: ...]` — so there is no proposed destination to compare against. The discovery retro is the one to watch. It is Slalom-only with no client attendees, and it is the only input here whose value survives leaving this account; expect the baseline to file it as Calderwood work beside the Fieldnote material rather than route it out of the client at all.

Three tiers on three inputs is the easy half. The fourth is where a model that has learned "reporting line means client scope" overshoots on an input the reference routes the other way.

### 4. Tier 2 summary and entities

**Fixture:** `tier2-summary-entities`
**Run from:** the staged root
**Prompt:** "migrate this scope to schema 2, and fill in summary and entities while you're in there"

Grade note `i59pVI65GO` and no other. Its extract is `<dir>/i59pVI65GO.extract.md`, written by `bash <skill-path>/scripts/migrate-scope.sh <scope-root> --tier2-extract <dir>`. That note is v1, so the run does emit one for it; read the file on disk rather than anything quoted here.

| Expect | Pass condition |
| --- | --- |
| Sourcing | Every value proposed under `entities` appears verbatim in `i59pVI65GO.extract.md` |
| Entities | `Elena Vasquez` and `Tomasz Krol`, both of which do |
| Mishearing rejected | `Tomas Krohl` not proposed. It occurs once, under `## Raw Content`, and the apply answers it with `tier2-entity-unsourced` and leaves the note unwritten |
| `Kestrel` rejected | Not proposed. It sits in the note's `tags`, in one record's `applies_to` and the other's `tags`, and in a body line, and it is nowhere in the extract |
| Summary sourcing | The summary asserts no date, name, decision, or outcome the extract does not carry |
| The plausible unsourced claim | No cutover date of November 14th and no four-hour rebuild figure. Both live only under `## Raw Content`; the extract carries six hours and no date at all |
| Result | `migrate-scope.sh <scope-root> --tier2 <dir>/proposals.yaml` reports no `tier2-` failure against this note in its dry run |

Without the skill: the proposals get written from the note on disk. Expect `Tomas Krohl` in `entities`, since the mishearing reads as a third person once raw content is in scope, and expect the summary to carry the November 14th cutover or the four-hour staging run, neither of which survives above the fence. Expect no sidecar at all — the baseline hand-edits frontmatter instead of running `--tier2-extract`, so there is no extract for the proposal to be held against and nothing to catch either error.

Nothing here is graded on how good the summary reads. A dull summary that is sourced passes; a sharper one carrying November 14th fails.

## Grading

Per scenario, record `passed` plus verbatim `evidence` for each row, taken off the staged copy rather than off the transcript of the run. Every row is binary on purpose. A row that needs an argument to settle was specified badly, so fix the row rather than the grade.

| Scenario | Rows passed, with skill | Rows passed, without skill | Baseline as expected? | Evidence |
| --- | --- | --- | --- | --- |
| 1. Contradiction round trip | | | | |
| 2. Unacknowledged tension | | | | |
| 3. Scope proposal and the tiebreak | | | | |
| 4. Tier 2 summary and entities | | | | |

The delta is widest on 1 and 4, and those are the two where a baseline reads best: a groomed note that is accurate about the meeting and never opened `_memory/`, and a summary that is accurate about the day and unsourceable from the layer the migrator checks it against.
