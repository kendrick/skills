#!/usr/bin/env bash
# List a scope's accepted records whose last_confirmed has gone stale, one line each.
#
# stamp-confirmed.sh writes last_confirmed onto a record every time a note
# confirms it, and nothing read the field back, so a record nobody had restated
# in a year looked the same as one confirmed last week (#262). The rule and the
# line text match `ltm doctor`'s stale-confirmed check in long-term-memory-kit,
# so one habit covers both tools: stale means more than N days old, strictly,
# and a record with no last_confirmed is aged by its `date` instead.
#
# `LTM_TODAY` (YYYY-MM-DD) pins today, the same variable `ltm doctor` reads, so
# one pinned date drives both tools and the smoke suite can sit on a boundary.
#
# This script only reads the scope. It never writes, deletes, or moves anything
# in it: confirming or deprecating a stale record is the user's call, and a
# reporter that edited what it reports would make its own next run look clean.
#
# A v1 record (`memory_type` and no `schema` key) is skipped on stderr before
# its status is looked at, in the order stamp-confirmed.sh uses, since v1 files
# are not this tool's to age.
#
# The frontmatter reader is a minimal stdlib one rather than `yq`, so the smoke
# suite can run this script without a new test dependency.
#
# Exit 0 whenever the walk finishes, findings or not: this script reports and
# gates nothing. Exit 2 on a usage error, an unreadable scope or record, or
# frontmatter that opens and never closes.
set -euo pipefail

# The Python program arrives on stdin via a quoted heredoc, so nothing in it is
# expanded by the shell and a bare apostrophe below is safe.
exec python3 - "$@" <<'PY'
import datetime
import os
import re
import sys

USAGE = """\
usage: stale-records.sh <scope-root> [--days N]

Print one line per `accepted` record under <scope-root>/_memory/ whose
last_confirmed (or its date, when it has no last_confirmed) is more than N
days before today:

  <path>: stale-confirmed: last_confirmed <d> is <n> days old (threshold <N>)

  --days N   threshold in days, an integer of 1 or more (default 90)

Set LTM_TODAY=YYYY-MM-DD to pin today. v1 records are listed on stderr as
`skipped: <path> (v1)`. Exits 0 with or without findings, 2 on an error.
"""


def die(msg):
    sys.stderr.write("stale-records: %s\n" % msg)
    sys.exit(2)


def usage():
    sys.stderr.write(USAGE)
    sys.exit(2)


# unquote through md_files are copied from bench-fixture.sh. Upstream is
# authoritative: fix the bug there, then re-copy.
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
        # An opening fence with no close is a malformed record, not a non-record.
        # Returning {} dropped its query and still exited 0 (PR #202 review).
        die("%s: frontmatter opens with --- but never closes" % path)
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


def md_files(root, skip_top=None):
    out = []
    if not os.path.isdir(root):
        return out

    def unreadable(err):
        # os.walk swallows these by default, which would emit an empty fixture
        # that reads like a scope with no accepted records.
        die("unreadable directory: %s" % err.filename)

    for dp, dn, fns in os.walk(root, onerror=unreadable):
        if dp == root and skip_top in dn:
            dn.remove(skip_top)
        for fn in fns:
            if fn.endswith(".md"):
                out.append(os.path.join(dp, fn))
    return sorted(out)


ISO = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def parse_date(s):
    # The regex keeps 3.11+'s looser fromisoformat (`20260210`) from aging a
    # value ltm would call malformed.
    if not isinstance(s, str) or not ISO.match(s):
        return None
    try:
        return datetime.date.fromisoformat(s)
    except ValueError:
        return None


def main():
    scope, days, args = None, 90, sys.argv[1:]
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--days":
            if i + 1 >= len(args):
                usage()
            try:
                days = int(args[i + 1])
            except ValueError:
                usage()
            # ltm's own floor for stale_confirmed_days.
            if days < 1:
                usage()
            i += 2
        elif a.startswith("-") or scope is not None:
            usage()
        else:
            scope = a
            i += 1
    if scope is None:
        usage()

    today = datetime.date.today()
    if "LTM_TODAY" in os.environ:
        today = parse_date(os.environ["LTM_TODAY"])
        if today is None:
            die("LTM_TODAY is not a YYYY-MM-DD date: %s" % os.environ["LTM_TODAY"])

    given, scope = scope, os.path.normpath(scope)
    memory = os.path.join(scope, "_memory")
    if not os.path.isdir(memory):
        # A journal keeps entries/ and no records to age.
        if os.path.isdir(os.path.join(scope, "entries")):
            return
        die("not a scope: %s" % given)

    rel = lambda p: os.path.relpath(p, scope).replace(os.sep, "/")
    for p in md_files(memory):
        fm = frontmatter(p)
        if not fm or "memory_type" not in fm:
            continue
        if "schema" not in fm:
            sys.stderr.write("skipped: %s (v1)\n" % rel(p))
            continue
        if fm.get("status") != "accepted":
            continue
        lc = fm.get("last_confirmed")
        # `last_confirmed:` left empty, or a legacy null, means unconfirmed.
        confirmed = isinstance(lc, str) and lc.strip() and lc.lower() not in ("null", "~")
        field = "last_confirmed" if confirmed else "date"
        raw = lc if confirmed else fm.get("date")
        d = parse_date(raw)
        # A malformed field is the validator's to report, as in ltm.
        if d is None:
            continue
        age = (today - d).days
        if age > days:
            tail = "" if confirmed else " and there's no last_confirmed"
            print("%s: stale-confirmed: %s %s is %d days old%s (threshold %d)"
                  % (rel(p), field, raw, age, tail, days))


main()
PY
