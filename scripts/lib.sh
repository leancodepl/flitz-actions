# shellcheck shell=bash
# Helpers the step scripts source.

# Resolves a path against the workspace root; an absolute path is used as is.
workspace_path() {
  if [[ "$1" = /* ]]; then
    printf '%s\n' "$1"
  else
    printf '%s\n' "${GITHUB_WORKSPACE}/$1"
  fi
}

# Prints the sdk: tag a flitz.yaml pins, without its comment and quotes. Prints nothing when the
# file pins none.
pin_tag() {
  sed -n -e '/^sdk:/!d' -e 's/^sdk:[[:space:]]*//' -e 's/#.*//' -e 's/[[:space:]]*$//' \
    -e "s/^[\"']//" -e "s/[\"']\$//" -e p -e q "$1"
}

# Whether the value is a Flitz release tag: MAJOR.MINOR.PATCH+flz.N, or the -flz.N spelling.
is_release_tag() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+[-+]flz\.[1-9][0-9]*$ ]]
}

# The SHA-256 command, printing sha256sum's format: coreutils where it is installed, else the
# shasum that macOS ships.
if command -v sha256sum > /dev/null 2>&1; then
  sha256=(sha256sum)
else
  sha256=(shasum -a 256)
fi
