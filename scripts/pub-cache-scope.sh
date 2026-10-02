#!/usr/bin/env bash
# Outputs the pub cache's path and its key, a digest of the pubspec files under PROJECT_DIR. A
# project directory outside the workspace outputs neither, which skips the cache.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

path="${PUB_CACHE:-${HOME}/.pub-cache}"
project="$(cd "$PROJECT_DIR" && pwd -P)"
workspace="$(cd "$GITHUB_WORKSPACE" && pwd -P)"

if [[ "$project" != "$workspace" && "$project" != "$workspace"/* ]]; then
  echo "::notice::the project directory ${project} is outside the workspace; the pub cache is skipped"
  exit 0
fi

# Each file's relative path is hashed with its contents, so moving a package changes the key.
digest="$(
  cd "$project"
  find . -type f \( -name pubspec.yaml -o -name pubspec.lock \) -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 -r "${sha256[@]}" \
    | "${sha256[@]}" \
    | cut -d ' ' -f 1
)"

{
  echo "path=${path}"
  echo "key=pub-${RUNNER_OS}-${RUNNER_ARCH}-${digest}"
} >> "$GITHUB_OUTPUT"
