#!/usr/bin/env python3
"""Check that every vault note this repo's prose names still exists.

Renumbering two system notes once left seventeen references across the jd
skills pointing at files that had ceased to exist, and nothing caught it:
`validate.py` audits the vault rather than the repo, and the smoke tests pin
the decisions the prose reaches rather than the facts it asserts along the
way. This closes the narrow half of that gap.

Narrow on purpose. The only claim checked is a backticked `AC.ID Label.md`,
which names one numbered note and resolves against the register with no
judgment involved. Bare IDs and labels without the suffix are left
alone, because the findings catalog quotes them as illustrations that are
wrong deliberately. `11.03 Cobalt` against `11.03 Cobalt Freight` is the
whole point of a name-mismatch example, and a check that flagged it would
train its reader to ignore it.

The register is the only thing consulted. Whether the register agrees with
the folders is `validate.py`'s `drift-orphaned`, which owns that comparison
and reports it better. So this is a partial answer to "does the prose still
describe the vault", and the many claims a skill makes that no register can
confirm stay the reader's job.
"""

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "jd-audit" / "scripts"))

import validate as v  # noqa: E402  (path setup has to land first)

# Prose that describes the real vault. `tests/` is out because its fixtures
# are invented vaults by design, and every ID in them is meant to be fictional.
PROSE_ROOTS = [
    "jd-file",
    "jd-audit",
    "_maintenance/jd",
    "_maintenance/jd-file",
    "_maintenance/jd-audit",
    "README.md",
]

# A backticked note reference, with or without a leading path:
#   `00.01 JDex.md`
#   `<VAULT_ROOT>/00-09 Admin & Meta/00 System/00.02 Vault Conventions.md`
REFERENCE = re.compile(r"`(?:[^`]*/)?(\d\d\.\d\d) ([^`/]+?)\.md`")

# A row of the register's retired-numbers table. Of the ways a reference goes
# stale, retirement is the one a reader most needs spelled out: the number
# resolves to nothing, and the old label may still be sitting in a live entry
# under a different number.
RETIRED_ROW = re.compile(r"^\|\s*(\d\d\.\d\d)\s*\|\s*([^|]+?)\s*\|")


def load_register(conventions: dict, vault_root: Path):
    """Returns (live entries by ID, retired IDs to what they held)."""
    entry_pattern = re.compile(conventions["register"]["entry"])
    path = vault_root / conventions["register"]["path"]
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as e:
        raise v.FatalError(f"cannot read the register at '{path}': {e}")

    live, retired = {}, {}
    for line in lines:
        m = entry_pattern.match(line)
        if m:
            live[m.group("id")] = m.group("label")
            continue
        m = RETIRED_ROW.match(line)
        if m and m.group(1) not in live:
            retired[m.group(1)] = m.group(2)
    return live, retired


def collect_references(repo: Path):
    for root in PROSE_ROOTS:
        target = repo / root
        files = [target] if target.is_file() else sorted(target.rglob("*.md"))
        for f in files:
            for i, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
                for m in REFERENCE.finditer(line):
                    yield f.relative_to(repo), i, m.group(1), m.group(2)


def main(argv=None) -> int:
    p = argparse.ArgumentParser(
        prog="check-prose-refs.py",
        description="Confirm every `AC.ID Label.md` in jd prose still resolves.")
    p.add_argument("--vault", type=Path, default=None)
    p.add_argument("--host", type=str, default=None)
    p.add_argument("--repo", type=Path, default=REPO)
    args = p.parse_args(argv)

    try:
        cli_vault = v.expand(str(args.vault)).resolve() if args.vault else None
        if cli_vault is not None:
            conventions_path = cli_vault / v.DEFAULT_CONVENTIONS_RELATIVE
        else:
            from resolve_vault import resolve as resolve_vault
            res = resolve_vault()
            if res.conventions is None:
                raise v.FatalError(
                    "no vault root resolvable and --vault was not given, so "
                    "there is nothing to check the prose against.")
            conventions_path = res.conventions

        data = v.load_conventions(conventions_path)
        roots, _, _ = v.resolve_all_roots(data, cli_vault, args.host)
        vault_root = roots["vault"]["canonical"]
        live, retired = load_register(data, vault_root)
    except v.FatalError as e:
        print(f"FATAL: {e}", file=sys.stderr)
        return 2

    checked = stale = 0
    for path, line, ac_id, label in collect_references(args.repo):
        checked += 1
        where = f"{path}:{line}"
        if ac_id in retired:
            stale += 1
            print(f"STALE {where}: `{ac_id} {label}` names a retired number "
                  f"(it held {retired[ac_id]!r}).")
        elif ac_id not in live:
            stale += 1
            print(f"STALE {where}: `{ac_id} {label}` names an ID the register "
                  f"does not carry.")
        elif live[ac_id] != label:
            stale += 1
            print(f"STALE {where}: `{ac_id} {label}` disagrees with the "
                  f"register, which calls {ac_id} {live[ac_id]!r}.")

    if stale:
        print(f"\n{stale} stale reference(s) across {checked} checked.")
        return 1
    print(f"{checked} note reference(s) checked, all resolving.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
