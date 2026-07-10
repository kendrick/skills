# What Makes a Great README — And How to Build a Wizard-Style Skill to Write Them

## TL;DR

- A great README hooks a reader in seconds by leading with a plain-language value proposition, then uses "cognitive funneling"[^artofreadme] to move from what-and-why → is-this-for-me → how-to-start → deeper reference, letting readers "short-circuit" the moment they know it isn't for them. Voice and concrete examples—not badge walls—separate a memorable README from a templated one.
- Serving AI agents well is now a distinct, measurable requirement handled BEST by keeping the human README concise and pushing agent-specific operational detail into a complementary AGENTS.md[^agentsmd] plus tool-specific files like CLAUDE.md; ETH Zurich research[^eth] shows badly-scoped context files actively HURT agent performance, so "machine-readable" means clean structure and non-inferable commands/constraints, not verbose duplication.
- A README-writing skill should run a short, type-aware wizard: detect repo type and scan metadata (package.json, license, git remote, CI, directory tree), ask a handful of targeted questions (audience, problem solved, fastest path to "it works"), generate from a type-specific template, never fabricate, and validate the output against a checklist.

## Key Findings

1. **The opening does almost all the work.** Readers decide in seconds. Lead with the project name, a one-line value proposition in plain language, and (for many project types) a runnable example—before installation or configuration.
2. **Structure by reader need, ordered as a funnel.** General → specific: name, description/value prop, visual or example, "is this for me," quickstart, usage, then reference/config/contributing/license. This mirrors both _Art of README_'s cognitive funneling[^artofreadme] and the Diátaxis separation of tutorial/how-to/reference/explanation.[^diataxis]
3. **Concrete examples beat prose claims.** Every strong-README source converges on "show, don't tell": minimal working examples, copy-pasteable commands in fenced blocks, expected output.
4. **Personality is a feature, not a risk—within limits.** A conversational, human voice[^google] makes READMEs engaging; the failure mode is either sterile templating or unprofessional throwaway tone.
5. **Badges/visuals help when they carry real signal and hurt when they clutter.** Screenshots/GIFs for anything visual; a demo GIF for CLIs; diagrams (Mermaid) for architecture; but only badges for things that actually exist.
6. **Length: as long as needed, no longer; use progressive disclosure.** Keep the README to what's needed to get started and contribute; link out (or use `<details>`) for deep reference.[^github]
7. **AI-actionability is a separate layer.** READMEs for humans; AGENTS.md/CLAUDE.md for agents. Clean headings, tables, explicit command references, and file/directory maps help agents parse; verbose auto-generated context files measurably degrade agent success and raise cost.[^eth]
8. **Nested READMEs are navigational.** A subdirectory README explains that directory's purpose, points up to the root, and stays scoped—mirroring how nested AGENTS.md files work (nearest file wins).[^agentsmd]

## Details

### A. Root / project-level README craft

**Setting the hook (the first screen).**
The single highest-leverage part of a README is the top. Nate Berkopec's `github-readme` skill[^berkopec] frames the reader's questions in strict order: "1. What is this project? 2. Why should I use it? 3. How do I run it right now? 4. How do I configure common cases? 5. How do I contribute?" Bane Sullivan (banesullivan/README)[^banesullivan] argues a "Highlights"/bulleted selling-points list near the very top is one of the most important sections, and that build/development instructions should be pushed to the bottom so they don't scare off the average user.

_Art of README_ (Kira Oakley, widely read as the canonical essay) and its companion tool common-readme codify **cognitive funneling**:[^artofreadme] "Start with the most general information at the top (Name, Description, Examples) and if the reader maintains interest, narrow down to specifics (API, Installation). This makes it easy for readers to 'short circuit' and continue the hunt for the right module elsewhere without wasting time." A related principle from perlmodstyle, quoted by common-readme: "Ideally, someone who's slightly familiar with your module should be able to refresh their memory without hitting 'page down.' As your reader continues through the document, they should receive a progressively greater amount of knowledge."

**Concrete opener guidance:**

- One-sentence description ("what + why"), placed immediately under the title, under ~120 characters (standard-readme requires the short description be its own line and under 120 chars, matching the package manager / GitHub description).[^standardreadme]
- Follow with a "Why" / value proposition. A widely-shared 2026 practitioner guide argues most READMEs wrongly skip straight to installation: "Before I install anything, I need to know why this exists. What problem does it solve?... Two sentences here save your users twenty minutes of research."
- Aggressively linkify references (Art of README)[^artofreadme] and, if the project sits in a crowded space, add a brief comparison table and an explicit "non-goals" section (signals scope and maturity).

**Answering "is this for me?"** — purpose, scope, audience, problem solved. Communicate target audience and prerequisites early; state supported platforms/versions; add a Background section when the project depends on non-obvious concepts (Art of README).[^artofreadme] softaworks/crafting-effective-readmes[^softaworks] stresses audience-awareness as its first best practice: "Always ask about audience — Don't assume OSS defaults for everything."

**Getting started / usage.** makeareadme.com:[^makeareadme] list _specific_ install steps (don't assume the ecosystem is obvious), add a Requirements subsection for version/OS/dependency constraints, "use examples liberally, and show the expected output if you can," keeping the smallest inline example and linking to bigger ones. The Berkopec skill:[^berkopec] "Add a runnable quickstart with copy-pastable commands," "Add usage examples for the 1–3 most common tasks," "Add configuration/reference sections only after core onboarding is complete."

**Ideal section order (default, adapt per type).** A synthesized default from the Berkopec skill,[^berkopec] standard-readme,[^standardreadme] Best-README-Template,[^bestreadme] and makeareadme.com:[^makeareadme]

1. Title / logo
2. One-line description + value proposition (and badges, if warranted)
3. Visual (screenshot / GIF / demo) when applicable
4. Table of contents (only if long — standard-readme: required over ~100 lines, GitHub auto-generates an Outline)
5. Features / highlights
6. Install (with prerequisites)
7. Quickstart / Usage (with examples + expected output)
8. Configuration / API reference (or link out)
9. Development / testing
10. Contributing (or link to CONTRIBUTING.md)
11. License
12. Acknowledgements / contact

standard-readme's required order for compliant OSS libraries: Title → (Banner) → short description → (badges/ToC) → Background → Install → Usage → (API) → Contributing → License, with Install and Usage required for installable projects and Contributing/License always required.[^standardreadme]

**Voice, tone, and the "human touch."** The Google developer documentation style guide[^google] is the most authoritative articulation: aim for "conversational, friendly, and respectful without using slang," "sound like a knowledgeable friend," "Be human, let your personality show, and be memorable," and don't overuse "please" in instructions. Bane Sullivan[^banesullivan] uses emoji in section headers deliberately as navigation aids and to break up plain text. The counter-example (from a Medium "README Rules" piece): an overly-casual throwaway tone ("Hey guys this is just something I made real quick lol") undersells the work. The synthesis: a distinct, confident, warm voice that still delivers information directly.

**Badges, visuals, diagrams.** makeareadme.com:[^makeareadme] screenshots or GIFs where it's visual (ttygif/Asciinema for terminals). standard-readme[^standardreadme] and the Berkopec skill:[^berkopec] place badges near the top but avoid clutter. The readme-wizard skill's[^readmewizard] "Golden rule": "Only include badges for things that actually exist. A badge for a nonexistent CI workflow or a guessed npm package is worse than no badge at all." GitHub Flavored Markdown extras worth using _when they add value_ (Berkopec skill):[^berkopec] `<kbd>` for keys, `<details>`/`<summary>` for collapsible deep-dives, Mermaid for architecture/flow/sequence diagrams, alerts (`> [!NOTE]`, `> [!WARNING]`) sparingly (one or two max), `<picture>` for dark/light variants.

**Length & progressive disclosure.** makeareadme.com:[^makeareadme] "while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information." GitHub Docs:[^github] keep the README to getting-started + contributing; longer docs belong in a wiki. Use relative links for in-repo docs (GitHub rewrites them per branch). Diátaxis[^diataxis] provides the deeper principle: don't mix tutorial, how-to, reference, and explanation in one blob—separate them so each serves its purpose.

**Common anti-patterns to avoid (synthesized):**

- The empty / name-only README ("opening a restaurant with no sign").
- The "obvious to me" README—install steps that assume the ecosystem ("run make install" with no dependencies/platforms).
- The "see the docs" README—one line pointing to an empty/auth-walled wiki; the README is the entry point.
- Wall of text (no headers/lists/spacing).
- No examples; no visuals for visual projects.
- Stale content (commands/paths that no longer exist); add "last reviewed" dates for internal/config repos (softaworks).[^softaworks]
- Burying setup deep in prose; complex build instructions above the average user's needs.
- Badge overload; badges for things that don't exist.
- Generic templated tone with no audience awareness.

### B. README needs by project type (keep general, adapt)

Across softaworks[^softaworks] (OSS / personal / internal / config), readme-wizard[^readmewizard] (libraries / apps / docs-repos / small utilities), and llm-docs-optimizer[^llmdocs] (library / CLI / framework / skill), the consistent lesson is **adapt sections to type and keep proportional to size** ("a simple script doesn't need a 200-line README"):

- **Libraries / frameworks:** installation, API, examples; documentation should be complete enough to use the module without reading its code (standard-readme).[^standardreadme]
- **CLI tools:** the common commands/flags, a demo GIF, copy-paste quickstart.
- **Applications:** setup, configuration, screenshots, environment/`.env` guidance (never commit secrets).
- **Docs / learning repos:** structure and navigation over install.
- **Small utilities / dotfiles / config:** short — hero + what it does + usage; softaworks[^softaworks] adds "What's Here," "How to Extend," "Gotchas," and "Last Reviewed" for config dirs, whose audience is "future you (confused)."
- **Monorepos / design systems / agent-skill repos:** root README orients + maps subprojects; each package/subdir gets its own scoped README (and, for agents, its own nested AGENTS.md).

### C. AI-actionability & machine-readable structure (critical secondary focus)

**How agents actually read repos.** Two paradigms coexist. IDE-based tools (Cursor, Windsurf, Copilot) use RAG: AST-aware chunking via tree-sitter at function/class boundaries, code-specialized embeddings, vector stores, Merkle-tree re-indexing (Cursor re-indexes roughly every 10 minutes via Merkle-tree diffs). Agentic CLIs (Claude Code) instead navigate like a developer—`read_file`, `list_directory`, exact-match grep/find, reasoning over a large context window—no vector DB. Implication for docs: clear headings, explicit file/directory maps, and command references are directly useful to agentic tools that literally read and grep your files; consistent markdown structure and de-duplicated content help RAG chunkers too. "Lost in the middle" (Stanford; models show 20–25% accuracy variance depending on where information sits in a long context)[^lostmiddle] means the most important pointers should sit near the top, not buried mid-file.

**The file landscape.**

- **README.md** — for humans. AGENTS.md's own site[^agentsmd] is explicit: "README.md files are for humans... AGENTS.md complements this by containing the extra, sometimes detailed context coding agents need: build steps, tests, and conventions that might clutter a README."
- **AGENTS.md** — the open standard ("a README for agents"), plain Markdown with no required fields; popular sections: project overview, setup/build/test commands, code style, testing instructions, security considerations, PR/commit conventions. Released by OpenAI in August 2025 and donated to the Linux Foundation's Agentic AI Foundation (AAIF, formed December 9, 2025, alongside Anthropic's MCP and Block's goose).[^lf] Per the Linux Foundation,[^lf] AGENTS.md "has already been adopted by more than 60,000 open source projects and agent frameworks including Amp, Codex, Cursor, Devin, Factory, Gemini CLI, GitHub Copilot, Jules and VS Code." Nested files are supported: "the nearest file in the directory tree takes precedence"[^agentsmd] — and, per agents.md, "at time of writing the main OpenAI repo has 88 AGENTS.md files."
- **CLAUDE.md** — Claude Code's native memory file, auto-loaded every session; "written to govern," whereas README is "written to inform." Often symlinked to AGENTS.md for a single source of truth.
- **llms.txt / llms-full.txt** — Jeremy Howard / Answer.AI proposal (Sept 2024):[^llmstxt] a root `/llms.txt` Markdown file with an H1 project name (only required element), a blockquote summary, and H2-delimited curated link lists (with an "Optional" section that can be skipped for shorter context). It's for _inference-time_ website/docs navigation, complementing (not replacing) sitemap.xml/robots.txt.
- **.cursorrules** and other tool-specific rule files — being consolidated under the AGENTS.md umbrella; tools like Ruler synthesize one source into many.

**What the evidence says about agent-facing docs (this is the key, non-obvious finding).** ETH Zurich research[^eth] — Gloaguen, Mündler, Müller, Raychev & Vechev, "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?" (arXiv:2602.11988, Feb 2026; ICLR 2026 workshop) — studied whether context files actually help. Across 438 tasks (SWE-bench Lite plus a new 138-task "AGENTbench" of repos with developer-committed context files), and using Claude Sonnet 4.5, GPT-5.x (Codex), and Qwen3-30B, the paper's abstract states context files "tend to reduce task success rates compared to providing no repository context, while also increasing inference cost by over 20%." LLM-generated (auto-init) files reduced task success in 5 of 8 tested settings (≈−3%) and added 2.45–3.92 steps per task; developer-written files helped only modestly (~+4 percentage points on AGENTbench). The mechanism: agents dutifully follow instructions—running extra tests, reading more files, more grep—which is often unnecessary for the task, making reasoning models "think harder" without better patches. A follow-up removing all _other_ documentation found LLM-generated files then improved performance by 2.7%, confirming the redundancy insight: agents already discover most of that content independently. The actionable conclusion: agent docs should contain **only minimal requirements, custom/non-standard commands, and specific tooling choices**—things the agent cannot infer by reading the repo. Architecture overviews specifically don't help (per the Augment Code guide summarizing the study):[^augment] removing an "Architecture" section while keeping commands/constraints/non-standard patterns "produces the same agent behavior at a lower token budget."

**Length/budget for agent files.** Practitioner consensus originates with HumanLayer's "Writing a good CLAUDE.md":[^humanlayer] "Frontier thinking LLMs can follow ~150-200 instructions with reasonable consistency... As instruction count increases, instruction-following quality decreases uniformly" (i.e., the model doesn't just drop the newest rules—adherence to _all_ of them degrades). Claude Code's own system prompt already consumes ~50 of those slots, and HumanLayer keeps its own root file under 60 lines. General consensus: keep CLAUDE.md/AGENTS.md under ~200–300 lines; split into nested per-directory files beyond ~150–200 lines. Use emphasis markers (IMPORTANT, YOU MUST) and explicit negative rules ("never commit .env"). Use pointers/`file:line` references, not pasted code.

**A counter-example that reinforces the rule.** Vercel found[^vercel] that embedding a _compressed docs index_ directly in AGENTS.md beat on-demand "skills" retrieval for teaching new Next.js 16 APIs: a compressed 8KB index reached a 100% pass rate versus 79% for skills-with-instructions and a 53% no-docs baseline—because passive context has "no decision point," is consistently available, and avoids ordering issues (in 56% of eval cases the skill was never invoked). This is not a contradiction of ETH: the winning artifact was a tight, high-signal, pipe-delimited lookup index of non-inferable information (new APIs outside training data), compressed 80% (40KB → 8KB) with no loss of pass rate, and carrying an explicit instruction to "prefer retrieval-led reasoning over pre-training-led reasoning."

**Serving humans and agents at once without going robotic.** Practical rules:

- Keep the README human and warm; move build/test/lint/convention minutiae to AGENTS.md/CLAUDE.md.
- Use clean, consistent, semantic headings and tables (they help scanning humans AND parsing agents).
- Put a short, explicit "Project structure" / file map in the README or AGENTS.md (helps agents locate entry points; helps new humans too).
- Put command references in fenced code blocks with the exact commands.
- Don't duplicate what the repo already makes discoverable; redundancy costs agent tokens and adds no signal.
- Structuring content around the developer's real questions (llm-docs-optimizer / Context7 c7score approach:[^llmdocs] turn "Installation" into "How do I install X?") aids LLM retrieval and reads naturally to humans.

### D. Nested / subdirectory READMEs

Consensus from monorepo practice (Tweag,[^tweag] Wix sample-monorepo, GitHub community discussions) and the AGENTS.md nested pattern:[^agentsmd]

- **Purpose is local and navigational.** A nested README explains _that_ directory: what the package/module is, who owns it, how to run/test just it, its local dependencies, and gotchas. Tweag's monorepo README-per-package[^tweag] "lists the owners... a short description of what the package is about and example commands to run the code or test it... a gentle introduction to newcomers to this package."
- **Reference the parent/root.** Link back up to the root README for global setup; don't repeat org-wide setup—link to it. The root should carry a table of contents linking down to sub-READMEs (GitHub community guidance: root is "the lobby of the building," each folder README is "the welcome mat for that specific floor").
- **Stay scoped and proportional.** Don't duplicate the root; cover only what's specific to the directory.
- **Mirror the pattern for agents.** Nested AGENTS.md files in subprojects let the nearest-file-wins rule give each package tailored agent instructions; keep each small and split when a section exceeds ~150–200 lines.
- **Consistency across folders** matters for both human and agent navigation (same section names, same style).

### E. Light survey — wizard / skill mechanics

The user's example skills reveal a consistent, reusable pattern for a README-writing wizard:

**1. Detect task and type first.** softaworks[^softaworks] branches on task (Creating / Adding / Updating / Reviewing) and project type (OSS / Personal / Internal / Config). readme-wizard[^readmewizard] adapts by type (libraries / apps / docs / utilities).

**2. Scan before asking (reduce burden, avoid fabrication).** readme-wizard[^readmewizard] runs `scan_project.sh` to collect structured JSON: project name, description, license, git remote (owner/repo), package manager (npm/yarn/pnpm/pip/cargo/go…), CI setup, social links, and a 2-level directory tree. Its rule: "Never fabricate metadata — if a field is empty, skip the related section or badge entirely." standard-readme's generator[^standardreadme] pulls name/description/license from package.json to avoid re-asking.

**3. Progressive elicitation — a small, targeted question set.** From softaworks[^softaworks] and standard-readme's generator,[^standardreadme] the highest-value questions:

- What type of project is this (OSS / personal / internal / library / CLI / app / docs)?
- Who is the audience?
- What problem does it solve / why does it exist?
- What is the quickest path to "it works" (install + first run)?
- What are the 1–3 most common tasks/usages?
- Are contributions accepted? License? Maintainer handle?
- Any banner/logo, security section, background, or API section needed?
- (Review mode) Compare README against actual project state (package.json, main files) and flag stale sections.
  End with an open catch-all: "Anything else to highlight that I might have missed?" (softaworks).[^softaworks]

**4. Template + adapt, don't copy blindly.** readme-wizard[^readmewizard] uses a placeholder template (`{{PLACEHOLDER}}`) and a badges catalog, but instructs: "Adapt — don't copy blindly," drop inapplicable sections, match tone to project. It reads a best-practices reference before writing "so you produce READMEs that feel intentional rather than formulaic."

**5. Validate/audit the output.** The Berkopec skill[^berkopec] ships an audit script checking H1 presence, core onboarding sections (install, usage/quickstart), license, command code blocks, intro-length guardrail, and a ToC reminder for long files. readme-wizard[^readmewizard] validates against assertions: no leftover placeholders/TODOs, badges only for things that exist, sections proportional to project size, tone concise not marketing fluff. llm-docs-optimizer[^llmdocs] adds automated scoring (Context7 c7score) with before/after metrics.

**6. Optional enrichment.** Diagrams only when there are multiple components or a clear data flow (readme-wizard reads `diagrams.md` only then). Offer to generate a complementary AGENTS.md / llms.txt.

## Recommendations

**For building the README-writing skill — staged plan:**

_Stage 1 — Detect & scan (no user burden yet)._ Programmatically detect repo type and harvest metadata: presence/paths of package.json / pyproject.toml / Cargo.toml / go.mod, LICENSE, .github/workflows, existing README(s), directory tree (2 levels), git remote, and whether AGENTS.md/CLAUDE.md/llms.txt already exist. Infer a candidate type (library / CLI / app / framework / docs / dotfiles / monorepo / agent-skill). Never fabricate—empty field means skip the section.

_Stage 2 — Elicit the non-inferable._ Ask only what you can't detect, in priority order: audience, problem/why, fastest path to "it works," top 1–3 usages, contribution/license status, and any assets (logo, demo). Keep it to ~5–8 questions; offer sensible type-based defaults.

_Stage 3 — Generate with a funnel + type template._ Produce: title → one-line value prop (<120 chars) → optional visual → funnel of features → install → quickstart/usage with runnable, expected-output examples → config/reference (or link out) → development → contributing → license. Match the section set and length to the detected type. Write in a warm, direct, human voice; use `<details>` and Mermaid only where they earn their place.

_Stage 4 — Serve agents separately._ Offer to generate/refresh a complementary AGENTS.md (and symlink CLAUDE.md) containing ONLY non-inferable commands, constraints, tooling, and conventions—not architecture prose or duplicated docs. Keep it under ~150–200 lines; use IMPORTANT/negative rules; add a short project-structure map. For docs-heavy projects, offer llms.txt (H1 + blockquote summary + curated H2 link lists, with an Optional section).

_Stage 5 — For nested directories._ When run on a subdirectory, generate a scoped README: local purpose, owner, run/test-this-package commands, local dependencies, gotchas, and a link up to the root. Ensure the root README's ToC links down to it. Mirror with a nested AGENTS.md if the parent uses them.

_Stage 6 — Validate._ Run a checklist audit: H1 present; value prop present and short; install + usage present with fenced commands; examples show expected output; no leftover placeholders/TODOs; badges only for real artifacts; sections proportional to size; relative links for in-repo docs; tone check (human, not fluff, not sterile). Optionally score with a question-coverage heuristic.

**Thresholds that should change the guidance:**

- If README length > ~100 lines → add a table of contents; if a section is deep reference → move to `<details>` or linked docs.
- If repo type = small utility/dotfile → cap at hero + what-it-does + usage; skip contributing/license unless OSS.
- If an AGENTS.md/CLAUDE.md file exceeds ~150–200 lines → split into nested per-directory files.
- If the project has multiple components/clear data flow → add one architecture diagram (else skip).
- If agent-facing content merely restates discoverable repo facts → delete it (it costs tokens and can lower agent success per ETH Zurich).[^eth]

## Caveats

- **Agent-doc findings are early and partly vendor-summarized.** The ETH Zurich results[^eth] are from a 2026 preprint/workshop paper (arXiv:2602.11988); several specific figures reach this report via the Augment Code vendor guide[^augment] (which has a commercial CTA) rather than the paper's own text. The "150–200 instruction" limit is explicitly described by its originator (HumanLayer)[^humanlayer] as not rigorously investigated. Treat these as strong directional guidance, not settled fact.
- **The Vercel result is narrow.**[^vercel] It covers ~20 fixture tasks for one framework's new APIs with limited disclosed methodology; "passive context beats retrieval" may not generalize to all repos or agents.
- **Fast-moving conventions.** AGENTS.md, llms.txt, and CLAUDE.md practices are evolving; filenames, tool support, and stewardship (e.g., Linux Foundation involvement) may shift. Build the skill to treat these as configurable.
- **"Best README" examples are opinionated.** Sources like Best-README-Template[^bestreadme] are popular but heavyweight; several practitioners note over-templated READMEs can feel formulaic. The craft principles (funnel, examples, voice, proportionality) matter more than any single template.
- **Some cited guidance is blog/practitioner-level**, not primary research (Medium pieces, vendor blogs). Where this report states principles, they are corroborated across multiple independent sources; where a claim rests on a single source, it is attributed inline.

---

## References

[^artofreadme]: Kira Oakley (hackergrrl), _Art of README_ and the companion `common-readme` tool. https://github.com/hackergrrl/art-of-readme — perlmodstyle quoted therein.

[^diataxis]: Daniele Procida, _Diátaxis_ documentation framework (tutorials / how-to guides / reference / explanation). https://diataxis.fr

[^google]: Google _Developer Documentation Style Guide_, "Voice and tone." https://developers.google.com/style/tone

[^github]: GitHub Docs, "About READMEs" / "About the repository README file." https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes

[^makeareadme]: _Make a README_ (makeareadme.com), maintained community guide and template. https://www.makeareadme.com

[^standardreadme]: RichardLitt et al., _standard-readme_ specification and generator. https://github.com/RichardLitt/standard-readme

[^bestreadme]: Othneil Drew, _Best-README-Template_. https://github.com/othneildrew/Best-README-Template

[^banesullivan]: Bane Sullivan, _README_ (banesullivan/README) — opinionated README guidance and template. https://github.com/banesullivan/README

[^berkopec]: Nate Berkopec, `github-readme` Claude Code skill in dotfiles. https://github.com/nateberkopec/dotfiles/blob/main/files/home/.claude/skills/github-readme/SKILL.md

[^softaworks]: softaworks, `crafting-effective-readmes` skill (agent-toolkit). https://github.com/softaworks/agent-toolkit/blob/main/skills/crafting-effective-readmes/README.md

[^readmewizard]: debs-obrien, `readme-wizard` agent skill. https://github.com/debs-obrien/learn-agent-skills/blob/main/.agents/skills/readme-wizard/SKILL.md

[^llmdocs]: alonw0, `llm-docs-optimizer` (uses Context7 c7score for before/after documentation scoring). https://github.com/alonw0/llm-docs-optimizer

[^agentsmd]: _AGENTS.md_ open standard and website ("a README for agents"; nearest-file-wins nesting; OpenAI repo example). https://agents.md

[^lf]: The Linux Foundation / Agentic AI Foundation (AAIF) announcement — formation Dec 9, 2025 with AGENTS.md, MCP (Anthropic), and goose (Block); adoption figures. https://www.linuxfoundation.org

[^llmstxt]: Jeremy Howard / Answer.AI, "The /llms.txt file" proposal (Sept 2024). https://llmstxt.org

[^eth]: Gloaguen, Mündler, Müller, Raychev & Vechev (ETH Zurich / LogicStar), "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?" arXiv:2602.11988 (Feb 2026; ICLR 2026 workshop). https://arxiv.org/abs/2602.11988

[^augment]: Augment Code, vendor guide summarizing the ETH AGENTS.md study (note: commercial CTA). https://www.augmentcode.com/blog

[^humanlayer]: HumanLayer, "Writing a good CLAUDE.md" (~150–200 instruction heuristic; short root file). https://github.com/humanlayer/humanlayer

[^vercel]: Vercel, "AGENTS.md outperforms skills in our agent evals" (compressed docs index vs. on-demand skills for Next.js 16 APIs). https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals

[^lostmiddle]: Liu et al. (Stanford), "Lost in the Middle: How Language Models Use Long Contexts." arXiv:2307.03172. https://arxiv.org/abs/2307.03172

[^tweag]: Tweag, monorepo tooling write-ups on per-package README conventions (owners, description, run/test commands). https://www.tweag.io/blog
