#!/usr/bin/env python3
"""Fill one task's worker prompt from the Waves table and write it to a file.

    divvy-up/scripts/render-prompt.py PLAN.md --wave 1 --task api --out DIR/1-api.md \\
        [--contract FILE] [--verify-cmd CMD] [--baseline FILE] \\
        [--caller-notes FILE] [--prior FILE]

The orchestrator used to type each prompt into its dispatch call, about 15k
characters a worker, and output tokens are the slow part of a wave: measured at
roughly 2.4 s per 1k characters, that is ~37 s per prompt before any worker
starts. A script fills the same template in milliseconds, and the dispatch
shrinks to a pointer at the file.

On success it writes --out, prints that path on stdout, and exits 0.

Why --out may not land inside the work tree: Step 6 derives ownership from the
diff, and a rendered prompt sitting in the tree would show up as a write no task
owns. The check asks git about the directory --out lands in, never the cwd, so it
holds whichever directory the orchestrator runs from. A `.git/` directory is the
exception, because that is where a wrapping skill's run directory lives, and git
reports no work tree there.

Why a placeholder left unfilled is a failure rather than a warning: a template
edit that adds a placeholder this script does not know would otherwise ship the
literal `{{NEW_THING}}` to a worker, which reads it as an instruction it cannot
follow. The same check fires on caller notes still holding a placeholder the
caller should have filled.

Substitution runs in two passes so that data is never rescanned. Caller notes are
template material (a wrapping skill writes `{{TASK}}` into them), so they go in
first and are scanned with the rest. The remaining values are data: a BASELINE
holding test output, or a PRIOR holding a report, may contain `{{...}}` and must
cross verbatim, so one `re.sub` over the template fills them and never looks at
what it inserted. File inputs lose trailing newlines so a file's final newline
does not become a blank line in the prompt.

Exit codes: 0 rendered; 1 semantic failure (malformed Waves table, task absent
from or repeated in the wave, no Template block between '## Template' and '## Placeholders', unfilled
placeholder, --out inside the work tree)
with one line per problem on stderr; 3 usage, missing or unreadable input.
Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable. check-waves.py is loaded by
path rather than imported, because it lives in this skill and its name has a
hyphen.
"""
import argparse
import importlib.util
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_TEMPLATE = os.path.join(HERE, "..", "references", "worker-prompt.md")
# CALLER_NOTES is filled in the first pass, so it is absent from this list.
DATA_NAMES = {"TASK", "OWNS", "CONTRACT", "DONE_WHEN", "CONSTRAINTS", "PRIOR", "VERIFY_CMD", "BASELINE"}
PLACEHOLDER = re.compile(r"\{\{([A-Z_]+)\}\}")


def fail(code, msg):
    sys.stderr.write(f"render-prompt: {msg}\n")
    raise SystemExit(code)


def read(path, label):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError as e:
        fail(3, f"{label}: {e}")
    except UnicodeDecodeError as e:
        fail(3, f"{label}: not valid UTF-8: {e}")


def load_check_waves():
    # No bytecode: a __pycache__ written into the skill's directory is an
    # untracked file the ownership check would see.
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("check_waves", os.path.join(HERE, "check-waves.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def extract_template(md):
    """The lines between the Template block's outer fences. The block holds a
    nested ```json fence, so the closing fence is the last bare one before
    `## Placeholders`, not the next one."""
    lines = md.splitlines()
    try:
        head = lines.index("## Template")
        tail = lines.index("## Placeholders")
    except ValueError:
        return None
    fences = [i for i in range(head, tail) if lines[i] == "```"]
    if len(fences) < 2:
        return None
    return "\n".join(lines[fences[0] + 1 : fences[-1]]) + "\n"


def refuse_in_tree_out(out):
    """Exit 1 when `out` would sit in a work tree. Decided from the directory
    --out lands in, not from the cwd: an orchestrator often runs from ROOT while
    --out points into WORKTREE. Inside a `.git/` directory `--show-toplevel`
    fails, so a run directory under the common dir passes without a special case."""
    where = os.path.dirname(os.path.realpath(out))
    git = subprocess.run(["git", "-C", where, "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if git.returncode == 0:
        fail(1, f"--out {out} is inside the work tree; Step 6 would count it as an unowned write")


def main(argv=None):
    ap = argparse.ArgumentParser(description="Render one task's worker prompt to a file.")
    ap.add_argument("plan", metavar="PLAN_MD")
    ap.add_argument("--wave", type=int, required=True, metavar="N")
    ap.add_argument("--task", required=True, metavar="LABEL")
    ap.add_argument("--out", required=True, metavar="PATH")
    ap.add_argument("--contract", metavar="FILE")
    ap.add_argument("--verify-cmd", metavar="CMD", default="absent")
    ap.add_argument("--baseline", metavar="FILE")
    ap.add_argument("--caller-notes", metavar="FILE")
    ap.add_argument("--prior", metavar="FILE")
    # Test-only: lets the smoke suite feed an edited template.
    ap.add_argument("--template", metavar="FILE", default=DEFAULT_TEMPLATE)
    args = ap.parse_args(argv)

    cw = load_check_waves()
    plan = read(args.plan, "plan")
    rows, problems = cw.read_rows(plan)
    if problems:
        for p in problems:
            sys.stderr.write(f"render-prompt: {p}\n")
        return 1
    matches = [r for r in rows if r.wave == args.wave and r.task == args.task]
    if len(matches) != 1:
        found = "absent from" if not matches else f"listed {len(matches)} times in"
        fail(1, f"task {args.task!r} is {found} wave {args.wave}")
    row = matches[0]

    template = extract_template(read(args.template, "template"))
    if template is None:
        fail(1, "no Template block between '## Template' and '## Placeholders'")

    def optional(path, default, label):
        return read(path, label).rstrip("\n") if path else default

    values = {
        "TASK": row.task,
        "OWNS": "\n".join(row.entries),
        "CONTRACT": optional(args.contract, "none recorded", "contract"),
        "DONE_WHEN": row.done,
        "CONSTRAINTS": row.constraints or "none recorded",
        "PRIOR": optional(args.prior, "", "prior"),
        "VERIFY_CMD": args.verify_cmd,
        "BASELINE": optional(args.baseline, "absent", "baseline"),
    }
    caller_notes = optional(args.caller_notes, "", "caller notes")

    # replace(), not re.sub: the notes may hold backslashes that sub would eat.
    text = template.replace("{{CALLER_NOTES}}", caller_notes)
    unknown = sorted({n for n in PLACEHOLDER.findall(text) if n not in DATA_NAMES})
    if unknown:
        for name in unknown:
            sys.stderr.write(f"render-prompt: unfilled placeholder {{{{{name}}}}}\n")
        return 1
    text = PLACEHOLDER.sub(lambda m: values[m.group(1)], text)

    refuse_in_tree_out(args.out)
    try:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)
    except OSError as e:
        fail(3, f"--out: {e}")
    print(args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
