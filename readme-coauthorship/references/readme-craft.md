# README Craft

Loaded at Step 4, every run. The funnel order lives in SKILL.md; this file is how to fill it well.

## The Hook

Readers decide in seconds, and they arrive with questions in strict order:

1. What is this project?
2. Why should I use it?
3. How do I run it right now?
4. How do I configure common cases?
5. How do I contribute?

Answer them in that order, top of file down. The whole point of the funnel is the short-circuit: a reader who learns in the first screen that this isn't for them leaves informed, not annoyed. So the first screen carries the name, the value proposition in plain language, and — for most types — a runnable example, before any installation or configuration. Someone slightly familiar with the project should be able to refresh their memory without hitting page-down.

State audience and prerequisites early. If the project sits in a crowded space, a short comparison or an explicit non-goals list signals scope and maturity faster than any adjective.

## Show, Don't Tell

Concrete examples beat prose claims everywhere they compete:

- The smallest working example inline; link to bigger ones.
- Commands in fenced blocks, copy-pasteable, with the expected output shown.
- Specific install steps — name the package manager, the version constraints, the platforms. What's obvious to the maintainer is the ecosystem knowledge a newcomer lacks.

## Voice

Write as a knowledgeable friend: conversational, warm, direct, and never slang-dependent. Personality is a feature — let it show — but it lives between two failure poles:

- **Sterile template** — grammatically perfect, interchangeable with a thousand other READMEs, no evidence a human cared.
- **Throwaway** — "hey this is just something i made real quick lol" undersells real work.

Deliver information directly and let the phrasing carry the warmth. Don't overuse "please" in instructions.

## Anti-Slop Rules

These rules apply to the README content this skill generates — not to SKILL.md or the files in references/, which are agent-facing scaffolding and stay terse and imperative. Self-apply while drafting; the Step 5 voice check is the gate. Distilled from Wikipedia's "Signs of AI writing":

- **Name the concrete benefit, not its vibe.** No significance inflation: a feature never "marks a pivotal step" or "underscores a commitment" — it does something specific; say that.
- **Cut promotional adjectives with no referent.** "Powerful", "seamless", "blazing-fast", "robust" claim nothing. Replace each with the fact that earned it ("parses 1GB logs in ~4s") or drop it.
- **No hollow -ing trailers.** Clauses like "streamlining your workflow, empowering developers" tack fake depth onto a sentence. End the sentence at the fact.
- **Say "is".** "X is a linter" beats "X serves as a comprehensive linting solution". Plain copulas, plain verbs.
- **Skip the "not just X but Y" construction.** State what the thing is; the contrast adds ceremony, not information.
- **Break the rule of three.** Triples read as manufactured completeness. Two items, four items, one item — let content set the count.
- **Prefer a period or comma to a third em-dash.** One or two em dashes across a README is punctuation; one per paragraph is a tell.
- **Filler transitions go.** "It is important to note that", "in order to", "additionally" piling up at paragraph heads — delete or replace with the plain form.
- **Watch the AI vocabulary cluster.** "Delve", "leverage", "landscape", "tapestry", "crucial", "showcase", "vibrant" — each is fine alone; together they read as generated. Prefer the ordinary word.
- **No signposting.** "Let's dive in" and "here's what you need to know" announce writing instead of doing it. Start with the content.
- **No generic upbeat closer.** READMEs end at license or acknowledgements, not at "exciting times lie ahead".
- **Describe the thing as it is, not the diff.** "Uses a hash map for O(1) lookups", never "was rewritten to replace the old approach" — unless the section is a changelog.
- **No chat residue.** "I hope this helps", "feel free to", "let me know" belong in conversation, not documentation.

## Badges and Visuals

Golden rule: only for things that actually exist. A badge for a nonexistent CI workflow or a guessed package name is worse than no badge — every badge must trace to a harvest row. Place them near the top, and stop before they clutter.

Visuals earn their place by type:

- Screenshot or GIF for anything with a visible interface.
- Terminal recording (asciinema, ttygif) for CLIs — a demo GIF near the top does more than a paragraph.
- Mermaid diagram only when there are multiple components or a real data flow to show; a diagram of one box is decoration.
- GFM extras where they pull weight: `<details>` for collapsible deep dives, `> [!NOTE]`/`> [!WARNING]` alerts at most once or twice, `<kbd>` for keys, `<picture>` for dark/light logo variants.

## Length and Progressive Disclosure

As long as needed, no longer — and when in doubt, too long beats too short: move depth elsewhere rather than cutting it.

- Past ~100 lines, add a table of contents.
- Deep reference material goes to linked docs or a `<details>` block; the README stays the entry point for getting started and contributing.
- Use relative links for in-repo files — GitHub rewrites them per branch.
- Proportionality is the master rule: a simple script doesn't need a 200-line README (type-specific caps in [section-templates.md](section-templates.md)).

## Anti-Patterns

The failure modes strong READMEs avoid:

1. Empty or name-only — a restaurant with no sign.
2. "Obvious to me" — install steps that assume the maintainer's ecosystem ("run make install", no dependencies, no platforms).
3. "See the docs" — one line pointing at an empty or auth-walled wiki; the README is the entry point.
4. Wall of text — no headers, no lists, no breathing room.
5. No examples, or no visuals for a visual project.
6. Stale content — commands and paths that no longer exist.
7. Setup buried in prose, or build internals placed above what the average user needs.
8. Badge overload, or badges for things that don't exist.
9. Generic templated tone with no audience awareness.

## Enhancing an Existing README

Enhance means the existing document is the patient, not the donor. Method:

1. **Audit against the harvest** (done in Step 3): every command run or verified against the repo, every path checked, every badge resolved. Stale claims and funnel gaps are the work list.
2. **Preserve voice.** The author's tone — emoji headers, first person, dry humor — is theirs; new and rewritten passages match it rather than the default voice above. Live passages survive verbatim.
3. **Additive first.** Prefer inserting the missing quickstart over restructuring the whole file. Reorder sections only when the current order actively fights the funnel, and rewrite a passage only when the audit flagged it.
4. Fixes to stale facts change the fact and keep the sentence.
