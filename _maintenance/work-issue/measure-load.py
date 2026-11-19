#!/usr/bin/env python3
"""Measure what one work-issue invocation loads from its own instructions.

Built for #190. An invocation reads SKILL.md whole, then whichever references
its step names, so the cost of a launch is the sum of those, not the size of
any one file. This prints that cost per unit (frontmatter, preamble, each
`## ` section, each reference) and per resume phase 0 through 8: what the
invocation loads today, what it would load if only its own step were read, and
the share it didn't need.

Everything is parsed from the files as they stand when it runs, so the numbers
follow SKILL.md edits and no expected value from any past tree lives here.
Reference tags come from SKILL.md's own `## Further Reading` bullets for the
same reason.

Token mode exists because the model's tokenizer is the consumer: tiktoken and
bytes/4 both disagree with what the model reports, so units are counted by
Anthropic's count_tokens endpoint over raw HTTP (stdlib only, no SDK).

Exit 0 printed, 1 structure problem, 3 usage, unreadable input, or API failure.
"""
import argparse
import json
import os
import re
import statistics
import sys
import urllib.error
import urllib.request
from pathlib import Path

PHASES = range(9)
READ_AT = re.compile(r"read at Steps? (\d+(?:(?:,| and|, and) \d+)*)")
STEP = re.compile(r"^## Step (\d+)\b")
ADOPT = re.compile(r"^## Adopt\b")
FENCE = re.compile(r"^\s*(```|~~~)")


class Fail(Exception):
    def __init__(self, code, lines):
        self.code, self.lines = code, lines


def split_units(text):
    """(name, tag, text) per unit, in file order.

    A `## ` line inside a fenced block is example text, not a heading: SKILL.md
    quotes whole headings in fences, and splitting there would invent a step.
    """
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].rstrip() != "---":
        raise Fail(1, ["measure-load: SKILL.md: no frontmatter"])
    end = next((i for i in range(1, len(lines)) if lines[i].rstrip() == "---"), None)
    if end is None:
        raise Fail(1, ["measure-load: SKILL.md: frontmatter never closes"])
    units = [("frontmatter", "always", "".join(lines[: end + 1]))]
    starts, fenced = [], False
    for i in range(end + 1, len(lines)):
        if FENCE.match(lines[i]):
            fenced = not fenced
        elif not fenced and lines[i].startswith("## "):
            starts.append(i)
    first = starts[0] if starts else len(lines)
    units.append(("preamble", "always", "".join(lines[end + 1 : first])))
    for n, s in enumerate(starts):
        e = starts[n + 1] if n + 1 < len(starts) else len(lines)
        head = lines[s].rstrip("\r\n")
        m = STEP.match(head)
        tag = f"Step {m.group(1)}" if m else "adopted runs" if ADOPT.match(head) else "always"
        units.append((head[3:], tag, "".join(lines[s:e])))
    bad = []
    for k in PHASES:
        c = sum(1 for _, t, _ in units if t == f"Step {k}")
        if c != 1:
            bad.append(f'measure-load: SKILL.md: expected one "## Step {k}" heading, found {c}')
    if bad:
        raise Fail(1, bad)
    return units


def reference_tags(skill_text, ref_names):
    """name -> sorted step numbers, or [] for always. Fails on untagged or missing.

    Takes the Further Reading text only: other sections mention references in
    prose, some of which don't exist as files.
    """
    tagged, named = {}, set()
    for line in skill_text.splitlines():
        for name in set(re.findall(r"references/([\w.-]+\.md)", line)):
            named.add(name)
            m = READ_AT.search(line)
            if m:
                tagged[name] = sorted({int(n) for n in re.findall(r"\d+", m.group(1))})
    bad = [f"measure-load: references/{n}: missing" for n in sorted(named - set(ref_names))]
    bad += [f"measure-load: references/{n}: untagged" for n in sorted(set(ref_names) - set(tagged))]
    if bad:
        raise Fail(1, bad)
    # The resume probe runs before the phase is known, so no phase can skip it.
    tagged["resume.md"] = []
    return tagged


def make_counter(mode, model):
    if mode == "bytes":
        return lambda text: len(text.encode("utf-8"))
    base = os.environ.get("ANTHROPIC_BASE_URL") or "https://api.anthropic.com"
    headers = {"content-type": "application/json", "anthropic-version": "2026-10-21"}
    if os.environ.get("ANTHROPIC_API_KEY"):
        headers["x-api-key"] = os.environ["ANTHROPIC_API_KEY"]
    elif os.environ.get("ANTHROPIC_AUTH_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["ANTHROPIC_AUTH_TOKEN"]
        headers["anthropic-beta"] = "oauth-2025-04-20"
    else:
        raise Fail(3, ["measure-load: count_tokens: neither ANTHROPIC_API_KEY nor ANTHROPIC_AUTH_TOKEN is set"])

    def raw(text):
        body = json.dumps({"model": model, "messages": [{"role": "user", "content": text}]}).encode()
        req = urllib.request.Request(base + "/v1/messages/count_tokens", body, headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                n = json.load(r).get("input_tokens")
        except (urllib.error.URLError, OSError, ValueError) as e:
            raise Fail(3, [f"measure-load: count_tokens: {e}"])
        if not isinstance(n, int) or isinstance(n, bool):
            raise Fail(3, ["measure-load: count_tokens: response has no integer input_tokens"])
        return n

    # Subtracting the bare wrapper strips the request framing; a unit can read
    # one token low where the text merges with it.
    wrapper = raw(".")
    return lambda text: raw(text) - wrapper


def run(skill_dir, mode, model):
    sd = Path(skill_dir)
    try:
        skill_text = (sd / "SKILL.md").read_text(encoding="utf-8")
        refs = {p.name: p.read_text(encoding="utf-8") for p in sorted((sd / "references").glob("*.md"))}
    except (OSError, UnicodeDecodeError) as e:
        raise Fail(3, [f"measure-load: {e}"])
    units = split_units(skill_text)
    tags = reference_tags(next(t for n, _, t in units if n.startswith("Further Reading")), list(refs))
    count = make_counter(mode, model)
    sizes = [count(t) for _, _, t in units]
    rsize = {n: count(t) for n, t in refs.items()}

    def label(n):
        s = tags[n]
        return "always" if not s else ("Step " if len(s) == 1 else "Steps ") + ", ".join(map(str, s))

    col = "Bytes" if mode == "bytes" else "Tokens"
    what = "bytes" if mode == "bytes" else f"tokens (model {model})"
    out = [f"measure-load: {what} over {skill_dir}", f"| Unit | Read at | {col} |", "|---|---|---|"]
    always_total = 0
    for (name, tag, _), n in zip(units, sizes):
        out.append(f"| SKILL.md: {name} | {tag} | {n} |")
        if tag == "always":
            always_total += n
    for n in sorted(refs):
        out.append(f"| references/{n} | {label(n)} | {rsize[n]} |")
        if not tags[n]:
            always_total += rsize[n]
    out += [f"| always-loaded total | always | {always_total} |", "",
            "| Phase | Today | Only its step | Not needed |", "|---|---|---|---|"]
    resume = rsize["resume.md"]
    saves = []
    for k in PHASES:
        step_refs = sum(rsize[n] for n in refs if k in tags[n])
        today = sum(sizes) + resume + step_refs
        only = sum(n for (_, t, _), n in zip(units, sizes) if t in ("always", f"Step {k}")) + resume + step_refs
        saves.append(today - only)
        out.append(f"| {k} | {today} | {only} | {100 * (today - only) / today:.1f}% |")
    out += ["", f"median saving (phases 0-8): {statistics.median(saves)}"]
    return out


class Parser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write(f"measure-load: usage: {message}\n")
        sys.exit(3)


def main():
    p = Parser(description=__doc__.splitlines()[0])
    p.add_argument("--skill-dir", default="work-issue")
    p.add_argument("--count", choices=["bytes", "tokens"], default="bytes")
    p.add_argument("--model", default="claude-opus-5-5")
    a = p.parse_args()
    try:
        print("\n".join(run(a.skill_dir, a.count, a.model)))
    except Fail as f:
        print("\n".join(f.lines), file=sys.stderr)
        return f.code
    return 0


if __name__ == "__main__":
    sys.exit(main())
