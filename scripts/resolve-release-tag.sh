#!/usr/bin/env bash
# Outputs the release tag install-sdk installs: FLITZ_VERSION, else the tag the pin at FLITZ_PATH
# pins.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [[ -n "$FLITZ_VERSION" ]]; then
  tag="$FLITZ_VERSION"
else
  pin="$(workspace_path "$FLITZ_PATH")"

  if [[ ! -f "$pin" ]]; then
    echo "no flitz-version given and no pin at ${pin}" >&2
    echo "  -> pass the tag as flitz-version, or commit a flitz.yaml naming it" >&2
    exit 1
  fi

  tag="$(pin_tag "$pin")"

  if [[ -z "$tag" ]]; then
    echo "${pin} names no sdk: tag" >&2
    echo "  -> pass the tag as flitz-version, or add an sdk: key to flitz.yaml" >&2
    exit 1
  fi
fi

if [[ "$tag" == "latest" ]]; then
  echo "'latest' is not a concrete Flitz release tag" >&2
  echo "  -> run 'flitz sdk releases' to find the tag to pass" >&2
  exit 1
fi

if ! is_release_tag "$tag"; then
  echo "'${tag}' is not a Flitz release tag" >&2
  echo "  -> expected MAJOR.MINOR.PATCH+flz.N, or the -flz.N spelling" >&2
  exit 1
fi

echo "version=${tag}" >> "$GITHUB_OUTPUT"
