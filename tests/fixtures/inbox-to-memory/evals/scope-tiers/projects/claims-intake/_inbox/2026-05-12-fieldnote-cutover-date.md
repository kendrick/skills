# Working session — pinning the Fieldnote cutover

2026-05-12, 09:30 to 10:40, room 2B and Roshan on the bridge. Typed as we went.

Present: Bridget Lomax, Colm Deasy, Dermot Sayer. On the bridge: Roshan Ellery (release management).

We went in to pick a date and spent most of the hour on who picks it.

Roshan opened with the calendar. Build is code-complete 2026-11-06. The release train on 2026-11-17 is the last one before the December change freeze, and the next train after the freeze is 2026-02-09. His recommendation was 11-17 on the basis that it is the only train that fits the plan we have been showing him since January.

Dermot said no before Roshan had finished. December through mid-January is the claims peak — storm season and the post-holiday motor spike land on top of each other, and intake volume roughly doubles from the second week of December through to the middle of January. Putting a new intake screen in front of the highest-volume six weeks of the year, with the people who use it having been trained in October, is not a trade he is willing to make. His words: "You are asking me to change how we take a claim in the week we take the most claims."

Roshan's answer was that in that case it is 2026-02-09, because those are the dates. And that is where it turned into the other conversation.

Dermot: those are release dates, and release management decides whether a thing may go on a date, not which date it goes. Fieldnote is funded out of the Claims Operations budget. The intake function is his and it has never sat under IT — he reports to the COO, not to the CIO, and the platform side of the house advises on his systems rather than owning them. He was not heated about it, but he was flat: "You can tell me a date is unsafe. You cannot tell me which safe date I take."

Roshan did not dispute any of it. He said he would want it minuted, because it is the sort of thing that gets rediscovered by argument every time there is a date to pick, and nobody has written it down.

Where it landed: cutover 2026-01-12, the Monday after the peak drops off. That is not a train date, so it goes as an off-train controlled change, which needs Roshan's sign-off on technical grounds. He said he will give it — Fieldnote deploys onto its own stack and shares nothing with the platforms the train exists to sequence — and he will raise it at the change board on the 20th.

The two dates we did not take and why, so it is on the record:

2026-11-17. Ruled out on the peak, above. Dermot also pointed out that a November go-live means the first month of live running has no one senior available to fix anything, because claims leadership is on the floor.

2026-02-09. Ruled out because the business case for Fieldnote is built on handling-time savings landing inside FY27, and a February cutover leaves seven weeks of benefit against a case written on six months of it. Colm had the number: about 40% of the year-one saving disappears.

Between code-complete and cutover, the build sits in pre-prod and the claims team runs parallel intake against it for four weeks in December. Dermot wanted that anyway and now it is free — the delay he was going to have to argue for is a delay he is getting.

Contract consequence, which Bridget raised and Colm has: milestone 6 in the SOW reads "go-live, November 2026". That becomes 2026-01-12 as change note 4, alongside the milestone 5 acceptance criteria change already drafted. Colm to take both to the change board on the 20th as one paper.

Left open:

- who owns the four weeks of parallel running, since it is claims staff doing it and it is not in anyone's plan
- Roshan to confirm the off-train change window against the December freeze exception list
- Dermot wants the training calendar redrawn off the new date before the change board, not after
