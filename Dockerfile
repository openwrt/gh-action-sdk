ARG CONTAINER=openwrt/sdk
ARG ARCH=mips_24kc
FROM $CONTAINER:$ARCH

LABEL "com.github.actions.name"="OpenWrt SDK"

ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
