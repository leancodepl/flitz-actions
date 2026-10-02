#!/usr/bin/env bash
# Outputs the release tag the flitz.yaml FLITZ_PATH names pins. Runs after find-pin.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

pin="$(workspace_path "$FLITZ_PATH")"
tag="$(pin_tag "$pin")"

if [[ -z "$tag" ]]; then
  echo "${pin} names no sdk: tag" >&2
  echo "  -> run 'flitz sdk use <tag>' in the project to pin one" >&2
  exit 1
fi

if ! is_release_tag "$tag"; then
  echo "${pin} pins '${tag}', which is not a Flitz release tag" >&2
  echo "  -> expected MAJOR.MINOR.PATCH+flz.N, or the -flz.N spelling; run 'flitz sdk use <tag>' to repin" >&2
  exit 1
fi

echo "version=${tag}" >> "$GITHUB_OUTPUT"
