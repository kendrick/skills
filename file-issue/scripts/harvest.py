#!/usr/bin/env python3
"""Print the filesystem and git facts file-issue's Step 1 harvests, as JSON.

Run from inside the target repo:

    harvest.py

Reading the template ladder, the verification ladder, CODEOWNERS, workflows,
and the 90-day contributor count is the same mechanical job every run, so it
lives here and not in a fresh act of judgment each time. Choosing among the
verification candidates, reading issues with `gh issue list`, and picking depth
all stay in SKILL.md: this script lists and never picks.

Exit 0 with JSON, 3 outside a git repository or on a usage error.

A rung counts as missed only when the script looked and found nothing. The one
rung that can fail to look is the org-level `.github` repo, which needs `gh`:
when `gh` is missing, unauthenticated, or errors for any reason but a 404, the
template rung is `unchecked` and the built-in fallback is not chosen. That
failure touches only the org rung. Any local rung above it still wins, because
those rungs are filesystem reads that already looked.

Workflow `run:` lines are read line by line, never parsed as YAML. A `run:`
inside a block scalar of another key, or one split by YAML flow syntax, is
read wrong; see Known Limitations in the ledger.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

GH_TIMEOUT = 20
SCRIPT_SUFFIXES = (".sh", ".py")


def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    return r.returncode, r.stdout


# Excluded by full filename: a template may legitimately be named config.md.
CHOOSER_CONFIGS = ("config.yml", "config.yaml")
TEMPLATE_SUFFIXES = (".yml", ".yaml", ".md")


def files_in(root, directory, suffixes):
    d = root / directory
    if not d.is_dir():
        return []
    return sorted(
        str(p.relative_to(root))
        for p in d.iterdir()
        if p.is_file() and p.suffix in suffixes and p.name not in CHOOSER_CONFIGS
    )


def blank_issues_enabled(root):
    # config.yml is read for one key, so a line match beats a YAML parse.
    for name in ("config.yml", "config.yaml"):
        p = root / ".github" / "ISSUE_TEMPLATE" / name
        if p.is_file():
            m = re.search(r"^blank_issues_enabled:\s*(true|false)\b", p.read_text(errors="replace"), re.M)
            if m:
                return m.group(1) == "true"
    return None


def org_owner():
    rc, out = git("remote", "get-url", "origin")
    m = re.search(r"github\.com[:/]([^/]+)/", out) if rc == 0 else None
    return m.group(1) if m else None


def org_templates(owner):
    """Return ('found', [names]), ('absent', []), or ('unchecked', [])."""
    if owner is None:
        return "unchecked", []
    # GitHub's docs keep default issue templates in .github/ISSUE_TEMPLATE of
    # the org's .github repo; the repo-root ISSUE_TEMPLATE/ location is not served.
    path = ".github/ISSUE_TEMPLATE"
    try:
        r = subprocess.run(
            ["gh", "api", f"repos/{owner}/.github/contents/{path}"],
            capture_output=True, text=True, timeout=GH_TIMEOUT,
        )
    except (OSError, subprocess.TimeoutExpired):
        return "unchecked", []
    if r.returncode != 0:
        # A 404 means the owner has no such repo or directory: looked, found nothing.
        if "404" in r.stderr or "Not Found" in r.stderr:
            return "absent", []
        return "unchecked", []
    try:
        listing = json.loads(r.stdout)
    except ValueError:
        return "unchecked", []
    found = [
        f"{path}/{e['name']}" for e in listing
        if isinstance(e, dict) and e.get("type") == "file"
        and Path(e.get("name", "")).suffix in TEMPLATE_SUFFIXES
        and e.get("name", "") not in CHOOSER_CONFIGS
    ] if isinstance(listing, list) else []
    return ("found", found) if found else ("absent", [])


def template(root, blank):
    for rung, directory, suffixes in (
        ("forms", ".github/ISSUE_TEMPLATE", (".yml", ".yaml")),
        ("markdown", ".github/ISSUE_TEMPLATE", (".md",)),
    ):
        found = files_in(root, directory, suffixes)
        if found:
            return {"rung": rung, "files": found}
    found = files_in(root, "ISSUE_TEMPLATE", TEMPLATE_SUFFIXES)
    if found:
        return {"rung": "root", "files": found}
    status, found = org_templates(org_owner())
    if status == "found":
        return {"rung": "org", "files": found}
    if status == "unchecked":
        return {"rung": "unchecked", "files": []}
    # A repo that disables blank issues has ruled out the built-in templates too.
    return {"rung": "none" if blank is False else "builtin", "files": []}


def manifest_candidates(root):
    out = []
    pkg = root / "package.json"
    if pkg.is_file():
        try:
            scripts = json.loads(pkg.read_text()).get("scripts", {})
            out += [f"package.json:{k}" for k in scripts] if isinstance(scripts, dict) else []
        except ValueError:
            out.append("package.json")
    mk = root / "Makefile"
    if mk.is_file():
        targets = re.findall(r"^([A-Za-z0-9_][A-Za-z0-9_./-]*)\s*:(?!=)", mk.read_text(errors="replace"), re.M)
        out += [f"Makefile:{t}" for t in dict.fromkeys(targets)]
    for name in ("pyproject.toml", "Cargo.toml"):
        if (root / name).is_file():
            out.append(name)
    return out


def script_candidates(root):
    out = []
    # One runnable rule for both directories: a Python or executable entry
    # point under tests/ is as much a verification command as a .sh file.
    for name in ("tests", "scripts"):
        sd = root / name
        for p in sorted(sd.iterdir()) if sd.is_dir() else []:
            if p.is_file() and (p.suffix in SCRIPT_SUFFIXES or os.access(p, os.X_OK)):
                out.append(str(p.relative_to(root)))
    return out


def workflow_runs(root):
    out = []
    for p in workflow_files(root):
        lines = p.read_text(errors="replace").splitlines()
        i = 0
        while i < len(lines):
            # Group 1 spans the `- ` marker, so its length is the `run` key's own
            # column; sibling keys (`shell:`) sit at that column and end the block.
            m = re.match(r"^(\s*(?:-\s+)?)run:\s*(.*)$", lines[i])
            i += 1
            if not m:
                continue
            indent, rest = len(m.group(1)), m.group(2).strip()
            if rest[:1] in ("|", ">"):
                block = []
                while i < len(lines) and (not lines[i].strip() or len(lines[i]) - len(lines[i].lstrip()) > indent):
                    if lines[i].strip():
                        block.append(lines[i].strip())
                    i += 1
                out += block
            elif rest:
                out.append(rest.strip("'\""))
    return list(dict.fromkeys(out))


def workflow_files(root):
    wf = root / ".github" / "workflows"
    return sorted(wf.glob("*.y*ml")) if wf.is_dir() else []


def verification(root):
    for rung, finder in (
        ("manifest", manifest_candidates),
        ("scripts", script_candidates),
        ("workflows", workflow_runs),
    ):
        found = finder(root)
        if found:
            return {"rung": rung, "candidates": found}
    return "absent"


def main(argv):
    if argv:
        print("usage: harvest.py   (no arguments; run from inside the target repo)", file=sys.stderr)
        return 3
    rc, top = git("rev-parse", "--show-toplevel")
    if rc != 0:
        print("harvest.py: not inside a git repository", file=sys.stderr)
        return 3
    root = Path(top.strip())
    blank = blank_issues_enabled(root)
    result = {"template": template(root, blank)}
    if blank is not None:
        result["blank_issues_enabled"] = blank
    result["verification"] = verification(root)
    result["codeowners"] = any(
        (root / d / "CODEOWNERS").is_file() for d in (".github", ".", "docs")
    )
    result["workflows"] = bool(workflow_files(root))
    # --since matches `git shortlog` in SKILL.md; HEAD keeps an empty repo from reading stdin.
    rc, out = git("shortlog", "-sne", "--since=90 days ago", "HEAD")
    result["contributors_90d"] = len(out.splitlines()) if rc == 0 else 0
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
