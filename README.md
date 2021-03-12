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
        uses: aparcar/action-openwrt-sdk@composite
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
* `BUILD_LOG` stores build logs in `./logs`.
* `CONTAINER` can set other SDK containers than `openwrt/sdk`.
* `EXTRA_FEEDS` are added to the `feeds.conf`, where `|` are replaced by white
  spaces.
* `FEEDNAME` used in the created `feeds.conf` for the current repo. Defaults to
  `action`.
* `IGNORE_ERRORS` can ignore failing packages builds.
* `KEY_BUILD` can be a private Signify/`usign` key to sign the packages feed.
* `NO_REFRESH_CHECK` disable check if patches need a refresh.
* `V` changes the build verbosity level.
