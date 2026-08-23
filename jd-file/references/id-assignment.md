# ID Assignment

Read this at Step 3, before any number is minted, and before proposing a new category to a user who did not ask for one.

Step 3's three outcomes ascend in cost because they descend in reversibility. Expanding an existing ID is undone by moving a file. Minting a new ID is close to permanent—the number leaks immediately into `file://` links, into folder names in two other trees, and into the user's memory of where things live. Creating a category changes the shape of the system for years. Take the first move that fits.

## Test 1 — Does an existing ID already cover this?

Read the purpose clause of every ID in the target category, from the register rather than from the folder names. Folder names are labels; the purpose clause is the sentence written to answer exactly this question.

An existing ID absorbs the thing when the thing is another instance of what that ID is for. It does not absorb the thing merely because both are "about" the same broad topic—an HOA folder and a car policy are both records, and that shared abstraction is too weak to file on.

When an ID nearly fits but its purpose clause is narrower than the subject it has grown into, the move is to widen the purpose clause and keep the number. Rewriting a sentence is cheap; renumbering is not.

## Test 2 — Does this earn an ID at all?

The constitution sets the bar: an item is for something long-running that will hold several related notes and get referenced over time. Individual meetings, one-off thoughts, and temporary work are notes inside an existing ID, not IDs of their own.

The test that catches most mistakes: name the next three things that will land here. If you cannot, the subject is a note, and minting an ID for it just moves the "where does this go" problem down one level where it will be harder to see.

## Finding the next free number

Take the union of what the register lists for the category and what every in-scope substrate actually contains, then pick the lowest number above the highest one in use. Union, not either source alone—a number present in a substrate but missing from the register is drift, and reusing it converts a reportable inconsistency into a genuine collision.

Gaps are free (`[rules].require_contiguous_ids`). A category that starts at `.10` is complete as it stands; the numbers exist to reduce the effort of finding things, not to consume the sequence tidily. So leave every gap where it is, and open a new one only when the user has a reason—reserving a run for a group that is arriving.

Retired numbers stay retired. The old name survives in absolute links, in other people's bookmarks, and in whatever the user remembers, and all three resolve to the wrong thing quietly once the number is reissued.

`[rules].meta_slot_item` reserves the high number in each category for category-level meta, the way a journal covering every client sits at the top of the clients category rather than beside them. Keep that number for meta, and read its absence as normal—most categories have no such note.

A category holds one hundred IDs. Approaching that ceiling is worth reporting to the user, because it usually means the category is really two—but the split is a structural decision and belongs to them.

## Test 3 — When a new category is actually right

Every test below has to pass. Any single failure means the subject is an ID inside an existing category.

| Test | Failing looks like |
|---|---|
| The subject is a different kind of thing, not a subtype of something already categorized | "Vehicles" versus "Property & Records"—the second already covers ownership records of every kind |
| You can write a one-line description that overlaps no existing category | A description that has to say "except the parts that live in X" |
| Several IDs will populate it within a year | One ID, with a plan to add more later |
| No existing ID has to be renumbered to accommodate it | Any proposal containing the word "move" |
| A free number exists in the right area | Needing to renumber categories, which is an area-level change |

Areas are the coarsest commitment in the system, so a new one is a further step again: proposing it says the existing ten did not describe the user's life, which is a conclusion they get to reach themselves.

## The depth invariant

Numbering stops at AC.ID (`[rules].max_numbered_depth`, `[rules].numbered_depth_below_id`). Everything below an ID is unnumbered, free-form, and often very deep—a client ID carries its own memory store, project folders, pursuit folders, and git repositories many levels down, and all of that is correct.

When you find yourself wanting `AC.ID.NN`, what you want is a named subfolder. The urge usually signals that the ID is holding two subjects, in which case the answer is a second ID, or that a sequence needs ordering, in which case dates in filenames order it without inventing a tier.

## Labels

Name an ID for the durable subject, never for the artifact that triggered its creation. The artifact is the least stable thing in the situation: a renewal PDF becomes a policy history, a kickoff deck becomes an engagement.

Before committing a label, check whether that same name already exists under a different number anywhere—the register, and every substrate. One name under two numbers is a split, and a split is invisible to any check that joins on numbers, so it survives until a human notices two folders with the same name in different categories. Catching it at mint time costs one search.

Match the category's existing naming convention rather than an external standard. If client IDs there are bare company names, the next one is a bare company name.
