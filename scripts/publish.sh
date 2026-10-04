#!/usr/bin/env bash
# Runs flitz publish, the CLI at FLITZ, with the inputs that are set, and saves its JSON result in
# RUNNER_TEMP.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The first line of the pushed commit's message; only a push event carries one.
subject="${HEAD_COMMIT_MESSAGE%%$'\n'*}"
subject="${subject%$'\r'}"

# The flags that describe the run are always set here, never left to the CLI: from the input when
# it is set, else from the pull request when there is one, else from the ref the run is for.
if [[ -n "$PR_NUMBER" ]]; then
  TRACK="${TRACK:-${PR_HEAD_REF}}"
  NAME="${NAME:-PR #${PR_NUMBER}: ${PR_TITLE}}"
  VERSION_NAME="${VERSION_NAME:-pr-${PR_NUMBER}-${PR_HEAD_SHA:0:7}}"
  COMMENT="${COMMENT:-${GITHUB_REPOSITORY}#${PR_NUMBER} ${PR_HEAD_REF} -> ${PR_BASE_REF} @ ${PR_HEAD_SHA:0:7} by ${GITHUB_ACTOR}}"
else
  TRACK="${TRACK:-${GITHUB_REF_NAME}}"
  NAME="${NAME:-${GITHUB_REF_NAME}}"
  VERSION_NAME="${VERSION_NAME:-${GITHUB_REF_NAME}-${GITHUB_SHA:0:7}}"
  COMMENT="${COMMENT:-${GITHUB_REPOSITORY} ${GITHUB_REF_NAME} @ ${GITHUB_SHA:0:7} by ${GITHUB_ACTOR}${subject:+: ${subject}}}"
fi

# flitz publish rejects values over its caps, so over-long values are cut to fit.
trim() {
  local var="$1" input="$2" max="$3" value="${!1}"
  if (( ${#value} > max )); then
    echo "::warning::${input} is ${#value} characters, over the ${max} flitz publish accepts; trimmed to ${max}"
    printf -v "$var" '%s' "${value:0:max}"
  fi
}
trim TRACK track 255
trim NAME name 120
trim VERSION_NAME version-name 64
trim COMMENT comment 1000

# The step runs from the project directory, so a relative path would otherwise resolve there.
if [[ -n "$DIR" ]]; then
  DIR="$(workspace_path "$DIR")"
elif [[ -n "$APP" && -f "$(workspace_path "$APP")/pubspec.yaml" ]]; then
  echo "the app input '${APP}' is an app directory, not an app key" >&2
  echo "  -> pass the directory as the dir input" >&2
  exit 1
fi

args=(publish --yes --json)

# Forwards a flag only when its value is non-empty.
opt() {
  if [[ -n "$2" ]]; then
    args+=("$1" "$2")
  fi
}

opt --dir "$DIR"
opt --target "$TARGET"
opt --app "$APP"
opt --track "$TRACK"

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
