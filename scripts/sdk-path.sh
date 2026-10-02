#!/usr/bin/env bash
# Outputs where flitz sdk install puts the release TAG: the CLI's cache directory.
set -euo pipefail

cache_root="${XDG_CACHE_HOME:-${HOME}/.cache}"
echo "path=${cache_root}/flitz/sdk/${TAG}" >> "$GITHUB_OUTPUT"
