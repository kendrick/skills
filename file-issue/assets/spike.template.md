<!--
Spike template. A time-boxed investigation whose output is a decision or a
document, never shipped production code.

Worth knowing: "spike" is convention, not a canonical type. Linear ships four
fixed types and this is not one of them; GitHub's defaults are bug and feature.
It earns its place because time-boxed research really is a different shape of
work — but if the repo's own label taxonomy has no room for it, file it as a
task rather than inventing a category the project does not use.

Strip every HTML comment before rendering the draft.
-->

# <title>

<!-- Phrase the title as the question, not the topic. "Can we migrate off X
without downtime?" beats "Investigate X migration." -->

## Question to Answer

<!--
[gate] The single question this spike exists to settle. It is also the
done-criterion: the spike is finished when this can be answered, and not one
hour sooner.

If there are three questions here, this is three spikes or one that has not
been thought through yet.
-->

## Why Now

<!-- What decision is blocked on the answer, and who is blocked. -->

## Timebox

<!--
[gate] A fixed budget — hours or days. Appetite, not estimate: this is how much
the answer is worth, not how long the work will take.

The timebox is what makes a spike a spike. Without it, an investigation runs
until someone gets bored.
-->

## Deliverable

<!--
[gate] What exists when this closes. Be specific about the artifact and where
it lands: a recommendation comment on this issue, an ADR at a named path, a
throwaway branch, a benchmark table.
-->

## Non-Goals

<!--
Always present on a spike, and the first line is always the same: no production
code. Add whatever else is out of bounds.
-->

- No production code. Findings only — anything shippable gets its own issue.
