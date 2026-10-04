#!/usr/bin/env bash
# Outputs the fields of the flitz publish result, and links them from the job summary.
set -euo pipefail

result="${RUNNER_TEMP}/flitz-publish.json"

# Prints one string field of the result, failing when the result names none.
field() {
  if ! jq -er "${1} | strings" "$result"; then
    echo "the publish result names no ${1#.}" >&2
    exit 1
  fi
}

id="$(field .id)"
page_url="$(field .page_url)"
deeplink="$(field .deeplink)"
bundle_url="$(field .bundle_url)"

# The app and the track the build landed on; empty when the result does not name them.
app="$(jq -r '.app // empty' "$result")"
track="$(jq -r '.track // empty' "$result")"
track_url="$(jq -r '.track_url // empty' "$result")"

for output in id page-url deeplink bundle-url app track track-url; do
  var="${output//-/_}"
  printf '%s<<FLITZ_OUTPUT_EOF\n%s\nFLITZ_OUTPUT_EOF\n' "$output" "${!var}"
done >> "$GITHUB_OUTPUT"

{
  echo "### Flitz publish"
  echo
  echo "| | |"
  echo "|---|---|"
  echo "| Landing page | ${page_url} |"
  if [[ -n "$track_url" ]]; then
    echo "| Track \`${track}\` of \`${app}\` | ${track_url} |"
  fi
  echo "| Bundle | ${bundle_url} |"
  echo "| Deeplink | \`${deeplink}\` |"
  echo "| Publish id | \`${id}\` |"
  if [[ -n "$TARGET" ]]; then
    echo "| Entrypoint | \`${TARGET}\` |"
  fi
} >> "$GITHUB_STEP_SUMMARY"
