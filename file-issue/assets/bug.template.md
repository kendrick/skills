<!--
Bug template. Sections are ordered by measured developer importance (Bettenburg
FSE 2008), not by habit — steps to reproduce outrank everything, and metadata
that feels obligatory (OS, product, component) ranks near zero.

[gate] sections block the write guard. Everything else is a default: fill it
when you have it, drop the heading when you don't. Never ship an empty heading.

Strip every HTML comment before rendering the draft. They are authoring
guidance, not issue content.
-->

# <title>

<!--
[gate-adjacent] Ko structure: {component} + {wrong behavior} + {trigger}.
"Token refresh drops the session when the tab is backgrounded" — not "auth bug".
Match any title prefix convention the harvest observed in this repo.
-->

## Steps to Reproduce

<!--
[gate] The one item developers rank highest (83%) and the one that most often
arrives broken — errors here are the single most severe reported problem (79%).

Runnable, not gestural. A stranger with a clean checkout must be able to follow
these without asking anything.

  Bad:  "log in and go to settings, it breaks"
  Good: 1. `pnpm dev`
        2. Sign in as any user
        3. Open a second tab, wait 60s, return to the first tab
        4. Click Save
-->

1.
2.
3.

## Observed vs. Expected

<!--
[gate] Two separate statements. Cheap for the reporter (2-3% difficulty) and
high-value to the developer; errors in observed behavior carry 48% severity.
Collapsing them into one sentence is how the expectation goes unstated.
-->

**Observed:**

**Expected:**

## Error Output

<!--
[gate where applicable] 57% developer importance. Reports carrying stack traces
get fixed sooner and are likelier to reach a FIXED resolution.

Applicable = the failure produces a trace, a console error, a non-zero exit, or
a server log. Silent visual bugs have none — drop the section rather than
padding it. Fence as a code block; keep it verbatim.
-->

```
```

## Minimal Reproduction

<!--
[optional] High developer value (51%) but the single hardest thing to ask for
(75% of reporters find it hard). Offer it, never gate on it. A failing test, a
gist, a stripped-down branch.
-->

## Environment

<!--
[non-blocking] Version, OS, browser, runtime. Developers rank these near zero
(OS 4%, product 5%, component 3%) and they are cheap to supply, so collect them
without spending a question and never hold the issue for them. Value varies by
project type: it matters more for native and mobile than for a web service.
-->

## Screenshots

<!--
[GUI bugs only] Helpful for a subset of bugs — visual and layout defects. Omit
the heading entirely for anything non-visual.
-->

## For a Coding Agent

<!--
Include this block only when the issue will be assigned to a coding agent.
Then it is a gate, and every line has to resolve. An agent in an ephemeral
sandbox has none of the tacit local knowledge a teammate reuses without
noticing.
-->

- **Verify with:** <the exact command, e.g. `pnpm test src/auth/session.test.ts`>
- **Setup:** <deps, versions, env vars, or the file that documents them>
- **Start here:** <file and module paths>
- **Done when:** <binary condition>
- **Out of scope:** <what not to touch>
