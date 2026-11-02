#!/usr/bin/env bash
# A stand-in for long-term-memory-kit's `ltm`, so the smoke suite can drive
# verify-migration.sh's verify-ltm sweep through its pass, finding, and silent
# failure paths without the kit installed (#276). It proves the plumbing and
# nothing about ltm itself; the suite's real-ltm block covers that. Install it
# as `ltm` with a symlink into a temp bin dir placed first on PATH.
#
#   LTM_SHIM_LOG   append each call's argv here, one line per call
#   LTM_SHIM_OUT   print this to stdout, as ltm validate prints its findings
#   LTM_SHIM_EXIT  exit with this code (default 0)
set -euo pipefail

[[ -n "${LTM_SHIM_LOG:-}" ]] && printf '%s\n' "$*" >>"$LTM_SHIM_LOG"
[[ -n "${LTM_SHIM_OUT:-}" ]] && printf '%s\n' "$LTM_SHIM_OUT"
exit "${LTM_SHIM_EXIT:-0}"
