#!/usr/bin/env bash
# Puts the SDK at SDK_PATH on PATH for the later steps, and exports it as FLUTTER_ROOT.
set -euo pipefail

echo "${SDK_PATH}/bin" >> "$GITHUB_PATH"
echo "FLUTTER_ROOT=${SDK_PATH}" >> "$GITHUB_ENV"
