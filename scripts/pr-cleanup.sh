#!/usr/bin/env bash
# Deletes AUTHOR's older comments on pull request NUMBER that carry KEY's marker. The new comment
# is already up, so nothing here fails the step: a leftover comment is only clutter.
set -uo pipefail

marker="<!-- flitz-preview:${KEY} -->"

if ! stale="$(gh api --paginate "repos/${GITHUB_REPOSITORY}/issues/${NUMBER}/comments" \
  | jq -r --arg author "$AUTHOR" --arg marker "$marker" --arg new "$NEW_ID" \
    '.[] | select(.user.login == $author and (.body | contains($marker)) and (.id | tostring) != $new) | "\(.id) \(.html_url)"')"; then
  echo "::warning::could not list the comments on pull request #${NUMBER}; older Flitz preview comments stay"
  exit 0
fi

while read -r id url; do
  if [[ -z "$id" ]]; then
    continue
  fi
  if ! gh api --method DELETE "repos/${GITHUB_REPOSITORY}/issues/comments/${id}" > /dev/null; then
    echo "::warning::could not delete the previous Flitz preview comment ${url}"
  fi
done <<< "$stale"
