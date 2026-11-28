#!/usr/bin/env python3
"""Resolve a Johnny.Decimal vault root without reading anything inside it.

Every other script in jd-file and jd-audit learns its rules from the
conventions note (`00.02 Vault Conventions.md`) -- but that note names the
substrate roots, and the note itself lives inside the vault. Something has
to find the vault before any of that can be read, which means this one
script is not allowed to lean on the conventions block at all. It walks a
short, hardcoded ladder instead: an explicit env var, then Obsidian's own
vault registry, then a couple of well-known parent folders. See GitHub
issue #55 in this repo for the fuller writeup of why the loop exists.

Every rung is gated on `verify()`, never on existence alone. A directory that
merely exists proves nothing about what it holds. Only
a rung whose candidate actually contains the conventions note counts as a
hit; anything else falls through to the next rung with a note explaining
the miss.

This file is duplicated byte-for-byte into jd-file/scripts/ and
jd-audit/scripts/. Skills install standalone (`npx skills add ... --skill
jd-file` pulls only that skill's directory), so each skill needs its own
copy on disk rather than a shared import outside either tree. Edit one
copy and re-copy it verbatim over the other -- tests/jd-file-resolve-smoke.sh
runs `cmp` on the two files and fails the suite if they drift apart.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path

DEFAULT_CONVENTIONS_RELATIVE = "00-09 Admin & Meta/00 System/00.02 Vault Conventions.md"
CONVENTIONS_GLOB = "00-09 Admin & Meta/00 System/*Vault Conventions.md"
OBSIDIAN_JSON = "~/Library/Application Support/obsidian/obsidian.json"
PROBE_GLOBS = (
    "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/*",
    "~/Documents/*",
)
EXIT_OK, EXIT_AMBIGUOUS, EXIT_NONE = 0, 3, 4


def expand(p: str) -> Path:
    return Path(os.path.expanduser(p))


# --------------------------------------------------------------------------
# Verification
# --------------------------------------------------------------------------

def verify(root: Path) -> Path | None:
    """Confirm a candidate root by finding the conventions note beneath it.

    Exact path first, since that's the documented location and the common
    case shouldn't pay for a glob. The glob fallback exists only because
    real vaults drift on the note's own numbering -- this repo's own test
    fixtures use 00.03 instead of 00.02 -- so a second-choice lookup has to
    exist somewhere. Two or more glob hits means the candidate is not
    actually verified: this script has no basis for guessing which note is
    the real one, so that counts as a miss rather than a pick. Returning
    the matched path (not a bool) lets the caller load the exact note that
    did the verifying, instead of re-deriving it from a constant that may
    not be the one that matched.
    """
    exact = root / DEFAULT_CONVENTIONS_RELATIVE
    if exact.is_file():
        return exact
    matches = [p for p in sorted(root.glob(CONVENTIONS_GLOB)) if p.is_file()]
    if len(matches) == 1:
        return matches[0]
    return None


def _verify_all(roots: list[Path]) -> list[tuple[Path, Path]]:
    """Verify a batch of candidates and dedupe the survivors by real path.

    iCloud sync and bind mounts routinely put the same vault under two
    different-looking paths (a symlink plus its target, say). Deduping on
    os.path.realpath keeps that from reading as a false ambiguous hit --
    ambiguity should mean "two different vaults," not "one vault, counted
    twice."
    """
    out: list[tuple[Path, Path]] = []
    seen_real: set[str] = set()
    for root in roots:
        conventions = verify(root)
        if conventions is None:
            continue
        real = os.path.realpath(root)
        if real in seen_real:
            continue
        seen_real.add(real)
        out.append((root, conventions))
    return out


# --------------------------------------------------------------------------
# Resolution
# --------------------------------------------------------------------------

@dataclass
class Resolution:
    vault: Path | None
    conventions: Path | None
    rung: str | None
    rungs_tried: list[str]
    candidates: list[Path]
    notes: list[str]


def resolve(environ=None) -> Resolution:
    """Walk the ladder and stop at the first rung that verifies cleanly.

    The stop is a hard short-circuit: a later rung is never even consulted
    once an earlier one wins, and a rung that turns up two or more verified
    candidates stops the whole run right there rather than falling through
    to see if a later rung disagrees. Silently preferring one match over
    another -- by recency, by an "open": true flag, by sort order -- is
    exactly the kind of guess this script exists to avoid; that judgment
    call belongs to the human who knows which vault they meant.
    """
    if environ is None:
        environ = os.environ

    rungs_tried: list[str] = []
    notes: list[str] = []

    # --- $JD_VAULT ------------------------------------------------------
    rungs_tried.append("$JD_VAULT")
    raw = environ.get("JD_VAULT", "")
    if raw:
        candidate = expand(raw)
        conventions = verify(candidate)
        if conventions is not None:
            return Resolution(candidate, conventions, "$JD_VAULT", rungs_tried, [], notes)
        notes.append(
            f"$JD_VAULT is set to '{raw}' but no conventions note verifies beneath it"
        )
    else:
        notes.append("$JD_VAULT is not set")

    # --- obsidian.json ----------------------------------------------------
    rungs_tried.append("obsidian.json")
    obsidian_path = expand(OBSIDIAN_JSON)
    verified: list[tuple[Path, Path]] = []
    try:
        data = json.loads(obsidian_path.read_text(encoding="utf-8"))
        raw_vaults = data.get("vaults", {}) if isinstance(data, dict) else {}
        candidates = [
            expand(entry["path"])
            for entry in raw_vaults.values()
            if isinstance(entry, dict) and entry.get("path")
        ]
        verified = _verify_all(candidates)
    except (OSError, json.JSONDecodeError) as e:
        # Missing file is the common case (Obsidian never installed, or
        # installed but never opened a vault) and not itself an error --
        # it just means this rung has nothing to offer and falls through.
        notes.append(f"obsidian.json at '{obsidian_path}' could not be read: {e}")
    else:
        if not verified:
            notes.append(f"obsidian.json at '{obsidian_path}' lists no vault that verifies")

    if len(verified) == 1:
        root, conventions = verified[0]
        return Resolution(root, conventions, "obsidian.json", rungs_tried, [], notes)
    if len(verified) >= 2:
        notes.append(
            "obsidian.json lists more than one verified vault -- ask the user which one is meant"
        )
        return Resolution(None, None, None, rungs_tried, [r for r, _ in verified], notes)

    # --- probes -------------------------------------------------------
    rungs_tried.append("probes")
    probe_roots: list[Path] = []
    for pattern in PROBE_GLOBS:
        for hit in glob.glob(os.path.expanduser(pattern)):
            hit_path = Path(hit)
            if hit_path.is_dir():
                probe_roots.append(hit_path)
    verified = _verify_all(probe_roots)
    if len(verified) == 1:
        root, conventions = verified[0]
        return Resolution(root, conventions, "probes", rungs_tried, [], notes)
    if len(verified) >= 2:
        notes.append(
            "more than one probed folder verifies as a vault -- ask the user which one is meant"
        )
        return Resolution(None, None, None, rungs_tried, [r for r, _ in verified], notes)
    notes.append("no probed folder (iCloud Obsidian documents, ~/Documents) verifies as a vault")

    return Resolution(None, None, None, rungs_tried, [], notes)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def parse_args(argv):
    p = argparse.ArgumentParser(prog="resolve_vault.py")
    p.add_argument("--json", action="store_true")
    return p.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv)
    result = resolve()

    if result.vault is not None:
        if args.json:
            print(json.dumps({
                "vault": str(result.vault),
                "conventions": str(result.conventions),
                "rung": result.rung,
            }, indent=2))
        else:
            # Bare path only, so callers can do VAULT="$(resolve_vault.py)".
            print(result.vault)
        return EXIT_OK

    if result.candidates:
        if args.json:
            print(json.dumps({
                "error": "ambiguous",
                "rungs_tried": result.rungs_tried,
                "notes": result.notes,
                "candidates": [str(c) for c in result.candidates],
            }, indent=2))
        else:
            for c in result.candidates:
                print(c, file=sys.stderr)
            print("multiple vaults verify -- ask the user which one is meant instead of guessing",
                  file=sys.stderr)
        return EXIT_AMBIGUOUS

    if args.json:
        print(json.dumps({
            "error": "none",
            "rungs_tried": result.rungs_tried,
            "notes": result.notes,
            "candidates": [],
        }, indent=2))
    else:
        for note in result.notes:
            print(note, file=sys.stderr)
        print("no vault found -- ask the user where it is, or set $JD_VAULT", file=sys.stderr)
    return EXIT_NONE


if __name__ == "__main__":
    sys.exit(main())
