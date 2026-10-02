#!/usr/bin/env bash
# Resolves CLI_VERSION, a version or 'latest', to its release manifest, and outputs the version and
# the binary published for HOST.
set -euo pipefail

base_url="${BASE_URL%/}"

if [[ "$CLI_VERSION" == *[-+]flz.* ]]; then
  echo "cli-version '${CLI_VERSION}' is a Flitz release tag, not a CLI version" >&2
  echo "  -> cli-version takes the CLI's own version; the SDK tag comes from flitz.yaml, or from install-sdk's flitz-version" >&2
  exit 1
fi

if [[ "$CLI_VERSION" == "latest" ]]; then
  manifest_url="${base_url}/cli.json"
elif [[ "$CLI_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  manifest_url="${base_url}/cli/${CLI_VERSION}/cli-release.json"
else
  echo "cli-version '${CLI_VERSION}' is not a version" >&2
  echo "  -> expected MAJOR.MINOR.PATCH with an optional pre-release suffix, or 'latest'" >&2
  exit 1
fi

if ! manifest="$(curl --fail --silent --show-error --location --retry 3 --retry-all-errors "$manifest_url")"; then
  if [[ "$CLI_VERSION" == "latest" ]]; then
    echo "could not read the CLI release index at ${manifest_url}" >&2
  else
    echo "CLI version '${CLI_VERSION}' is not published at ${base_url}" >&2
    echo "  -> see ${base_url}/ for the published versions" >&2
  fi
  exit 1
fi

if ! version="$(jq -er '.version' <<<"$manifest")"; then
  echo "the manifest at ${manifest_url} names no version" >&2
  exit 1
fi

if ! entry="$(jq -e --arg host "$HOST" '.binaries[$host]' <<<"$manifest")"; then
  echo "CLI ${version} publishes no binary for ${HOST}" >&2
  exit 1
fi

url="$(jq -er '.url' <<<"$entry")"
sha256="$(jq -er '.sha256' <<<"$entry")"

{
  echo "version=${version}"
  echo "url=${url}"
  echo "sha256=${sha256}"
} >> "$GITHUB_OUTPUT"
