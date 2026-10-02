#!/usr/bin/env bash
# Fails when no flitz CLI is on PATH.
set -euo pipefail

if ! command -v flitz > /dev/null 2>&1; then
  echo "the flitz CLI is not on PATH" >&2
  echo "  -> run the install-cli action first" >&2
  exit 1
fi
