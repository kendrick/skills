# Review Correspondence

SKILL.md dispatches here at Step 1 when the artifact is a reply to a review comment or a standalone comment on a pull request. STE, Google developer style, and Global English all apply. Diátaxis does not—correspondence answers a question somebody asked rather than occupying a document mode. A reply is addressed to a reviewer and still belongs here rather than with the email and DMs the router sends to a voice process: it is public developer prose hanging off a diff.

## Register

Explanation register, answering rather than summarizing. The reader has the diff open and asked one specific question, so write back to the question instead of about the change; a paragraph recapping what the commit did instead of saying whether the finding held has answered nobody. Voice and tone as everywhere else here: a helpful technical writer who is also in a hurry.

## Content

Write for the one thing the reviewer needs from you: whether their claim held, and what you did about it. Everything that serves that belongs in the reply, and everything else is crowding out something that does.

That rules out the three drafts a reply usually turns into. The acknowledgement says "good catch, fixed" and never states whether the claim was right. The changelog restates what the commit did, which is the diff the reader already has open. The silent divergence fixes something other than what the reviewer proposed and describes it as agreement, leaving the difference for them to find. All three cost the reviewer a second pass, so spend the words instead on the verdict, the divergence, and whatever the finding turned out to expose that it did not name.

A reply outlives the round it was written in. It is read from a merged pull request, in a thread collapsed to its first line, by somebody who was not there for the argument—so no "as I said above", and nothing that only parses next to the comment above it.

## Hard Rules

- Never sign a reply. No `Co-Authored-By` trailer, no "Generated with" line, no robot-emoji footer, whatever the harness inserts by default. The thread already shows who posted it, and a footer under a two-paragraph answer is the largest thing on the page.
- Never hard-wrap the body. GitHub renders a single newline inside a comment as a line break, so a body wrapped at 74 columns arrives on the page broken at 74 columns and breaks again on a phone.

## The Reply

The first sentence says whether the finding held. Four verdicts cover every thread—confirmed and fixed, confirmed and deferred, partly right, refused—so lead with one of them by name, then say what changed. A caller may mandate the opening: `work-issue` replies to a queued row with `deferred: <Outside because>`, which is `confirmed and deferred` in the short form that caller fixes, and it satisfies this rule as written. Follow the caller's template where it has one, and this rule where it does not.

Where the fix diverged from what the reviewer proposed, say so in the reply rather than leaving it in the diff. A reviewer who asked for a narrowed pathspec and reads "fixed" will open the next round expecting a narrowed pathspec, and a reply that never mentions the exclusion was deleted outright has spent their attention on finding that out.

Where the finding exposed something it did not name, that belongs here too, and it is usually the most valuable thing the reply carries, because it is the only part the reviewer could not have reached alone.

A refusal owes more than an agreement does. Name what you checked, quote what you found, and say what would change your mind. "That path is unreachable" is an assertion; "`cmd_validate` resolves the root before the call, so the branch is dead—here is the grep" is an answer.

## The Standalone Comment

A pull-request comment has no finding above it, so its first line states its own subject. It answers a review that left no thread to reply into, or puts a set of findings on the record that no individual thread claims.

Where it carries a table something will read back, the table is data. Copy it exactly and keep the prose outside it. A cell reformatted as a link or wrapped in backticks compares as a different row.

Edit one comment in place across rounds rather than posting a second. Two comments carrying the same list leave no rule for which is current, and the reviewer reading the older one is looking at something already dealt with.

## Citing the Change

A short SHA is the natural thing to hand a reviewer and the first thing to go stale. A review cycle normally ends in a rebase and the merge normally squashes, so the commit a reply names stops being reachable from the default branch at about the moment the pull request closes.

So where the reply names a change, cite the SHA and write the sentence so that losing it costs nothing. "Fixed in `a869637`" is a reply that stops working. "The exclusion is gone rather than narrowed, in `a869637`" is the same reply with the answer still in it. A refused reply and a standalone comment that changed no code have no commit to name, so they cite none: reaching for HEAD attaches a SHA that answers nothing, and the reply then carries a locator a reader will try.

The same rule covers a line number, a path a later commit renames, and "see my comment above" in a thread the reviewer reads collapsed. Name the symbol, the function, the test—the things a rebase carries along—and let the locator be a convenience rather than the content.

## Example

From the pass that produced this profile, over every reply answering an automated reviewer on #115, #119 and #121, and the comment that put a deferred-findings queue on the record. That corpus is a superset of the nine pieces #111 names. Every one was drafted under the PR-description profile, because the table's nearest row was that one.

The drafts were good, and that is the finding. All sixteen replies lead with the verdict rather than a recap, so the habit this profile's first rule writes down was already there—held by the author, not by the table, and unavailable to the next run. Two moves recur and neither is anything a PR description would ask for. One reply opens a paragraph "One place I did not follow you" and then names the half of the reviewer's proposal it declined and why declining it was deliberate. Another opens "Two things your report did not cover that followed from it" and hands back a mode-bit failure the finding had not reached.

The citations are where every draft failed the same way, and that part is measurable. The SHAs those replies name—`3fd363f`, `d38ede6`, `221eedb`, `a869637`, `7aa9413`—all fail `git merge-base --is-ancestor <sha> main` today, and the branches that carried them are gone from the remote. The replies still read, because each says what changed in prose beside the SHA. A reply that had put the answer in the SHA would now be a sentence pointing at nothing.

## Layer Application

- **STE**—one thought per sentence, condition before what it governs: "Where the fix diverged from what you proposed, the reply says so." The verdict sentence carries the verdict and nothing else.
- **Google developer style**—active voice, naming who does what. "The exclusion is gone", not "the exclusion was removed." Address the reviewer as "you" for what they proposed, and use "I" for what you did; a reply is one person answering another, and the passive hides which of the two did the thing.
- **Global English**—one name per thing across the finding, the reply, and the commit, so the reviewer's "pathspec exclusion" is not "the filter" in your answer. Keep "only" against the word it changes: "only the definition line" and "the definition line only" are different fixes. Every "this" points at one obvious noun, which matters most where a reply is discussing the finding and the code in the same sentence.
