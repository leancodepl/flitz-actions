#!/usr/bin/env bash
# Fails without an API key, and masks the key in the job log.
set -euo pipefail

if [[ -z "$API_KEY" ]]; then
  echo "no Flitz credential was given" >&2
  echo "  -> pass the organization API key as the api-key input, from a repository secret" >&2
  exit 1
fi

echo "::add-mask::${API_KEY}"
