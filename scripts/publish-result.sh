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
app_key="$(field .app.key)"
app_name="$(field .app.name)"
track_key="$(field .track.key)"
track_name="$(field .track.name)"
track_url="$(field .track_url)"

for output in id page-url deeplink bundle-url app-key app-name track-key track-name track-url; do
  var="${output//-/_}"
  printf '%s<<FLITZ_OUTPUT_EOF\n%s\nFLITZ_OUTPUT_EOF\n' "$output" "${!var}"
done >> "$GITHUB_OUTPUT"

{
  echo "### Flitz publish"
  echo
  echo "| | |"
  echo "|---|---|"
  echo "| Landing page | ${page_url} |"
  echo "| Bundle | ${bundle_url} |"
  echo "| Deeplink | \`${deeplink}\` |"
  echo "| App | \`${app_key}\` |"
  echo "| Track | [${track_name}](${track_url}) |"
  echo "| Publish id | \`${id}\` |"
  if [[ -n "$TARGET" ]]; then
    echo "| Entrypoint | \`${TARGET}\` |"
  fi
} >> "$GITHUB_STEP_SUMMARY"
