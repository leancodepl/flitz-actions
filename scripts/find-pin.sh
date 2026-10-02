#!/usr/bin/env bash
# Requires the flitz.yaml FLITZ_PATH names, and outputs its directory: the project directory.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

pin="$(workspace_path "$FLITZ_PATH")"

if [[ ! -f "$pin" ]]; then
  echo "${pin} is not a flitz.yaml" >&2
  echo "  -> run 'flitz sdk use <tag>' in the project, or point flitz-path at its flitz.yaml" >&2
  exit 1
fi

echo "dir=$(dirname "$pin")" >> "$GITHUB_OUTPUT"
