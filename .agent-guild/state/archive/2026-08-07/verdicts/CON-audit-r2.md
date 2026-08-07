---
task: CON-audit
checker: auditor
vendor: anthropic
model: claude-opus-5
verdict: PASS
checked_at: 2026-08-06T00:00:00Z
---

## Per-clause results

| clause | result | severity | description | evidence |
| ------ | ------ | ------ | ----------- | -------- |
| C-1 | PASS | blocker | unchanged since r1; re-confirmed present and still consistent with C-2's precedence rule | constitution.md:20-23 |
| C-2 | PASS | blocker | unchanged except the r1 correction, which landed: mutation runs on a scratch copy, with restore-before-return spelled out and C-8's diff-scope run named as the party that would otherwise eat a dirty tree | constitution.md:27 |
| C-3 | PASS | blocker | unchanged since r1 | constitution.md:32-35 |
| C-4 | PASS | blocker | unchanged since r1 | constitution.md:38-41 |
| C-5 | PASS | blocker | unchanged since r1; six-sibling count still correct in both places | constitution.md:8, :44 |
| C-6 | PASS | major | the r1 correction landed: `note:` now opens "non-normative, for the worker's orientation rather than the checker's judgment," and the siting guidance ends "nothing here requires that siting" | constitution.md:53 |
| C-7 | PASS | blocker | unchanged since r1 | constitution.md:57-60 |
| C-8 | PASS | blocker | unchanged; invocation re-run against the working tree | `check-diff-scope.py inbox-to-memory/ tests/ --ignore .agent-guild/` → `OK: 0 path(s) in scope`, exit 0 |
| C-9 | PASS | major | rewritten; the process requirement is gone and the clause is now decidable from the artifact alone. Falsified independently against a constructed violating string. Nothing the spec asks for is lost | constitution.md:69-73; ~/.claude/skills/humanizer/SKILL.md:50-346 |

## C-9: does the rewrite close the gap or relocate it?

It closes it. The two versions differ in logical form, not just wording.

The old text was a conjunction of two requirements: the prose "goes through the `humanizer` skill's audit-and-revise loop" **and** "carries the house voice." The first conjunct quantifies over events in the worker's session. No artifact records it, so no reading of any artifact can decide it. That is what I flagged in r0 and again in r1, and what the codex lane failed the clause over (`CON-audit-r1-codex.json`, one finding, `major` on C-9).

The new text has one requirement: the prose "reads as though a person wrote it, judged against the `humanizer` skill's pattern list and the voice of the surrounding files." The skill now appears as the *standard of judgment* rather than as a *procedure that must have occurred*. Give a checker the added prose, the pattern list, and the neighbouring files, and the clause's truth value is fully determined. Nothing else is needed and nothing unobservable is quantified over.

**Falsifiable from the artifact alone.** I did not take the clause's failing example on faith; I constructed my own. A replacement for `machine-contracts.md:29` reading "The frontmatter budget is a critical constraint that ensures records stay concise, scannable, and maintainable" violates the clause on two named tells at once, rule-of-three padding (humanizer pattern 10) and promotional framing (pattern 4). "Records have no headroom. Eighteen keys close the fence on line 20, so adding one means removing one" satisfies it. The clause separates those two artifacts cleanly, which is the whole test.

**The referenced standard is real and enumerable.** `~/.claude/skills/humanizer/SKILL.md` carries a numbered pattern list, 33-plus entries at `:50-346`. Every tell the check names maps onto one: rule-of-three padding to 10, promotional framing to 4, bolded inline headers to 15/16, em dashes to 14, title case to 17. The carve-outs are correct against the house preferences the pattern list would otherwise contradict, and the r2 addition ("Spaced em dashes are a finding") matches the standing rule to chain em dashes directly against text on both sides. A checker can apply this without interpretation.

**Nothing the spec asked for is lost.** The spec never mentions the humanizer. Its six Done-when criteria (`spec.md:88-93`) are entirely about lint behavior, doc registration, fixtures, and suite exit codes; not one concerns prose quality. C-9 has always been a house-standard clause layered on top of the spec rather than derived from it, so trimming its process half cannot uncover a spec requirement.

**Detection is unchanged.** This is the point that settles it. The `check:` field was already artifact-only in r0 and r1, and it was not edited this round. So the set of artifacts that fail C-9 today is exactly the set that failed it before. The rewrite removed a promise the check never covered; it did not weaken a check.

What genuinely does leave the constitution is enforcement of the standing house habit of formally invoking the skill rather than applying its principles from memory. That habit is real and worth keeping, and the residual risk is real too: a worker who skips the loop but whose prose happens to survive a pattern-list read now passes. That risk is not fixable by any clause, because no artifact can testify to its own provenance. The clause's `note:` sends the instruction to the worker's task brief, which is where an instruction about process belongs and where it can actually direct behavior. That is a relocation, but of the requirement to the layer that can carry it, not of the verification gap.

**One follow-through, for DEC-audit rather than for this verdict.** The `note:` is only true if the brief actually carries the instruction. The prior job on this branch did exactly this, so the pattern is precedented rather than hypothetical: `archive/2026-08-06/tasks/T-004.md:48` instructs the worker to draft the commit message and run the prose through the loop. When I audit the decomposition, I will check that whichever task owns C-9 carries "formally invoke the `humanizer` skill and follow its audit-and-revise loop" as an explicit instruction. If it does not, the habit is lost in fact and not merely unverified.

## Corrections required, not clause failures

None outstanding. Both corrections from r1 landed and are quoted in the table above. The r1 note on C-9's unverifiable half is now moot, since that half is gone.

## Verified without finding

Confirmed only where something this round bears on it, per the dispatch. I did not re-derive the key-order arithmetic, the sibling recount, the `:156-159` citation, the `comm -23` method, or the spec-coverage map; all three of those were reproduced against the tree in r0 and again in r1 and nothing in the C-9 rewrite touches them.

- **Only C-9 moved.** Every anchor r1 quoted is still verbatim in place: C-2's "reports `frontmatter-key-domain` and does not report `frontmatter-budget`, per C-1" (`:26`), the six-sibling count at `:8` and `:44`, C-3's failing example pointing at `tests/inbox-to-memory-smoke.sh:708` (`:35`), and the `lint-scope.sh:156-159` citation in both the preamble (`:13`) and C-2's failing example (`:29`). Note that `.agent-guild/state/` is untracked, so this is a text comparison against r1's quotations rather than a `git diff`.
- **C-9 introduces no contradiction with any other clause.** It grades the failure message's prose; C-1 constrains what that message must name. A message can name the file and both keys while reading like a person wrote it, so the two are independent rather than opposed. C-9's "comments explaining why rather than what" agrees with the check's "flag comments that restate the code." The commit message falls outside C-8's `inbox-to-memory/` and `tests/` deliverable scope, but C-8 constrains what the deliverable *touches*, not what a clause may grade, and the archived precedent puts the drafted message under `.agent-guild/state/`, which C-8's invocation ignores outright.
- **The em-dash rule does not fight the "voice of the surrounding files" appeal.** `machine-contracts.md` contains exactly one spaced em dash and zero unspaced ones, which on its face reads like the surrounding voice contradicting the check. It does not: the one instance is `:116`, an attribution separating a quotation from its speaker, where the space is ordinary typography rather than prose style. There is no prose counter-example in the file for a checker to be misled by.
- **C-8 re-run.** `OK: 0 path(s) in scope`, exit 0. Still the document's only deterministic check, still routed correctly away from `checker-judgment`.
- **Protected content.** Still no manifest claimed and still none needed. Nothing in this job ships verbatim author words.
