![logo](resource/png/logo.png)

# Kawa [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/Windemiatrix/kawa/master/LICENSE) [![GitHub release](https://img.shields.io/github/release/Windemiatrix/kawa.svg)](https://github.com/Windemiatrix/kawa/releases)

A macOS input source switcher with user-defined shortcuts.

This is a personal fork of [hatashiro/kawa](https://github.com/hatashiro/kawa).
Upstream is unmaintained; the fork ships the upstream changes that never got
released and adds its own release pipeline:

- Universal binary (arm64 + x86_64), built and released via GitHub Actions.
- Distribution through the `windemiatrix/tap` Homebrew tap (cask, ad-hoc signed).
- Requires macOS 10.15 (Catalina) or later.

## Demo

[![demo](https://cloud.githubusercontent.com/assets/1013641/9109734/d73505e4-3c72-11e5-9c71-49cdf4a484da.gif)](http://vimeo.com/135542587)

## Install

### Using [Homebrew](https://brew.sh/)

`Kawa.app` is ad-hoc signed and not notarized, so Gatekeeper blocks a
quarantined copy. Install without quarantine:

```shell
brew install --cask --no-quarantine windemiatrix/tap/kawa
```

### Manually

The prebuilt binaries can be found in
[Releases](https://github.com/Windemiatrix/kawa/releases).

Unzip `Kawa.zip`, move `Kawa.app` to `Applications`, and clear the quarantine
attribute:

```shell
xattr -cr /Applications/Kawa.app
```

## Development

We use [Carthage](https://github.com/Carthage/Carthage) as a dependency
manager; install it with `brew install carthage`.

```shell
git clone git@github.com:Windemiatrix/kawa.git
cd kawa
make bootstrap
```

`make bootstrap` builds the dependencies from source (`--no-use-binaries`) so
the frameworks come out universal. After that, open the project with Xcode or
build from the command line:

```shell
make help    # list all targets
make build   # Release build, universal arm64 + x86_64
make lint    # swiftlint + shellcheck
```

## Release

The version source of truth is `kawa/Info.plist`:

```shell
make bump-version VERSION=X.Y.Z
```

Commit the bump together with a `## X.Y.Z (date)` section in `CHANGELOG.md`,
then run the manual `Release` workflow on GitHub Actions. It builds the
universal binary, creates the `vX.Y.Z` tag and the GitHub release, and updates
the Homebrew cask in `Windemiatrix/homebrew-tap`. `make status` shows whether
`Info.plist`, the latest GitHub release, and the cask are in sync.

First-release prerequisites: the `Windemiatrix/homebrew-tap` repository must
exist, and the `TAP_GITHUB_TOKEN` repository secret must hold a token with
write access to it.

A published release is never rolled back on a failed cask bump; `make status`
shows the lag. To recover without cutting a new version, update the cask in a
tap clone manually: `scripts/update-cask.sh <version> <sha256> <tap-clone>`
(the sha256 is in the release's `Kawa.zip.sha256` asset), then commit and
push the tap.

## License

Kawa is released under the [MIT License](LICENSE).
