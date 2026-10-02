#!/usr/bin/env bash
# Posts the comment file BODY on pull request NUMBER, and outputs the new comment's URL, id, and
# author.
set -euo pipefail

response="${RUNNER_TEMP}/flitz-pr-comment-response.json"
errors="${RUNNER_TEMP}/flitz-pr-comment-errors.txt"

if ! gh api --method POST "repos/${GITHUB_REPOSITORY}/issues/${NUMBER}/comments" -F "body=@${BODY}" \
  > "$response" 2> "$errors"; then
  if grep -q "HTTP 403" "$errors"; then
    echo "the token cannot comment on pull request #${NUMBER}" >&2
    echo "  -> grant the job 'permissions: pull-requests: write'; runs from forks get a read-only token" >&2
  else
    cat "$errors" >&2
  fi
  exit 1
fi

jq -r '"comment-url=\(.html_url)", "id=\(.id)", "author=\(.user.login)"' "$response" >> "$GITHUB_OUTPUT"
