#!/usr/bin/env bash
# Renders pr-comment/comment.md into a file in RUNNER_TEMP, and outputs its path. A template line
# naming a placeholder whose value is empty is left out.
set -euo pipefail

if [[ -z "$PAGE_URL" ]]; then
  echo "no landing page URL was given" >&2
  echo "  -> pass the page-url output of the publish action as page-url" >&2
  exit 1
fi

# jq substitutes literally: sed and bash's ${var//} both give characters like & and \ a
# meaning in the replacement, and URLs carry them.
body="${RUNNER_TEMP}/flitz-pr-comment.md"
jq -Rrs \
  --arg MARKER "<!-- flitz-preview:${KEY} -->" \
  --arg HEADER "$HEADER" \
  --arg PAGE_URL "$PAGE_URL" \
  --arg MESSAGE "$MESSAGE" \
  --arg DEEPLINK "$DEEPLINK" \
  --arg BUNDLE_URL "$BUNDLE_URL" \
  --arg TRACK_NAME "$TRACK_NAME" \
  --arg TRACK_URL "$TRACK_URL" \
  --arg ID "$ID" \
  --arg HEAD_SHA "$HEAD_SHA" \
  '
    $ARGS.named as $values
    | [$values | to_entries[] | select(.value == "") | "{{" + .key + "}}"] as $empty
    | split("\n")
    | map(select(. as $line | any($empty[]; inside($line)) | not)
        | reduce ($values | to_entries[]) as $e (.; split("{{" + $e.key + "}}") | join($e.value)))
    | join("\n")
  ' "$(dirname "${BASH_SOURCE[0]}")/../pr-comment/comment.md" > "$body"

echo "path=${body}" >> "$GITHUB_OUTPUT"
