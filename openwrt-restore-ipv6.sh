#!/bin/sh
set -eu

uci -q delete network.wan6.disabled || true
uci set network.lan.ip6assign='60'
uci set dhcp.lan.ra='server'
uci set dhcp.lan.dhcpv6='server'
uci -q delete dhcp.lan.ndp || true
uci commit network
uci commit dhcp

/etc/init.d/network reload
/etc/init.d/odhcpd restart
ifup wan6
