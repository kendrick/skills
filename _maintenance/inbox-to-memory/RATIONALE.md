# inbox-to-memory—rationale

Evidence tiers: **[E]** measured or observed in a real run, **[P]** practitioner reasoning from prior art, **[C]** convention inherited from this repo or its neighbors.

## Where This Came From

This ledger covers `scripts/collapse-vtt.sh` and nothing else. The skill predates the rationale bar in `AGENTS.md`, so the rest of it is unledgered; a later change to another part of the skill is the moment to add rows for that part rather than backfilling here.

The collapser turns a WebVTT file into speaker turns, and its output becomes a note's `## Raw Content` zone. Phase 4 then deletes the source file, on the stated grounds that the raw zone preserved it. That chain is what makes a quiet defect here expensive: whatever the collapser emits is the only surviving record, and three P0s (#78, #84, #85) each ended in a note that read as correct while the original was gone.

## Decision Ledger

| # | Decision | Why | Tier |
|---|---|---|---|
| 1  A cue identifier is recognized by position, one line above the timing line, and the `/^[0-9]+$/` pattern is deleted rather than widened (#78). | Position is the only thing WebVTT guarantees about an identifier: not blank, no arrow, directly above the timing line. Any pattern match covers whichever formats the author thought of, and Teams and Zoom already use `<uuid>/<n>-<n>`. Deleting it puts a numbered transcript and a UUID-keyed one on one path, so no future format needs a new rule. | [P] |
| 2  NOTE, STYLE, and REGION open a block that runs to its terminating blank line, and a keyword opens a block only outside a cue (#85). | The three keywords share one block grammar, so one rule covers them. The `!in_cue` guard is what keeps a caption line beginning with the word NOTE as speech, since inside a cue the keyword carries no special meaning. Matches the approach `jira-refine/scripts/segment.py` took for the same defect in 3abf4c4. | [P] |
| 3  The `WEBVTT` header is skipped as a block rather than as a single line. | The header has the same block grammar, and its `Kind: captions` line matches the `Name: ` speaker form exactly. Under the old single-line skip, a header carrying that line was one blank line away from emitting a turn spoken by someone named Kind. Not reported in any of the three issues; it falls out of the same flag. | [P] |
| 4  Unlabelled speech is attributed to `@unknown`, never to a name inferred from a neighbouring turn (#84). | `@unknown` is the token this skill already uses for a person nobody named, in an open question's resolver field. `references/extraction-heuristics.md` gives the reason: an admitted gap beats a guess, because a fabricated name reads exactly like a fact and sends someone to ask a person who was never in the room. | [C] |
| 5  A speakerless file emits one turn per cue, where `segment.py` merges consecutive unlabelled cues into one long `unknown` turn. | The two scripts want different things from the same input. `segment.py` needs turns to find ticket-key boundaries and carries a per-cue table to recover timing. This zone is read by a human checking a quote, and a merged turn would leave the first cue's timestamp standing for a whole meeting, so every quote after it is unlocatable. A labelled turn still absorbs the unlabelled cues after it, because the captioner said whose words those are. | [P] |

## Deliberately Not Built

| Not built | Why | Pinned by |
| --- | --- | --- |
| A wider cue-identifier pattern. | Every widening covers one more format and misses the next. Position needs no pattern at all. | `refute_text "$vtt" "/^[0-9]+$/ { next }"` |
| A single-line NOTE skip. | It leaves the block body reaching the speaker branch, which is the whole of #85. | `refute_text "$vtt" "/^NOTE/ { next }"` |
| Inferring a speaker for an unlabelled cue from the surrounding turns. | A guessed name is indistinguishable from a captured one once the source file is deleted. | The `@unknown` require_line assertions on `speakerless.vtt`. |
| Merging consecutive unlabelled cues into one turn. | One timestamp for a whole meeting, and the raw zone exists for locating a quote. | The four-turn count on `speakerless.vtt`. |
| SRT input. | Nothing in the skill queues `.srt`; `SKILL.md` routes `.md`, `.txt`, and `.vtt`. `segment.py` handles SRT because jira-refine takes transcripts from wherever the user has them. | The `.vtt`-only file-type row in `SKILL.md`. |

## Known Limitations

- A spoken line sitting directly above a timing line, with no blank line between them, is read as a cue identifier and dropped. That input is invalid WebVTT, since cue text is terminated by a blank line, but the failure is silent when it happens.
- A speakerless transcript prints one timestamp per cue, so the raw zone reads dense where a labelled one reads as paragraphs. The alternative loses the timestamps, which is the worse trade for a zone whose job is locating a quote.
- The `Name: ` speaker form requires a capitalized first letter, so a lowercase-named speaker collapses into the previous turn as a continuation. Unchanged by this work and untested.
