#!/bin/sh

set -ef

FEEDNAME="${FEEDNAME:-action}"
BUILD_LOG="${BUILD_LOG:-1}"

cd /home/build/openwrt/

echo "src-link $FEEDNAME $GITHUB_WORKSPACE/" > feeds.conf
cat feeds.conf.default >> feeds.conf

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
		CONFIG_SIGNED_PACKAGES="$SIGNED_PACKAGES" \
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
			"package/$PKG/download" V=s

		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			"package/$PKG/check" V=s 2>&1

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

mv bin/ "$GITHUB_WORKSPACE/"

if [ -d logs/ ]; then
	mv logs/ "$GITHUB_WORKSPACE/"
fi
