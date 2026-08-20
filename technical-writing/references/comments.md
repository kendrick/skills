# Code Comments

SKILL.md dispatches here at Step 1 for writing new comments and for auditing comments that already exist. All four layers apply; Diátaxis arrives through the mode mapping below rather than at the file level.

## When to Comment

Comment proactively, but only when the comment carries weight. Every comment should explain the WHY behind the code — the constraint that forced this shape, the past incident this guards against, the surprising invariant a reader might miss, the broader context the code lives inside.

## WHAT and HOW

Comments that explain WHAT the code does are worthless when the code is well-named. Comments that explain HOW the code works shouldn't be necessary if the code is written cleanly. The only comment worth writing is the one that explains something the code itself can't.

## Register

Write comments in the voice and tone of a helpful technical writer who is also in a hurry; commonly-recognized abbreviations and acronyms are acceptable.

## Mode Mapping

One comment, one mode. Which one depends on where the comment sits:

- **Docblocks**—JSDoc, TSDoc, Python docstrings, anything a tool extracts—are reference mode. Describe, and only describe: parameters, return, raises, limits. No hedging, no tutorial hand-holding, no persuasion, no voice. Dry is correct here.
- **Inline comments** are explanation mode. Why this shape, what constrains it, which alternative was rejected and what it cost. Voice is allowed.

Mixing them is the common failure: a docblock that argues, or an inline comment that restates the signature.

## Diff-Anchored Rule

Describe the thing as it is, never the change that produced it. No "this function was added to replace the previous approach", no "renamed from `oldFn`", no "see the refactor in #412 for context." A comment true only relative to a diff is stale the moment the diff merges, and the reader who arrives a year later has no diff to stand in.

The incident a comment guards against is different, and worth keeping: "the vendor API returns 200 with an empty body on rate-limit" is a fact about the world, not a note about an edit.

## Global English, Fully

Comments are where ambiguous "this" and misplaced "only" do the most damage, because there's no surrounding prose to disambiguate them.

- Every "this", "it", and "they" points at one obvious noun. Repeat the noun when the antecedent sits more than a line away.
- Keep "only" next to what it modifies. "Only retries on 5xx" and "retries only on 5xx" are different guarantees.
- Use the real symbol names in scope. A comment that calls `retryBudget` "the counter" teaches a second name for one thing.
- Keep the articles. "Remove backup file" reads two ways; "remove the backup file" reads one.

## No Stale-Adjacent Content

- No commented-out code left behind. Version control remembers it; the comment block only makes the reader wonder whether it's about to come back.
- Match the repo's existing TODO convention before writing one—read a few first. A lone `TODO(name):` in a repo that uses bare `TODO:` is noise, and the reverse loses an owner the repo expects.

## Auditing Existing Comments

Precision matters as much as recall here. A pass that rewrites healthy comments has failed even if it also caught the bad ones.

- Flag WHAT-restaters for deletion. Section banners that name the code beneath them (`# --- argument parsing ---` over the argument parsing) are the common case.
- Leave WHY comments alone, including the long-winded ones. A comment recording an incident does work that concision would destroy.
- Never invent a comment where the code already speaks. Silence is the correct output for well-named code.
- Read every surviving comment against the code it sits on, not just for whether it carries a why. A comment that claims an effect the adjacent code doesn't have is worse than no comment, because the specificity makes it read as verified.
- A banner that carries a real claim is not a WHAT-restater. `# --- stage 1: collapse every group's claim on a record to one candidate ---` tells the reader something the loop beneath it does not.

## Example

From the audit run that produced this profile, over `_maintenance/databricks-api/tools/refresh.sh`.

Flagged, one of eight like it:

```
# --- helpers ---------------------------------------------------------------
```

Deleted rather than reworded. It names the functions beneath it and claims nothing else, so every word of it is already in the code.

Kept, untouched:

```
# Mind the two hops out of MAINT_DIR. The maintenance folder and the shipped
# folder share a name, so a single `..` resolves right back here instead of
# failing, and the script would happily scan itself for domains.
```

Three lines guarding one path expression, and worth it: the trap is that the wrong `..` succeeds quietly instead of failing, which is precisely what the code cannot show. A tighter rewrite loses the reason.

The same pass over `adversarial-review/scripts/check-territories.py` changed nothing, which is the right answer for a file whose comments already carry why.
