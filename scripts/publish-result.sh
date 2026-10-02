#!/usr/bin/env bash
# Outputs the fields of the flitz publish result, and links them from the job summary.
set -euo pipefail

result="${RUNNER_TEMP}/flitz-publish.json"
fields=(id page_url deeplink bundle_url)

for field in "${fields[@]}"; do
  if ! value="$(jq -er --arg f "$field" '.[$f] | strings' "$result")"; then
    echo "the publish result names no ${field}" >&2
    exit 1
  fi
  printf -v "$field" '%s' "$value"
done

# The app and the track the build landed on; empty when the result does not name them.
app="$(jq -r '.app // empty' "$result")"
track="$(jq -r '.track // empty' "$result")"
track_url="$(jq -r '.track_url // empty' "$result")"

for field in "${fields[@]}" app track track_url; do
  printf '%s<<FLITZ_OUTPUT_EOF\n%s\nFLITZ_OUTPUT_EOF\n' "${field//_/-}" "${!field}"
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
