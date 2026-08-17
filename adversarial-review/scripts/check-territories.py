#!/usr/bin/env python3
"""Prove a scope contract's territories are disjoint before anything fans out,
and later work out which territories a fix diff landed in.

    scripts/check-territories.py validate RUN_DIR/scope.json
    git diff <prev_round_head_sha>..HEAD --name-only \\
        | scripts/check-territories.py intersect RUN_DIR/scope.json

`validate` is the hard gate at the end of the scope contract step. Overlapping
territories are worth failing a run over: the whole reason findings can be
trusted without cross-territory agreement is that no two finders were looking at
the same file, so an overlap quietly removes the property the verification gate
is standing on.

`intersect` is the round loop's terminator. Empty stdout means no territory owns
any part of the fix diff, which is how a round ends. A path in the fix diff that
no territory owns exits 1 instead of being skipped, because a blind spot that
appears mid-run is precisely the thing that should stop and get recorded rather
than pass unnoticed.

Exit codes: 0 pass; 1 semantic failure (overlap, malformed entry, unowned or
multiply-owned path) with one line per problem on stderr; 3 usage, missing file,
unreadable JSON. Argparse supplies 2 for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SCHEMA_PATH = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "assets", "scope.schema.json")
)

# ---------------------------------------------------------------------------
# Vendored verbatim from agent-guild's check-diff-scope.py (lines 135-240 of
# plugins/agent-guild/project-template/.agent-guild/scripts/check-diff-scope.py),
# vendored 2026-08-17. Upstream is authoritative: fix a bug there first, then
# re-copy. The docstrings travel with the code on purpose — they record the
# incident (#162) that set each rule, and a reader who trims them will
# eventually re-introduce the bug they describe. This skill installs standalone
# to ~/.claude/skills/, so importing from the sibling repo is not available.
# ---------------------------------------------------------------------------


def paths_overlap(a, b):
    """True if ownership paths `a` and `b` denote overlapping territory.
    Each is either an exact file path or a directory prefix ending in
    '/'—the same two shapes ALLOWED and `owns:` entries both take.

    The comparison is on the path itself, with the trailing slash treated
    as notation rather than as part of the name, so `src/lib` and
    `src/lib/` are the same territory spelled two ways. #162 found the
    earlier version answering False there: it compared a file claim
    against a directory claim, correctly for the shapes it was handed and
    uselessly for what the author meant, and two tasks writing one tree
    rode the same wave on the strength of that answer. R15 refuses the
    slashless spelling of a directory that already exists, but a task's
    whole job is often to create the tree it owns, and this predicate is
    the only thing standing between that case and a lost write.

    So: two paths overlap when they name the same node, or when either is
    a parent directory of the other. A trailing slash still carries
    meaning for anyone reading the file, and `plugin/` still does not
    swallow `plugin-extra/`, because a parent relationship is tested at a
    separator rather than by raw string prefix. `a` and `b` are
    interchangeable—the check is symmetric—which matters to a caller like
    R13 comparing two tasks' owns lists pairwise without caring which one
    it read first."""
    a_core = a.rstrip("/")
    b_core = b.rstrip("/")
    if a_core == b_core:
        return True
    return a_core.startswith(b_core + "/") or b_core.startswith(a_core + "/")


def owns_entry_problem(entry, repo_root=None):
    """A short reason an `owns:` entry is malformed, or None if it's one of
    the two shapes paths_overlap above understands.

    Shape is load-bearing rather than cosmetic. `paths_overlap` above
    answers "same territory?" for the two documented shapes; hand it a
    third thing and its answer is meaningless rather than wrong, and a
    meaningless "no overlap" is what puts two tasks on one file in the
    same wave (#162). Every check here catches a spelling that would
    produce one: `./src/a.py` never matches `src/a.py`, a glob never
    matches the files it was meant to stand for, an invisible character
    makes a path that matches nothing at all.

    Existence is never required—a task's whole job is often to create the
    file it owns. The repo_root checks fire only when the path DOES exist
    and its kind contradicts its spelling. Pass repo_root=None for the
    textual checks alone, which is what ready-set.py does to stay a pure
    function of the task files."""
    if not isinstance(entry, str):
        return f"not a string ({type(entry).__name__})"
    if not entry.strip():
        return "empty entry"
    if entry != entry.strip():
        return "leading or trailing whitespace"
    invisible = next((c for c in entry if c in "​‌‍﻿\xa0"), None)
    if invisible is not None:
        # Survives .strip(), reads as an ordinary path, matches nothing.
        # Usually arrived by paste rather than by typing.
        return f"invisible character U+{ord(invisible):04X}"
    if "\\" in entry:
        return "backslash; entries use '/' separators"
    # `*` and `?` only. Brackets are ordinary filename characters and
    # `app/[slug]/page.tsx` is the most common path shape in half the
    # frameworks a copied-in kit will meet; rejecting it would fail
    # DEC-audit with no spelling the author could fix.
    glob_char = next((c for c in entry if c in "*?"), None)
    if glob_char is not None:
        return (
            f"glob character {glob_char!r}; an entry is a literal path, and a "
            "pattern here would own nothing"
        )
    if entry.startswith("~") or entry.startswith("$"):
        return "shell expansion; entries are literal repo-relative paths"
    if entry.startswith("/"):
        return "absolute path; entries are repo-relative"
    core = entry[:-1] if entry.endswith("/") else entry
    if not core:
        return "bare '/'"
    parts = core.split("/")
    if "" in parts:
        return "empty path segment ('//')"
    if "." in parts:
        return "'.' segment; write the path without './'"
    if ".." in parts:
        return "'..' segment; entries stay inside the repo"
    if repo_root is not None:
        full = os.path.join(repo_root, core)
        if entry.endswith("/"):
            if os.path.isfile(full):
                return "ends with '/' but exists as a file"
        elif os.path.isdir(full):
            return "exists as a directory but lacks the trailing '/'"
    return None


def path_within(path, prefix):
    """True if `path` sits inside directory `prefix`, which ends in '/'.

    Containment, not overlap, and the difference is the whole reason this
    isn't paths_overlap. Overlap is symmetric because two owners collide
    whichever way you read the pair. A grant flows one way only: allowing
    `docs/generated/` says nothing about a file at `docs`, which is
    ABOVE the granted territory rather than inside it. Sharing the
    symmetric predicate here let exactly that through."""
    return path.startswith(prefix)


# ---------------------------------------------------------------------------
# End vendored block.
# ---------------------------------------------------------------------------


def _type_name(value):
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


def _matches_type(value, expected):
    actual = _type_name(value)
    if expected == "number":
        return actual in ("number", "integer")
    return actual == expected


def schema_violation(instance, schema, path=""):
    """Return (json_path, reason) for the first thing about `instance` that
    fails `schema`, or None if it conforms. Walks type -> enum -> object
    (required, additionalProperties, properties) -> array (items).

    A small re-implementation rather than a shared import, matching the kit
    convention: a second copy is cheaper than coupling one script's behavior to
    a change made for a different schema."""
    types = schema.get("type")
    if types is not None:
        expected = types if isinstance(types, list) else [types]
        if not any(_matches_type(instance, t) for t in expected):
            want = " or ".join(expected)
            return (
                path or "$",
                f"expected type {want}, got {_type_name(instance)} ({instance!r})",
            )

    if "enum" in schema and instance not in schema["enum"]:
        allowed = ", ".join(repr(v) for v in schema["enum"])
        return path or "$", f"must be one of [{allowed}], got {instance!r}"

    if isinstance(instance, dict) and (
        "properties" in schema or "required" in schema or types == "object"
    ):
        for key in schema.get("required", []):
            if key not in instance:
                return (f"{path}.{key}" if path else key), "required field missing"
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            extra = sorted(set(instance) - set(properties))
            if extra:
                return path or "$", f"additional properties not allowed: {extra}"
        for key, subschema in properties.items():
            if key in instance:
                violation = schema_violation(
                    instance[key], subschema, f"{path}.{key}" if path else key
                )
                if violation:
                    return violation

    if isinstance(instance, list) and "items" in schema:
        items_schema = schema["items"]
        for i, item in enumerate(instance):
            violation = schema_violation(item, items_schema, f"{path}[{i}]")
            if violation:
                return violation

    return None


def load_json(path, label):
    """Read a JSON file, or exit 3. Anything wrong at this layer is an
    environment problem rather than a scope problem, and the two exit codes stay
    separate so a caller can tell 'your territories overlap' from 'your file
    isn't there'."""
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except OSError as e:
        sys.stderr.write(f"check-territories: {label}: {e}\n")
        raise SystemExit(3)
    except json.JSONDecodeError as e:
        sys.stderr.write(f"check-territories: {label}: not valid JSON: {e}\n")
        raise SystemExit(3)


def owners_of(path, territories):
    """Every territory owning `path`, by exact entry match or by sitting inside
    a directory entry. Containment, not overlap: a territory owning `src/api/`
    does not thereby own `src`, which is above it."""
    owners = []
    for territory in territories:
        for entry in territory.get("entries", []):
            if entry.endswith("/"):
                if path_within(path, entry):
                    owners.append(territory["name"])
                    break
            elif path == entry:
                owners.append(territory["name"])
                break
    return owners


def cmd_validate(args):
    scope = load_json(args.scope, args.scope)

    violation = schema_violation(scope, load_json(SCHEMA_PATH, "scope.schema.json"))
    if violation:
        json_path, reason = violation
        sys.stderr.write(f"check-territories: scope.json: {json_path}: {reason}\n")
        return 1

    territories = scope["territories"]
    problems = []

    repo_root = os.getcwd() if args.check_kind else None
    for territory in territories:
        for entry in territory["entries"]:
            reason = owns_entry_problem(entry, repo_root)
            if reason:
                problems.append(
                    f"malformed entry {entry!r} in {territory['name']}: {reason}"
                )

    # Pairwise across distinct territories only. Two entries inside one
    # territory may nest freely — a territory is allowed to name a directory and
    # a file within it; what must never happen is two owners for one file.
    for i, ta in enumerate(territories):
        for tb in territories[i + 1 :]:
            for ea in ta["entries"]:
                for eb in tb["entries"]:
                    if paths_overlap(ea, eb):
                        problems.append(
                            f"overlap: {ta['name']}:{ea} ~ {tb['name']}:{eb}"
                        )

    for path in scope["changed_files"]:
        owners = owners_of(path, territories)
        if not owners:
            problems.append(f"unowned: {path}")
        elif len(owners) > 1:
            problems.append(f"multiply-owned: {path} ({', '.join(owners)})")

    if problems:
        for problem in problems:
            sys.stderr.write(f"check-territories: {problem}\n")
        return 1

    print(
        f"OK: {len(territories)} territories, "
        f"{len(scope['changed_files'])} files, disjoint"
    )
    return 0


def cmd_intersect(args):
    scope = load_json(args.scope, args.scope)
    territories = scope["territories"]

    paths = [line.strip() for line in sys.stdin.read().splitlines() if line.strip()]

    hit = []
    unowned = []
    for path in paths:
        owners = [
            t["name"]
            for t in territories
            if any(paths_overlap(path, entry) for entry in t["entries"])
        ]
        if owners:
            hit.extend(owners)
        else:
            unowned.append(path)

    # Scope order, deduped: the next round's fan-out should be stable across
    # runs for the same fix diff, and the input's order is an accident of git's
    # output rather than anything meaningful.
    for territory in territories:
        if territory["name"] in hit:
            print(territory["name"])

    if unowned:
        for path in unowned:
            sys.stderr.write(f"check-territories: unowned in fix diff: {path}\n")
        return 1
    return 0


def parse_args(argv=None):
    ap = argparse.ArgumentParser(
        description="Validate territory disjointness, or intersect a fix diff."
    )
    sub = ap.add_subparsers(dest="command", required=True)

    v = sub.add_parser("validate", help="prove territories are disjoint and total")
    v.add_argument("scope", metavar="SCOPE_JSON")
    v.add_argument(
        "--check-kind",
        action="store_true",
        help="also reject an entry whose file-or-directory kind on disk "
        "contradicts its spelling; run from the repo root",
    )
    v.set_defaults(func=cmd_validate)

    i = sub.add_parser("intersect", help="territories a fix diff (stdin) lands in")
    i.add_argument("scope", metavar="SCOPE_JSON")
    i.set_defaults(func=cmd_intersect)

    return ap.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
