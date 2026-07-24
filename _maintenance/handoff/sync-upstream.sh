#!/usr/bin/env bash
# Run the portable maintenance workflow from Bash.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec node "$script_dir/sync-upstream.mjs" "$@"
