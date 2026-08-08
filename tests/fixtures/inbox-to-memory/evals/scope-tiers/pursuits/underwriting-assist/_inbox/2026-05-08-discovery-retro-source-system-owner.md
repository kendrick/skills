# Internal retro — how we ran the Lantern data discovery

2026-05-08, 16:00, the small room. Slalom only: Adaeze Nwoye, Tomas Kral, Bridget Lomax. No client attendees, nothing here is for sharing as written.

Tomas called it, so he started. Looking back at the four weeks of discovery, the thing worth carrying out of it is not the mapping. The mapping is fixed and it is written up in the walkthrough note. What is worth carrying is how the mapping got wrong in the first place, because we have done this before.

The workshops had the business users and the analytics team in the room. The person who actually owns the source system — the one who knows which columns were repurposed a decade ago and never renamed — was down as a reviewer of the output rather than as an attendee of the sessions. He signed off a document. Three weeks later he sat in a room with the data on the screen and half the mapping fell over in twenty minutes.

Adaeze's point, and this is why we are writing it down: this is the third time. Harrow Water, both of the building society jobs, now here. Every time the source-system owner is a reviewer rather than an attendee, the field-level mapping comes back wrong, and it comes back wrong in the same way each time. The columns that are semantically wrong but syntactically plausible are exactly the ones that survive a document review, because a reviewer reads a document for internal consistency and an attendee reads the actual values. A document can be perfectly consistent and describe a system that does not exist.

So the generalized version, which we should be applying by default rather than rediscovering: on any engagement where the source is a system older than the people documenting it, the source-system owner is a named attendee of the first three data sessions, not a reviewer of what comes out of them. A plan that has that person down as a reviewer is a scoping defect, and it is one we can catch when we write the plan rather than after.

Bridget on why it keeps happening: the pushback is always the same and it is always plausible. That person is too senior, too busy, too much of a bottleneck to sit in three workshops. In general we accept it, because it sounds reasonable and because the cost of not having them is invisible at the point where you agree to it. The ask is about six hours of their time. What we spent here instead was three weeks of a data engineer building on a mapping that was half wrong, and we got that back cheaply — we found out in April rather than in September. On the building society work we did not, and it cost us roughly four times the discovery effort to unpick in build.

Tomas's addition, which is the sharpest version of it: the reason the review step feels like protection is that it produces an artifact. A signature on a mapping document is evidence that someone looked, and nobody asks what they looked at. If the only thing available to look at is the document, then the review can only ever check the document against itself.

Where this leaves us in general:

- Put the source-system owner in the first three sessions by default, and treat their absence as something the plan has to justify rather than something we have to justify.
- Stop counting a document sign-off as verification of anything except the document. If nobody has read the values, the mapping is unverified, whatever is written on it.
- The cost curve is the argument to use when someone pushes back. It is not that discovery goes better; it is that the same defect costs four times as much in build, and there is no version of this where you find out early by accident.

Nothing here needs to go to the client. It goes in our own patterns, and honestly it should have been there after the second time.
