#!/usr/bin/env bash
# A stand-in for qmd, so the smoke suite and eval scenario 6 can drive
# find-candidates.sh's vec lookup without a real index or its model download
# (#194). Install it as `qmd` with a symlink into a temp bin dir placed first on
# PATH.
#
#   QMD_SHIM_LOG   append each call's argv here, one line per call
#   QMD_SHIM_FAIL  print this to stderr and exit 1, as an unregistered
#                  collection does in real qmd
#   QMD_SHIM_HITS  file of <type>/<file> lines relative to _memory/; `vsearch`
#                  prints one hit per line whose type matches a -c argument
#
# Hits key on type rather than on a full collection name, so the shim works on
# a staged copy whatever its directory is called. Every call returns the same
# hits; find-candidates.sh dedupes, so that is all the suite needs.
set -euo pipefail

[[ -n "${QMD_SHIM_LOG:-}" ]] && printf '%s\n' "$*" >>"$QMD_SHIM_LOG"
if [[ -n "${QMD_SHIM_FAIL:-}" ]]; then
  printf '%s\n' "$QMD_SHIM_FAIL" >&2
  exit 1
fi
[[ "${1:-}" == vsearch ]] || exit 0

# json.dumps, not printf, so a hit path with a quote in it still parses.
exec python3 - "$@" <<'PY'
import json
import os
import sys

argv = sys.argv[1:]
collections = [argv[i + 1] for i, a in enumerate(argv[:-1]) if a == "-c"]
hits_file = os.environ.get("QMD_SHIM_HITS", "")
lines = []
if hits_file:
    with open(hits_file, encoding="utf-8") as fh:
        lines = [ln.strip() for ln in fh if ln.strip()]
out = []
for ln in lines:
    t, _, rest = ln.partition("/")
    for c in collections:
        if c.endswith("-" + t):
            out.append({"file": "qmd://%s/%s" % (c, rest), "score": 0.5})
            break
json.dump(out, sys.stdout)
sys.stdout.write("\n")
PY
