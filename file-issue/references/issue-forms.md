# Issue Forms — Schema and `gh` Mechanics

Read this when the detection ladder finds `.github/ISSUE_TEMPLATE/*.yml`. Conforming to a repo's own form beats anything this skill would write on its own, and the conformance is worth getting exactly right: across 100 projects and 1.9M+ issues, YAML forms measurably reduced time-to-resolution, reopenings, and discussion length compared with plain Markdown templates.

## Where Forms Live

Resolution order, first hit wins:

1. `.github/ISSUE_TEMPLATE/*.yml` (or `.yaml`) in the target repo
2. `.github/ISSUE_TEMPLATE/*.md` — legacy Markdown templates, same repo
3. `ISSUE_TEMPLATE/` at the repo root
4. The org-level `.github` repo — it supplies default community health files to every repo in the org that lacks its own

`.github/ISSUE_TEMPLATE/config.yml` is not a template. It configures the chooser: `blank_issues_enabled` and `contact_links`. When `blank_issues_enabled: false`, the repo has decided every issue goes through a form — respect that and never fall back to the built-in templates.

Forms do not apply to pull requests.

## Top-Level Keys

| Key | Effect |
| --- | --- |
| `name` | Template name in the chooser |
| `description` | Subtitle in the chooser |
| `title` | Default title, usually a prefix like `[Bug]: ` — preserve it verbatim and write after it |
| `labels` | Applied automatically on submit; do not re-apply them by hand |
| `assignees` | Applied automatically |
| `body` | The array of elements below |

## Body Element Types

Five types, and only five.

- **`markdown`** — display-only prose. **Not submitted.** Read it for instructions to the reporter, then ignore it as a slot. Filling it produces nothing.
- **`input`** — single-line text.
- **`textarea`** — multi-line text. Carries `render:` for fenced output (`render: shell` wraps the value in a shell code block); when `render` is set, the value must be raw text with no Markdown of its own.
- **`dropdown`** — single or multi choice. Pick only from `attributes.options`. Never invent an option; if none fits, pick the closest and say so in the draft.
- **`checkboxes`** — a list of `attributes.options`, each with its own `label` and optional `required`.

Every element takes `attributes` (`label`, `description`, `placeholder`, `value`, `options`, `render`) and `validations`.

## Validations Are the Contract

`validations.required: true` marks a field GitHub itself will refuse to submit without. Treat every required field as a slot the elicit step must fill — those, not this skill's own rubric, define the floor for a form-carrying repo.

Optional fields still get filled when the harvest or the interview supplies an answer. Leave them empty rather than padding.

## Filling a Form

Map each answer into its declared field. Do not add sections the form does not declare, do not reorder, and do not merge two fields into one because the prose flows better — the form is the repo's stated agreement with its maintainers about what an issue contains.

When the form has no slot for something the rubric considers a gate (a form with no steps-to-reproduce field, say), put it in the closest textarea and note the mismatch in the draft render. The repo's structure wins; the information still has to land somewhere.

## Creating

```
gh issue create --template <filename> --title <title> --body <body>
```

`--template` takes the filename, not the `name` key. `--label`, `--assignee`, and `--milestone` are available but redundant when the form's top-level keys already set them — passing both is how issues end up double-labeled.

For a repo with no template, plain `--title` and `--body` with a body assembled from `assets/`.

## Known Quirks

- The form schema is officially beta and subject to change. If a form fails to parse, fall back to reading it as prose and filling what you can identify rather than erroring out.
- `id` is not permitted on some element types at body level. If a form carries an unexpected `id`, it is the repo's problem, not a parse failure — ignore it.
- Markdown templates (`*.md`) may carry YAML frontmatter with `name`, `about`, `title`, `labels`, and `assignees`. Same handling: frontmatter sets metadata, the body is the structure to fill.
