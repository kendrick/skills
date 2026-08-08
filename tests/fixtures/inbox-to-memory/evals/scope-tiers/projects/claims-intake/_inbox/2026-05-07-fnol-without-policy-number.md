# Working session — taking a notice with no policy number

2026-05-07, 14:00 to 15:20, room 2B with the sample on the screen. Typed live, so the quotes are close but not word for word.

Present: Bridget Lomax, Tomas Kral, Colm Deasy, Yvette Mbeki.

Tomas had the pilot sample up. 4,112 first notices, 2025-12-01 to 2026-02-28, pulled for the discovery baseline. Of those, 587 arrived with no policy number available at the point of the call. That is 14.3%, and the split is not what anyone in the room expected: hospital billing offices and body shops are most of it, then third-party solicitors, then policyholders phoning from the side of a road with the car still in the hedge.

Yvette confirmed the shape from the floor. "They ring us before they ring anyone. They have a registration and a name and that is all they have, and we cannot type any of it."

The current intake screen will not open a notice without a policy number. So the agent spends the call searching, and if the search fails they take the details on paper and re-key later, or they ask the caller to ring back, which Yvette said happens more than she would like to put in writing. Our March baseline had the average first-notice call at 11 minutes 20, and the time-in-motion sample attributed about nine of those minutes to finding the policy rather than to taking the notice.

Colm asked the question that settled it: what is the notice for. It is the record that a loss was reported and when. The policy link is how it gets to the right file eventually, not what makes it a notice.

So: Fieldnote will open a notice with a null policy link and issue a provisional claim reference on submit. The notice is complete and retrievable from that moment. Matching happens afterwards, out of an unmatched queue that a clerk works, and the queue is a screen in Fieldnote rather than a report someone gets emailed. Yvette was firm on that last part — she has three reports arriving weekly that nobody works, and a fourth would go the same way.

Two things we ruled out and the reasons given at the time:

Requiring a minimum identifying triple — name, date of birth, postcode — so the system could auto-match on submit. Tomas killed it with the sample: 31% of the third-party callers in the 587 could not give a date of birth, because they are a repair shop and they have a vehicle, not a person. Making the triple mandatory would push exactly the calls we are trying to fix back onto paper.

Holding the notice in a draft state until it matches. Colm's objection: a draft is not a notice, so the timestamp we would be recording is the timestamp of the match rather than the timestamp of the report. The SOW's cycle-time measure at milestone 5 runs from notice submitted, and if a submitted notice can sit unsubmitted for two days the measure means nothing.

Bridget flagged the contract consequence and Colm agreed to raise it: acceptance criteria for milestone 5 currently assume every notice carries a policy link. That has to change to say a notice can be submitted, retrieved, and amended with a null policy link, and that the unmatched queue is deliverable scope rather than an operational workaround. Colm to draft the amended criteria for the next change board.

Open at the end:

- Tomas to size the unmatched queue at steady state from the same sample — Yvette wants to know whether this is a half-hour-a-day job or a person
- Colm to draft the milestone 5 acceptance criteria change
- nobody has said what happens to a notice that is never matched, and it is not obvious that anything should
