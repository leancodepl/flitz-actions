#!/usr/bin/env bash
# Fails unless the installed CLI at FLITZ reports the EXPECTED version.
set -euo pipefail

reported="$("$FLITZ" --version)"
if [[ "$reported" != "$EXPECTED" ]]; then
  echo "the installed flitz reports version '${reported}', expected '${EXPECTED}'" >&2
  exit 1
fi
