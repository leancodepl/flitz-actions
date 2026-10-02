#!/usr/bin/env bash
# Fails unless the comment can be posted: KEY must be a valid comment key, and gh must be on PATH.
set -euo pipefail

if [[ ! "$KEY" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "'${KEY}' is not a valid comment key" >&2
  echo "  -> use letters, digits, '.', '_', or '-'" >&2
  exit 1
fi

if ! command -v gh > /dev/null 2>&1; then
  echo "the gh CLI is not on PATH" >&2
  echo "  -> use a GitHub-hosted runner, or install gh before this step" >&2
  exit 1
fi
