#!/usr/bin/env bash
# Names the host the Flitz artifacts are published for, and fails on any other runner.
set -euo pipefail

case "${RUNNER_OS}/${RUNNER_ARCH}" in
  Linux/X64) host=linux-x64 ;;
  macOS/ARM64) host=macos-arm64 ;;
  *)
    echo "unsupported runner ${RUNNER_OS}/${RUNNER_ARCH}" >&2
    echo "  -> supported runners: Linux/X64 (linux-x64), macOS/ARM64 (macos-arm64)" >&2
    exit 1
    ;;
esac

echo "host=${host}" >> "$GITHUB_OUTPUT"
