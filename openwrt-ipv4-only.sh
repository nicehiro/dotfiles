#!/bin/sh
set -eu

uci set network.wan6.disabled='1'
uci -q delete network.lan.ip6assign || true
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'
uci commit network
uci commit dhcp

ifdown wan6 || true
/etc/init.d/network reload
/etc/init.d/odhcpd restart
