#!/bin/sh

set -ef

FEEDNAME="${FEEDNAME:-action}"

cd /home/build/openwrt/

echo "src-link $FEEDNAME $GITHUB_WORKSPACE/" > feeds.conf
cat feeds.conf.default >> feeds.conf

#shellcheck disable=SC2153
for EXTRA_FEED in $EXTRA_FEEDS; do
	echo "$EXTRA_FEED" | tr '|' ' ' >> feeds.conf
done

./scripts/feeds update -a
if [ -z "$PACKAGES" ]; then
	./scripts/feeds install -d y -p "$FEEDNAME" -f -a
else
	# shellcheck disable=SC2086
	./scripts/feeds install -d y -p "$FEEDNAME" -f $PACKAGES
fi

make defconfig
make \
	BUILD_LOG="$BUILD_LOG" \
	CONFIG_SIGNED_PACKAGES="$SIGNED_PACKAGES" \
	IGNORE_ERRORS="$IGNORE_ERRORS" \
	V="$V" \
	-j "$(nproc)"

mv bin/ "$GITHUB_WORKSPACE/"

if [ -d logs/ ]; then
	mv logs/ "$GITHUB_WORKSPACE/"
fi
