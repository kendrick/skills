#!/usr/bin/env python3
"""Build a red-team round's verdict file from per-claim verdict lines.

    work-issue/scripts/merge-verdicts.py --claims CLAIMS.json --parts DIR \\
        --round K --uncovered UNCOVERED.json [--fallback FILE] --out ROUND.json

An external reproducer writes one JSON line per finished claim into
`round-<k>.part-<p>.verdicts.jsonl` files under --parts. This script matches
those lines to the claims the round dispatched, names the claims no line
covers, and writes --out once nothing is uncovered. It exists so that no one,
the orchestrator included, assembles or tidies a verdict by hand. The rule in
redteam.md forbids editing a verdict, and a hand merge is where such edits
happen. It also decides which claims the subagent fallback re-runs, so a
miscount either drops a claim unverified or redoes finished work.

--claims is `{"claims": [...], "left": [...]}`, the objects this round
dispatched in report order. Each object carries an integer `n`, its 1-based
position in its own list, so `claims` and `left` each run 1..len. A line
carrying a string `claim` is a verdict, and one carrying a string `what` is a
left check.

Matching: a line covers the entry its `n` names, in the list its key picks.
Its `claim` (or `what`) string must equal that entry's text exactly, as a
cross-check. Identity rides on `n` and never on text or line order: two claims
can share their text, and when part 1 of a split stops before writing its copy,
any rule that infers identity from the surviving lines gives part 2's verdict
to the wrong claim and sends a finished claim to the fallback.

A claim line is accepted only when its `verdict` is `REPRODUCED`,
`NOT_REPRODUCED`, or `UNVERIFIABLE`, and a left line only when `holds` is a
JSON boolean. Without that check, a line holding only the claim text counts as
covered and its claim skips the fallback with no verdict at all.

A line is rejected, with `merge-verdicts: rejected <file>:<lineno>: <reason>`
on stderr, when it does not parse, is not an object, carries neither key, lacks
an integer `n` naming a dispatched entry, disagrees with that entry's text,
lacks a valid `verdict` or `holds`, or names an `n` an earlier line already
covered. A rejection never covers a claim, and only an uncovered claim fails
the run. Parts are read in ascending numeric <p>; coverage follows the lines in
the files, never the file count or the part number.

--fallback is a saved subagent answer, one fenced json block holding
`verdicts` and `left_checks`. Its elements pass the same checks, after the part
lines, and fill only the `n` values the part files left uncovered. An element
naming an `n` already covered, or failing any other check, is rejected on
stderr as `rejected --fallback <list>[<i>]: <reason>`. A part file is decoded
with replacement characters, so a line cut mid-character is rejected per line;
a --fallback file that is not UTF-8 is unreadable input.

The script always writes --uncovered, holding the uncovered --claims objects
unchanged. --out is `{"verdicts": [...], "left_checks": [...]}` in report
order, written only when nothing is uncovered, via a `.merge-<k>.tmp` file and
os.replace: the resume probe counts any `round-*.json` it finds, so a
half-written file must never carry that name.

Exit codes: 0 pass; 1 semantic failure (something uncovered) with one line per
problem on stderr; 3 usage, missing or unreadable input.

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
    for key in ("claims", "left"):
        if [c.get("n") for c in data[key]] != list(range(1, len(data[key]) + 1)) or any(
                isinstance(c["n"], bool) for c in data[key]):
            die(f"--claims {path}: every `{key}` object needs an integer `n`, numbered 1..len in order")
    return data


def load_fallback(path):
    try:
        text = Path(path).read_text(encoding="utf-8")
    except (OSError, ValueError) as e:  # ValueError covers UnicodeDecodeError
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


VERDICTS = ("REPRODUCED", "NOT_REPRODUCED", "UNVERIFIABLE")


def check(obj, entries, covered):
    """Return (field, n) when `obj` covers an uncovered entry, else a rejection reason string."""
    if not isinstance(obj, dict):
        return "not a JSON object"
    field = "claim" if isinstance(obj.get("claim"), str) else "what" if isinstance(obj.get("what"), str) else None
    if field is None:
        return "carries neither a string `claim` nor `what`"
    n, items = obj.get("n"), entries[field]
    if not isinstance(n, int) or isinstance(n, bool) or not 1 <= n <= len(items):
        return f'{field} "{obj[field]}" carries no `n` naming a {field} dispatched this round'
    if obj[field] != items[n - 1][field]:
        return f'{field} "{obj[field]}" disagrees with the text of {field} n={n}'
    if field == "claim" and obj.get("verdict") not in VERDICTS:
        return f"claim n={n} carries no `verdict` of {', '.join(VERDICTS)}"
    if field == "what" and not isinstance(obj.get("holds"), bool):
        return f"what n={n} carries no boolean `holds`"
    if n in covered[field]:
        return f"surplus line for {field} n={n}, already covered"
    return field, n


def read_lines(files, entries, covered, rejected):
    for f in files:
        # errors="replace": the 2700 s cap can kill codex partway through a
        # multi-byte character. The damaged line then fails to parse or names no
        # dispatched claim, is rejected per line, and its claim stays uncovered.
        text = f.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.split("\n"), 1):
            if not line.strip():
                continue
            try:
                obj = json.loads(line, strict=False)
            except ValueError as e:
                rejected.append(f"rejected {f.name}:{lineno}: not JSON: {e}")
                continue
            got = check(obj, entries, covered)
            if isinstance(got, str):
                rejected.append(f"rejected {f.name}:{lineno}: {got}")
            else:
                covered[got[0]][got[1]] = obj


class Parser(argparse.ArgumentParser):
    # argparse exits 2 on bad usage; the repo's validator convention is 3.
    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        sys.exit(3)


def main():
    ap = Parser(description="merge per-claim verdict lines into a round file")
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

    entries = {"claim": claims, "what": left}
    covered = {"claim": {}, "what": {}}
    rejected = []
    try:
        read_lines(part_files(a.parts, a.round), entries, covered, rejected)
    except OSError as e:
        die(f"cannot read a part file: {e}")

    if a.fallback:
        fb = load_fallback(a.fallback)
        for key in ("verdicts", "left_checks"):
            for i, obj in enumerate(fb.get(key, [])):
                got = check(obj, entries, covered)
                if isinstance(got, str):
                    rejected.append(f"rejected --fallback {key}[{i}]: {got}")
                else:
                    covered[got[0]][got[1]] = obj
    for r in rejected:
        print(f"merge-verdicts: {r}", file=sys.stderr)

    verdicts = [covered["claim"].get(c["n"]) for c in claims]
    checks = [covered["what"].get(c["n"]) for c in left]

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
            print(f"merge-verdicts: uncovered claim n={c['n']}: {c['claim']}", file=sys.stderr)
        for c in unc_left:
            print(f"merge-verdicts: uncovered left n={c['n']}: {c['what']}", file=sys.stderr)
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
