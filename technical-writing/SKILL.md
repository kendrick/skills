---
name: technical-writing
description: "Layered prose standard for developer-facing writing: commit messages, code comments, PR descriptions, API reference, changesets, and other technical docs, including the prose inside a README that already exists. Use when writing or reviewing a commit message, drafting or auditing code comments, describing a PR, or polishing developer documentation. Dispatches each artifact type to a profile that names which layers apply—Diátaxis document modes, Google developer style, STE sentence principles, Global English—and every draft finishes with a prose audit. Not for conversational answers, not for the code itself, and never for anything addressed to a person: emails, DMs, and other messages route to the setup's own voice process, which replaces the prose audit rather than layering on it. Authoring a whole README belongs to readme-coauthorship, and proposals and specs to doc-coauthoring. This skill governs prose style, not document-structure workflows."
---

# technical-writing

Four public standards stacked under four house rules, aimed at prose a tired engineer understands on the first read. Each artifact dispatches to a profile naming which layers apply and how they land there. Every draft ends in a prose audit, with house rules on top where they exist.

## The Rules Above the Layers

- **Cut every word that does no work.** "In order to" is "to". "It is important to note that" is nothing.
- **Use the short everyday word.** "Use", not "utilize"; "help", not "facilitate". A long word buys its length with precision or it doesn't come.
- **When a rule makes a sentence worse, fix the sentence another way.** The rules serve the reader; a sentence that obeys all of them and still reads machine-written has failed.
- **The codebase is the word list.** Write the real symbol, file, flag, and command names, never a synonym or a description of one.

## The Four Layers

**Diátaxis** decides what kind of thing a document is: tutorial (learning by doing), how-to (steps to a goal), reference (facts for lookup), explanation (understanding and why). One document, one mode—split and link rather than mix. It governs docs and reaches comments through the mode mapping; commits, PR descriptions, and changesets have no document mode, so it skips them.

**Google developer style** decides how sentences address the reader. Talk to them as "you", in the present tense, and say who does what—"the compiler checks", not "is checked". Write instructions as commands, condition first, common case before the exception. Applies everywhere.

**STE principles** decide how much one sentence carries. One instruction per sentence and one thought everywhere else, split past about 20 words for instructions and 25 otherwise, with the condition ahead of the step it guards. Keep the articles—"remove backup file" reads two ways. Applies everywhere; principles only, no dictionary or numbered-rule conformance.

**Global English** decides whether a sentence can be read two ways. Keep "only" and "not" against the word they change. Make every "it" and "this" point at one obvious thing. Break up long noun strings. Call each thing by one name. Applies everywhere, and does the most work in comments.

## Step 1 — Dispatch

| Artifact | Profile | Layers |
| --- | --- | --- |
| Commit message | [references/commit-messages.md](references/commit-messages.md) | STE, Google, Global English — no Diátaxis |
| Code comments, writing or auditing | [references/comments.md](references/comments.md) | All four; Diátaxis via the mode mapping |
| PR description | not yet written — globals above | STE, Google, Global English |
| Issue body, drafted or filed | not yet written — globals above | STE, Google, Global English |
| API reference, docblock sets | not yet written — globals above | All four; reference mode, dry |
| README, docs | not yet written — globals above | All four |
| How-to guides, walkthroughs | not yet written — globals above | All four; how-to mode |
| Release notes, changelog, migration guide | not yet written — globals above | All four |
| Changeset, workshop brief | no profile planned — globals above | STE, Google, Global English |

Read the profile fresh at dispatch; a remembered summary drifts from what it says, which is why it's a file.

Rows marked *not yet written* fall back to the globals, meaning the rules and layers above. That is a real standard and not a placeholder, so don't improvise a missing profile or write one mid-run.

**Done when:** the profile is read fresh, or the row's globals-only fallback is the acknowledged standard for the draft.

## Step 2 — Audit

Draft under the profile first. Then, in order:

1. **Self-check.** Every instruction is a command with its condition in front. No sentence carries two instructions or two thoughts. "Only" sits next to the word it changes, every "it" and "this" points at one thing, and no clause has lost its verb. Each thing has exactly one name across the artifact. Every symbol, path, flag, and count is real at this commit, and any count travels with the command that regenerates it.
2. **Run the prose audit.** Where your setup provides a prose-audit skill, invoke it formally via the Skill tool and follow its audit-and-revise loop. Applying one from memory misses tells. This skill owns the invocation, so callers route to one skill, not two.
3. **Layer the house rules.** Where your setup defines house prose rules, read them fresh and apply them over the audit, never from a remembered summary.

Register gates the audit. The profile states the artifact's register and the audit respects it: reference is dry and carries no voice, so a flat docblock is correct and shouldn't be warmed up. Explanation allows it.

**Done when:** the available audit has run and every house rule that applies either fired or was checked and cleared.

## Further Reading

- [references/commit-messages.md](references/commit-messages.md) — register, content, per-repo subject-line conventions, layers
- [references/comments.md](references/comments.md) — when a comment earns its place, mode mapping, auditing existing comments
- House prose rules, where your setup defines them — read fresh at Step 2, never summarized

## Sources

Adapted from Lauren Tan's `pstack/technical-writing` skill in `cursor/plugins` (MIT), restructured as a router with per-artifact profiles. Layers from diataxis.fr, the Google developer documentation style guide, ASD-STE100 Issue 9 (principles only), and Kohl's *Global English Style Guide*. Full provenance and deviations: [_maintenance/technical-writing/PROVENANCE.md](../_maintenance/technical-writing/PROVENANCE.md).
