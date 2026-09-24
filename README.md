# Flitz GitHub Actions

Six composite actions that put the public `flitz` CLI and a pinned Flitz SDK on a GitHub Actions
runner, publish a `.flitz` from it, and link the result from the pull request.

| Action | `uses:` |
|---|---|
| Combined: install, publish, and comment | `leancodepl/flitz-actions@<ref>` |
| CLI, SDK, and pub cache | `leancodepl/flitz-actions/install@<ref>` |
| CLI only | `leancodepl/flitz-actions/install-cli@<ref>` |
| SDK only | `leancodepl/flitz-actions/install-sdk@<ref>` |
| Publish only | `leancodepl/flitz-actions/publish@<ref>` |
| Comment on the pull request | `leancodepl/flitz-actions/pr-comment@<ref>` |

`<ref>` is any tag, branch, or commit SHA of this repository.

## Supported runners

| `RUNNER_OS` | `RUNNER_ARCH` | Host |
|---|---|---|
| `Linux` | `X64` | `linux-x64` |
| `macOS` | `ARM64` | `macos-arm64` |

Every other combination — Windows, Intel macOS, Linux arm64 — fails on the first step, before any
download, cache lookup, or credential handling. `pr-comment` is the exception: it touches no Flitz
artifact and runs on any runner with `bash`, `gh`, and `jq`.

## Usage

One step installs the CLI and the pinned SDK, builds and publishes, and comments on the pull
request:

```yaml
on: pull_request
permissions:
  contents: read
  pull-requests: write
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: leancodepl/flitz-actions@main
        with:
          api-key: ${{ secrets.FLITZ_APIKEY }}
```

A monorepo app whose pin is not at the repository root, built from a flavor entry point, with
publish metadata taken from the pull request and a comment note for reviewers:

```yaml
- uses: leancodepl/flitz-actions@main
  with:
    flitz-path: mobile/flitz.yaml
    api-key: ${{ secrets.FLITZ_APIKEY }}
    target: lib/main_tst.dart
    name: "PR #${{ github.event.pull_request.number }}"
    version-name: pr-${{ github.event.pull_request.number }}
    comment: ${{ github.event.pull_request.html_url }}
    pr-comment-message: Scan the QR with the Flitz-enabled test build.
```

The parts composed by hand — a job that tests before it publishes and comments:

```yaml
- uses: leancodepl/flitz-actions/install@main
  with:
    flitz-path: mobile/flitz.yaml
    api-key: ${{ secrets.FLITZ_APIKEY }}
- run: flutter test
  working-directory: mobile
- id: flitz
  uses: leancodepl/flitz-actions/publish@main
  with:
    flitz-path: mobile/flitz.yaml
    api-key: ${{ secrets.FLITZ_APIKEY }}
- uses: leancodepl/flitz-actions/pr-comment@main
  with:
    page-url: ${{ steps.flitz.outputs.page-url }}
    deeplink: ${{ steps.flitz.outputs.deeplink }}
    bundle-url: ${{ steps.flitz.outputs.bundle-url }}
    id: ${{ steps.flitz.outputs.id }}
```

A job that pins the CLI version and installs the halves separately:

```yaml
- uses: leancodepl/flitz-actions/install-cli@main
  with:
    cli-version: 0.1.0
- uses: leancodepl/flitz-actions/install-sdk@main
  with:
    api-key: ${{ secrets.FLITZ_APIKEY }}
```

A job that needs the CLI but no SDK:

```yaml
- uses: leancodepl/flitz-actions/install-cli@main
- run: flitz status
  env:
    FLITZ_APIKEY: ${{ secrets.FLITZ_APIKEY }}
```

A `flitz` command a workflow runs itself supplies its own credential, as in the last example: no
action exports one.

## Shared inputs

**`flitz-path`** — the project's pin file, `flitz.yaml`. Default `flitz.yaml`. A relative value
resolves against the workspace root; an absolute value is used as is. The value names the file
itself, and its directory is the **project directory**: the CLI runs there, and the pub cache is
scoped to it. Every message about the pin names the resolved path.

**`api-key`** — the organization API key, stored as a repository secret by whoever configures the
workflow. Required on every action that runs a licensed command. An empty value fails before any
cache, network, or build work. See [Secret handling](#secret-handling).

## `install-cli`

Downloads a published CLI binary, verifies its checksum, and puts it on `PATH`. It authenticates
nothing — the binaries and the manifests describing them are public.

| Input | Default | Description |
|---|---|---|
| `cli-version` | `latest` | A CLI semantic version (`0.1.0`, `1.5.0-rc.1`), or `latest`. |
| `base-url` | `https://download.flitz.dev` | The public download host serving the CLI artifacts. |

| Output | Description |
|---|---|
| `version` | The concrete version installed, with `latest` already resolved. |
| `path` | The absolute path of the installed `flitz` executable. |

The binary is installed as `$HOME/.local/bin/flitz`.

## `install-sdk`

Installs one Flitz release into the CLI cache and puts its toolchain on `PATH`. Requires `flitz`
already on `PATH`.

| Input | Default | Description |
|---|---|---|
| `flitz-version` | *(empty)* | The Flitz release tag to install, e.g. `3.41.4-flz.1`. Empty reads the tag from the pin file `flitz-path` names. |
| `flitz-path` | `flitz.yaml` | The project's pin file. Read only when `flitz-version` is empty. |
| `api-key` | *(required)* | The organization API key. |
| `cache` | `true` | Whether to restore and save the SDK cache. |

| Output | Description |
|---|---|
| `version` | The resolved release tag. |
| `path` | The absolute path of the installed SDK root — a valid `FLUTTER_ROOT`. |
| `cache-hit` | `true` when the SDK cache was restored. |

`flitz-version` takes a **concrete** release tag in either separator spelling (`3.41.4-flz.1`,
`3.41.9+flz.2`). `latest` is rejected: the cache key is derived from the tag before any network
call. Run `flitz sdk releases` to find the tag.

The action appends the SDK's `bin` directory to `PATH` ahead of any stock Flutter on the runner and
exports `FLUTTER_ROOT` — the only variable it exports. It writes no pin: the project's `flitz.yaml`
is never modified.

The SDK cache is keyed `flitz-sdk-<os>-<arch>-<tag>` with no prefix fallback, so a tag always
restores exactly its own release. `install-sdk` does not cache pub dependencies; `install` does.

## `install`

Installs the CLI and the project's pinned SDK, then restores the pub cache: one step leaves the
runner ready for `flutter` commands and a `flitz publish`. It takes no `flitz-version`: the SDK tag
is the `sdk:` value of the pin file `flitz-path` names.

| Input | Default | Description |
|---|---|---|
| `cli-version` | `latest` | The CLI version, as for `install-cli`. |
| `base-url` | `https://download.flitz.dev` | The CLI download host, as for `install-cli`. |
| `flitz-path` | `flitz.yaml` | The project's pin file. Names the SDK tag and the project directory. |
| `api-key` | *(required)* | The organization API key. |
| `cache` | `true` | Whether to restore and save the SDK cache. |
| `pub-cache` | `true` | Whether to restore and save the pub cache. |

| Output | Description |
|---|---|
| `cli-version` | The concrete CLI version installed. |
| `flitz-version` | The resolved Flitz release tag. |
| `sdk-path` | The absolute path of the installed SDK root — a valid `FLUTTER_ROOT`. |
| `sdk-cache-hit` | Whether the SDK cache was restored. |

The host, the pin, and the credential are checked first, before any download or cache lookup.

## Pub cache

A stage of `install` and of the combined action. It exposes no output.

- **Path** — `${PUB_CACHE:-$HOME/.pub-cache}`, so a job that sets `PUB_CACHE` has that directory
  cached.
- **Scope** — every `pubspec.yaml` and `pubspec.lock` under the project directory: the app and its
  local path packages, nothing else in the repository. A pin at the workspace root scopes it to the
  whole workspace.
- **Key** — `pub-<os>-<arch>-<hash of the scoped pubspec files>`, falling back to the newest
  `pub-<os>-<arch>-` entry when a pubspec changes.
- **Save** — at the end of the job, when the exact key missed.

A project directory outside the workspace skips the pub cache with a notice; the action continues.
The stage resolves no dependencies: `flutter pub get` and `flitz publish` fill the restored cache.

## `publish`

Builds the project's app with `flitz publish` and exposes the result. Requires `flitz` already on
`PATH`.

| Input | Default | Description |
|---|---|---|
| `api-key` | *(required)* | The organization API key. |
| `flitz-path` | `flitz.yaml` | The project's pin file. The CLI runs from the project directory. |
| `app` | *(empty)* | The Flutter application directory, forwarded as `--app`. Empty builds the app in the project directory. |
| `target` | *(empty)* | The Dart entry-point file, relative to the app directory, forwarded as `--target`. Empty builds `lib/main.dart`. |
| `target-platform` | *(empty)* | Forwarded as `--target-platform`. Empty uses the CLI's default for the build host. |
| `dart-define` | *(empty)* | Compile-time constants, one `KEY=VALUE` per line, each forwarded as one `--dart-define`. |
| `dart-define-from-file` | *(empty)* | `.json` or `.env` constant files, one path per line, each forwarded as one `--dart-define-from-file`. |
| `schema` | *(empty)* | The deeplink URL scheme, forwarded as `--schema`. Empty uses `flitz`. |
| `name` | *(empty)* | Display title for the publish, forwarded as `--name`. Trimmed to 120 characters. |
| `version-name` | *(empty)* | Version label for the publish, forwarded as `--version-name`. Trimmed to 64 characters. |
| `comment` | *(empty)* | Free-text comment for the publish, forwarded as `--comment`. Trimmed to 1000 characters. |

| Output | Description |
|---|---|
| `id` | The publish record's opaque id. |
| `page-url` | The landing page's download URL. |
| `deeplink` | The `<schema>://download?url=…` deeplink the landing page and the QR encode. |
| `bundle-url` | The `.flitz` bundle's download URL. |

The action runs `flitz publish --yes --json` from the project directory, forwarding each optional
input only when it is non-empty. `app` and each `dart-define-from-file` path resolve against the
workspace root and reach the CLI as absolute paths. `target` stays relative to the app directory.

`dart-define` and `dart-define-from-file` take one value per line, in order. Empty lines are
skipped; nothing else is trimmed, and a value is never split on commas:

```yaml
dart-define: |
  API_URL=https://api.example.com/?a=1,b=2
  FEATURE_X=true
```

`--yes` lets `publish` download the pinned SDK when it is not installed yet. On success the four
outputs are the fields of the CLI's JSON result, and a summary table with the links — plus an
`Entrypoint` row when `target` is set — is added to the job page. On failure the step fails with
the CLI's own exit code and message, and no output is set.

## `pr-comment`

Posts a comment on the pull request that triggered the workflow, linking the landing page, the
deeplink, and the bundle. Each run replaces the previous comment with the same key, so the pull
request carries one current preview comment per key, at the bottom of its timeline.

| Input | Default | Description |
|---|---|---|
| `page-url` | *(required)* | The landing page URL — the `page-url` output of `publish`. |
| `deeplink` | *(empty)* | The deeplink — the `deeplink` output of `publish`. |
| `bundle-url` | *(empty)* | The bundle URL — the `bundle-url` output of `publish`. |
| `id` | *(empty)* | The publish id — the `id` output of `publish`. |
| `key` | `default` | Identifies the comment among the Flitz comments on one pull request. Letters, digits, `.`, `_`, or `-`. |
| `header` | `📱 Flitz preview build` | The comment's heading text. |
| `message` | `Open it with a Flitz-enabled loader build.` | Markdown inserted below the landing-page link, e.g. which loader build opens the bundle. Empty omits it. |
| `github-token` | `${{ github.token }}` | The token the comment is posted and cleaned up with. |

| Output | Description |
|---|---|
| `comment-url` | The HTML URL of the posted comment. Empty when the action skipped. |

The comment carries a heading, a bold link to the landing page, the `message`, and a collapsed
**Details** block with the deeplink, the bundle URL, the publish id, and the pull request's head
commit. A row whose input is empty is left out. The body comes from
[`pr-comment/comment.md`](pr-comment/comment.md).

- **Replacing.** The new comment is posted first. Older comments by the same author carrying the
  hidden marker `<!-- flitz-preview:<key> -->` are deleted after it. Comments by other authors and
  comments with other keys are left alone. A job publishing several apps gives each its own `key`.
- **Permissions.** The job's token needs `pull-requests: write`. A run from a fork gets a read-only
  token and fails with a message naming that permission.
- **Other events.** On an event that is not a pull request — a push, a manual dispatch — the action
  logs a notice, posts nothing, and succeeds.
- **Cleanup failures.** A comment that cannot be deleted leaves a warning; the action still
  succeeds.

## The combined action

Runs `install`, then `publish`, then `pr-comment`. It takes no `flitz-version`: the SDK tag is the
`sdk:` value of the pin file `flitz-path` names — the tag `publish` builds against.

| Input | Default | Description |
|---|---|---|
| `cli-version` | `latest` | Forwarded to `install`. |
| `base-url` | `https://download.flitz.dev` | Forwarded to `install`. |
| `flitz-path` | `flitz.yaml` | Forwarded to `install` and `publish`. |
| `api-key` | *(required)* | Forwarded to `install` and `publish`. |
| `cache` | `true` | Forwarded to `install` as its SDK-cache switch. |
| `pub-cache` | `true` | Forwarded to `install`. |
| `app` | *(empty)* | Forwarded to `publish`. |
| `target` | *(empty)* | Forwarded to `publish`. |
| `target-platform` | *(empty)* | Forwarded to `publish`. |
| `dart-define` | *(empty)* | Forwarded to `publish`. |
| `dart-define-from-file` | *(empty)* | Forwarded to `publish`. |
| `schema` | *(empty)* | Forwarded to `publish`. |
| `name` | *(empty)* | Forwarded to `publish`. |
| `version-name` | *(empty)* | Forwarded to `publish`. |
| `comment` | *(empty)* | Forwarded to `publish` — the publish record's comment. |
| `pr-comment-key` | `default` | Forwarded to `pr-comment` as `key`. |
| `pr-comment-header` | `📱 Flitz preview build` | Forwarded to `pr-comment` as `header`. |
| `pr-comment-message` | `Open it with a Flitz-enabled loader build.` | Forwarded to `pr-comment` as `message`. |
| `github-token` | `${{ github.token }}` | Forwarded to `pr-comment`. |

| Output | Description |
|---|---|
| `cli-version` | The concrete CLI version installed. |
| `flitz-version` | The resolved Flitz release tag. |
| `sdk-path` | The absolute path of the installed SDK root. |
| `sdk-cache-hit` | Whether the SDK cache was restored. |
| `id` | The publish record's opaque id. |
| `page-url` | The landing page's download URL. |
| `deeplink` | The deeplink the landing page and the QR encode. |
| `bundle-url` | The `.flitz` bundle's download URL. |
| `comment-url` | The HTML URL of the pull-request comment. Empty on other events. |

On a pull request event the combined action always posts the comment, so the job needs
`pull-requests: write`. A comment failure after a successful publish fails the action; the publish
outputs are already set, and a later step with `if: always()` can read them.

## Failure modes

`install` embeds `install-cli` and `install-sdk`, and the combined action embeds `install`,
`publish`, and `pr-comment`, so every row applies to the actions that embed the detecting one.

| Condition | Detected by | Behavior |
|---|---|---|
| Unsupported runner OS or architecture | every action except `pr-comment` | Fails naming the detected pair and the supported set, before any other work. |
| `cli-version` malformed, or a Flitz release tag | `install-cli` | Fails naming the rejected value and the expected shape. |
| Requested CLI version not published | `install-cli` | Fails naming the version and the download host. |
| No CLI binary for the detected host in the manifest | `install-cli` | Fails naming the version and the host. |
| CLI checksum mismatch | `install-cli` | Fails with both digests; nothing is installed. |
| Installed CLI reports a different version | `install-cli` | Fails naming the expected and reported versions. |
| `flitz` not on `PATH` | `install-sdk`, `publish` | Fails naming `install-cli`. |
| No `flitz-version` and `flitz-path` names no readable pin | `install-sdk` | Fails naming the resolved path and the `flitz-version` input. |
| `flitz-version` malformed, or `latest` | `install-sdk` | Fails naming the rejected value; `latest` names `flitz sdk releases`. |
| `flitz-path` names no readable pin | `install` | Fails naming the resolved path and `flitz sdk use`, before any cache or network work. |
| `flitz-path` names no regular file | `publish` | Fails naming the resolved path and `flitz sdk use`. |
| `api-key` empty | `install-sdk`, `install`, `publish` | Fails naming the `api-key` input and the workflow secret that supplies it, before any network, cache, or build work. |
| Project directory outside the workspace | pub cache | Logs a notice naming the directory and skips the pub cache; the action continues. |
| Credential rejected, or the organization's license inactive | `flitz sdk install`, `flitz publish` | The CLI's not-authorized error, exit 3. |
| Release carries no SDK archive for the detected host | `flitz sdk install`, `flitz publish` | The CLI's configuration error naming the tag and the host, exit 1. |
| SDK archive checksum mismatch | `flitz sdk install`, `flitz publish` | The CLI's service error naming both digests, exit 4; the cache is left untouched. |
| `app` holds no Flutter application, or `schema` invalid | `flitz publish` | The CLI's usage error naming the path, the flag, or the field, exit 1. |
| Kernel, bytecode, or packaging failure, including a `target` or a `dart-define-from-file` path that names no file | `flitz publish` | The CLI's build error naming the failing tool, exit 5. |
| Bundle or page upload failed, or the write-once destination occupied | `flitz publish` | The CLI's service error, exit 4; a failed page upload names the landed bundle URL. No output is set. |
| `name`, `version-name`, or `comment` over its cap | `publish` | Logs a warning naming the input and its length, trims it to the cap, and continues. |
| Publish result missing a field | `publish` | Fails naming the field. |
| Event is not a pull request | `pr-comment` | Logs a notice naming the event, posts nothing, and succeeds. |
| `page-url` empty | `pr-comment` | Fails naming the input and the `publish` output that supplies it. |
| `key` malformed | `pr-comment` | Fails naming the rejected value and the allowed characters. |
| `gh` not on `PATH` | `pr-comment` | Fails naming `gh`. |
| Token lacks `pull-requests: write`, or the run comes from a fork | `pr-comment` | Fails naming the `pull-requests: write` permission. |
| An older comment cannot be deleted | `pr-comment` | Logs a warning naming its URL; the action succeeds. |

Failures from `flitz sdk install` and `flitz publish` are the CLI's own, reported with its message
convention and exit codes; the actions add no wrapper text and propagate the exit status as the
step's result.

## Secret handling

`api-key` is masked in the job log before its first use and reaches only the steps that run
`flitz sdk install` or `flitz publish`, as the `FLITZ_APIKEY` variable of each such step's
environment. It is never written to `$GITHUB_ENV`, never written to a file, never passed on a
command line, and never echoed. Once an action returns, no later step holds a credential from it.

`github-token` reaches only the `pr-comment` steps that call the GitHub API, as `GH_TOKEN`, under
the same rules.

`install-cli` handles no credential: every URL it fetches is public.
