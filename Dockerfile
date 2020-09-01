ARG ARCH=mips_24kc
FROM openwrtorg/sdk:$ARCH

LABEL "com.github.actions.name"="OpenWrt SDK"

ADD entrypoint.sh /

USER root

ENTRYPOINT ["/entrypoint.sh"]
