# Service desk walkthrough — Larkspur Supply #118 Rosemont

2026-04-21, 07:30 to 08:45. Typed live at the desk, so the quotes are close but not court-reporter close.

There: Ruben Ortiz (Larkspur store ops), Ellie Kwan (Rowan payments), Nadia Barros (service desk lead, 118), Dana Okonkwo (me).

Went out to watch the desk before the 5/4 go/no-go. Return traffic picks up around 7:45 with the contractor crowd.

Nadia ran three returns in the first half hour. The second one was a pressure washer, warranty claim, $912 on the original ticket. The model is discontinued and there was nothing on the floor to hand the man instead, so she put the $912 back on his card out of the claims console. Vendor claim number, printed slip, four minutes, and it never touched a register.

I asked who approved it.

Nadia: "Approved it? It's a warranty claim. The claim number is the approval."

Me: it's $912 back on a card. Doesn't that need the district manager code?

Ruben: "Desk claims don't take a code. They never have. Doesn't matter what it's worth." The code prompt lives in the POS refund flow, he said, and the console posts its credits straight to the processor — the register never sees one, so there is nothing for the prompt to sit in front of.

Ellie pulled up the config while we were standing there. Confirmed it: the approval-code prompt is bound to the POS refund transaction type, and the claims console has never emitted that transaction type, in any build. A desk credit and a register refund put money back on the same card and only one of them is a refund as far as Rowan is concerned.

Ellie: "So we've been counting refunds out of the POS report this whole time." Which is where the pilot metrics come from, and where the $61k in the audit response came from. Nobody could tell me whether a desk credit has ever been in that number.

What the desk has instead, per Ruben:

- the console won't print a slip without a vendor claim number
- claims go to the vendor weekly and the district manager gets that report Monday morning
- anything the vendor rejects lands back on the store as a chargeback against its shrink number, which Ruben says is a sharper stick than a code somebody reads off a phone

He was firm that the register rule shouldn't be touched: "Nothing changes at the register. That one's right." His objection is to writing the desk into a rule that was never about the desk in the first place.

Nadia, unprompted, on the paper journal: they still initial anything over $250 in the binder under the counter. "We never stopped." Ruben confirmed the stores kept it after the console went in.

Third return was a no-receipt, a $38 hose fitting. Nadia tapped the customer's card, pulled up the 3/28 purchase, refunded it at the register. No paper involved anywhere.

Self-checkout came up on the way out. 118 and 042 both turned refunds on at self-checkout on 4/6 when the build landed. Nadia says it's fine, they're nearly all single items under twenty dollars. Ruben didn't know until this morning and was not happy. Nobody has turned it off.

Open at the end:

- Ruben to pull six weeks of the Monday claims report so we can see how many desk credits clear $500
- nobody could say whether the audit response covers the desk at all — me to ask Larkspur's controller
