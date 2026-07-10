# Elicitation — Guided Mode

Ask only the non-inferable. Anything Step 1 captured (mode, posture, output path) or the harvest answered (name, license, CI, commands in scripts) is settled — re-asking it burns budget and trust.

## Budget and Batching

- At most **8 questions total**, exclusive of the Step 1 setup call. Enhance-posture keep/cut questions count inside the 8.
- AskUserQuestion carries up to 4 questions per call — so at most two calls. Batch by theme: identity questions (audience, problem) first call; usage and assets second.
- Every question ships with harvest-derived default options, so the user can answer with one click. Free-text arrives via the built-in Other.
- Fewer is better. If the harvest already answers a slot well enough, skip the question and note the inference in the Step 4 state-back.

## The Question Set

Draw from these, in priority order, skipping any the harvest settled:

1. **Audience** — "Who is this README for?" Options from type signals: e.g. for a library, *developers integrating it / contributors / both*; for a config repo, *future you / teammates*.
2. **Problem** — "What problem does this solve — why does it exist?" Offer the manifest description as the default option if one exists.
3. **Fastest path to "it works"** — "What's the quickest route from clone to first success?" Default from harvest: the install command plus the most obvious first run (for a CLI, install + one invocation; for a library, install + smallest snippet; for an app, setup + dev server).
4. **Top usages** — "What are the 1–3 things people do with this most?" Defaults from `scripts`, `bin` subcommands, or exported entry points.
5. **Contribution posture** — "Accepting contributions?" Options: *yes, link CONTRIBUTING / yes, keep it informal / not right now*. Skip if CONTRIBUTING.md exists.
6. **Visuals** — "Any logo, screenshot, or demo to feature?" Only ask when the type is visual (app, CLI with TUI) and the harvest found no image assets.
7. **Catch-all closer**, always last — "Anything else to highlight that I might have missed?"

## Enhance-Posture Variants

When the Step 3 audit flagged stale or questionable material, spend up to 2 of the 8 on:

- **Keep/cut** — "The audit flagged these sections as stale or unverifiable: [list]. Keep and fix, or cut?" One question, the flagged items as options (multiSelect).
- **Voice** — "Keep the current tone, or shift it?" Only when the existing voice is distinctive (emoji headers, first person, humor) and the requested changes might collide with it.

## After Asking

Map every answer into its brief slot. A skipped or declined question resolves its slot to the harvest default or *omit* — the brief leaves Step 3 with no blanks either way.
