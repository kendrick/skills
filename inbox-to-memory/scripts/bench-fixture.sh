#!/usr/bin/env bash
# Generate a `qmd bench` fixture from a scope's memory records on stdout.
#
# Retrieval changes were being judged by feel because labeling a query set is the
# part of an eval nobody finishes. Here the labels already exist: every record
# names the notes it was distilled from in `source_refs`, so a query built from an
# accepted record should retrieve those notes and the record itself. Deriving the
# labels from that field means they stay current as records are written, with no
# hand-labeled set to rot (#191).
#
# Superseded files stay in the scope and stay indexed, and are only kept out of
# `expected_files`. The point of the fixture is to count how often a superseded
# record intrudes on results for a question its replacement answers; deleting it
# from the index would make that number zero by construction. For the same reason
# this script only reads the scope. It never writes, deletes, or moves anything in
# it, so a fixture run cannot change the thing being measured.
#
# A record whose `source_refs` entry does not resolve to exactly one note is
# skipped whole, with a line on stderr. A partly right label set would make the
# recall number meaningless, and a missing query is visible where a wrong one is not.
#
# The frontmatter reader is a minimal stdlib one rather than `yq`, so the smoke
# suite can run this script without a new test dependency.
#
# Exit 0 once a fixture is emitted (skipped records included). Exit 2 on a usage
# error or an unreadable scope, note, record, or questions file, matching
# collapse-vtt.sh, since this script produces an artifact and does not gate a run.
set -euo pipefail

# The Python program arrives on stdin via a quoted heredoc, so nothing in it is
# expanded by the shell and a bare apostrophe below is safe.
exec python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import sys

USAGE = """\
usage: bench-fixture.sh <scope-root> [--collection NAME] [--top-k K] [--questions FILE]

Emit a qmd bench fixture (JSON) on stdout: one query per `accepted` record under
<scope-root>/_memory/, expecting the notes it cites in source_refs plus the record.

Index the scope first so the expected paths match what qmd ls shows:
  qmd collection add <scope-root> --name <collection>
  qmd embed -c <collection>
  qmd ls <collection>   # confirm it lists the scope's files; qmd scores an unindexed collection as all zeros
  bench-fixture.sh <scope-root> --collection <collection> > fixture.json
  qmd bench fixture.json -c <collection>

  --collection NAME  collection name (default: basename of <scope-root>)
  --top-k K          expected_in_top_k floor (default 5); raised to the number
                     of expected files when that is larger
  --questions FILE   JSON array of {query, expected_files[, expected_in_top_k, type]}
                     appended as question-1, question-2, ...
"""


def die(msg):
    sys.stderr.write("bench-fixture: %s\n" % msg)
    sys.exit(2)


def unquote(v):
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
        q = v[0]
        v = v[1:-1]
        if q == "'":
            v = v.replace("''", "'")
    return v


def strip_comment(v):
    # Whitespace has to precede the `#` so a URL fragment like `page#top` survives.
    # A comment left in the value turns `status: accepted # ok` into a status that
    # fails the accepted gate, and the record drops out with exit 0.
    quote, i = None, 0
    while i < len(v):
        ch = v[i]
        if quote:
            if quote == '"' and ch == "\\":
                i += 1
            elif ch == quote:
                if quote == "'" and v[i + 1:i + 2] == "'":
                    i += 1
                else:
                    quote = None
        # A quote opens a scalar only at its start; `Bob's` is plain text.
        elif ch in "'\"" and v[:i].rstrip()[-1:] in ("", "[", ","):
            quote = ch
        elif ch == "#" and (i == 0 or v[i - 1] in " \t"):
            return v[:i].rstrip()
        i += 1
    return v


def scalar(v):
    return unquote(strip_comment(v))


def split_inline(body):
    items, cur, quote = [], "", None
    for ch in body:
        if quote:
            cur += ch
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
            cur += ch
        elif ch == ",":
            items.append(cur)
            cur = ""
        else:
            cur += ch
    items.append(cur)
    return [unquote(i) for i in items if i.strip()]


KEY = re.compile(r"^([A-Za-z_][\w-]*):(?:\s+(.*)|\s*)$")


def frontmatter(path):
    """Top-level keys of the leading --- block. Scalars become str; inline and
    block lists become list[str]; a block-list item written as a mapping
    (v1 `- note_id: X`) becomes the value of its note_id (or id) key."""
    try:
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except (OSError, UnicodeDecodeError) as e:
        # Skipping the file would drop a note or record from the labels and still
        # exit 0, so the fixture would look complete when it isn't.
        die("%s: unreadable (%s)" % (path, e))
    if not lines or lines[0].strip() != "---":
        return {}
    block = []
    for ln in lines[1:]:
        if ln.strip() == "---":
            break
        block.append(ln)
    else:
        return {}
    fm, i = {}, 0
    while i < len(block):
        m = KEY.match(block[i])
        i += 1
        if not m:
            continue
        key, val = m.group(1), strip_comment(m.group(2) or "").strip()
        if val.startswith("[") and val.endswith("]"):
            fm[key] = split_inline(val[1:-1])
        elif val:
            fm[key] = unquote(val)
        else:
            items, cur = [], None
            while i < len(block) and (
                block[i].startswith((" ", "\t", "-", "#")) or not block[i].strip()
            ):
                ln = block[i].strip()
                i += 1
                if ln.startswith("#"):
                    continue
                if ln.startswith("- ") or ln == "-":
                    if cur is not None:
                        items.append(cur)
                    body = ln[1:].strip()
                    mm = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", body)
                    cur = {mm.group(1): scalar(mm.group(2))} if mm else scalar(body)
                elif isinstance(cur, dict):
                    mm = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", ln)
                    if mm:
                        cur[mm.group(1)] = scalar(mm.group(2))
            if cur is not None:
                items.append(cur)
            if items:
                fm[key] = [
                    (it.get("note_id") or it.get("id") or "") if isinstance(it, dict) else it
                    for it in items
                ]
            else:
                fm[key] = ""
    return fm


def md_files(root):
    out = []
    if not os.path.isdir(root):
        return out

    def unreadable(err):
        # os.walk swallows these by default, which would emit an empty fixture
        # that reads like a scope with no accepted records.
        die("unreadable directory: %s" % err.filename)

    for dp, _dn, fns in os.walk(root, onerror=unreadable):
        for fn in fns:
            if fn.endswith(".md"):
                out.append(os.path.join(dp, fn))
    return sorted(out)


def as_list(v):
    if isinstance(v, list):
        return v
    return [v] if v else []


def top_k_for(k, n):
    return max(k, n)


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("scope", nargs="?")
    ap.add_argument("--collection")
    ap.add_argument("--top-k", dest="top_k", default="5")
    ap.add_argument("--questions")
    ap.add_argument("-h", "--help", action="store_true")
    try:
        args, extra = ap.parse_known_args(sys.argv[1:])
    except SystemExit:
        sys.stderr.write(USAGE)
        sys.exit(2)
    if args.help or args.scope is None or extra:
        sys.stderr.write(USAGE)
        sys.exit(2)
    try:
        top_k = int(args.top_k)
        if top_k < 1:
            raise ValueError
    except ValueError:
        die("--top-k must be a positive integer")
    scope = os.path.normpath(args.scope)
    if not os.path.isdir(scope):
        die("not a directory: %s" % args.scope)
    if not os.path.isdir(os.path.join(scope, "_memory")):
        die("no _memory/ directory under %s" % args.scope)
    collection = args.collection or os.path.basename(os.path.abspath(scope))

    questions = []
    if args.questions is not None:
        try:
            with open(args.questions, encoding="utf-8") as fh:
                data = json.load(fh)
        except (OSError, ValueError) as e:
            die("cannot read questions file %s: %s" % (args.questions, e))
        if not isinstance(data, list):
            die("questions file must be a JSON array")
        # 1-based so an error names the item the same way its question-<n> id would.
        for idx, it in enumerate(data, 1):
            ok = isinstance(it, dict)
            q = it.get("query") if ok else None
            ef = it.get("expected_files") if ok else None
            if not (isinstance(q, str) and q.strip()):
                die("questions item %d: query must be a non-empty string" % idx)
            if not (isinstance(ef, list) and ef and all(isinstance(f, str) and f for f in ef)):
                die("questions item %d: expected_files must be a non-empty list of strings" % idx)
            k = it.get("expected_in_top_k")
            if k is not None and (not isinstance(k, int) or isinstance(k, bool) or k < 1):
                die("questions item %d: expected_in_top_k must be a positive integer" % idx)
            t = it.get("type", "semantic")
            if not isinstance(t, str) or not t:
                die("questions item %d: type must be a non-empty string" % idx)
            questions.append((q, ef, k, t))

    rel = lambda p: os.path.relpath(p, scope).replace(os.sep, "/")

    notes = {}
    for p in md_files(os.path.join(scope, "notes")):
        fm = frontmatter(p)
        if fm and fm.get("id"):
            notes.setdefault(fm["id"], []).append((p, fm))

    queries = []
    for p in md_files(os.path.join(scope, "_memory")):
        fm = frontmatter(p)
        if not fm or "memory_type" not in fm:
            continue
        # Exact match on purpose: proposed, rejected, and superseded records are
        # all things a user would not want retrieval to be graded against.
        if fm.get("status") != "accepted":
            continue
        rid = fm.get("id") or os.path.splitext(os.path.basename(p))[0]
        text = (fm.get("summary") or "").strip() or (fm.get("title") or "").strip()
        if not text:
            sys.stderr.write("bench-fixture: %s: no summary or title to use as query text\n" % rel(p))
            continue
        files, bad = [], False
        for entry in as_list(fm.get("source_refs")):
            nid = entry.split("::", 1)[1] if "::" in entry else entry
            hits = notes.get(nid, [])
            if len(hits) != 1:
                what = "does not resolve to a note" if not hits else "resolves to %d notes" % len(hits)
                sys.stderr.write("bench-fixture: %s: source_ref %s %s\n" % (rel(p), entry, what))
                bad = True
                break
            np_, nfm = hits[0]
            if nfm.get("status") != "superseded" and rel(np_) not in files:
                files.append(rel(np_))
        if bad:
            continue
        if rel(p) not in files:
            files.append(rel(p))
        queries.append({
            "id": "record-%s" % rid,
            "query": text,
            "type": "semantic",
            "expected_files": files,
            "expected_in_top_k": top_k_for(top_k, len(files)),
        })

    for n, (q, ef, k, t) in enumerate(questions, 1):
        queries.append({
            "id": "question-%d" % n,
            "query": q,
            "type": t,
            "expected_files": ef,
            "expected_in_top_k": k if k is not None else top_k_for(top_k, len(ef)),
        })

    json.dump({
        "description": "Generated from source_refs by bench-fixture.sh (#191)",
        "version": 1,
        "collection": collection,
        "queries": queries,
    }, sys.stdout, indent=2)
    sys.stdout.write("\n")


main()
PY
