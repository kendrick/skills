#!/usr/bin/env python3
"""Report what Step 5's draft still carries from the template it was filled from.

Step 5's done-when asked for "no placeholders and no orphaned headings", and
the agent that wrote the draft was the one confirming it. A leftover comment
or template slot reads as finished from the inside and posts as written (#400).

    check-draft.py BODY [--title TITLE]

One stderr line per problem, `LINE: kind: text`, in line order. The title's
lines carry no number and come last.

  html comment         any `<!--` or `-->`; the templates' comments are
                       authoring guidance, and Step 5 strips them
  placeholder          a `<...>` span the templates carry verbatim, such as
                       `<the exact command>`. The list is read from
                       `../assets/*.template.md` at run time, with their
                       comments removed, so a slot added to a template is
                       covered with no edit here. An angle-bracket span no
                       template carries, like the `<skill>` in
                       `_maintenance/<skill>/RATIONALE.md`, is prose and passes
  empty list item      `- [ ]` with nothing after it, or `1.` alone
  empty fenced block   a fence with only blank lines between its markers
  empty heading        no content before the next heading at the same or a
                       shallower level, or before the end of the body. A
                       heading whose next heading is deeper is a parent and
                       passes
  n/a heading          a heading whose only content is `n/a` or `n/a — reason`;
                       Step 5 drops those headings
  title                `{component}`, `{wrong behavior}`, `{trigger}`, or any
                       other `{...}` token the templates' comments name

Exit codes:
    0  clean
    1  at least one problem, one stderr line each
    3  usage error, an unreadable body file, or no template to read the
       placeholders from
"""

import argparse
import re
import sys
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"

COMMENT_RE = re.compile(r"<!--.*?-->", re.S)
SLOT_RE = re.compile(r"<[^<>\n]+>")
TITLE_TOKEN_RE = re.compile(r"\{[^{}\n]+\}")
FENCE_RE = re.compile(r"^( {0,3})(`{3,}|~{3,})")
HEADING_RE = re.compile(r"^ {0,3}(#{1,6})(?:[ \t]+(.*?))?(?:[ \t]+#+)?[ \t]*$")
EMPTY_ITEM_RE = re.compile(r"^\s*(?:[-*+] \[[ xX]\]|\d{1,9}[.)])[ \t]*$")
NA_RE = re.compile(r"^\s*n/a(?:\s*[—–-]+\s*\S.*)?\s*$", re.I)


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on bad usage; the repo's validator convention is 3.
    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        sys.exit(3)


def die(message):
    print(f"check-draft.py: {message}", file=sys.stderr)
    sys.exit(3)


def read(path):
    try:
        return Path(path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as e:
        die(f"cannot read {path}: {e}")


def template_vocabulary():
    """Return (placeholders, title tokens) the shipped templates carry."""
    paths = sorted(ASSETS.glob("*.template.md"))
    if not paths:
        die(f"no *.template.md under {ASSETS}, so there are no placeholders to check against")
    slots, tokens = set(), set()
    for path in paths:
        text = read(path)
        slots.update(SLOT_RE.findall(COMMENT_RE.sub("", text)))
        # Only the comments name the title tokens; the body never does.
        for comment in COMMENT_RE.findall(text):
            tokens.update(TITLE_TOKEN_RE.findall(comment))
    return slots, tokens


def scan(text, slots):
    """Return (line, kind, text) problems for one body."""
    lines = text.splitlines()
    problems = []
    headings = []  # (index, level, line) outside fences
    fence = None  # (opening index, char, length, has content)
    for i, line in enumerate(lines):
        if "<!--" in line or "-->" in line:
            problems.append((i + 1, "html comment", line.strip()))
        for slot in sorted(s for s in slots if s in line):
            problems.append((i + 1, "placeholder", slot))
        m = FENCE_RE.match(line)
        if fence:
            close = m and m.group(2)[0] == fence[1] and len(m.group(2)) >= fence[2] and not line[m.end():].strip()
            if close:
                if not fence[3]:
                    problems.append((fence[0] + 1, "empty fenced block", lines[fence[0]].strip()))
                fence = None
            elif line.strip():
                fence = fence[:3] + (True,)
            continue
        if m and not (m.group(2)[0] == "`" and "`" in line[m.end():]):
            fence = (i, m.group(2)[0], len(m.group(2)), False)
            continue
        if EMPTY_ITEM_RE.match(line):
            problems.append((i + 1, "empty list item", line.strip()))
        h = HEADING_RE.match(line)
        if h:
            headings.append((i, len(h.group(1)), line.strip()))
    if fence and not fence[3]:
        problems.append((fence[0] + 1, "empty fenced block", lines[fence[0]].strip()))
    for n, (i, level, heading) in enumerate(headings):
        end, deeper = (headings[n + 1][0], headings[n + 1][1] > level) if n + 1 < len(headings) else (len(lines), False)
        body = [(j, ln) for j, ln in enumerate(lines[i + 1:end], i + 1) if ln.strip()]
        if not body and not deeper:
            problems.append((i + 1, "empty heading", heading))
        elif len(body) == 1 and NA_RE.match(body[0][1]):
            problems.append((body[0][0] + 1, "n/a heading", heading))
    return sorted(problems)


def main(argv=None):
    ap = Parser(description="Report template leftovers in a drafted issue body.")
    ap.add_argument("body", metavar="BODY", help="the drafted issue body")
    ap.add_argument("--title", help="the drafted issue title")
    args = ap.parse_args(argv)
    slots, tokens = template_vocabulary()
    problems = [f"{n}: {kind}: {text}" for n, kind, text in scan(read(args.body), slots)]
    if args.title is not None:
        problems += [f"title: {t}" for t in sorted(tokens) if t in args.title]
    for p in problems:
        print(p, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
