#!/usr/bin/env python3
"""Stamp a `scaffold_digest` onto the Overviews a vault already holds.

`jd-file` stamps every Overview it mints, so `jd-audit` can later ask whether
anyone has written into one. No Overview predating that change carries the
key, and under the rule that reads it, a missing digest means payload. On the
first run after the validator starts reading digests, every ID that correctly
reports `hygiene-empty` today would go quiet -- the check would break in the
exact direction the work set out to fix, and it would break silently. This
script closes that gap once per vault, before the reader lands. See GitHub
issue #59 in this repo.

Stamping the wrong file is worse than stamping nothing. A digest on an
Overview someone wrote into freezes their writing as furniture and makes an
occupied ID report empty, which is the same silent failure from the other
direction. So this pass does not guess. It stamps what still looks untouched
and reports everything else for the user to rule on, which is the guided
reconciliation `jd-audit` runs everywhere else.

"Still looks untouched" is a heuristic and this script says so rather than
hiding it. An Overview qualifies only when its `## Context` holds nothing,
its `**Next action:**` is empty or still the template's placeholder, its
`## Log` holds only lines `jd-file` writes, and it carries no section the
template never put there. Anything else goes on the report. The bar is
deliberately set where a false skip costs a person one decision and a false
stamp costs them a silently unreportable ID.

This runs once per vault. It is not part of a normal audit, and nothing in
`validate.py` calls it.

  stamp_overviews.py --vault VAULT_ROOT           # report, write nothing
  stamp_overviews.py --vault VAULT_ROOT --write   # stamp the candidates
"""

from __future__ import annotations

import argparse
import os
import re
import sys

# 0 nothing needs a person, 1 something is on the report, 2 the run could not
# happen. A reported file is not an error -- it is the pass doing its job --
# but it does mean a human still has to look, which is what 1 says here and
# in validate.py.
EXIT_OK, EXIT_REPORTED, EXIT_FATAL = 0, 1, 2

OVERVIEW = "Overview.md"

# The placeholder jd-file's template ships; an Overview minted and never
# filled still carries it verbatim.
NEXT_ACTION_MARKER = "**Next action:**"
NEXT_ACTION_PLACEHOLDER = "{{next action, or leave blank for the user}}"

# Every line jd-file writes into a Log: the mint line, the by-name filing
# line, and the batch line whose tail is free prose. The em dash is jd-file's
# own; a line that swapped it for a hyphen was touched by hand, so matching
# loosely here would widen the gate exactly where edits show up.
LOG_LINE = re.compile(r"^- \*\*\d{4}-\d{2}-\d{2}\*\* — (created|filed .*)$")

# Sections the template puts there. Anything else is someone's own heading.
TEMPLATE_SECTIONS = {"Context", "Log", "Rollups"}


# --------------------------------------------------------------------------
# Classification
# --------------------------------------------------------------------------

def split_sections(body: str) -> tuple[list[str], dict[str, list[str]]]:
    """Split a body into its preamble and its `##` sections.

    Only `##` headings open a section. The `###` headings under Rollups are
    part of Rollups, not siblings of it, and treating them as sections would
    put every stock Overview on the report for carrying its own template.
    """
    preamble: list[str] = []
    sections: dict[str, list[str]] = {}
    current: list[str] | None = None

    for line in body.splitlines():
        if line.startswith("## ") and not line.startswith("### "):
            current = sections.setdefault(line[3:].strip(), [])
            continue
        (preamble if current is None else current).append(line)

    return preamble, sections


def is_blank_context(lines: list[str]) -> bool:
    """True when `## Context` holds nothing a person put there.

    The template seeds the section with a lone empty bullet, so an untouched
    Context is not literally empty. An absent section is blank too: Overviews
    minted before the section existed simply do not have one.
    """
    return all(line.strip() in ("", "-") for line in lines)


def next_action_is_empty(preamble: list[str]) -> bool | None:
    """Whether `**Next action:**` is unfilled, or None when there is no line."""
    for line in preamble:
        if line.strip().startswith(NEXT_ACTION_MARKER):
            value = line.strip()[len(NEXT_ACTION_MARKER):].strip()
            return value in ("", NEXT_ACTION_PLACEHOLDER)
    return None


def preamble_is_clean(preamble: list[str]) -> bool:
    """True when the preamble holds only what the template puts above `## Context`.

    That is the H1, the callout pointing at the register, the Next action
    line, and blanks. Prose here is someone writing in the most obvious place
    on the page, and it counts even though the issue's three conditions never
    mention it.
    """
    for line in preamble:
        stripped = line.strip()
        if stripped == "" or stripped.startswith("#") or stripped.startswith(">"):
            continue
        if stripped.startswith(NEXT_ACTION_MARKER):
            continue
        return False
    return True


def classify(body: str) -> str | None:
    """Name the reason this body disqualifies as untouched, or None if it is.

    Ordered so the report names the most concrete thing wrong. A file trips
    on the first reason found, because listing every way a file is occupied
    helps nobody decide anything.
    """
    preamble, sections = split_sections(body)

    if not preamble_is_clean(preamble):
        return "content above the first section"

    empty = next_action_is_empty(preamble)
    if empty is None:
        return f"no {NEXT_ACTION_MARKER} line"
    if not empty:
        return "Next action is filled in"

    if not is_blank_context(sections.get("Context", [])):
        return "content under ## Context"

    if "Log" not in sections:
        return "no ## Log section"
    for line in sections["Log"]:
        if line.strip() and not LOG_LINE.match(line.rstrip()):
            return "hand-written line in ## Log"

    extra = sorted(set(sections) - TEMPLATE_SECTIONS)
    if extra:
        return f"section the template never wrote: ## {extra[0]}"

    return None


# --------------------------------------------------------------------------
# The pass
# --------------------------------------------------------------------------

def find_overviews(vault: str) -> list[str]:
    """Every `Overview.md` under `vault`, in a stable order.

    Dot-directories are pruned rather than walked: `.git`, `.obsidian`, and
    friends hold nothing this pass may write to. Only files named exactly
    `Overview.md` are ever opened, which keeps the walk off a cloud-synced
    office tree where touching a file can stall on hydration.
    """
    found = []
    for dirpath, dirnames, filenames in os.walk(vault):
        dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
        if OVERVIEW in filenames:
            found.append(os.path.join(dirpath, OVERVIEW))
    return sorted(found)


def run(vault: str, write: bool, digest) -> int:
    compute, stored, restamp, split = digest
    stamped = candidates = skipped = matching = 0

    for path in find_overviews(vault):
        rel = os.path.relpath(path, vault)
        try:
            with open(path, encoding="utf-8", newline="") as f:
                text = f.read()
        except OSError as exc:
            print(f"skipped: {rel}: {exc.strerror}")
            skipped += 1
            continue

        try:
            current = compute(text)
        except ValueError as exc:
            # restamp cannot invent a frontmatter block, and guessing where
            # one should go is a rewrite, not a stamp.
            print(f"skipped: {rel}: {exc}")
            skipped += 1
            continue

        recorded = stored(text)
        if recorded is not None:
            if recorded == current:
                matching += 1
            else:
                # Someone wrote here after the stamp. Re-stamping would erase
                # the only evidence of that.
                print(f"skipped: {rel}: digest no longer matches the body")
                skipped += 1
            continue

        reason = classify(split(text)[1])
        if reason is not None:
            print(f"skipped: {rel}: {reason}")
            skipped += 1
            continue

        if not write:
            print(f"candidate: {rel}")
            candidates += 1
            continue

        try:
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(restamp(text))
        except OSError as exc:
            print(f"skipped: {rel}: {exc.strerror}")
            skipped += 1
            continue
        print(f"stamped: {rel}")
        stamped += 1

    verb = "stamped" if write else "candidates"
    count = stamped if write else candidates
    print(f"summary: {verb} {count}, skipped {skipped}, already matching {matching}")

    return EXIT_REPORTED if skipped or candidates else EXIT_OK


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def parse_args(argv):
    p = argparse.ArgumentParser(prog="stamp_overviews.py")
    p.add_argument("--vault", required=True)
    p.add_argument("--write", action="store_true")
    return p.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])

    if not os.path.isdir(args.vault):
        print(f"not a directory: {args.vault}", file=sys.stderr)
        return EXIT_FATAL

    # Imported rather than reimplemented: this pass has to agree with every
    # other writer byte for byte, and a second implementation of the rule is
    # how that stops being true.
    # `_split` comes along for the same reason: where the frontmatter ends is
    # part of the rule, and reading the body by any other boundary would let
    # the heuristic see a different file than the digest covers.
    try:
        from scaffold_digest import _split, compute, restamp, stored
    except ImportError:
        print(
            "scaffold_digest.py is missing beside this script, so no digest "
            "matching what jd-file writes is computable. Restore it.",
            file=sys.stderr,
        )
        return EXIT_FATAL

    return run(args.vault, args.write, (compute, stored, restamp, _split))


if __name__ == "__main__":
    sys.exit(main())
