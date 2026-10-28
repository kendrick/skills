# Triage

Read this at Step 6 to score what came back from review, and again at Step 8 to answer it.

## The three states, and why they need a cutoff

| State | Rule (relative to SINCE) |
|---|---|
| findings | any unresolved review thread whose root comment, or whose latest comment from a login other than the author, is newer than SINCE; or a `CHANGES_REQUESTED` review newer than SINCE; or a pull-request-level or issue comment newer than SINCE from a login other than the author that is not a bare approval, does not open with Codex's review-summary marker comment, and, read after any leading HTML comments, does not open with Codex's no-issues verdict or its create-an-environment setup notice |
| cleared | no findings, and either an `APPROVED` review newer than SINCE, or a `+1` reaction on the pull request newer than SINCE from a login other than the author, or a comment newer than SINCE from a login other than the author that opens with Codex's no-issues verdict, read after any leading HTML comments |
| pending | neither |

SINCE is the last push, read from `RUN_DIR/pushed_at`, which Step 5 writes just before pushing. Everything above is scored against it, inclusively: an event stamped the same second as the cutoff counts, since both carry one-second precision. That cutoff is what makes the whole scheme usable.

The evidence is in this repo. PR #100 carries a `+1` reaction *and* five finding threads from the same reviewer, opened earlier the same day:

```
$ gh api repos/kendrick/skills/issues/100/reactions --jq '.[] | "\(.content) \(.user.login) \(.created_at)"'
+1 chatgpt-codex-connector[bot] 2026-09-15T19:06:03Z
```

A reviewer that signals approval with a reaction is approving the push it was looking at, not the pull request as an object. Read without a cutoff, that reaction says "cleared" forever, including across every later push that introduced the bug. Read against SINCE, it says what it actually meant: this push, at this moment, looked fine to somebody.

The `findings`-outranks-`cleared` order matters for the same reason. A reviewer can leave an approving reaction and a blocking thread in one pass, and a run that sees the reaction first stops looking.

**Cleared counts an approving reaction or review, or a comment opening with Codex's no-issues verdict, from any login other than the pull request's author, newer than the last push.** The verdict is matched by the comment's opening, read after any leading HTML comments, never by who posted it. GitHub renders no `<!-- … -->`, and Codex writes a `<!-- codex-review-receipt:v1 -->` marker ahead of the verdict, so the first text a reader sees is the opening that counts. There is no bot allowlist: a run that only accepts approval from a list of known logins ignores the human who actually looked, and a list of trusted bots goes stale the week somebody changes their CI.

## The `[bot]` rule

Strip a trailing `[bot]` from every login before comparing. REST reports `chatgpt-codex-connector[bot]`; GraphQL reports `chatgpt-codex-connector` for the same account. Compared unstripped, one reviewer reads as two different logins depending on which API answered, and the author check that distinguishes a real reviewer from the run's own voice starts passing for the wrong reason.

## The in-scope test

A finding is **in scope** where any of these holds:

- it points at a line inside `git diff BASE_SHA..HEAD`
- it names a CRITERIA line
- it names a task in the plan

It is **out of scope** otherwise. Two shapes account for most of them: pre-existing code the diff did not touch, and a capability neither the issue nor the plan ever asked for. The issue this skill came from has the second kind on record — a reviewer asking for `navigator.storage.persist()` on a change that was about something else entirely. The suggestion was good. It was also a new feature, arriving through a review thread, with no issue behind it and no plan covering it, and building it there would have grown the diff past what anyone approved.

Every row of `RUN_DIR/triage/round-<k>.md` carries a `Severity` cell: the reviewer's marker, `P0`, `P1`, or `P2`, or `-` where they gave none. Take it from the badge or bold run that opens the finding's body in `RUN_DIR/review/poll-<k>.json`, never from words later in the body. `run-state.py`'s deciding line is no substitute: it marks thread lines only, and it matches `P0` or `P1` anywhere in the body, so a finding that says "not a P1" reads as one. Write `blocking` where the finding says it blocks merge in words rather than a badge. Step 8 reads this cell to decide whether a repair goes back through `adversarial-review`, and the resume probe counts it, so write the marker alone in the cell.

Ambiguous goes in scope where the reviewer marked it P0, and out otherwise. Either way the ambiguity is recorded on the row, because the next reader's question is always why this one went the way it did.

Scope is not a judgment about whether the finding is right. An out-of-scope finding can be entirely correct and still belong in the queue; what puts it there is that fixing it here would make this pull request about something the issue did not ask for.

## The round file

Each round is `RUN_DIR/triage/round-<k>.md`, and its first line is its heading: `# Triage round <k>, since <SINCE>`. `<SINCE>` is the exact `--since` value the poll that returned `findings` ran with, which is the contents of `RUN_DIR/pushed_at`, copied verbatim. Write it once, when the round is created, and never rewrite it. The table of rows follows, under this header:

```
| # | Source | Finding | Severity | Scope | Reply |
```

The resume probe reads the Severity, Scope, and Reply cells by their header names, so keep those three names as written. A round missing one of those columns reads `null` for every probe field that needs it, and the run stops naming that field. The Reply cell stays empty until Step 8 posts the reply, then holds that reply's URL.

The resume probe decides whether the newest round is current by comparing this recorded SINCE with `pushed_at` (`triage_newer_than_since` in `references/resume.md`). The file itself changes after the push that answers it, because Step 8 writes each reply URL into its row, so nothing but the heading can say which push a round was written against. A round with no `since` in its heading stops the run.

## The review round cap

An in-scope row gets queued for two reasons: the review round cap, and a human's deferral at the cap stop or row 16's budget stop. Round k is capped once k reaches N, the value `--max-review-rounds` set and Step 0 wrote to `RUN_DIR/max_review_rounds` (`2` where the file is absent). In a capped round, each in-scope row's Scope cell reads `in scope; queued: review round cap reached (N)`, and the row is appended to `queue.md` with Outside-because `review round cap reached (N)`. The cell keeps `in scope` at its head because the finding was in scope and the record should say so. The resume probe's `triage_inscope_rows` and `triage_stop_rows` skip a cell that begins `in scope; queued:`, so a queued row is owed no repair and stops nothing.

An in-scope row whose Severity is `P0` or `blocking` is never queued this way. Its Scope cell stays `in scope`, and the resume probe's `triage_stop_rows`, which counts in-scope rows alone, stops the run on it with a reason naming the cap and the blocker. Queueing it ships a known blocker, and repairing it breaks the cap, so the call goes to a human. An out-of-scope `P0` is queued like any other out-of-scope row and stops nothing: the cap never decided its fate.

A human's deferral is written the same way. When the user defers an in-scope row at the cap stop or row 16's budget stop, its Scope cell reads `in scope; queued: <reason>`, and the row is appended to `queue.md` with that reason as Outside-because. Step 8 answers it like any other queued row. The Scope cell is the only record the resume probe reads: the reply lands at Step 8, after row 16 has already read the round, and `queue.md` also holds out-of-scope and worker rows.

## The queue

Out-of-scope rows, a capped round's in-scope rows, and a human's deferrals append to `RUN_DIR/queue.md`:

```
| # | Source | Finding | Outside because | Recommendation | Status |
```

- `Source` — the thread or comment URL, or the literal `worker` for a `plan_concerns` entry that came out of a build report rather than a review. A thread's URL is the second half of the `reply-to <id> <url>` on its deciding line; a review's or a pull-request comment's URL ends its own line; all three are in the saved poll file as `root_url` or `url`. Where the deciding line carries a `reply <ts> <url>`, the finding is that reply rather than the root: quote its body from the saved file's `comments` list (the entry whose `url` the line names, which is the newest one not by the author, not always the last), and use the reply's URL as the Source, while the reply still goes to the root's `reply-to` id.
- `Finding` — the reviewer's words, quoted. Paraphrased, it stops being searchable against the thread it came from. Neither a thread's deciding line nor a review's carries the finding's actual words — a thread's carries a severity marker, a review's carries a state, an author, and a timestamp — so the words to quote come from `RUN_DIR/review/poll-<k>.json`, written by `run-state.py review`'s `--save` flag.
- `Outside because` — which leg of the in-scope test it failed, in a clause, or `review round cap reached (N)` for a capped round's in-scope row. This is the sentence that goes back to the reviewer, so it is written to be read by them.
- `Recommendation` — usually a `file-issue` line for the human to run, with the finding and its URL. The skill writes the recommendation and leaves the filing to a person: an issue opened by an unattended run arrives with nobody's judgment attached to whether it should exist.
- `Status` — `queued`, or `filed #M` once the human has acted.

## Answering

Every finding gets a reply, and the rule is **answer, never resolve**. Marking a thread resolved is the reviewer's act. Taking it from them destroys the only signal they have that anybody read the finding, and it hides the thread from the view they use to check.

An in-scope fix, replied on the thread:

```
gh api repos/{owner}/{repo}/pulls/<pr>/comments/<comment-id>/replies -f body='Fixed in <sha>. <one line on what changed and why that addresses the finding.>'
```

`<comment-id>` is the `reply-to` id on the thread's deciding line, which the saved poll file carries as `threads[].root_comment_id`. It is the root comment's REST id, not the `PRRT_…` thread node id beside it.

Review-level and issue-level findings have no thread to reply into; those get a pull-request comment naming the finding they answer.

A queued row that names no change, posted through the same `gh api` call as an in-scope fix:

```
deferred: <Outside because>; tracked in the deferred-findings comment
```

Where the run checked whether the finding holds, add one sentence after it saying which way the check came out and what showed it. Where it did not check, the reply ends at the template, because `deferred` says where the finding went, not whether it was right.

A queued row somebody fixed anyway names that change, so it gets the in-scope fix's reply above, `<sha>` included.

A finding the run checked and changed nothing for, replied on the thread:

The body opens on its verdict by name, as `technical-writing`'s review-correspondence profile gives it, then names what was checked and what it showed. It carries no SHA, because no commit answers it, and HEAD answers nothing. This covers a refused finding, an in-scope row the repair left in `left`, and every reply in a round where each finding was refused. A queued row takes the deferred template above in place of a verdict.

Replies go through `technical-writing`, and they carry no attribution trailer or footer.

## The deferred-findings comment

One pull-request comment, headed `Deferred findings`, carrying the queue table copied byte-for-byte — a Source cell rewritten as a markdown link or wrapped in backticks compares as disjoint from the queue's bare cell, the way `divvy-up`'s owns entries once did (#97):

```
## Deferred findings

| # | Source | Finding | Outside because | Recommendation | Status |
|---|---|---|---|---|---|
| 1 | <url> | <quoted> | not in the diff under review | `file-issue` — <one line> | queued |
```

Edited in place on later rounds rather than posted again. A second comment leaves two tables on the pull request and no rule for which is current, and the reviewer reading the older one is looking at a row somebody has already dealt with. The resume probe reads this comment back and checks every queue row, whole, against it, which is why the table is quoted exactly as it appears on disk: a row the comment lacks, or carries with a changed cell, is a Step 8 still owed.
