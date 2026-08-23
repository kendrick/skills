#!/usr/bin/env python3
"""Regenerate the table inside a category's map of content.

Only the block between the markers is touched. Everything else in the file --
the framing, the caveats, the sections a person wrote -- survives untouched,
because a map that overwrites its own prose stops being worth writing prose in.

Columns, labels, and which categories carry a map all come from the [moc]
table in the conventions note. Nothing about the shape of the table is decided
here, so changing what it shows is a config edit rather than a code edit.

Rows come from the folders, never from the file being rewritten: the point is
to make the table agree with the disk, so reading the old table as input would
let a stale row perpetuate itself.

  build_moc.py --vault PATH [--category 11] [--check]

--check writes nothing and exits 1 if the table is out of date, which is what
lets an audit ask "is this stale?" without holding the power to fix it.
"""

from __future__ import annotations

import argparse
import re
import socket
import sys
import tomllib
from pathlib import Path
from urllib.parse import quote

DEFAULT_CONVENTIONS = "00-09 Admin & Meta/00 System/00.02 Vault Conventions.md"


def load_conventions(path: Path) -> dict:
    m = re.search(r"```toml\n(.*?)\n```", path.read_text(encoding="utf-8"), re.S)
    if not m:
        sys.exit(f"no fenced toml block in {path}")
    data = tomllib.loads(m.group(1))
    if data.get("schema_version") != 1:
        sys.exit(f"unsupported schema_version {data.get('schema_version')!r}")
    return data


def roots_for_host(data: dict, host: str) -> dict:
    hosts = data.get("hosts", {})
    entry = hosts.get(host)
    if not entry:
        return {}
    return {k: [Path(p) for p in v] for k, v in entry.items() if isinstance(v, list)}


def status_of(id_dir: Path, data: dict) -> str:
    anchor = id_dir / data.get("status", {}).get("anchor_note", "README.md")
    prop = data.get("status", {}).get("property", "status")
    if not anchor.exists():
        return "—"
    m = re.search(rf"^{re.escape(prop)}:\s*(\S+)", anchor.read_text(encoding="utf-8"), re.M)
    return m.group(1) if m else "—"


def furl(p: Path) -> str:
    return "file://" + quote(str(p))


def cell(col: str, jd: str, name: str, folder: str, id_dir: Path,
         roots: dict, data: dict) -> str:
    if col == "id":
        return jd
    if col == "name":
        return f"**{name}**"
    if col == "status":
        return status_of(id_dir, data)
    if col == "vault":
        return f"[notes]({quote(folder)}/)"
    if col == "updated":
        newest = max((f.stat().st_mtime for f in id_dir.rglob("*") if f.is_file()),
                     default=0)
        return __import__("datetime").date.fromtimestamp(newest).isoformat() if newest else "—"
    # office and code resolve through this host's roots. A substrate that does
    # not carry the category, or a folder that was never made, both read as a
    # dash -- the map says where material is, not where it could hypothetically go.
    for candidate in roots.get(col, []):
        # the office tree nests categories; the code tree holds IDs flat
        for probe in (candidate / id_dir.parent.name / folder, candidate / folder):
            if probe.exists():
                return f"[{col}]({furl(probe)})"
    return "—"


def build_table(category_dir: Path, data: dict, roots: dict) -> str:
    moc = data["moc"]
    cols = moc["columns"]
    labels = moc.get("labels", {})
    id_re = re.compile(data["grammar"]["id"])

    excluded = set(moc.get("exclude", []))
    rows = []
    for d in sorted(category_dir.iterdir(), key=lambda p: p.name):
        if not d.is_dir():
            continue
        m = id_re.match(d.name)
        if not m:
            continue
        jd, name = d.name.split(" ", 1)
        if jd in excluded:
            continue
        rows.append("| " + " | ".join(
            cell(c, jd, name, d.name, d, roots, data) for c in cols) + " |")

    head = "| " + " | ".join(labels.get(c, c) for c in cols) + " |"
    rule = "|" + "|".join("---" for _ in cols) + "|"
    return "\n".join([head, rule] + rows)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--vault", required=True, type=Path)
    ap.add_argument("--conventions", type=Path)
    ap.add_argument("--category", action="append", default=[])
    ap.add_argument("--host", default=None)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    conv = args.conventions or (args.vault / DEFAULT_CONVENTIONS)
    data = load_conventions(conv)
    roots = roots_for_host(data, args.host or socket.gethostname())
    moc = data.get("moc")
    if not moc:
        sys.exit("conventions declare no [moc] table")

    wanted = args.category or moc["categories"]
    begin, end = moc["begin_marker"], moc["end_marker"]
    stale = False

    for cat in wanted:
        matches = [p for p in args.vault.rglob(f"{cat} *") if p.is_dir()]
        if not matches:
            print(f"category {cat}: no folder found", file=sys.stderr)
            continue
        cat_dir = matches[0]
        moc_file = cat_dir / moc["filename"]
        if not moc_file.exists():
            print(f"category {cat}: no {moc['filename']} to update", file=sys.stderr)
            continue

        text = moc_file.read_text(encoding="utf-8")
        if begin not in text or end not in text:
            print(f"category {cat}: {moc['filename']} has no generated block "
                  f"({begin} … {end}); leaving it alone", file=sys.stderr)
            continue

        table = build_table(cat_dir, data, roots)
        pre, rest = text.split(begin, 1)
        _, post = rest.split(end, 1)
        updated = f"{pre}{begin}\n{table}\n{end}{post}"

        if updated == text:
            print(f"category {cat}: table already current")
            continue
        stale = True
        if args.check:
            print(f"category {cat}: table is out of date")
        else:
            moc_file.write_text(updated, encoding="utf-8")
            print(f"category {cat}: table rewritten ({len(table.splitlines()) - 2} rows)")

    return 1 if (args.check and stale) else 0


if __name__ == "__main__":
    raise SystemExit(main())
