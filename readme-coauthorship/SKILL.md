---
name: readme-coauthorship
description: Co-author README files — create a brand-new README.md, enhance an existing one in place, or rewrite it from scratch, at the repo root or in any nested subdirectory (a package, module, or monorepo workspace). Use when the user wants to write a README, update or improve the README, document this directory or package, add a README to a subfolder, review a README for staleness, or make a project more approachable. Two modes chosen up front: guided (a short wizard of targeted questions) or autopilot (infers everything from repo metadata and asks nothing beyond setup). Scans manifests, LICENSE, CI, git remote, and the directory tree before asking or writing; structures output as a cognitive funnel; never fabricates badges or sections; when a README already exists, the user chooses enhance vs rewrite and in-place vs a separate draft file; can offer a companion AGENTS.md or llms.txt. For README.md files specifically — for proposals, specs, and other prose docs, use doc-coauthoring instead.
---

# readme-coauthorship

Co-author a README in five steps — setup, harvest, brief, generate, validate — plus an optional companions step. Four axes set at the start steer every run: mode (guided or autopilot), scope (root or nested), posture (create, enhance, or rewrite), and output (in place or draft).

## Step 1 — Orient and Ask the Setup Question

Resolve the four axes before touching anything else.

Infer silently:
- **Target directory** — the path the user named, else the current directory.
- **Scope** — root when the target is the git toplevel (`git rev-parse --show-toplevel`), else nested.
- **Mode**, from phrasing — "guided", "walk me through", "ask me" → guided; "autopilot", "just write it", "don't ask me anything" → autopilot.
- **Posture**, from phrasing — no README at the target → create, unambiguously. Otherwise: "update / improve / refresh / enhance / audit / fix" → enhance; "rewrite / redo / replace / start over / from scratch" → rewrite. Any other verb, or none, leaves posture unsettled.

Then make ONE AskUserQuestion call carrying only the axes phrasing didn't settle:

- **Mode** (skip if phrasing chose): *Guided* — "I'll ask up to 8 targeted questions" vs. *Autopilot* — "I'll infer everything from the repo; this setup is the only thing I'll ask."
- **Posture + output** (only when a README exists and phrasing didn't settle posture): one question, four options — *Enhance in place / Enhance into a draft / Rewrite in place / Rewrite into a draft*. Draft default: `README.new.md` beside the target; custom path via Other.
- **Output alone** (README exists, posture settled by phrasing): *In place* vs. *Draft*.

Guards:
- No version control detected → default output to draft without asking (in-place replacement would be unrecoverable) and say so in the Step 4 state-back.
- Autopilot + create → write `README.md` directly, unattended by design: nothing exists to overwrite, and the Step 4 state-back is the interject point.

Setup is the last question autopilot ever asks.

**Done when:** mode, scope, posture, and output path are each resolved — by inference, answer, or default.

## Step 2 — Harvest

Scan before asking, and before writing. Collect from the target directory (and the repo root, for context):

| Source | Facts |
|---|---|
| Manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `*.gemspec`, …) | name, description, license field, scripts, `bin`, workspaces, entry points |
| `LICENSE` / `LICENSE.*` | license type |
| `.github/workflows/` | CI that actually exists |
| `git remote -v` | owner/repo for links and badges |
| Directory tree, 2 levels | structure, notable dirs |
| Existing README(s) at target and root | current claims, voice, links |
| `AGENTS.md` / `CLAUDE.md` / `llms.txt` | agent-doc conventions already in use |
| `CONTRIBUTING.md`, `CHANGELOG.md`, docs dirs | what to link instead of restate |

Type signals: `bin` or an entry command → CLI; workspaces or `packages/` → monorepo; exported library entry → library; Dockerfile or framework config → app; mostly `.md` files → docs repo; dotfiles → config.

Rewrite posture: mine the old README as one more harvest source — salvage its links, its badges that point at real artifacts, and its hard-won gotchas as rows; discard its structure and prose.

**Never fabricate.** Every claim, badge, and section in the output traces to a harvest row or a user answer. Absent evidence, omit the section — no invented badges, commands, or capabilities.

**Done when:** you hold a harvest digest in which every row is a concrete value or an explicit `absent` — no blanks.

## Step 3 — Fill the Brief

The brief is one artifact with seven slots; the two modes are two ways to fill it:

1. Audience — who reads this and what they already know
2. Problem — why the project exists, what it solves
3. Fastest path to "it works" — install plus first successful run
4. Top usages — the 1–3 most common tasks
5. Contribution and license posture
6. Visuals available — logo, screenshot, demo, or none
7. Anything else worth highlighting

**Guided** → read [references/elicitation.md](references/elicitation.md), then ask. Budget: at most 8 questions, exclusive of Step 1 setup; ask only what Step 1 and the harvest left non-inferable.

**Autopilot** → fill every slot from the harvest alone; mark unanswerable slots *omit*, which omits the matching sections downstream per never-fabricate.

**Enhance posture, both modes:** audit the existing README against the harvest first — list every stale claim (commands, paths, badges that no longer resolve) and every funnel gap, and feed them into the brief. Guided may spend up to 2 of its 8 questions on keep/cut calls.

**Done when:** all seven slots are answered, defaulted, or marked *omit* — no blanks.

## Step 4 — Generate the Funnel

Open with an interruptible state-back now that the harvest has firmed the signals — "Proceeding: scope=X, type=Y, posture=Z, output=P" — then continue without pausing. This is the user's correction point if scope or target was mis-inferred.

Read [references/readme-craft.md](references/readme-craft.md) before drafting — every run. Then by scope:
- **Root** → also read [references/section-templates.md](references/section-templates.md) and adapt the funnel to the detected type.
- **Nested** → instead read [references/nested-readmes.md](references/nested-readmes.md) and write a scoped, navigational README.

The funnel, in order — general to specific, so a reader can short-circuit the moment they know the project isn't for them. Adapt per type and scope; omit what the brief marked *omit*:

1. Title
2. One-line value proposition, on its own line, under 120 characters
3. Visual (screenshot / GIF / demo) when one exists
4. Table of contents, only past ~100 lines
5. Highlights / features
6. Install, with prerequisites
7. Quickstart / usage — copy-pasteable commands with expected output
8. Configuration / API reference, or a link out
9. Development / testing
10. Contributing, or a link to CONTRIBUTING.md
11. License
12. Acknowledgements / contact

Voice, in one line: a knowledgeable friend — warm, direct, human.

Posture gate:
- **Enhance** → preserve the author's voice and every live passage; rewrite only what the Step 3 audit flagged stale or funnel-violating.
- **Create / rewrite** → fresh generation from brief plus harvest.

Write the result to the Step 1 output path.

**Done when:** the draft exists at the chosen path and every section traces to a brief slot or harvest row.

## Step 5 — Validate

Check the draft against every item; fix and re-check failures:

1. Exactly one H1
2. Value proposition present, on its own line, under 120 characters
3. Install and usage present, commands fenced and copy-pasteable
4. Examples show expected output
5. No leftover placeholders or TODOs
6. Badges only for artifacts the harvest confirmed exist
7. Length and sections proportional to project type and size
8. Relative links for in-repo files
9. ToC present if the file exceeds ~100 lines
10. Nested only: links up to the root README; duplicates nothing the root covers
11. Enhance only: no stale command or path survives
12. Tone reads human — not marketing fluff, not sterile template
13. Voice is warm with no AI tells — em-dash spam, rule-of-three padding, negative parallelism, hollow -ing clauses

**Done when:** all 13 items are checked and each failure is fixed-and-rechecked or reported with a reason.

## Step 6 — Companions

- **Nested scope:** the root README should link down to this one. Guided: offer to add the link — editing the root is its own consent. Autopilot: name it as a follow-up in the wrap-up and touch nothing.
- **Both scopes:** a companion AGENTS.md (or llms.txt for docs-heavy projects) keeps agent-facing minutiae out of the human README. Guided: offer it; on acceptance, read [references/agent-companions.md](references/agent-companions.md) and build it. Autopilot: name it as a follow-up in the wrap-up and create nothing — setup was the last question.

**Done when:** the wrap-up names the output file(s), the validation result, and each companion with its status — offered-accepted, offered-declined, or stated-only.

## Further Reading

- [references/elicitation.md](references/elicitation.md) — guided-mode question set with harvest-derived defaults
- [references/readme-craft.md](references/readme-craft.md) — hook, voice, anti-slop rules, badges and visuals, anti-patterns, enhance audit method
- [references/section-templates.md](references/section-templates.md) — root-scope funnel adaptation by project type
- [references/nested-readmes.md](references/nested-readmes.md) — scoped, navigational subdirectory READMEs
- [references/agent-companions.md](references/agent-companions.md) — AGENTS.md, CLAUDE.md symlink, and llms.txt formats
