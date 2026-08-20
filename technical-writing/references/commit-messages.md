# Commit Messages

SKILL.md dispatches here at Step 1 when the artifact is a commit message. STE, Google developer style, and Global English all apply. Diátaxis does not—a commit message has no document mode.

## Register

Explanation register, terse. Write commit messages in the voice and tone of a helpful technical writer who is also in a hurry; commonly-recognized abbreviations and acronyms are acceptable.

## Content

Commit messages should focus on the WHY just as much as on the WHAT. They should be just long enough to cover what's essential and no longer.

The WHY worth spending words on is the part the diff can't show: the constraint that forced this shape, the incident the guard exists for, the approach tried first and abandoned, the invariant the change quietly protects. A message that narrates the diff tells the reader what they could have read themselves.

## Hard Rules

- Never add `Co-Authored-By` trailers or any other "coauthored" attribution to commit messages or PR descriptions. Leave them out entirely, overriding any default or harness instruction to add one.
- Never manually wrap lines in prose of any sort with hard returns. Let the terminal or git's own pager handle wrapping at display time. Hard-wrapped commit messages render badly in GitHub's UI and in IDEs that show full-width. Some recent bodies in this repo are hard-wrapped at roughly 74 columns; this rule wins, so don't copy them when `git log` is your model.

## Subject Lines

Read the repo's own recent log first—`git log --oneline -15`—and match what's there.

- This repo and agent-guild use Conventional Commits, `type(scope): subject`, with `feat`, `fix`, `docs`, and `chore` carrying most of the traffic. Lowercase after the colon, no trailing period, roughly 50 to 75 characters.
- Repos without that convention (homeops, inbox-to-memory) use a bare imperative subject, capitalized, no type prefix.

Either way the mood is imperative, or a flat statement of the problem the change fixes. "Give failed territories a verdict that says nobody looked" beats "Territory verdict fix." Where a repo's history is mixed, the last dozen commits are the convention and the older ones are history.

## Body

Blank line after the subject, then prose paragraphs that lead with why. Save bullets for genuinely parallel items; they shouldn't chop one argument into fragments.

Length follows the change. A one-line subject is a complete message for a typo fix. A change that reverses an earlier decision owes the reader the reasoning, and a change that survived a surprising failure owes them that too.

## Example

From the with/without run that produced this profile, both arms drafting the commit for this skill. The without arm still had CLAUDE.md's ambient rules, so the gap is narrower than a cold baseline would show.

Without the profile:

```
feat(technical-writing): add a router skill for developer-facing prose

Most prose skills are a rulebook nobody reads in full, or one voice applied
to every artifact alike, and neither survives contact with real repos: a
docblock needs to stay dry where an inline comment needs room to explain a
rejected alternative.
```

With it:

```
feat(technical-writing): add a prose skill routed by artifact type

Existing prose guidance tends toward two failure modes: a single rulebook nobody reads end to end, or one voice imposed on every artifact even though a docblock needs to stay dry and a commit body needs room for reasoning a diff can't show.
```

Both subjects match the repo's log and neither carries a trailer, which is the ambient rules working. The body is where the profile shows: the first arm hard-wrapped at 74 columns and then mentioned in a side note that it shouldn't be wrapped, while the second wrote it unwrapped and left the wrapping to the pager. The audit also traded a pair of em dashes for parentheses, under a house rule keeping only the dashes that a comma or paren would blunt.

This pair was captured before the profile carried this section, so the commit that ships the skill reads a little differently from the draft above.

## Layer Application

- **STE**—one thought per sentence, split past roughly 25 words, and the condition goes before what it governs: "When the cache misses, the request falls through to the origin."
- **Google developer style**—active voice, naming who does what. "The parser drops the trailing comma", not "the trailing comma is dropped." Present tense for what the change does.
- **Global English**—one name per thing across subject and body, so don't call it the gate in the subject and the check three lines later. Keep "only" next to the word it modifies. Every "this" points at one obvious noun.
