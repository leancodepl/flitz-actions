#!/usr/bin/env bash
# Downloads the CLI binary at URL, checks it against EXPECTED_SHA256, and puts it on PATH.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

download="${RUNNER_TEMP}/flitz-cli"
curl --fail --silent --show-error --location --retry 3 --retry-all-errors "$URL" -o "$download"

actual="$("${sha256[@]}" "$download" | cut -d ' ' -f 1)"
if [[ "$actual" != "$EXPECTED_SHA256" ]]; then
  echo "checksum mismatch on the downloaded flitz CLI" >&2
  echo "  expected ${EXPECTED_SHA256}" >&2
  echo "  actual   ${actual}" >&2
  rm -f "$download"
  exit 1
fi

install_dir="${HOME}/.local/bin"
mkdir -p "$install_dir"
mv -f "$download" "${install_dir}/flitz"
chmod +x "${install_dir}/flitz"

echo "$install_dir" >> "$GITHUB_PATH"
echo "path=${install_dir}/flitz" >> "$GITHUB_OUTPUT"
