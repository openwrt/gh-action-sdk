# OpenWrt GitHub Action SDK

GitHub CI action to build packages via SDK using official OpenWrt SDK Docker
containers. This is primary used to test build OpenWrt repositories but can
also be used for downstream projects maintaining their own package
repositories.

## Example usage

The following YAML code can be used to build all packages of a repository and
store created `ipk` files as artifacts.

```yaml
name: Test Build

on:
  pull_request:
    branches:
      - master

jobs:
  build:
    name: ${{ matrix.arch }} build
    runs-on: ubuntu-latest
    strategy:
      matrix:
        arch:
          - x86_64
          - mips_24kc

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Build
        uses: openwrt/gh-action-sdk@composite
        env:
          ARCH: ${{ matrix.arch }}

      - name: Store packages
        uses: actions/upload-artifact@v2
        with:
          name: ${{ matrix.arch}}-packages
          path: bin/packages/${{ matrix.arch }}/packages/*.ipk
```

## Environmental variables

The action reads a few env variables:

* `ARCH` determines the used OpenWrt SDK Docker container.
* `ARTIFACTS_DIR` determines where built packages and build logs are saved.
  Defaults to the default working directory (`GITHUB_WORKSPACE`).
* `BUILD_LOG` stores build logs in `./logs`.
* `CONTAINER` can set other SDK containers than `openwrt/sdk`.
* `EXTRA_FEEDS` are added to the `feeds.conf`, where `|` are replaced by white
  spaces.
* `FEED_DIR` used in the created `feeds.conf` for the current repo. Defaults to
  the default working directory (`GITHUB_WORKSPACE`).
* `FEEDNAME` used in the created `feeds.conf` for the current repo. Defaults to
  `action`.
* `IGNORE_ERRORS` can ignore failing packages builds.
* `KEY_BUILD` can be a private Signify/`usign` key to sign the packages feed.
* `NO_DEFAULT_FEEDS` disable adding the default SDK feeds
* `NO_REFRESH_CHECK` disable check if patches need a refresh.
* `NO_SHFMT_CHECK` disable check if init files are formated
* `V` changes the build verbosity level.
