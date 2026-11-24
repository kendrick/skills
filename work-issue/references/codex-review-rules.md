Maintainer note: `work-issue/scripts/review-rules.py install <repo>` copies the begin marker through the end marker below into that repo's `AGENTS.md`, and `check` compares the installed copy to it byte for byte. Any edit to the text between the markers bumps the version in both markers. Nothing above the begin marker is installed.

<!-- work-issue review rules v1 begin -->
These rules come from `work-issue`, which builds this repo's agent-authored pull requests and answers their review threads. A finding that applies one cites it by its bold label.

**Declared limits.** A limitation the PR body's "Left out" section or the skill's Known Limitations already names is a decision the author recorded, so it is settled for this PR. Raise it again only when the change loses data or writes outside the files it was handed, and quote the declaration the finding overrides. Safe path: cite the declaration and review the rest of the diff.

**Heuristic scripts.** For a script whose own docs call it a heuristic, a finding built on a constructed edge case is P1. Input that a real caller in this repo produces stays P0, whatever the finding's wording. Safe path: name the caller that produces the input, or band the finding P1.

**Writes outside a task's files.** A change that lets a script write, delete, or overwrite a path the caller didn't hand it, or lose data, is P0. In the finding, name the exact path that gets overwritten or the data that gets lost, and cite this rule. Safe path: refuse the write, or restore without following links.

**Repeat findings.** Each finding states whether its line changed since the last commit you reviewed on this PR, as `changed since last review`, `unchanged since last review`, or `last review unknown` when you cannot tell which commit that was. The author reads an unchanged line as a new edge case in old code and a changed one as a repair that broke. Safe path: tag every finding.

**Evidence.** Each finding names the file and line, quotes the text it is about, and states what breaks. Where running something can check the finding, run it and paste the real output. Safe path: when the diff is clean, say so plainly, since zero findings is a complete review.
<!-- work-issue review rules v1 end -->
