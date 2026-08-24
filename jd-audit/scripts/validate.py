#!/usr/bin/env python3
"""Deterministic validator for a Johnny.Decimal vault.

Every pattern and rule this script applies comes from the conventions note's
TOML block (`00.02 Vault Conventions.md`), never from a literal baked into
this file. The point of that split is that prose and script cannot drift
apart if the script never carries its own copy of a rule the prose also
states. Where this file *does* make a judgment call the conventions block
has no key for, it is called out in a comment at the point the call is made.

Three substrates hold the actual content (vault, office, code), joined by a
shared JD folder name. A fourth artifact, the register (00.01 JDex.md), is
the aspirational record of what each ID is *for* and which substrates
should hold it; drift checks compare that record against what the
substrates actually contain. The register may not exist yet on a vault
mid-rollout, so its absence is treated as a reportable gap, not a crash --
every check that does not need it still runs.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import socket
import sys
import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import unquote

SUPPORTED_SCHEMA_VERSIONS = {1}

# The four numbered tiers, outermost first. "deeper" is the fourth tier
# (AC.ID.NN) -- present in the grammar purely so it can be *detected*, since
# this dialect forbids it everywhere except as a thing to report.
TIER_ORDER = ("area", "category", "id", "deeper")

SEVERITY_RANK = {"error": 0, "warn": 1, "info": 2}

DEFAULT_CONVENTIONS_RELATIVE = "00-09 Admin & Meta/00 System/00.02 Vault Conventions.md"

ALL_CHECK_IDS = [
    "register-grammar",
    "register-duplicate-id",
    "register-bad-placement",
    "structure-numbering",
    "structure-deep-numbering",
    "structure-stray-number",
    "drift-undocumented",
    "drift-orphaned",
    "drift-name-mismatch",
    "drift-split-name",
    "triangle-constitution-folders",
    "triangle-register-constitution",
    "moc-stale",
    "hygiene-area-file",
    "hygiene-category-file",
    "hygiene-empty",
    "link-broken",
    "link-unverifiable",
]

REGISTER_DEPENDENT_CHECKS = {
    "register-grammar",
    "register-duplicate-id",
    "register-bad-placement",
    "drift-undocumented",
    "drift-orphaned",
    "drift-name-mismatch",
    "drift-split-name",
    "triangle-register-constitution",
}

CONSTITUTION_DEPENDENT_CHECKS = {
    "triangle-constitution-folders",
    "triangle-register-constitution",
}


class FatalError(Exception):
    """A condition the spec requires to stop the run (exit 2), not report and continue."""


@dataclass
class Finding:
    check: str
    severity: str
    message: str
    path: str | None = None
    id: str | None = None
    detail: str | None = None
    # AC.IDs this finding is "about", for the register's #conflict downgrade
    # and for exception matching that needs more than one ID (drift-split-name).
    # Not exported -- the public `id` field is the human-readable summary.
    ids: list[str] = field(default_factory=list, repr=False)
    suppressed_reason: str | None = field(default=None, repr=False)
    original_severity: str | None = field(default=None, repr=False)

    def to_dict(self) -> dict:
        d = {
            "check": self.check,
            "severity": self.severity,
            "message": self.message,
            "path": self.path,
            "id": self.id,
        }
        if self.detail:
            d["detail"] = self.detail
        if self.original_severity:
            d["downgraded_from"] = self.original_severity
        return d


def norm_ws(s: str) -> str:
    return " ".join(s.split())


def normalize_label(s: str) -> str:
    return norm_ws(s).casefold()


def id_label(raw_label: str, is_file: bool) -> str:
    """The [grammar].id pattern is written for folder names and has no
    concept of a file extension. It still has to match this dialect's one
    documented file-typed ID (00.00 Johnny Decimal Index.md), which means
    the captured label carries a trailing ".md" the register's own label
    never will. Stripping it only when the entry is actually a file keeps
    this narrow rather than quietly eating ".md" out of every label.
    """
    label = raw_label.strip()
    if is_file and label.lower().endswith(".md"):
        label = label[:-3].rstrip()
    return label


def expand(p: str) -> Path:
    return Path(os.path.expanduser(p))


# --------------------------------------------------------------------------
# Conventions loading
# --------------------------------------------------------------------------

def load_conventions(path: Path) -> dict:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        raise FatalError(f"cannot read conventions note at '{path}': {e}")

    m = re.search(r"```toml\n(.*?)```", text, re.DOTALL)
    if not m:
        raise FatalError(f"no fenced ```toml block found in conventions note '{path}'")

    try:
        data = tomllib.loads(m.group(1))
    except tomllib.TOMLDecodeError as e:
        raise FatalError(f"conventions TOML block in '{path}' does not parse: {e}")

    version = data.get("schema_version")
    if version not in SUPPORTED_SCHEMA_VERSIONS:
        supported = ", ".join(str(v) for v in sorted(SUPPORTED_SCHEMA_VERSIONS))
        raise FatalError(
            f"conventions note declares schema_version={version!r}; this validator "
            f"understands {{{supported}}}. Refusing to guess at an unrecognized shape -- "
            f"update the validator or the conventions note so they agree."
        )
    return data


def compile_patterns(data: dict) -> dict:
    """Compile every regex the conventions block declares, once, up front.

    Compiling here (rather than inline at each use) is what makes "never
    hardcode a pattern the block already has" actually true in practice --
    every check below reaches into this dict instead of writing a pattern.
    """
    try:
        grammar = {tier: re.compile(data["grammar"][tier]) for tier in TIER_ORDER}
        register = {
            "area_heading": re.compile(data["register"]["area_heading"]),
            "category_heading": re.compile(data["register"]["category_heading"]),
            "entry": re.compile(data["register"]["entry"]),
            "attempt": re.compile(r"^- `"),
        }
        constitution = {
            "area_heading": re.compile(data["constitution"]["area_heading"]),
            "category_line": re.compile(data["constitution"]["category_line"]),
        }
        links_pattern = re.compile(data["links"]["pattern"])
    except re.error as e:
        raise FatalError(f"a regex in the conventions block does not compile: {e}")
    except KeyError as e:
        raise FatalError(f"conventions block is missing expected key: {e}")
    return {
        "grammar": grammar,
        "register": register,
        "constitution": constitution,
        "links_pattern": links_pattern,
    }


# --------------------------------------------------------------------------
# Root resolution
# --------------------------------------------------------------------------

def resolve_hostname(cli_host: str | None) -> str:
    return cli_host or socket.gethostname()


def resolve_all_roots(data: dict, cli_vault: Path | None, cli_host: str | None):
    """Resolve a filesystem root for every declared substrate.

    Vault resolution failure is fatal (the spec names it explicitly in the
    exit-code table). A non-vault substrate that can't be resolved is not:
    the tool degrades to skipping that substrate's checks rather than
    refusing to look at the other two, which matters because an unmounted
    cloud-synced folder shouldn't take down a report about the vault.
    """
    hosts = data.get("hosts", {})
    discovery = data.get("discovery", {})
    substrates = data.get("substrate", [])
    hostname = resolve_hostname(cli_host)

    matched_host = hostname if hostname in hosts else None

    # If the raw hostname didn't match a [hosts.*] key but an explicit
    # --vault does match one of a host's declared vault roots, that host is
    # still the right one for resolving the *other* substrates and for
    # deciding "is this link on my host" during the link scan.
    if matched_host is None and cli_vault is not None:
        target = os.path.normpath(str(cli_vault))
        for hk, hentry in hosts.items():
            candidates = [os.path.normpath(str(expand(p))) for p in hentry.get("vault", [])]
            if target in candidates:
                matched_host = hk
                break

    roots: dict[str, dict | None] = {}
    notices: list[str] = []

    for sub in substrates:
        sid = sub["id"]
        if sid == "vault" and cli_vault is not None:
            roots[sid] = {"canonical": cli_vault, "aliases": []}
            continue

        if matched_host is not None:
            candidates = hosts[matched_host].get(sid)
            if candidates:
                resolved = [expand(p) for p in candidates]
                roots[sid] = {"canonical": resolved[0], "aliases": resolved[1:]}
                continue

        cands = discovery.get(sid, [])
        resolved = [expand(p) for p in cands]
        hits = [p for p in resolved if p.is_dir()]
        if len(hits) == 1:
            roots[sid] = {"canonical": hits[0], "aliases": []}
        elif sid == "vault":
            raise FatalError(
                f"cannot resolve vault root: hostname '{hostname}' has no [hosts.*] entry "
                f"and {len(hits)} of the [discovery].vault candidates exist "
                f"(need exactly 1): {[str(p) for p in resolved]}. Pass --vault explicitly."
            )
        else:
            notices.append(
                f"substrate '{sid}' root could not be resolved (hostname '{hostname}' has no "
                f"[hosts.*] entry and {len(hits)} of its [discovery] candidates exist, need "
                f"exactly 1) -- its structure, hygiene, and drift checks are skipped"
            )
            roots[sid] = None

    return roots, matched_host, notices


def scope_covers(acid: str, scope: list[str]) -> bool:
    if "*" in scope:
        return True
    cat = acid.split(".", 1)[0]
    for token in scope:
        if "-" in token:
            lo, hi = token.split("-", 1)
            if lo <= cat <= hi:
                return True
        elif cat == token:
            return True
    return False


# --------------------------------------------------------------------------
# Structure walk
# --------------------------------------------------------------------------

class WalkContext:
    def __init__(self, substrate_id: str, root: Path, ignore_names: set[str],
                 tiers: dict, active, findings: list[Finding],
                 scaffold_names: set[str] | None = None):
        self.substrate_id = substrate_id
        self.root = root
        self.ignore_names = ignore_names
        # Scaffolded files (e.g. the Overview.md jd-file drops into every new
        # ID) don't count as payload for hygiene-empty -- an ID holding only
        # its own scaffold is still a reservation. Deliberately not folded
        # into ignore_names, which would prune these files from every walk
        # and hide their wiki-links from link-broken. walk_id_interior
        # consults this set at exactly one place, the payload check.
        self.scaffold_names = scaffold_names or set()
        self.tiers = tiers
        self.active = active
        self.findings = findings
        # acid -> {"label": str, "disp": str}
        self.actual_ids: dict[str, dict] = {}
        # cat -> {"label": str, "disp": str}  (only meaningfully populated for
        # the vault substrate, which is the only one with full category
        # coverage -- office and code are scoped to a slice of the system.)
        self.actual_categories: dict[str, dict] = {}

    def disp(self, p: Path) -> str:
        try:
            rel = str(p.relative_to(self.root))
        except ValueError:
            rel = str(p)
        return rel if self.substrate_id == "vault" else f"{self.substrate_id}:{rel}"

    def add(self, check: str, severity: str, message: str, path: str | None = None,
            acid: str | None = None, detail: str | None = None):
        if not self.active(check):
            return
        ids = [acid] if acid else []
        self.findings.append(Finding(check, severity, message, path=path, id=acid,
                                      detail=detail, ids=ids))


def other_tiers(own: str):
    return [t for t in TIER_ORDER if t != own]


def check_tier_entry(name: str, own_tier: str, path_disp: str, ctx: WalkContext):
    """Match `name` against its expected tier pattern.

    Returns the match on success. On failure, tells the difference between
    "this is a well-formed name for a *different* tier, just misplaced"
    (structure-stray-number -- the more actionable diagnosis) and "this
    isn't a JD-numbered name at all" (structure-numbering).
    """
    m = ctx.tiers[own_tier].match(name)
    if m:
        return m
    for other in other_tiers(own_tier):
        if ctx.tiers[other].match(name):
            ctx.add("structure-stray-number", "error",
                    f"'{name}' is a valid {other} name but sits at the {own_tier} level",
                    path=path_disp)
            return None
    ctx.add("structure-numbering", "error",
            f"'{name}' does not match the {own_tier} grammar", path=path_disp)
    return None


def scandir_pruned(path: Path, ignore_names: set[str]):
    try:
        with os.scandir(path) as it:
            return [e for e in it if e.name not in ignore_names]
    except OSError:
        return []


def subtree_has_file(start_dirs: list[str], ignore_names: set[str]) -> bool:
    """DFS with a stack, stopping at the first real file anywhere below.

    Client scopes run ten directories deep with their own git repos --
    walking the whole thing just to answer "is this ID empty" would be
    wasteful. In practice the first file (a README, a lockfile, anything)
    is found within the first couple of directories, so this short-circuits
    almost immediately rather than actually touching thousands of files.

    Unlike the tier-level directory checks elsewhere in this file, this
    descent does not follow symlinks: a repo with a symlink pointing back
    up at one of its own ancestors would otherwise turn "is this empty"
    into an infinite loop.
    """
    stack = list(start_dirs)
    while stack:
        d = stack.pop()
        try:
            with os.scandir(d) as it:
                for e in it:
                    if e.name in ignore_names:
                        continue
                    if e.is_dir(follow_symlinks=False):
                        stack.append(e.path)
                    else:
                        return True
        except OSError:
            continue
    return False


def walk_id_interior(id_path: Path, acid: str, ctx: WalkContext, numbered_depth_below_id: bool):
    direct = scandir_pruned(id_path, ctx.ignore_names)
    has_payload = False
    subdirs: list[str] = []

    for entry in direct:
        name = entry.name
        disp = ctx.disp(Path(entry.path))
        m_deep = ctx.tiers["deeper"].match(name)
        if m_deep:
            if numbered_depth_below_id:
                # The rule that forbids this is itself data
                # ([rules].numbered_depth_below_id); if a future dialect
                # flips it, this check should stop firing without a code
                # change.
                pass
            else:
                ctx.add("structure-deep-numbering", "error",
                        f"'{name}' introduces a fourth numbered tier under ID '{acid}'",
                        path=disp, acid=acid)
        else:
            for other in ("area", "category", "id"):
                if ctx.tiers[other].match(name):
                    ctx.add("structure-stray-number", "error",
                            f"'{name}' matches the {other} pattern but sits directly "
                            f"inside ID '{acid}'", path=disp, acid=acid)
                    break
            # Anything else here is ordinary unnumbered nesting below an ID
            # -- normal and deliberately deep in this system. Silent.
        if entry.is_dir(follow_symlinks=False):
            subdirs.append(entry.path)
        elif name not in ctx.scaffold_names:
            has_payload = True

    if not has_payload:
        has_payload = subtree_has_file(subdirs, ctx.ignore_names)

    if not has_payload:
        ctx.add("hygiene-empty", "info", f"ID '{acid}' holds no payload files",
                path=ctx.disp(id_path), acid=acid)


def walk_category(cat_path: Path, cat_num: str, ctx: WalkContext,
                   numbered_depth_below_id: bool):
    children = scandir_pruned(cat_path, ctx.ignore_names)
    if not children:
        ctx.add("hygiene-empty", "info",
                f"category '{cat_path.name}' holds no IDs and no files",
                path=ctx.disp(cat_path))
        return

    for entry in children:
        p = Path(entry.path)
        disp = ctx.disp(p)
        m_id = ctx.tiers["id"].match(entry.name)
        if m_id:
            # ID grammar can match a *file*, not just a folder: 00.00 is the
            # one documented exception (IDs are folders; the constitution
            # note is the one file that carries an ID directly). Treat any
            # id-shaped name here as a valid ID slot regardless of type,
            # rather than special-casing 00.00 by name.
            id_cat, id_item = m_id.group("cat"), m_id.group("item")
            acid = f"{id_cat}.{id_item}"
            is_dir = entry.is_dir()
            if id_cat != cat_num:
                ctx.add("structure-numbering", "error",
                        f"ID '{entry.name}' category prefix '{id_cat}' does not match "
                        f"its parent category '{cat_num}'", path=disp, acid=acid)
            ctx.actual_ids[acid] = {"label": id_label(m_id.group("label"), not is_dir), "disp": disp}
            if is_dir:
                walk_id_interior(p, acid, ctx, numbered_depth_below_id)
            continue

        if not entry.is_dir():
            ctx.add("hygiene-category-file", "warn",
                    f"'{entry.name}' is a file directly inside category '{cat_path.name}'",
                    path=disp)
            continue

        for other in ("area", "category", "deeper"):
            if ctx.tiers[other].match(entry.name):
                ctx.add("structure-stray-number", "error",
                        f"'{entry.name}' is a valid {other} name but sits at the ID level "
                        f"inside category '{cat_path.name}'", path=disp)
                break
        else:
            ctx.add("structure-numbering", "error",
                    f"'{entry.name}' does not match the id grammar", path=disp)


def walk_area(area_path: Path, a_lo: str, a_hi: str, ctx: WalkContext,
              numbered_depth_below_id: bool):
    for entry in scandir_pruned(area_path, ctx.ignore_names):
        p = Path(entry.path)
        disp = ctx.disp(p)
        if not entry.is_dir():
            ctx.add("hygiene-area-file", "error",
                    f"'{entry.name}' is a file directly inside area '{area_path.name}'",
                    path=disp)
            continue
        m = check_tier_entry(entry.name, "category", disp, ctx)
        if not m:
            continue
        cat = m.group("cat")
        if not (a_lo <= cat <= a_hi):
            ctx.add("structure-numbering", "error",
                    f"category '{entry.name}' (cat {cat}) falls outside its area's "
                    f"range {a_lo}-{a_hi}", path=disp)
        ctx.actual_categories[cat] = {"label": m.group("label").strip(), "disp": disp}
        walk_category(p, cat, ctx, numbered_depth_below_id)


def walk_vault_shaped(root: Path, ctx: WalkContext, ignore_top_level: set[str],
                       numbered_depth_below_id: bool):
    """shape == "areas": root holds area folders directly."""
    for entry in scandir_pruned(root, ctx.ignore_names):
        if entry.name in ignore_top_level:
            continue  # legacy non-JD trees -- not drift, not a filing target
        if not entry.is_dir():
            continue  # a stray file at the vault root has no named check; not our problem
        p = Path(entry.path)
        disp = ctx.disp(p)
        m = check_tier_entry(entry.name, "area", disp, ctx)
        if not m:
            continue
        walk_area(p, m.group("a_lo"), m.group("a_hi"), ctx, numbered_depth_below_id)


def walk_area_shaped(root: Path, ctx: WalkContext, scope: list[str],
                      numbered_depth_below_id: bool):
    """shape == "area": root itself IS the one area folder."""
    m = ctx.tiers["area"].match(root.name)
    if m:
        a_lo, a_hi = m.group("a_lo"), m.group("a_hi")
    else:
        # Root's basename doesn't look like an area name (unusual mount
        # naming); fall back to the substrate's declared scope, which for
        # this shape is always a single area token.
        token = scope[0] if scope else "00-99"
        if "-" in token:
            a_lo, a_hi = token.split("-", 1)
        else:
            a_lo = a_hi = token
    walk_area(root, a_lo, a_hi, ctx, numbered_depth_below_id)


def walk_flat_ids_shaped(root: Path, ctx: WalkContext, numbered_depth_below_id: bool):
    """shape == "flat-ids": root holds ID folders directly, no category level."""
    for entry in scandir_pruned(root, ctx.ignore_names):
        p = Path(entry.path)
        disp = ctx.disp(p)
        m_id = ctx.tiers["id"].match(entry.name)
        if m_id:
            id_cat, id_item = m_id.group("cat"), m_id.group("item")
            acid = f"{id_cat}.{id_item}"
            is_dir = entry.is_dir()
            ctx.actual_ids[acid] = {"label": id_label(m_id.group("label"), not is_dir), "disp": disp}
            if is_dir:
                walk_id_interior(p, acid, ctx, numbered_depth_below_id)
            continue
        if not entry.is_dir():
            # No named check covers a loose file at a flat-ids root (the
            # spec's hygiene group only names "area" and "category"
            # folders). A flat-ids root plays the same structural role a
            # category folder plays elsewhere -- it's the level directly
            # above IDs -- so treated the same way: warn, allowlist-able.
            ctx.add("hygiene-category-file", "warn",
                    f"'{entry.name}' is a file directly inside ID root '{root.name}'",
                    path=disp)
            continue
        for other in ("area", "category", "deeper"):
            if ctx.tiers[other].match(entry.name):
                ctx.add("structure-stray-number", "error",
                        f"'{entry.name}' is a valid {other} name but sits at the ID "
                        f"level in a flat-ids root", path=disp)
                break
        else:
            ctx.add("structure-numbering", "error",
                    f"'{entry.name}' does not match the id grammar", path=disp)


# --------------------------------------------------------------------------
# Register parsing
# --------------------------------------------------------------------------

@dataclass
class RegisterEntry:
    acid: str
    label: str
    substrates: list[str]
    conflict: bool
    line: int


def parse_register(path: Path, patterns: dict, conflict_tag: str, separator: str,
                    active, findings: list[Finding]):
    """Returns (entries, category_headings) or (None, None) if the file is absent."""
    if not path.is_file():
        return None, None

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        findings.append(Finding("register-grammar", "error",
                                 f"register at '{path}' could not be read: {e}"))
        return None, None

    entries: list[RegisterEntry] = []
    category_headings: list[dict] = []  # {"cat", "label", "line"}
    current_cat: str | None = None
    seen: dict[str, list[tuple[int, str]]] = {}

    for i, raw in enumerate(text.splitlines(), start=1):
        if patterns["area_heading"].match(raw):
            current_cat = None
            continue
        m_cat = patterns["category_heading"].match(raw)
        if m_cat:
            current_cat = m_cat.group("cat")
            category_headings.append({
                "cat": current_cat,
                "label": m_cat.group("label").strip(),
                "line": i,
            })
            continue
        if not patterns["attempt"].match(raw):
            # Prose: title, blockquote header, explanatory paragraphs, rules,
            # blank lines, bare headings that aren't category/area headings.
            # Only a line that *attempts* to be an entry (starts "- `") is
            # held to the entry grammar.
            continue

        m_entry = patterns["entry"].match(raw)
        if not m_entry:
            if active("register-grammar"):
                findings.append(Finding("register-grammar", "error",
                                         f"line {i} does not match the register entry "
                                         f"grammar: {raw.strip()!r}",
                                         path=str(path_rel_or_name(path))))
            continue

        acid = m_entry.group("id")
        label = m_entry.group("label").strip()
        substrates_raw = m_entry.group("substrates") or ""
        substrates = [s.strip() for s in substrates_raw.split(separator) if s.strip()]
        tags_raw = m_entry.group("tags") or ""
        tags = tags_raw.split()
        conflict = conflict_tag in tags

        entry_cat = acid.split(".", 1)[0]
        if current_cat is None or entry_cat != current_cat:
            if active("register-bad-placement"):
                where = "no heading" if current_cat is None else f"category heading '{current_cat}'"
                findings.append(Finding(
                    "register-bad-placement", "error",
                    f"entry '{acid} {label}' sits under {where}, but its own category "
                    f"is '{entry_cat}'", path=str(path_rel_or_name(path)), id=acid,
                    ids=[acid]))

        seen.setdefault(acid, []).append((i, raw.strip()))
        entries.append(RegisterEntry(acid, label, substrates, conflict, i))

    if active("register-duplicate-id"):
        for acid, occurrences in seen.items():
            if len(occurrences) > 1:
                lines = ", ".join(f"line {ln}" for ln, _ in occurrences)
                findings.append(Finding(
                    "register-duplicate-id", "error",
                    f"AC.ID '{acid}' appears {len(occurrences)} times in the register "
                    f"({lines})", path=str(path_rel_or_name(path)), id=acid, ids=[acid]))

    return entries, category_headings


def path_rel_or_name(path: Path) -> str:
    return path.name


def build_register_index(entries: list[RegisterEntry]) -> dict[str, dict]:
    index: dict[str, dict] = {}
    for e in entries:
        slot = index.setdefault(e.acid, {"labels": [], "substrates": set(), "conflict": False})
        slot["labels"].append(e.label)
        slot["substrates"].update(e.substrates)
        slot["conflict"] = slot["conflict"] or e.conflict
    return index


# --------------------------------------------------------------------------
# Constitution parsing
# --------------------------------------------------------------------------

def parse_constitution(path: Path, patterns: dict):
    if not path.is_file():
        return None
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return None
    categories: dict[str, dict] = {}
    for i, raw in enumerate(text.splitlines(), start=1):
        m = patterns["category_line"].match(raw)
        if m:
            categories[m.group("cat")] = {"label": m.group("label").strip(), "line": i}
    return categories


# --------------------------------------------------------------------------
# Triangle checks
# --------------------------------------------------------------------------

def compare_category_maps(check_id: str, left_name: str, left: dict, right_name: str,
                           right: dict, active, findings: list[Finding]):
    if not active(check_id):
        return
    all_cats = sorted(set(left) | set(right))
    for cat in all_cats:
        in_left = cat in left
        in_right = cat in right
        if in_left and in_right:
            ll, rl = left[cat]["label"], right[cat]["label"]
            if ll != rl:
                findings.append(Finding(
                    check_id, "warn",
                    f"category {cat}: {left_name} calls it '{ll}', {right_name} calls "
                    f"it '{rl}'", id=cat, ids=[cat]))
        elif in_left and not in_right:
            findings.append(Finding(
                check_id, "warn",
                f"category {cat} '{left[cat]['label']}' is in {left_name} but missing "
                f"from {right_name}", id=cat, ids=[cat]))
        else:
            findings.append(Finding(
                check_id, "warn",
                f"category {cat} '{right[cat]['label']}' is in {right_name} but missing "
                f"from {left_name}", id=cat, ids=[cat]))


# --------------------------------------------------------------------------
# MOC staleness
# --------------------------------------------------------------------------

def check_moc_staleness(vault_root: Path, data: dict, patterns: dict, active,
                         findings: list[Finding]):
    """Does each category's [moc] table still name the same IDs its folder holds.

    Detection only -- jd-file/scripts/build_moc.py owns writing the block.
    A validator able to regenerate the table would be a validator able to
    silently rewrite the very thing it is supposed to be auditing, so this
    only ever reads the file and reports.

    A category with no map file, or a map file that never opted into the
    generated block (no marker pair present), is not stale -- it just isn't
    a generated map, so there is nothing here to compare it against.
    """
    if not active("moc-stale"):
        return
    moc = data.get("moc")
    if not moc:
        return
    begin, end = moc.get("begin_marker"), moc.get("end_marker")
    if not begin or not end:
        return

    id_pattern = patterns["grammar"]["id"]
    filename = moc.get("filename", "README.md")
    columns = moc.get("columns") or ["id"]
    id_col = columns[0]
    header_label = moc.get("labels", {}).get(id_col, id_col)
    excluded = set(moc.get("exclude", []))

    for cat in moc.get("categories", []):
        matches = sorted(p for p in vault_root.rglob(f"{cat} *") if p.is_dir())
        if not matches:
            continue  # no category folder on disk -- nothing to hold a map about
        cat_dir = matches[0]
        moc_path = cat_dir / filename
        if not moc_path.is_file():
            continue  # no map file: not stale, just absent
        try:
            text = moc_path.read_text(encoding="utf-8")
        except OSError:
            continue
        if begin not in text or end not in text:
            continue  # hand-written file that never opted into a generated block

        _, rest = text.split(begin, 1)
        block, _ = rest.split(end, 1)

        # Only the ID set is compared, never the rendered cells -- link text
        # and status values change for reasons that have nothing to do with
        # whether the map knows about the same IDs the folders do.
        table_ids: set[str] = set()
        for raw in block.splitlines():
            line = raw.strip()
            if not line.startswith("|"):
                continue
            cells = [c.strip() for c in line.strip("|").split("|")]
            if not cells or not cells[0]:
                continue
            first = cells[0]
            if first == header_label:
                continue  # the header row
            if re.fullmatch(r":?-+:?", first):
                continue  # the markdown rule row
            table_ids.add(first)

        try:
            entries = list(cat_dir.iterdir())
        except OSError:
            entries = []
        folder_ids: set[str] = set()
        for entry in entries:
            if not entry.is_dir():
                continue
            m = id_pattern.match(entry.name)
            if not m:
                continue
            folder_ids.add(f"{m.group('cat')}.{m.group('item')}")

        table_ids -= excluded
        folder_ids -= excluded

        missing_from_table = sorted(folder_ids - table_ids)
        missing_from_disk = sorted(table_ids - folder_ids)
        if not missing_from_table and not missing_from_disk:
            continue

        parts = []
        if missing_from_table:
            parts.append(f"on disk but missing from the table: {', '.join(missing_from_table)}")
        if missing_from_disk:
            parts.append(f"in the table but no longer on disk: {', '.join(missing_from_disk)}")
        rel_path = str(moc_path.relative_to(vault_root))
        all_ids = sorted(set(missing_from_table) | set(missing_from_disk))
        findings.append(Finding(
            "moc-stale", "warn",
            f"category {cat} map ({filename}) is out of sync with its folders -- "
            + "; ".join(parts),
            path=rel_path, id=", ".join(all_ids), ids=all_ids))


# --------------------------------------------------------------------------
# Drift checks
# --------------------------------------------------------------------------

def run_drift_checks(register_index: dict, actual_by_substrate: dict[str, dict],
                      substrates_by_id: dict, available_substrates: set[str],
                      active, findings: list[Finding]):
    if active("drift-undocumented"):
        for sid, ids in actual_by_substrate.items():
            for acid, info in ids.items():
                reg = register_index.get(acid)
                if reg is None:
                    findings.append(Finding(
                        "drift-undocumented", "error",
                        f"'{acid} {info['label']}' exists in {sid} at '{info['disp']}' "
                        f"but has no register entry", path=info["disp"], id=acid,
                        ids=[acid]))
                elif sid not in reg["substrates"]:
                    listed = ", ".join(sorted(reg["substrates"])) or "(none)"
                    findings.append(Finding(
                        "drift-undocumented", "error",
                        f"'{acid} {info['label']}' exists in {sid} at '{info['disp']}' "
                        f"but its register entry only lists [{listed}]", path=info["disp"],
                        id=acid, ids=[acid]))

    orphaned: list[Finding] = []
    if active("drift-orphaned"):
        for acid, reg in register_index.items():
            label = reg["labels"][0] if reg["labels"] else acid
            for sid in sorted(reg["substrates"]):
                sub_def = substrates_by_id.get(sid)
                if sub_def is None:
                    orphaned.append(Finding(
                        "drift-orphaned", "error",
                        f"register lists unrecognized substrate '{sid}' for "
                        f"'{acid} {label}'", id=acid, ids=[acid]))
                    continue
                if sid not in available_substrates:
                    continue  # root unresolved this run -- can't confirm either way
                if not scope_covers(acid, sub_def["scope"]):
                    continue  # absent by design, not drift
                if acid not in actual_by_substrate.get(sid, {}):
                    orphaned.append(Finding(
                        "drift-orphaned", "error",
                        f"register lists '{sid}' for '{acid} {label}' but {sid} does "
                        f"not hold it", id=acid, ids=[acid]))

    mismatch_acids: set[str] = set()
    if active("drift-name-mismatch"):
        for acid in set(register_index) | {a for ids in actual_by_substrate.values() for a in ids}:
            seen: list[tuple[str, str]] = []
            reg = register_index.get(acid)
            if reg:
                for label in reg["labels"]:
                    seen.append(("register", label))
            for sid, ids in actual_by_substrate.items():
                if acid in ids:
                    seen.append((sid, ids[acid]["label"]))
            distinct = {label for _, label in seen}
            if len(distinct) > 1:
                mismatch_acids.add(acid)
                where = "; ".join(f"{src}: '{label}'" for src, label in seen)
                findings.append(Finding(
                    "drift-name-mismatch", "error",
                    f"'{acid}' carries different labels across sources: {where}",
                    id=acid, ids=[acid]))

    # A rename shows up as both "the old spelling looks orphaned" and "the
    # ID's label doesn't match" -- one underlying fact, so report it once as
    # the mismatch, which actually names what happened.
    for f in orphaned:
        if not any(i in mismatch_acids for i in f.ids):
            findings.append(f)

    if active("drift-split-name"):
        pool: dict[str, dict[str, list[tuple[str, str]]]] = {}
        reg_pool_source = "register"
        for acid, reg in register_index.items():
            for label in reg["labels"]:
                norm = normalize_label(label)
                pool.setdefault(norm, {}).setdefault(acid, []).append((reg_pool_source, label))
        for sid, ids in actual_by_substrate.items():
            for acid, info in ids.items():
                norm = normalize_label(info["label"])
                pool.setdefault(norm, {}).setdefault(acid, []).append((sid, info["label"]))

        for norm, by_acid in pool.items():
            if len(by_acid) < 2:
                continue
            parts = []
            for acid in sorted(by_acid):
                locs = ", ".join(f"{src}" for src, _ in by_acid[acid])
                raw_label = by_acid[acid][0][1]
                parts.append(f"'{acid}' ({raw_label} -- seen in {locs})")
            findings.append(Finding(
                "drift-split-name", "warn",
                f"the name '{norm}' is split across distinct AC.IDs: " + "; ".join(parts),
                path=norm, id=", ".join(sorted(by_acid)), ids=sorted(by_acid)))


# --------------------------------------------------------------------------
# Link scan
# --------------------------------------------------------------------------

def build_global_host_roots(hosts: dict) -> list[tuple[str, str, Path]]:
    out = []
    for host_name, entry in hosts.items():
        for sid in ("vault", "office", "code"):
            for p in entry.get(sid, []):
                out.append((host_name, sid, expand(p)))
    # Longest path first so prefix matching picks the most specific root.
    out.sort(key=lambda t: len(str(t[2])), reverse=True)
    return out


def match_root(target: str, global_roots: list[tuple[str, str, Path]]):
    for host_name, sid, root in global_roots:
        root_s = str(root)
        if target == root_s or target.startswith(root_s + os.sep):
            return host_name, sid, root_s
    return None


_FENCE_RE = re.compile(r"^([ \t]*)(`{3,}|~{3,})[^\n]*\n.*?(?:^\1?\2[^\n]*$|\Z)",
                       re.DOTALL | re.MULTILINE)
_INLINE_CODE_RE = re.compile(r"`+[^`\n]*`+")


def blank_code(text: str) -> str:
    """Replace code spans and fenced blocks with same-length whitespace.

    A `file://` URL inside code is being displayed, not followed: the
    conventions note quotes the link pattern itself as a config value, and
    CLAUDE.md documents a `grep "file:///Users"` recipe. Scanning those
    produces findings about text that was never a link, and a report carrying
    false positives is one the reader learns to skim.
    """
    def blank(m: re.Match) -> str:
        return "".join("\n" if c == "\n" else " " for c in m.group(0))
    return _INLINE_CODE_RE.sub(blank, _FENCE_RE.sub(blank, text))


def scan_links(vault_root: Path, data: dict, patterns: dict, roots: dict,
                current_host: str | None, ignore_names: set[str], active,
                findings: list[Finding]):
    if not active("link-broken") and not active("link-unverifiable"):
        return

    links_cfg = data.get("links", {})
    percent_encoded = links_cfg.get("percent_encoded", True)
    skip_rel = data.get("ignore", {}).get("link_scan_skip", [])
    skip_abs = {str((vault_root / s).resolve()) for s in skip_rel}
    global_roots = build_global_host_roots(data.get("hosts", {}))
    pattern = patterns["links_pattern"]

    for dirpath, dirnames, filenames in os.walk(vault_root):
        dirnames[:] = [
            d for d in dirnames
            if d not in ignore_names
            and str((Path(dirpath) / d).resolve()) not in skip_abs
        ]
        for fname in filenames:
            if not fname.endswith(".md"):
                # Only .md payloads are ever opened during the link scan.
                # The office tree is cloud-synced with on-demand hydration; reading a
                # placeholder there can stall, so this scan never touches
                # anything but vault markdown, and never anything but text.
                continue
            fpath = Path(dirpath) / fname
            try:
                text = blank_code(fpath.read_text(encoding="utf-8", errors="replace"))
            except OSError:
                continue
            try:
                rel = str(fpath.relative_to(vault_root))
            except ValueError:
                rel = str(fpath)

            for m in pattern.finditer(text):
                raw = m.group(0)
                raw_path = raw[len("file://"):]
                target = unquote(raw_path) if percent_encoded else raw_path

                hit = match_root(target, global_roots)
                if hit is None:
                    findings.append(Finding(
                        "link-unverifiable", "info",
                        f"link target '{target}' in {rel} matched no configured root",
                        path=rel))
                    continue

                host_name, sid, root_s = hit
                if current_host is not None and host_name == current_host:
                    if not Path(target).exists():
                        findings.append(Finding(
                            "link-broken", "error",
                            f"link target '{target}' in {rel} does not exist on this host",
                            path=rel))
                    continue

                # Belongs to another host (or we don't know our own host key).
                suffix = target[len(root_s):].lstrip("/\\")
                this_host_root = roots.get(sid)
                if this_host_root is not None:
                    translated = str(this_host_root["canonical"] / suffix)
                    if Path(translated).exists():
                        findings.append(Finding(
                            "link-unverifiable", "info",
                            f"link target '{target}' in {rel} belongs to host "
                            f"'{host_name}'; it resolves here under a different "
                            f"prefix: '{translated}'", path=rel))
                    else:
                        findings.append(Finding(
                            "link-unverifiable", "info",
                            f"link target '{target}' in {rel} belongs to host "
                            f"'{host_name}'; its translated equivalent '{translated}' "
                            f"is also missing here -- stronger evidence of a dead link "
                            f"than plain unverifiability", path=rel))
                else:
                    findings.append(Finding(
                        "link-unverifiable", "info",
                        f"link target '{target}' in {rel} belongs to host '{host_name}', "
                        f"substrate '{sid}', which this host has no root for", path=rel))


# --------------------------------------------------------------------------
# Exceptions and #conflict downgrade
# --------------------------------------------------------------------------

def apply_exceptions(findings: list[Finding], exceptions: list[dict]):
    exc_by_key = {(e["check"], e["path"]): e["reason"] for e in exceptions}
    kept, suppressed = [], []
    for f in findings:
        reason = exc_by_key.get((f.check, f.path))
        if reason is not None:
            f.suppressed_reason = reason
            suppressed.append(f)
        else:
            kept.append(f)
    return kept, suppressed


def apply_conflict_downgrade(findings: list[Finding], conflict_acids: set[str], tag: str):
    for f in findings:
        if f.severity == "info":
            continue
        if any(i in conflict_acids for i in f.ids):
            f.original_severity = f.severity
            f.severity = "info"
            f.message += f" (marked {tag} in the register -- pending reconciliation, not news)"


# --------------------------------------------------------------------------
# Report rendering
# --------------------------------------------------------------------------

def render_human(findings: list[Finding], suppressed: list[Finding], notices: list[str],
                  skipped: dict[str, str], ran: set[str]) -> str:
    lines = []
    for n in notices:
        lines.append(f"NOTE: {n}")
    if notices:
        lines.append("")

    counts = {"error": 0, "warn": 0, "info": 0}
    for f in findings:
        counts[f.severity] += 1
    summary = (f"{counts['error']} errors, {counts['warn']} warnings, {counts['info']} info, "
               f"{len(suppressed)} suppressed by exception")
    lines.append(summary)
    lines.append("")

    ordered = sorted(findings, key=lambda f: (SEVERITY_RANK[f.severity], f.check, f.path or "", f.id or ""))
    last_key = None
    for f in ordered:
        key = (f.severity, f.check)
        if key != last_key:
            lines.append(f"[{f.severity.upper()}] {f.check}")
            last_key = key
        loc = f" ({f.path})" if f.path else ""
        idpart = f" {f.id}" if f.id else ""
        lines.append(f"  -{idpart} {f.message}{loc}")
        if f.detail:
            lines.append(f"      {f.detail}")
    if ordered:
        lines.append("")

    if suppressed:
        lines.append(f"{len(suppressed)} finding(s) suppressed by [[exceptions]]:")
        for f in suppressed:
            lines.append(f"  - {f.check} at '{f.path}': {f.suppressed_reason}")
        lines.append("")

    if skipped:
        lines.append("Skipped (did not run):")
        for cid in sorted(skipped):
            lines.append(f"  - {cid}: {skipped[cid]}")
        lines.append("")

    if ran:
        lines.append("Ran clean:")
        for cid in sorted(ran):
            lines.append(f"  - {cid}")

    return "\n".join(lines)


def render_json(findings: list[Finding], suppressed: list[Finding], notices: list[str],
                 skipped: dict[str, str], ran: set[str], meta: dict) -> str:
    counts = {"error": 0, "warn": 0, "info": 0}
    for f in findings:
        counts[f.severity] += 1
    payload = {
        "meta": meta,
        "notices": notices,
        "summary": {**counts, "suppressed": len(suppressed)},
        "findings": [f.to_dict() for f in findings],
        "suppressed": [
            {**f.to_dict(), "reason": f.suppressed_reason} for f in suppressed
        ],
        "skipped": skipped,
        "ran_clean": sorted(ran),
    }
    return json.dumps(payload, indent=2)


# --------------------------------------------------------------------------
# Orchestration
# --------------------------------------------------------------------------

def parse_args(argv):
    p = argparse.ArgumentParser(prog="validate.py",
                                 description="Deterministic validator for a Johnny.Decimal vault.")
    p.add_argument("--vault", type=Path, default=None)
    p.add_argument("--conventions", type=Path, default=None)
    p.add_argument("--host", type=str, default=None)
    p.add_argument("--json", action="store_true")
    p.add_argument("--only", action="append", default=[])
    p.add_argument("--skip", action="append", default=[])
    return p.parse_args(argv)


def run(args) -> int:
    cli_vault = None
    if args.vault is not None:
        cli_vault = expand(str(args.vault)).resolve()

    if args.conventions is not None:
        conventions_path = expand(str(args.conventions)).resolve()
    elif cli_vault is not None:
        conventions_path = cli_vault / DEFAULT_CONVENTIONS_RELATIVE
    else:
        raise FatalError(
            "no vault root resolvable: neither --vault nor --conventions was given, and "
            "the default conventions path is computed relative to the vault root, so "
            "there is nothing to bootstrap from. Pass at least one."
        )

    data = load_conventions(conventions_path)
    patterns = compile_patterns(data)

    roots, current_host, root_notices = resolve_all_roots(data, cli_vault, args.host)
    vault_root = roots["vault"]["canonical"]

    if cli_vault is None:
        # --vault omitted: conventions defaulting used the vault root we
        # just resolved from [hosts]/[discovery], per the spec's stated
        # bootstrap order (vault first, conventions path relative to it).
        # If --conventions was *also* omitted this is exactly consistent
        # with the default we already used above.
        pass

    only_set = set(args.only)
    skip_set = set(args.skip)

    def active(check_id: str) -> bool:
        if only_set and check_id not in only_set:
            return False
        if check_id in skip_set:
            return False
        return True

    skipped: dict[str, str] = {}
    for cid in ALL_CHECK_IDS:
        if only_set and cid not in only_set:
            skipped[cid] = "excluded by --only"
        elif cid in skip_set:
            skipped[cid] = "excluded by --skip"

    findings: list[Finding] = []
    notices: list[str] = list(root_notices)
    ignore_names = set(data.get("ignore", {}).get("names", []))
    ignore_top_level = set(data.get("ignore", {}).get("vault_top_level", []))
    numbered_depth_below_id = bool(data.get("rules", {}).get("numbered_depth_below_id", False))
    scaffold_names = set(data.get("rules", {}).get("scaffold_names", []))

    substrates = data.get("substrate", [])
    substrates_by_id = {s["id"]: s for s in substrates}
    available_substrates = {sid for sid, r in roots.items() if r is not None}

    actual_by_substrate: dict[str, dict] = {}
    vault_ctx: WalkContext | None = None

    for sub in substrates:
        sid = sub["id"]
        root_entry = roots.get(sid)
        if root_entry is None:
            continue
        root = root_entry["canonical"]
        if not root.is_dir():
            notices.append(f"substrate '{sid}' root '{root}' does not exist on disk -- "
                            f"its structure, hygiene, and drift checks are skipped")
            continue

        ctx = WalkContext(sid, root, ignore_names, patterns["grammar"], active, findings,
                          scaffold_names=scaffold_names)
        shape = sub["shape"]
        if shape == "areas":
            walk_vault_shaped(root, ctx, ignore_top_level, numbered_depth_below_id)
        elif shape == "area":
            walk_area_shaped(root, ctx, sub.get("scope", []), numbered_depth_below_id)
        elif shape == "flat-ids":
            walk_flat_ids_shaped(root, ctx, numbered_depth_below_id)
        else:
            notices.append(f"substrate '{sid}' declares unknown shape '{shape}' -- skipped")
            continue

        actual_by_substrate[sid] = ctx.actual_ids
        if sid == "vault":
            vault_ctx = ctx

    # --- Register -----------------------------------------------------
    register_path = vault_root / data["register"]["path"]
    conflict_tag = data["register"].get("conflict_tag", "#conflict")
    register_entries, register_categories = parse_register(
        register_path, patterns["register"], conflict_tag,
        data["register"].get("substrate_separator", ", "), active, findings)

    register_index: dict[str, dict] = {}
    conflict_acids: set[str] = set()
    if register_entries is None:
        notices.append(f"register not found at '{register_path}' -- register and drift "
                        f"checks are skipped")
        for cid in REGISTER_DEPENDENT_CHECKS:
            skipped.setdefault(cid, "register file not found")
    else:
        register_index = build_register_index(register_entries)
        conflict_acids = {acid for acid, slot in register_index.items() if slot["conflict"]}
        run_drift_checks(register_index, actual_by_substrate, substrates_by_id,
                          available_substrates, active, findings)

    # --- Constitution ---------------------------------------------------
    constitution_path = vault_root / data["constitution"]["path"]
    constitution_categories = parse_constitution(constitution_path, patterns["constitution"])
    if constitution_categories is None:
        notices.append(f"constitution not found at '{constitution_path}' -- triangle "
                        f"checks against it are skipped")
        for cid in CONSTITUTION_DEPENDENT_CHECKS:
            skipped.setdefault(cid, "constitution file not found")
    else:
        if vault_ctx is not None:
            compare_category_maps("triangle-constitution-folders", "the constitution",
                                   constitution_categories, "the vault substrate",
                                   vault_ctx.actual_categories, active, findings)
        if register_categories is not None:
            reg_cat_map = {c["cat"]: {"label": c["label"]} for c in register_categories}
            compare_category_maps("triangle-register-constitution", "the register",
                                   reg_cat_map, "the constitution", constitution_categories,
                                   active, findings)

    # --- MOC --------------------------------------------------------------
    check_moc_staleness(vault_root, data, patterns, active, findings)

    # --- Links ------------------------------------------------------------
    scan_links(vault_root, data, patterns, roots, current_host, ignore_names, active, findings)

    # --- Exceptions and #conflict downgrade --------------------------------
    findings, suppressed = apply_exceptions(findings, data.get("exceptions", []))
    apply_conflict_downgrade(findings, conflict_acids, conflict_tag)

    fired_checks = {f.check for f in findings} | {f.check for f in suppressed}
    ran_clean = {cid for cid in ALL_CHECK_IDS if cid not in skipped and cid not in fired_checks}

    meta = {
        "schema_version": data.get("schema_version"),
        "vault": str(vault_root),
        "host": current_host or resolve_hostname(args.host),
        "conventions": str(conventions_path),
    }

    if args.json:
        print(render_json(findings, suppressed, notices, skipped, ran_clean, meta))
    else:
        print(render_human(findings, suppressed, notices, skipped, ran_clean))

    return 1 if any(f.severity == "error" for f in findings) else 0


def main(argv=None) -> int:
    args = parse_args(argv)
    try:
        return run(args)
    except FatalError as e:
        if args.json:
            print(json.dumps({"fatal": str(e)}, indent=2))
        else:
            print(f"FATAL: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
