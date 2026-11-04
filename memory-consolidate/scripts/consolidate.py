#!/usr/bin/env python3
"""Turn `ltm doctor --json` findings into a consolidation report a scope can drain.

Writes <scope>/notes/reports/YYYY-MM-DD-consolidation.md and nothing else. The date comes from LTM_TODAY where set, else today, so a pinned date makes a second run rewrite identical bytes.

Every finding becomes a line the same way, whatever its `check`. The script deliberately keeps no list of known check names, so a check the kit adds later comes through as a candidate line with no change here.

Exit codes: 0 report written; 1 `ltm doctor` failed or couldn't run, or its output isn't a JSON array of {file, check} objects, with stderr quoting the cause, or the same-day report already holds a line Phase 5 resolved (an approved rewrite or a dismissed update-existing candidate), or can't be read to check, and `--force` is absent, with stderr starting `consolidate: refusing to overwrite` and the report untouched; 2 argparse usage error; 3 unreadable scope, unreadable `--json` file, or an LTM_TODAY not exactly YYYY-MM-DD.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

NANOID_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"


def report_date() -> str:
    raw = os.environ.get("LTM_TODAY")
    if not raw:
        return datetime.date.today().isoformat()
    # fromisoformat also takes 20261001 and 2026-W40-4, which would land verbatim in the filename; the round trip admits only YYYY-MM-DD.
    if datetime.date.fromisoformat(raw).isoformat() != raw:
        raise ValueError(raw)
    return raw


def run_doctor(scope: Path) -> str:
    try:
        proc = subprocess.run(
            ["ltm", "doctor", "--bank", str(scope), "--json"],
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        raise RuntimeError(f"could not run ltm: {exc}") from exc
    if proc.returncode != 0:
        raise RuntimeError(f"ltm doctor exited {proc.returncode}: {proc.stderr.strip() or proc.stdout.strip()}")
    return proc.stdout


def parse_findings(text: str) -> list[dict]:
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"doctor JSON didn't parse: {exc}: {text[:200]!r}") from exc
    if not isinstance(data, list) or not all(
        isinstance(f, dict) and isinstance(f.get("file"), str) and isinstance(f.get("check"), str)
        for f in data
    ):
        raise RuntimeError(f"doctor JSON isn't an array of {{file, check, ...}} objects: {text[:200]!r}")
    return data


def record_title(scope: Path, rel: str) -> str:
    path = scope / rel
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        lines = []
    if lines[:1] == ["---"]:
        for line in lines[1:]:
            if line == "---":
                break
            if line.startswith("title:"):
                title = line[len("title:"):].strip()
                if len(title) >= 2 and title[0] == title[-1] and title[0] in "'\"":
                    title = title[1:-1]
                if title:
                    return title
    return path.stem


def finding_line(scope: Path, f: dict) -> str:
    stem = Path(f["file"]).stem
    line = (
        f"[memory candidate: update existing [[{stem}|{record_title(scope, f['file'])}]]] "
        f"{f['check']}: {' '.join(str(f.get('message', '')).split())}"
    )
    related = f.get("related_files") or []
    if related:
        line += " related: " + ", ".join(f"[[{Path(r).stem}]]" for r in related)
    return line


def report_id(date: str) -> str:
    # Hashed from the date, not drawn from `nanoid -s 10` like inbox-to-memory's notes, so a same-day rerun writes the same bytes.
    digest = hashlib.sha256(f"memory-consolidate:{date}".encode()).digest()
    return "".join(NANOID_ALPHABET[b % 64] for b in digest[:10])


def render(scope: Path, date: str, findings: list[dict]) -> str:
    # Notes' fixed key order (machine-contracts.md); the three question counts are written even at 0, as that file requires.
    out = [
        "---",
        "schema: 2",
        f"id: {report_id(date)}",
        f"date: {date}",
        "type: report",
        "open_questions: 0",
        "resolved_questions: 0",
        "deferred_tensions: 0",
        f"unpromoted_candidates: {len(findings)}",
        "---",
        "",
        f"# Memory Consolidation {date}",
        "",
    ]
    out += [finding_line(scope, f) for f in findings] or ["No findings."]
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--scope", required=True, help="scope root holding memory-bank.yaml and _memory/")
    ap.add_argument("--json", dest="json_file", help="saved `ltm doctor --json` output to read instead of running ltm")
    ap.add_argument("--force", action="store_true", help="overwrite a same-day report even when Phase 5 has resolved some of its lines")
    args = ap.parse_args()

    scope = Path(args.scope)
    if not scope.is_dir():
        print(f"consolidate: scope is not a readable directory: {scope}", file=sys.stderr)
        return 3
    try:
        date = report_date()
    except ValueError:
        print(f"consolidate: LTM_TODAY is not YYYY-MM-DD: {os.environ.get('LTM_TODAY')!r}", file=sys.stderr)
        return 3

    out = scope / "notes" / "reports" / f"{date}-consolidation.md"
    # Runs before doctor, so a refusal costs no ltm call and never depends on doctor succeeding. An open candidate holds `[[` mid-line too, which is why the approved test checks the prefix.
    if out.exists() and not args.force:
        try:
            resolved = sum(
                1
                for ln in out.read_text(encoding="utf-8").splitlines()
                if ln.startswith("[[") or (ln.startswith("[memory candidate: update existing") and "| dismissed:" in ln)
            )
        except (OSError, UnicodeDecodeError):
            print(f"consolidate: refusing to overwrite {out}: can't read it to check for resolved lines; rerun with --force to replace it", file=sys.stderr)
            return 1
        if resolved:
            print(f"consolidate: refusing to overwrite {out}: it holds {resolved} line(s) Phase 5 resolved; rerun with --force to replace it", file=sys.stderr)
            return 1

    try:
        if args.json_file:
            try:
                text = Path(args.json_file).read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError) as exc:
                print(f"consolidate: cannot read --json file: {exc}", file=sys.stderr)
                return 3
        else:
            text = run_doctor(scope)
        findings = parse_findings(text)
    except RuntimeError as exc:
        print(f"consolidate: {exc}", file=sys.stderr)
        return 1

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render(scope, date, findings), encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
