#!/usr/bin/env bash
# Find the memory records an input might overlap, for phase 2.5 of SKILL.md.
#
# Grep alone misses a contradiction whose input never names the record's
# entity: "we're moving off the vendor" shares no word with a record about
# Tolland Freight. So each claim sentence also runs as a qmd vector search
# against the scope's per-type _memory collections, and both hit lists merge
# before any header is read (#194). Picking the entities and claims is
# judgment, so it stays in the prose. Merging, reading status, and counting
# come out the same every run, and a script is the only form a PATH shim can
# stub for the smoke suite.
#
# Reading stops at each record's closing frontmatter fence. The body-read
# budget lives in SKILL.md, and a lookup that never opens a body can't spend
# it. A status other than accepted or proposed drops at that header read,
# whichever lookup found the record, since a superseded record's body can
# produce no flag, stamp, or restatement line.
#
# qmd is optional. With it off PATH, or with any qmd call failing, the run
# falls back to grep alone and says so in exactly one `vec off:` line on
# stderr. Vec hits gathered before a failure are discarded, because partial
# hits make counts that describe an index that answered half the claims. When
# vec ran clean but a record is newer than the last memory-index refresh, one
# `vec stale:` line says the hits may miss it (#374). The script never
# registers or refreshes a scope: memory-index does that, after the user
# approves its dry run.
#
# Exit 0 once output is printed, the fallback included. Exit 2 on a usage
# error, an unreadable entities, claims, or record file, frontmatter that
# opens and never closes, or a scope with neither _memory/ nor entries/. This
# produces an artifact rather than gating a run, so it takes bench-fixture.sh's 2.
set -euo pipefail

# The Python program arrives on stdin via a quoted heredoc, so nothing in it is
# expanded by the shell and a bare apostrophe below is safe.
exec python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

USAGE = """\
usage: find-candidates.sh <scope-root> --entities FILE --claims FILE [--top-k K]

Print one line per record that grep or qmd vec search returned, sorted by path:
  candidate: <path> <status> <source>   status accepted or proposed
  dropped: <path> <status> <source>     any other status, never body-read
where <source> is grep, vec, or both. The last line is always
  counts: grep=<g> vec=<v> both=<b>

  --entities FILE  canonical entities, one per line, grepped against frontmatter
  --claims FILE    claim sentences, one per line, each run as a qmd vsearch
  --top-k K        hits per claim (default 5)

Both files are required and may be empty.
"""

QMD_TIMEOUT = 120
KEEP = ("accepted", "proposed")


def die(msg):
    sys.stderr.write("find-candidates: %s\n" % msg)
    sys.exit(2)


# ---------------------------------------------------------------------------
# Vendored verbatim from memory-index/scripts/memory-index.py (lines 33-34),
# 2026-10-30. Upstream is authoritative: fix a bug there first, then re-copy.
# A name that drifts from the one memory-index registers fails every lookup
# as an unregistered collection and says nothing else. This skill installs
# standalone, so importing from the sibling skill is not available.
# ---------------------------------------------------------------------------
def scope_name(root: Path) -> str:
    return re.sub(r"[^a-z0-9]+", "-", root.name.lower()).strip("-")
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Vendored verbatim from memory-index/scripts/memory-index.py (lines 38-63),
# 2026-11-19. Upstream is authoritative: fix a bug there first, then re-copy.
# A rule that drifts from the one `refresh` stamps against reports a stale
# index as fresh, or the reverse, and says nothing else. This skill installs
# standalone, so importing from the sibling skill is not available.
# ---------------------------------------------------------------------------
def state_dir() -> Path:
    return Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state") / "memory-index"


def last_refresh_ns() -> int | None:
    """Start time of the last successful refresh, or None when no stamp is readable."""
    try:
        return int(json.loads((state_dir() / "last-refresh.json").read_text(encoding="utf-8"))["started_ns"])
    except (OSError, ValueError, KeyError, TypeError):
        return None


def changed_since(folder: Path, pattern: str, since: int | None) -> bool:
    """True when a regular file in folder.glob(pattern) is newer than since.

    pathlib's glob, not fnmatch: fnmatch's `*` crosses `/`, so "*.md" would
    match notes/raw/x.md, which qmd's `*.md` mask leaves out. since None means
    no stamp, so every matching file counts as newer.
    """
    for f in folder.glob(pattern):
        try:
            if f.is_file() and (since is None or f.stat().st_mtime_ns > since):
                return True
        except OSError:
            continue
    return False
# ---------------------------------------------------------------------------


def read_lines(path, what):
    try:
        with open(path, encoding="utf-8") as fh:
            return [ln.strip() for ln in fh if ln.strip()]
    except (OSError, UnicodeDecodeError) as e:
        die("cannot read %s file %s: %s" % (what, path, e))


def frontmatter(path):
    """Lines between the opening --- on line 1 and the closing ---. Reads
    line by line and stops at the closing fence."""
    # Binary, decoding one line at a time: a text-mode reader decodes ahead in
    # chunks, so a body that isn't UTF-8 failed a record whose header was fine.
    try:
        with open(path, "rb") as fh:
            if fh.readline().decode("utf-8").strip() != "---":
                return []
            block = []
            for raw in fh:
                ln = raw.decode("utf-8").rstrip("\r\n")
                if ln.strip() == "---":
                    return block
                block.append(ln)
    except (OSError, UnicodeDecodeError) as e:
        die("%s: unreadable (%s)" % (path, e))
    die("%s: frontmatter opens with --- but never closes" % path)


STATUS = re.compile(r"^status:\s*(.*?)\s*$")


def status_of(block):
    for ln in block:
        m = STATUS.match(ln)
        if m:
            v = m.group(1)
            # A trailing comment would turn `accepted # ok` into a dropped
            # record. A quoted value can carry one too (`"accepted" # ok`), and
            # a `#` inside the quotes is not a comment, so a quoted value ends
            # at its closing quote (#273 review).
            q = v[:1]
            if q in ("'", '"'):
                end = v.find(q, 1)
                v = v[1:end] if end > 0 else v
            else:
                v = re.sub(r"\s+#.*$", "", v)
            return v.strip() or "none"
    return "none"


def records(scope):
    """{relpath: abspath} for every *.md under _memory/<type>/ at any depth,
    with the same first-level filter memory-index.py registers by."""
    mem = os.path.join(scope, "_memory")

    def unreadable(err):
        # os.walk swallows these by default, which reads as a scope with no records.
        die("unreadable directory: %s" % err.filename)

    try:
        types = sorted(
            n for n in os.listdir(mem)
            if not n.startswith(".") and os.path.isdir(os.path.join(mem, n))
        )
    except OSError as e:
        die("unreadable directory: %s (%s)" % (mem, e))
    out = {}
    for t in types:
        for dp, _, fns in os.walk(os.path.join(mem, t), onerror=unreadable):
            for fn in fns:
                if fn.endswith(".md"):
                    p = os.path.join(dp, fn)
                    out[os.path.relpath(p, scope).replace(os.sep, "/")] = p
    return types, out


def vec_hits(scope, types, recs, claims, k):
    """(set of relpaths, vec-off reason or None). All or nothing: one failed
    call discards every hit so far and stops further calls."""
    if not claims or not types:
        return set(), None
    if shutil.which("qmd") is None:
        return set(), "qmd not on PATH"
    name = scope_name(Path(scope).resolve())
    cols = {"%s-%s" % (name, t): t for t in types}
    col_args = []
    for t in types:
        col_args += ["-c", "%s-%s" % (name, t)]
    hits, unmapped = set(), set()
    for claim in claims:
        argv = ["qmd", "vsearch", claim] + col_args + ["-n", str(k), "--format", "json"]
        try:
            r = subprocess.run(argv, capture_output=True, text=True, timeout=QMD_TIMEOUT)
        except subprocess.TimeoutExpired:
            return set(), "qmd vsearch timed out"
        except OSError as e:
            return set(), "qmd vsearch failed to start (%s)" % e
        if r.returncode != 0:
            first = next((ln.strip() for ln in r.stderr.splitlines() if ln.strip()), "")
            return set(), first or "qmd vsearch exited %d" % r.returncode
        try:
            data = json.loads(r.stdout)
        except ValueError:
            return set(), "unreadable qmd output"
        if not isinstance(data, list) or not all(
            isinstance(h, dict) and isinstance(h.get("file"), str) for h in data
        ):
            return set(), "unreadable qmd output"
        for h in data:
            uri = h["file"]
            col, _, rel = uri[len("qmd://"):].partition("/") if uri.startswith("qmd://") else ("", "", "")
            path = "_memory/%s/%s" % (cols[col], rel) if col in cols else None
            # Checking against the walked set also refuses a `..` path that escapes the type dir.
            if path is None or path not in recs:
                if uri not in unmapped:
                    unmapped.add(uri)
                    sys.stderr.write("find-candidates: unmapped vec hit %s\n" % uri)
                continue
            hits.add(path)
    return hits, None


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("scope", nargs="?")
    ap.add_argument("--entities")
    ap.add_argument("--claims")
    ap.add_argument("--top-k", dest="top_k", default="5")
    ap.add_argument("-h", "--help", action="store_true")
    try:
        args, extra = ap.parse_known_args(sys.argv[1:])
    except SystemExit:
        sys.stderr.write(USAGE)
        sys.exit(2)
    if args.help or args.scope is None or extra or args.entities is None or args.claims is None:
        sys.stderr.write(USAGE)
        sys.exit(2)
    try:
        k = int(args.top_k)
        if k < 1:
            raise ValueError
    except ValueError:
        die("--top-k must be a positive integer")
    scope = os.path.normpath(args.scope)
    has_memory = os.path.isdir(os.path.join(scope, "_memory"))
    if not has_memory and not os.path.isdir(os.path.join(scope, "entries")):
        die("not a memory scope: %s" % args.scope)
    entities = [e.lower() for e in read_lines(args.entities, "entities")]
    claims = read_lines(args.claims, "claims")
    # A journal scope (entries/, no _memory/) passes phase 1 and holds no
    # records for phase 2.5 to check. Zero counts with no qmd call let journal
    # grooming run to the end (#273 review).
    if not has_memory:
        print("counts: grep=0 vec=0 both=0")
        return

    types, recs = records(scope)
    headers = {rel: frontmatter(p) for rel, p in recs.items()}

    grep = set()
    if entities:
        for rel, block in headers.items():
            text = "\n".join(block).lower()
            if any(e in text for e in entities):
                grep.add(rel)

    since = last_refresh_ns()
    vec, off = vec_hits(scope, types, recs, claims, k)
    if off:
        sys.stderr.write("vec off: %s; grep only\n" % off)
    # `**/*.md` is the qmd default `register` leaves on type folders. Only runs
    # when vec ran clean, so this line never pairs with `vec off:`.
    elif claims and types and any(
        changed_since(Path(scope) / "_memory" / t, "**/*.md", since) for t in types
    ):
        sys.stderr.write("vec stale: a record changed after the last memory-index refresh; vec hits may miss it\n")

    counts = {"grep": 0, "vec": 0, "both": 0}
    for rel in sorted(grep | vec):
        src = "both" if rel in grep and rel in vec else ("grep" if rel in grep else "vec")
        counts[src] += 1
        st = status_of(headers[rel])
        kind = "candidate" if st in KEEP else "dropped"
        print("%s: %s %s %s" % (kind, rel, st, src))
    print("counts: grep=%d vec=%d both=%d" % (counts["grep"], counts["vec"], counts["both"]))


main()
PY
