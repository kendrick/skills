# Patterns journal: agent conventions

> **Purpose of this directory:** Capture observations from the engagement as they happen, before they're polished or categorized. The journal is the field notebook that eventually feeds the cross-client journal and informs deliverable synthesis.
>
> **Audience:** Claude Code working in this directory.
>
> **Inherits from:** the scope's root `CLAUDE.md`, and (if present) `working-state.md` for current state and decisions.

## What this directory is for

The patterns journal is the staging ground for cross-cutting observations that don't fit any single working file. It's where field notes live before they've been categorized as engagement-specific (going to deliverables) or generic (going to the cross-client journal).

It solves a specific problem: during an active engagement, interesting observations show up faster than they can be processed. Someone says something surprising in a discovery session. A coaching session lands better or worse than expected. A pattern starts emerging across three different conversations. A meta-observation about how the engagement is going. None of these have an obvious home in structured working files, and without a low-friction capture mechanism they get lost.

The journal is that capture mechanism. It's deliberately rough — not a polished document, not a deliverable, not a synthesis. Just notes that future-self (and Claude) can scan, search, and promote.

## What goes here

- Observations that surprised, positively or negatively.
- Patterns noticed across multiple conversations — the first time something happens it's a data point, the third time it's a pattern.
- Things that didn't work as expected, and why.
- Decisions made on the fly that should be revisited later.
- Questions that emerged that there wasn't time to answer.
- Possible cross-client patterns, marked with `#reusable-candidate`.
- Engagement-level meta-observations about the process, client politics, anything that affects the work but isn't itself work.

## What does NOT go here

- Meeting notes or transcripts — those live in `../notes/`.
- Deliverable drafts — those live in the engagement's deliverables area.
- Polished cross-client patterns — those get promoted to the cross-client journal via the skill's journal-candidate flow.
- Decisions about engagement structure — those go in `working-state.md`.
- Formal meeting notes or status updates — those are deliverables.

Rule of thumb: if it's structured and has a downstream destination, it belongs in that destination. The journal is for unstructured-but-valuable stuff that has no other home.

## File structure

```
patterns-journal/
├── CLAUDE.md          # this file
└── journal.md         # single running file, reverse-chronological dated entries
```

A single `journal.md` is intentional. Multiple files would create the question "which file does this go in?" — and that friction kills the discipline. One file, append at the top, search the whole thing when needed.

## Entry format

Each entry is a dated heading followed by short bullets. Entries should take 3–10 minutes to write — if it's taking longer, you're writing a session note or a draft, not a journal entry.

```markdown
## YYYY-MM-DD — short context label

- Observation, in the speaker's words if possible. Tag with hashtags. #discovery #pattern-emerging
- Another observation. Note what it might mean. #coaching #adoption-concern
- Reusable pattern candidate. Note why it's interesting, but don't yet generalize — that's a separate operation. #reusable-candidate
```

Format is loose on purpose. The barrier to entry is intentionally low so entries actually get written.

## Tag vocabulary

Tags are how you find related entries later. Use them aggressively without over-engineering the vocabulary — start simple and let it evolve.

**Topic tags** (what the observation is about):
- `#discovery` — observations from discovery sessions
- `#coaching` — observations from coaching sessions
- `#tooling` — observations about tools or platforms
- `#governance` — observations about authority, approval, exceptions
- `#handoffs` — observations about cross-role work
- `#process` — observations about how the engagement itself is running
- `#meta` — observations about your own approach, reactions, second-thoughts

**Status tags** (what to do with this observation):
- `#reusable-candidate` — possibly belongs in the cross-client journal, needs deliberate extraction
- `#engagement-specific` — definitely client-specific, will not be promoted
- `#pattern-emerging` — first or second observation of something that might be a pattern
- `#pattern-confirmed` — third or more occurrence; definitely a pattern
- `#adoption-concern` — something that suggests the practice will be hard to land
- `#open-question` — emerged from observation, doesn't have an answer yet
- `#follow-up` — needs a specific action later

You can have multiple tags per bullet. Don't worry about consistency in the early days — the tags stabilize as you use them.

## How Claude should help

The agent's job in the patterns journal is to be a **thinking partner for pattern recognition**, not a scribe or a synthesizer. The discipline depends on the user actually capturing observations; the agent's role is to help make sense of what's been captured.

### When the user is adding to the journal

- **Don't polish.** The journal's value is in its rawness. Polished entries are less honest and slower to write.
- **Don't categorize prematurely.** If something might be a pattern or might be a one-off, say so. "Possibly a pattern but only one data point so far" is more useful than picking a side.
- **Suggest tags but don't enforce them.** Propose tags when entries lack them; accept the user's call.
- **Keep entries short.** If a single bullet is getting longer than 3-4 lines, ask whether it should be split or whether the longer version belongs in a working file.
- **Capture verbatim quotes when available.** They're gold. Paraphrases lose specificity.
- **Don't infer beyond what was observed.** The journal is for what happened, not for what it might mean. Interpretation is a separate step.

### When the user is scanning for patterns

This is the high-leverage use of the agent in this directory, and it's what makes the discipline pay off. Patterns become visible through repetition, but the user doesn't always notice repetition because entries were written days or weeks apart. The agent can help by reading the whole journal at once and surfacing things the user might have missed.

Useful prompts:
- "Scan the journal for patterns related to [topic]. What's the most-repeated observation?"
- "Which `#reusable-candidate` entries haven't been promoted yet?"
- "Are there observations that contradict each other?"
- "Which `#pattern-emerging` observations have become `#pattern-confirmed` since they were first noted?"
- "Read the journal end-to-end and tell me what's emerging that I might not have noticed."

When responding:
- **Quote original entries verbatim** rather than paraphrasing.
- **Group by tag or by theme** depending on what makes patterns most visible.
- **Flag the strongest patterns first.** Five mentions across four sessions beats two mentions in one session.
- **Distinguish "the user mentioned this" from "this is what it might mean."** Observation and interpretation are separate.
- **Don't invent patterns that aren't there.** False patterns are worse than no patterns.

### When promoting observations to the cross-client journal

Promotion is deliberate, never automatic. Whether something is generic vs. engagement-specific is a judgment call the user has to make.

The agent's role:
- **Identify candidates.** Pull all `#reusable-candidate` entries and present them as a candidate list.
- **Help extract the underlying pattern.** "What's the generalizable insight here, separate from the client specifics?"
- **Help strip the specifics.** Identify which words are client-specific (proper nouns, team names, percentages, quotes). Suggest the genericized version.
- **Verify the promotion.** Confirm the resulting cross-client journal entry has zero client-specific content.
- **Trace the lineage.** Note in the journal entry that it has been promoted, with a pointer to the cross-client journal entry.

## What Claude should NOT do in this directory

- Auto-promote. Promotion is always user-initiated.
- Synthesize the journal into a deliverable. Point at the relevant tagged entries; don't draft deliverables from journal entries directly.
- Lose entries. Append new ones at the top (reverse-chronological). Never delete.
- Impose structure the user didn't ask for. Looseness is intentional.
- Tag entries the user wrote without proposing the tags first.

## Weekly review ritual

The journal pays off only if it gets read, not just written. A weekly review takes about 30 minutes:

1. **Scan the week's entries.** Re-read everything from the past week.
2. **Update tags.** Add `#pattern-emerging` to repeated observations; upgrade to `#pattern-confirmed` when something's been observed three or more times.
3. **Flag promotion candidates.** Generalizable observations get `#reusable-candidate`.
4. **Promote the strongest candidates.** Take 1-3 entries and walk through the promotion operation. The skill handles the wiki-linking back.
5. **Note open questions** that have emerged. Add them to `working-state.md` if they affect downstream decisions.
6. **Update `working-state.md`** with anything from the journal that has graduated into a real decision or a confirmed hypothesis.

"Run the weekly review with me" is a reasonable prompt to kick off the whole flow.

## Failure modes to watch for

- **The journal stops getting written.** Most common failure. The fix: make journaling a transition ritual that ends every working session. If several days pass without an entry, the agent should flag it.
- **Entries become too polished.** The discipline collapses under its own weight. Push back: rough is the point.
- **The journal fills up but never gets reviewed.** Capture without review is half the discipline.
- **Tags become noisy.** Stabilize the vocabulary by week 3 or 4.
- **Promotion never happens.** If `#reusable-candidate` entries accumulate but never get promoted, the journal isn't doing its job. Force at least one promotion per week.

## Why this exists

The journal exists because the engagement is going to teach things that don't fit anywhere else, and most of those things get lost if they aren't captured in the moment. The discipline is to write things down before knowing what they mean, and to come back and figure out what they meant later. The agent's role is to make the "come back later" step actually happen.
