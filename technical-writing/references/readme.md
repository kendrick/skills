# README Prose

SKILL.md dispatches here at Step 1 when the artifact is a README or a README-shaped doc—a package landing page, a directory index, anything whose job is to greet a reader deciding whether to stay. All four layers apply; Diátaxis arrives per section through the mode mapping below, not at the file level. This profile governs the prose. The section set and its order belong to whatever authored the document and survive the audit untouched.

## Register

Warm by default. A README is the one developer-facing artifact whose reader is still deciding whether to care, so narrative sections carry voice: direct, conversational, never salesy. The mapping below dries out the sections that want dryness.

Where the README already carries an author's voice—emoji headers, first person, dry humor—that voice is the register: fix what reads two ways and leave how it sounds alone.

## Mode Mapping

One section, one mode. Which one depends on the question the section answers:

- **"What is this, and why would I use it?"**—the title line, the value proposition, the hook, a features or comparison section—is explanation mode, warm. Voice is allowed; the claim still has to be concrete, naming what the thing does rather than its vibe.
- **"How do I run it?"**—install, quickstart, usage, development and testing setup, contributing steps—is how-to mode, imperative. Commands as commands with the condition in front, expected output shown, and no narrative padding between steps: a reader mid-quickstart is executing, not browsing.
- **"What are the exact facts?"**—configuration tables, flag and option lists, API surface, environment variables, support matrices—is reference mode, dry. Describe, and only describe. No persuasion, no voice; dry is correct here.

Mixing them is the common failure: a quickstart that argues, a feature list that instructs, a flags table that sells.

## Content

The first screen answers the reader's first question in plain language before anything asks them to scroll. A value proposition is a claim, not a slogan—it names what the project does and for whom, and an example showing real input and real output beats a paragraph asserting the same thing.

## Hard Rules

- The audit changes wording only. It never adds, removes, or reorders a section, and never adds or drops a badge, a command, or a claim—structure belongs to whatever authored the document.
- A fact that looks wrong—a command, a path, a version—gets flagged for the author rather than silently rewritten. Fixing a fact takes the repo in front of you; without it, a plausible correction is fabrication.

## Example

From the audit run that produced this profile, over `readme-coauthorship/README.md`.

The Install section led its by-hand alternative with "Prefer to manage it by hand? Clone the collection and copy this directory in:". A question is narrative padding inside a how-to section, so the pass rewrote it condition-first: "To manage it by hand, clone the collection and copy this directory in:". Same information, imperative mode.

The same section's CLI command read `npx skills add https://github.com/kendrick/skills` while the root README and every sibling skill use `npx skills add kendrick/skills --skill <name>`. That's a fact, not a wording choice, so the Hard Rules made it a flag; with the repo in front of the run, the convention was verifiable, and the fix landed as its own change rather than as part of the audit.

The Why This Exists section—warm, opinionated, "a badge wall, a philosophy section, and install steps that assume the maintainer's machine"—survived untouched. Explanation mode allows the voice, and drying it out would have been the failure the Register section warns about.

## Layer Application

- **Diátaxis**—per section via the mode mapping, never file-wide: the same README correctly holds a warm hook, an imperative quickstart, and a dry flags table.
- **STE**—one instruction per sentence in the how-to sections, condition before the step it guards ("With Docker running, run `make up`"), split past about 20 words.
- **Google developer style**—address the reader as "you", present tense, commands as commands: "Run `npm test`", not "`npm test` can be run".
- **Global English**—one name per thing across the whole file, so the tool the hook names isn't "the CLI" in the quickstart and "the binary" in the flags table. Keep "only" against what it changes in support matrices, where "only supports macOS 14" and "supports only macOS 14" are different promises.
