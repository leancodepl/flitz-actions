#!/usr/bin/env bash
# Runs flitz publish, the CLI at FLITZ, with the inputs that are set, and saves its JSON result in
# RUNNER_TEMP.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Empty metadata describes the run: the pull request when there is one, else the ref.
run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
if [[ -n "$PR_NUMBER" ]]; then
  NAME="${NAME:-PR #${PR_NUMBER}: ${PR_TITLE}}"
  VERSION_NAME="${VERSION_NAME:-pr-${PR_NUMBER}-${PR_HEAD_SHA:0:7}}"
  COMMENT="${COMMENT:-${PR_URL} | ${PR_HEAD_REF} @ ${PR_HEAD_SHA} | ${run_url}}"
else
  NAME="${NAME:-${GITHUB_REF_NAME}}"
  VERSION_NAME="${VERSION_NAME:-${GITHUB_REF_NAME}-${GITHUB_SHA:0:7}}"
  COMMENT="${COMMENT:-${GITHUB_REF_NAME} @ ${GITHUB_SHA} | ${run_url}}"
fi

# flitz publish rejects metadata over its caps, so over-long values are cut to fit.
trim() {
  local var="$1" input="$2" max="$3" value="${!1}"
  if (( ${#value} > max )); then
    echo "::warning::${input} is ${#value} characters, over the ${max} flitz publish accepts; trimmed to ${max}"
    printf -v "$var" '%s' "${value:0:max}"
  fi
}
trim NAME name 120
trim VERSION_NAME version-name 64
trim COMMENT comment 1000

args=(publish --yes --json)

# Forwards a flag only when its value is non-empty.
opt() {
  if [[ -n "$2" ]]; then
    args+=("$1" "$2")
  fi
}

# The step runs from the project directory, so a relative path would otherwise resolve there.
if [[ -n "$APP" ]]; then
  APP="$(workspace_path "$APP")"
fi
opt --app "$APP"
opt --target "$TARGET"
opt --target-platform "$TARGET_PLATFORM"

while IFS= read -r define; do
  opt --dart-define "${define%$'\r'}"
done <<< "$DART_DEFINES"

while IFS= read -r file; do
  file="${file%$'\r'}"
  if [[ -n "$file" ]]; then
    file="$(workspace_path "$file")"
  fi
  opt --dart-define-from-file "$file"
done <<< "$DART_DEFINE_FILES"

opt --schema "$SCHEMA"
opt --name "$NAME"
opt --version-name "$VERSION_NAME"
opt --comment "$COMMENT"

"$FLITZ" "${args[@]}" > "${RUNNER_TEMP}/flitz-publish.json"
