#!/usr/bin/env python3
"""Build a red-team round's verdict file from per-claim verdict lines.

    work-issue/scripts/merge-verdicts.py --claims CLAIMS.json --parts DIR \\
        --round K --uncovered UNCOVERED.json [--fallback FILE] --out ROUND.json

An external reproducer writes one JSON line per finished claim into
`round-<k>.part-<p>.verdicts.jsonl` files under --parts. This script matches
those lines to the claims the round dispatched, names the claims no line
covers, and writes --out once nothing is uncovered. It exists so that no one,
the orchestrator included, assembles or tidies a verdict by hand: redteam.md
forbids editing a verdict, and a hand merge is where that happens. It also
decides which claims the subagent fallback re-runs, so a miscount either drops
a claim unverified or redoes finished work.

--claims is `{"claims": [...], "left": [...]}`, the objects this round
dispatched in report order. A line carrying a string `claim` is a verdict, and
one carrying a string `what` is a left check.

Matching: claims group by exact `claim` string (left entries by `what`). Within
a group the i-th accepted line carrying that string covers the i-th claim in
report order. Positional matching exists because one line must never cover two
claims that share their text. A line is rejected, with `merge-verdicts:
rejected <file>:<lineno>: <reason>` on stderr, when it does not parse, is not
an object, carries neither key, names a claim or left entry this round did not
dispatch, or is a surplus duplicate. A rejection leaves its claim uncovered,
and that is what fails the run. Parts are read in ascending numeric <p>;
coverage follows the lines in the files, never the file count or the part
number.

--fallback is a saved subagent answer, one fenced json block holding
`verdicts` and `left_checks`. Its elements fill only what the part files left
uncovered, by the same rule, after the part lines.

--uncovered is always written, holding the uncovered --claims objects
unchanged. --out is `{"verdicts": [...], "left_checks": [...]}` in report
order, written only when nothing is uncovered, via a `.merge-<k>.tmp` file and
os.replace: the resume probe counts any `round-*.json` it finds, so a
half-written file must never carry that name.

Exit codes: 0 pass; 1 semantic failure (something uncovered) with one line per
problem on stderr; 3 usage, missing or unreadable input. Argparse supplies 2
for a mistyped flag.

Stdlib only, so the skill stays copy-in portable.
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path


def die(msg):
    print(f"merge-verdicts: {msg}", file=sys.stderr)
    sys.exit(3)


def load_claims(path):
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"), strict=False)
    except (OSError, ValueError) as e:
        die(f"cannot read --claims {path}: {e}")
    if not (
        isinstance(data, dict)
        and isinstance(data.get("claims"), list)
        and isinstance(data.get("left"), list)
        and all(isinstance(c, dict) and isinstance(c.get("claim"), str) for c in data["claims"])
        and all(isinstance(c, dict) and isinstance(c.get("what"), str) for c in data["left"])
    ):
        die(f'--claims {path} is not {{"claims": [...], "left": [...]}} of objects with `claim`/`what`')
    return data


def load_fallback(path):
    try:
        text = Path(path).read_text(encoding="utf-8")
    except OSError as e:
        die(f"cannot read --fallback {path}: {e}")
    # Same single-fence strip as run-state.py's round parser: the subagent's
    # answer is one fenced block, and digging JSON out of surrounding prose
    # would be tidying a verdict.
    lines = text.strip().split("\n")
    if len(lines) >= 2 and lines[0].rstrip() in ("```", "```json") and lines[-1].rstrip() == "```":
        text = "\n".join(lines[1:-1])
    try:
        data = json.loads(text, strict=False)
    except ValueError as e:
        die(f"--fallback {path} is not JSON: {e}")
    if not (isinstance(data, dict) and isinstance(data.get("verdicts", []), list)
            and isinstance(data.get("left_checks", []), list)):
        die(f"--fallback {path} lacks `verdicts`/`left_checks` lists")
    return data


def part_files(parts_dir, k):
    pat = re.compile(rf"^round-{re.escape(str(k))}\.part-(\d+)\.verdicts\.jsonl$")
    found = []
    for p in Path(parts_dir).iterdir():
        m = pat.match(p.name)
        if m:
            found.append((int(m.group(1)), p))
    return [p for _, p in sorted(found)]


def read_lines(files, claim_keys, left_keys):
    """Return (accepted verdicts by key, accepted left checks by key, rejections)."""
    got = {"claim": {}, "what": {}}
    allowed = {"claim": claim_keys, "what": left_keys}
    rejected = []
    for f in files:
        text = f.read_text(encoding="utf-8")
        for n, line in enumerate(text.split("\n"), 1):
            if not line.strip():
                continue
            where = f"{f.name}:{n}"
            try:
                obj = json.loads(line, strict=False)
            except ValueError as e:
                rejected.append(f"rejected {where}: not JSON: {e}")
                continue
            if not isinstance(obj, dict):
                rejected.append(f"rejected {where}: not a JSON object")
                continue
            field = "claim" if isinstance(obj.get("claim"), str) else "what" if isinstance(obj.get("what"), str) else None
            if field is None:
                rejected.append(f"rejected {where}: carries neither a string `claim` nor `what`")
                continue
            key = obj[field]
            if key not in allowed[field]:
                rejected.append(f'rejected {where}: {field} "{key}" was not dispatched this round')
                continue
            bucket = got[field].setdefault(key, [])
            if len(bucket) >= allowed[field][key]:
                rejected.append(f'rejected {where}: surplus line for {field} "{key}"')
                continue
            bucket.append(obj)
    return got["claim"], got["what"], rejected


def fill(items, field, accepted, extra):
    """Pair each item with its positional line; `extra` tops up from the fallback."""
    seen = {}
    result = []
    for item in items:
        key = item[field]
        i = seen[key] = seen.get(key, -1) + 1
        pool = accepted.setdefault(key, [])
        if i >= len(pool) and extra.get(key):
            pool.append(extra[key].pop(0))
        result.append(pool[i] if i < len(pool) else None)
    return result


def main():
    ap = argparse.ArgumentParser(description="merge per-claim verdict lines into a round file")
    ap.add_argument("--claims", required=True)
    ap.add_argument("--parts", required=True)
    ap.add_argument("--round", required=True, type=int)
    ap.add_argument("--uncovered", required=True)
    ap.add_argument("--fallback")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    data = load_claims(a.claims)
    claims, left = data["claims"], data["left"]
    if not os.path.isdir(a.parts):
        die(f"--parts {a.parts} is not a directory")

    sizes = {"claim": {}, "what": {}}
    for field, items in (("claim", claims), ("what", left)):
        for it in items:
            sizes[field][it[field]] = sizes[field].get(it[field], 0) + 1

    try:
        got_v, got_l, rejected = read_lines(part_files(a.parts, a.round), sizes["claim"], sizes["what"])
    except OSError as e:
        die(f"cannot read a part file: {e}")
    for r in rejected:
        print(f"merge-verdicts: {r}", file=sys.stderr)

    extra_v, extra_l = {}, {}
    if a.fallback:
        fb = load_fallback(a.fallback)
        for obj in fb.get("verdicts", []):
            if isinstance(obj, dict) and isinstance(obj.get("claim"), str):
                extra_v.setdefault(obj["claim"], []).append(obj)
        for obj in fb.get("left_checks", []):
            if isinstance(obj, dict) and isinstance(obj.get("what"), str):
                extra_l.setdefault(obj["what"], []).append(obj)

    verdicts = fill(claims, "claim", got_v, extra_v)
    checks = fill(left, "what", got_l, extra_l)

    unc_claims = [c for c, v in zip(claims, verdicts) if v is None]
    unc_left = [c for c, v in zip(left, checks) if v is None]
    try:
        Path(a.uncovered).write_text(
            json.dumps({"claims": unc_claims, "left": unc_left}, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8")
    except OSError as e:
        die(f"cannot write --uncovered: {e}")

    if unc_claims or unc_left:
        for c in unc_claims:
            print(f"merge-verdicts: uncovered claim: {c['claim']}", file=sys.stderr)
        for c in unc_left:
            print(f"merge-verdicts: uncovered left: {c['what']}", file=sys.stderr)
        return 1

    out = Path(a.out)
    tmp = out.parent / f".merge-{a.round}.tmp"
    try:
        tmp.write_text(
            json.dumps({"verdicts": verdicts, "left_checks": checks}, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8")
        os.replace(tmp, out)
    except OSError as e:
        die(f"cannot write --out: {e}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
