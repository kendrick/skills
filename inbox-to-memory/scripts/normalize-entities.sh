#!/usr/bin/env bash
# Map phase 2.5's raw entities through the scope's alias tables (#419).
#
# find-candidates.sh matches each entity as a lowercase substring of a record's
# frontmatter, which is right only once every entity is canonical. A variant the
# agent missed by eye searches as a second person and the conflict report comes
# back clean on a scope that has the conflict. The mapping is a lookup, so it
# lives here; picking the entities stays judgment in SKILL.md.
#
# A project scope also reads its client root's table (the directory above the
# pursuits/ or projects/ parent), because project.template.md says client-wide
# aliases are inherited. An entity matches a canonical or a listed variant by
# whole string, ignoring case. A substring match would turn "Saatchi Group"
# into "Shachi Deshpande".
#
# Exit 0 with the canonical entities on stdout, one per line in input order,
# duplicates dropped; each mapping applied goes to stderr as
# `correction: <variant>→<canonical>`, the shape `transcript_corrections` uses.
# Exit 1 when one variant maps to two canonicals, naming both tables, with
# nothing on stdout: the script won't pick a winner. Exit 2 on a usage error or
# an unreadable entities file or scope root. This produces an artifact rather
# than gating a run, so it takes find-candidates.sh's 2 for usage.
set -euo pipefail

exec python3 - "$@" <<'PY'
from __future__ import annotations

import os
import re
import sys

USAGE = "usage: normalize-entities.sh <scope-root> --entities FILE\n"

HEADING = re.compile(r"^#{1,6}\s")
TABLE_HEADING = re.compile(
    r"^###\s+(alias table|transcription-error mapping)\s*$", re.IGNORECASE
)
# The tail after `]` is a `# comment`; a `#` inside the brackets is part of a name.
LINE = re.compile(r"^\s*(.+?)\s*<-\s*\[(.*)\]\s*(?:#.*)?$")
COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)


def die(msg, code=2):
    sys.stderr.write(msg + "\n")
    sys.exit(code)


def read_table(path):
    """(canonical, [variants]) pairs from one CLAUDE.md. HTML comments go first,
    so the template's commented examples never count, and a commented block can
    hold a heading without ending the section early."""
    if not os.path.isfile(path):
        return []
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except (OSError, UnicodeDecodeError) as e:
        die("cannot read %s: %s" % (path, e))
    pairs = []
    inside = False
    for ln in COMMENT.sub("", text).splitlines():
        if TABLE_HEADING.match(ln.strip()):
            inside = True
            continue
        if HEADING.match(ln):
            inside = False
            continue
        m = LINE.match(ln) if inside else None
        if m:
            variants = [v.strip() for v in m.group(2).split(",") if v.strip()]
            pairs.append((m.group(1).strip(), variants))
    return pairs


def client_root(scope):
    parent = os.path.dirname(scope)
    if os.path.basename(parent) in ("pursuits", "projects"):
        return os.path.dirname(parent)
    return None


def main(argv):
    scope = None
    entities = None
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--entities" and i + 1 < len(argv):
            entities = argv[i + 1]
            i += 2
        elif a.startswith("-") or scope is not None:
            die(USAGE.rstrip())
        else:
            scope = a
            i += 1
    if scope is None or entities is None:
        die(USAGE.rstrip())
    scope = os.path.abspath(scope)
    if not os.path.isdir(scope):
        die("scope root is not a directory: %s" % scope)
    try:
        with open(entities, encoding="utf-8") as fh:
            raw = [ln.strip() for ln in fh if ln.strip()]
    except (OSError, UnicodeDecodeError) as e:
        die("cannot read entities file %s: %s" % (entities, e))

    tables = [os.path.join(scope, "CLAUDE.md")]
    root = client_root(scope)
    if root:
        tables.append(os.path.join(root, "CLAUDE.md"))

    # key -> (canonical, table path). A canonical is its own key, so a variant
    # of A that is also B's canonical conflicts rather than resolving silently.
    mapping = {}
    for path in tables:
        for canon, variants in read_table(path):
            for key in [canon] + variants:
                prior = mapping.get(key.lower())
                if prior and prior[0].lower() != canon.lower():
                    sys.stderr.write(
                        "conflict: '%s' maps to '%s' in %s and to '%s' in %s\n"
                        % (key, prior[0], prior[1], canon, path)
                    )
                    sys.exit(1)
                mapping.setdefault(key.lower(), (canon, path))

    out = []
    seen = set()
    corrected = set()
    for ent in raw:
        canon = mapping.get(ent.lower(), (ent, None))[0]
        if canon != ent and ent.lower() not in corrected:
            corrected.add(ent.lower())
            sys.stderr.write("correction: %s→%s\n" % (ent, canon))
        if canon.lower() not in seen:
            seen.add(canon.lower())
            out.append(canon)
    for canon in out:
        print(canon)


main(sys.argv[1:])
PY
