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

for field in "${fields[@]}"; do
  printf '%s<<FLITZ_OUTPUT_EOF\n%s\nFLITZ_OUTPUT_EOF\n' "${field//_/-}" "${!field}"
done >> "$GITHUB_OUTPUT"

{
  echo "### Flitz publish"
  echo
  echo "| | |"
  echo "|---|---|"
  echo "| Landing page | ${page_url} |"
  echo "| Bundle | ${bundle_url} |"
  echo "| Deeplink | \`${deeplink}\` |"
  echo "| Publish id | \`${id}\` |"
  if [[ -n "$TARGET" ]]; then
    echo "| Entrypoint | \`${TARGET}\` |"
  fi
} >> "$GITHUB_STEP_SUMMARY"
