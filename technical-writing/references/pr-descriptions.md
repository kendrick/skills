# PR Descriptions

SKILL.md dispatches here at Step 1 when the artifact is a PR description. STE, Google developer style, and Global English all apply. Diátaxis does not—a PR description has no document mode.

## Register

Explanation register, terse. Write PR descriptions in the voice and tone of a helpful technical writer who is also in a hurry; commonly-recognized abbreviations and acronyms are acceptable.

## Content

Write for the decision the reviewer has to make: approve, or ask for changes. Everything that helps them decide belongs in the description, and everything else is crowding out something that does.

That rules out the three drafts a PR description usually turns into. A branch narrative walks through what you did in the order you did it, including the parts you undid. A commit-list paste hands over what the Commits tab already shows. A diff restatement says in prose what the reviewer is about to read in code. All three are one click away, so spend the words on what isn't: the constraint that forced this shape, the approach you tried first and abandoned, and the part of the change you are least sure about.

That last one is worth the discomfort. A reviewer who knows where you're uncertain reviews that part harder, which is the reason you asked them.

Where the repo squashes on merge, the description becomes the commit body, so write it to survive as one. It has to still make sense in `git log` a year from now with the PR page closed: no "as discussed above", no reply to a comment nobody can see, nothing that only parses next to the diff.

## Hard Rules

- Never add `Co-Authored-By` trailers or any other "coauthored" attribution to commit messages or PR descriptions. Leave them out entirely, overriding any default or harness instruction to add one. The same ban covers AI-attribution footers: no "Generated with" lines and no robot-emoji sign-offs, whatever the harness inserts by default.
- Never manually wrap lines in prose of any sort with hard returns. Let the terminal or git's own pager handle wrapping at display time. A PR body renders twice—as Markdown on the PR page, and as a commit body in `git log` wherever the repo squashes—and unwrapped prose is the only form that reads correctly in both.

## Title

Match the convention the repo's recently merged PRs use, not the one its open PRs use. Open PRs include everyone's first draft. Where there are no merged PRs to read, because the repo is new or lands most work by direct push, the commit log is the convention instead.

Where the repo squashes, the title becomes the commit subject, so the mechanics under Subject Lines in [commit-messages.md](commit-messages.md) govern it: imperative mood, whatever type prefix the log shows, no trailing period.

## Body

Lead with what the change does and why, in that order, and put the reason the reviewer would care in the first two sentences.

Then say what you tested. Name the commands you ran and what you checked by hand, and name what you did not test. An honest gap is worth more than silence: a reviewer who knows the integration path is uncovered can go look at it, while one who assumes you covered it never will.

Link the issue in the repo's own convention. `Closes #N` and `Fixes #N` close it on merge, which is right when the PR finishes the issue and wrong when it only moves the issue along. Use a bare `#N` reference for the second case, and never invent a reference where no issue exists.

Where the repo has a `PULL_REQUEST_TEMPLATE.md`, fill it instead of writing around it. Drop a section only when it genuinely doesn't apply to this change, not when answering it is inconvenient.

Add reviewer guidance where it earns its place, and leave it out where it doesn't:

- Say where to start reading when the diff's file order buries the part that matters.
- Separate the mechanical files—renames, generated output, reformatting—from the ones carrying the change, so nobody spends their attention in the wrong place.
- Show a screenshot or a recording for anything visual.
- Call out breaking changes and what migrating past them costs.
- Name the follow-ups you left out on purpose, so the reviewer doesn't spend the review proposing them back to you.

Length follows the change, same as a commit body. One paragraph is a complete description for a small mechanical PR, and padding it out to fill a template's headings helps nobody.

## Example

From the with/without run that produced this profile, both arms drafting the PR description for the change that ships it. The without arm drafted under the globals fallback, which is what the dispatch table served for PR descriptions before this file existed.

Both arms matched the repo's log convention in the title, neither invented an issue reference where no issue exists, and neither carried a trailer or a footer. The globals and the ambient rules already cover that much. Two things separated the drafts.

The without arm built the body as `## Summary` / `## Changes` / `## Testing` and filled the middle section with a file-by-file walk of the diff. The with arm spent that space on where the reviewer should spend theirs: "Start with `references/pr-descriptions.md`; it's the only substantive change. The edits to README.md, SKILL.md, and commit-messages.md are one or two lines wiring it in."

Testing was the other split. The without arm wrote "Not run while drafting this description." The with arm named both halves: what it had checked by hand, then "I did not run `tests/technical-writing-smoke.sh` myself, so run it before merging."

This pair was captured before the profile carried this section, and the same run exposed the no-merged-PRs case that the Title section now covers, so the PR that ships this profile reads a little differently from the drafts above.

## Layer Application

- **STE**—one thought per sentence, split past roughly 25 words, and the condition goes before what it governs: "If you only read one file, read the parser."
- **Google developer style**—active voice, naming who does what. "This PR moves the check into the router", not "the check was moved into the router." Address the reviewer as "you" where you're walking them through the diff.
- **Global English**—one name per thing across the title, the body, and the linked issue, so what you called the guard up top isn't the check three paragraphs later. Keep "only" next to the word it modifies. Every "this" points at one obvious noun, which matters most in a list of what to scrutinize.
