#!/bin/sh

_lib_8311 2>/dev/null || . /lib/8311.sh

pon_hash() {
    {
        ip li                  # 列出所有网络接口
        brctl show            # 显示网桥配置
    } | sha256sum | awk '{print $1}'
}
config_hash() {
	{
		fw_printenv -n 8311_uvlan 2>/dev/null
		fw_printenv -n 8311_mvlansource 2>/dev/null
		fw_printenv -n 8311_multicast_vlan 2>/dev/null
		fw_printenv -n 8311_vlan_trans_rules 2>/dev/null
		fw_printenv -n 8311_igmp_version 2>/dev/null
		fw_printenv -n 8311_vlandebug 2>/dev/null
		fw_printenv -n 8311_forceuvlan 2>/dev/null
		fw_printenv -n 8311_forcemerule 2>/dev/null
		fw_printenv -n 8311_force_me309 2>/dev/null
	} | sha256sum | awk '{print $1}'
}

FIX_ENABLED=$(fwenv_get_8311 "iopmask" "1")
[ "$FIX_ENABLED" -eq 0 ] 2>/dev/null && exit 0


FIXES=""
[ "$FIX_ENABLED" -eq 1 ] && FIXES="/usr/sbin/8311-fix-vlans.sh"

LAST_HASH=""
LAST_CFG_HASH=""

echo "8311 VLANs daemon: start monitoring" | to_console
sleep 5
while true ; do
	CMD="$FIXES"
	/usr/sbin/8311-tc-vlan-decode.sh > /tmp/8311-vlans
	if [ -n "$CMD" ] && [ -d "/sys/devices/virtual/net/gem-omci" ]; then
		HASH=$(pon_hash)
		CFG_HASH=$(config_hash)
		if [ "$HASH" != "$LAST_HASH" ] || [ "$CFG_HASH" != "$LAST_CFG_HASH" ]; then
			echo "8311 VLANs daemon: new configuration detected, ran fix-vlans script." | to_console
			flock /tmp/8311-fix-vlans.lock -c "$CMD" 2>&1
			LAST_HASH="$HASH"
			LAST_CFG_HASH="$CFG_HASH"
		fi
	fi

	sleep 5
done
