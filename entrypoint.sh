#!/bin/bash

set -ef

FEEDNAME="${FEEDNAME:-action}"
BUILD_LOG="${BUILD_LOG:-1}"

cd /home/build/openwrt/

if [ -n "$KEY_BUILD" ]; then
	echo "$KEY_BUILD" > key-build
	SIGNED_PACKAGES="y"
fi

echo "src-link $FEEDNAME /feed/" > feeds.conf

if [ -z "$NO_DEFAULT_FEEDS" ]; then
	sed \
		-e 's,https://git.openwrt.org/feed/,https://github.com/openwrt/,' \
		-e 's,https://git.openwrt.org/openwrt/,https://github.com/openwrt/,' \
		-e 's,https://git.openwrt.org/project/,https://github.com/openwrt/,' \
		feeds.conf.default >> feeds.conf
fi

#shellcheck disable=SC2153
for EXTRA_FEED in $EXTRA_FEEDS; do
	echo "$EXTRA_FEED" | tr '|' ' ' >> feeds.conf
done

cat feeds.conf

./scripts/feeds update -a > /dev/null
make defconfig > /dev/null

if [ -z "$PACKAGES" ]; then
	# compile all packages in feed
	./scripts/feeds install -d y -p "$FEEDNAME" -f -a
	make \
		BUILD_LOG="$BUILD_LOG" \
		SIGNED_PACKAGES="$SIGNED_PACKAGES" \
		IGNORE_ERRORS="$IGNORE_ERRORS" \
		V="$V" \
		-j "$(nproc)"
else
	# compile specific packages with checks
	for PKG in $PACKAGES; do
		./scripts/feeds install -p "$FEEDNAME" -f "$PKG"
		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			"package/$PKG/download" V=s || \
				exit $?

		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			"package/$PKG/check" V=s 2>&1 | \
				tee logtmp

		RET=${PIPESTATUS[0]}

		if [ "$RET" -ne 0 ]; then
			echo_red   "=> Package check failed: $RET)"
			exit "$RET"
		fi

		badhash_msg="HASH does not match "
		badhash_msg+="|HASH uses deprecated hash,"
		badhash_msg+="|HASH is missing,"
		if grep -qE "$badhash_msg" logtmp; then
			echo "Package HASH check failed"
			exit 1
		fi

		PATCHES_DIR=$(find /feed -path "*/$PKG/patches")
		if [ -d "$PATCHES_DIR" ] && [ -z "$NO_REFRESH_CHECK" ]; then
			make \
				BUILD_LOG="$BUILD_LOG" \
				IGNORE_ERRORS="$IGNORE_ERRORS" \
				"package/$PKG/refresh" V=s || \
					exit $?

			if ! git -C "$PATCHES_DIR" diff --quiet -- .; then
				echo "Dirty patches detected, please refresh and review the diff"
				git -C "$PATCHES_DIR" checkout -- .
				exit 1
			fi
		fi

		FILES_DIR=$(find /feed -path "*/$PKG/files")
		if [ -d "$FILES_DIR" ] && [ -z "$NO_SHFMT_CHECK" ]; then
			find "$FILES_DIR" -name "*.init" -exec shfmt -w -sr -s '{}' \;
			if ! git -C "$FILES_DIR" diff --quiet -- .; then
				echo "init script must be formatted. Please run through shfmt -w -sr -s"
				git -C "$FILES_DIR" checkout -- .
				exit 1
			fi
		fi

	done

	make \
		-f .config \
		-f tmp/.packagedeps \
		-f <(echo "\$(info \$(sort \$(package-y) \$(package-m)))"; echo -en "a:\n\t@:") \
			| tr ' ' '\n' > enabled-package-subdirs.txt

	for PKG in $PACKAGES; do
		if ! grep -m1 -qE "(^|/)$PKG$" enabled-package-subdirs.txt; then
			echo "::warning file=$PKG::Skipping $PKG due to unsupported architecture"
			continue
		fi

		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			V="$V" \
			-j "$(nproc)" \
			"package/$PKG/compile" || {
				RET=$?
				make "package/$PKG/compile" V=s -j 1
				exit $RET
			}
	done
fi

if [ -d bin/ ]; then
	mv bin/ /artifacts/
fi

if [ -d logs/ ]; then
	mv logs/ /artifacts/
fi
