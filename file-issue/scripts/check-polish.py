#!/usr/bin/env python3
"""Report what file-issue's Step 7 wording pass dropped from an issue body.

Step 7 keeps the body as it entered the step. This script compares that copy
with the revised body, so the agent that did the rewrite is not also the judge
of what it lost (#393). Gate 6 passed on the old body, and a verification
command dropped in the rewrite ships an issue that no longer passes gate 6.

    check-polish.py --before BODY --after BODY [--before-title T --after-title T]

Each item below that is present in --before and missing from --after gets one
stderr line naming its kind and quoting it. Additions are never reported.

  fenced code blocks   whole, fence lines included, byte for byte
  inline code spans    counted, so a span written twice and kept once reports
  URLs                 counted
  issue references     `#N` and `owner/repo#N`, counted; a `#` inside a URL
                       or a heading marker is not a reference
  headings             level and text; the before sequence has to appear in
                       the after sequence in order, so an added heading
                       passes and a rename or reorder reports
  `- [ ]` items        reported when the after count is lower, which is what
                       folding one criterion into another looks like
  title prefix         the before title up to and including its first `: `;
                       a title with no `: ` has no prefix to check

Spans, URLs, and references come only from text outside fenced blocks, so an
edit inside a fence reports once, as a fence. Paths and commands written
outside code spans are not compared; that stays a reading job.

Exit codes:
    0  nothing went missing
    1  at least one item went missing, one stderr line per item
    3  usage error (one title flag without the other) or an unreadable body
       file; argparse supplies 2 for a mistyped flag
"""

import argparse
import re
import sys
from collections import Counter

FENCE_OPEN_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
HEADING_RE = re.compile(r"^ {0,3}(#{1,6})(?:[ \t]+(.*?))?(?:[ \t]+#+)?[ \t]*$")
CHECKBOX_RE = re.compile(r"^\s*[-*+] \[ \]")
# A backtick run closes only on a run of the same length (CommonMark), which
# is how `` `cmd` `` keeps its inner backticks.
SPAN_RE = re.compile(r"(?<!`)(`+)(?!`)(.+?)(?<!`)\1(?!`)")
URL_RE = re.compile(r"https?://[^\s<>()\[\]`\"']+")
REF_RE = re.compile(r"(?<![\w./&#-])((?:[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9._-]+)?#\d+)(?!\w)")


def read_body(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        print(f"check-polish.py: cannot read {path}: {e}", file=sys.stderr)
        sys.exit(3)


def split_fences(text):
    """Return (fenced blocks, every line outside them)."""
    fences, prose = [], []
    current = None
    for line in text.splitlines(keepends=True):
        if current is None:
            m = FENCE_OPEN_RE.match(line)
            if m:
                marker = m.group(1)
                current = {"char": marker[0], "len": len(marker), "lines": [line]}
            else:
                prose.append(line.rstrip("\n"))
            continue
        current["lines"].append(line)
        close = re.match(r"^ {0,3}(`{3,}|~{3,})[ \t]*$", line)
        if close and close.group(1)[0] == current["char"] and len(close.group(1)) >= current["len"]:
            fences.append(current["lines"])
            current = None
    if current is not None:
        # CommonMark runs an unclosed fence to the end of the document.
        fences.append(current["lines"])
    return fences, prose


def extract(text):
    fences, prose = split_fences(text)
    spans, urls, refs, headings, boxes = [], [], [], [], 0
    for line in prose:
        h = HEADING_RE.match(line)
        if h:
            headings.append(f"{h.group(1)} {(h.group(2) or '').strip()}".rstrip())
        if CHECKBOX_RE.match(line):
            boxes += 1
        spans += [m.group(0) for m in SPAN_RE.finditer(line)]
        found = [u.rstrip(".,;:!?") for u in URL_RE.findall(line)]
        urls += found
        # Blank out URLs first so a `pull/9#12` fragment never reads as a ref.
        # A heading marker needs no handling: `#` there is followed by `#` or
        # a space, never a digit.
        refs += REF_RE.findall(URL_RE.sub(" ", line))
    return {
        "fences": ["".join(f) for f in fences],
        "spans": spans,
        "urls": urls,
        "refs": refs,
        "headings": headings,
        "boxes": boxes,
    }


def describe_fence(block):
    lines = block.splitlines()
    first = lines[1] if len(lines) > 1 else ""
    return f"{lines[0].strip()} ... {first.strip()}" if first.strip() else lines[0].strip()


def missing_counted(before, after):
    lost = Counter(before) - Counter(after)
    # Keep the before order so the report reads top to bottom like the body.
    out = []
    for item in before:
        if lost[item] > 0:
            out.append(item)
            lost[item] -= 1
    return out


def title_prefix(title):
    i = title.find(": ")
    return title[: i + 2] if i >= 0 else None


def compare(before, after, before_title=None, after_title=None):
    b, a = extract(before), extract(after)
    problems = []
    problems += [f"missing fenced block: {describe_fence(x)}" for x in missing_counted(b["fences"], a["fences"])]
    problems += [f"missing inline code: {x}" for x in missing_counted(b["spans"], a["spans"])]
    problems += [f"missing URL: {x}" for x in missing_counted(b["urls"], a["urls"])]
    problems += [f"missing issue reference: {x}" for x in missing_counted(b["refs"], a["refs"])]
    j = 0
    for h in b["headings"]:
        try:
            j = a["headings"].index(h, j) + 1
        except ValueError:
            problems.append(f"missing or reordered heading: {h}")
    if a["boxes"] < b["boxes"]:
        problems.append(f"missing checklist items: {b['boxes']} `- [ ]` before, {a['boxes']} after")
    if before_title is not None:
        prefix = title_prefix(before_title)
        if prefix is not None and not after_title.startswith(prefix):
            problems.append(f'missing title prefix: "{prefix}"')
    return problems


def main(argv=None):
    ap = argparse.ArgumentParser(description="Report what a wording pass dropped from an issue body.")
    ap.add_argument("--before", required=True, help="the body as it entered Step 7")
    ap.add_argument("--after", required=True, help="the revised body")
    ap.add_argument("--before-title")
    ap.add_argument("--after-title")
    args = ap.parse_args(argv)
    if (args.before_title is None) != (args.after_title is None):
        print("check-polish.py: --before-title and --after-title come as a pair", file=sys.stderr)
        return 3
    problems = compare(read_body(args.before), read_body(args.after), args.before_title, args.after_title)
    for p in problems:
        print(p, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
