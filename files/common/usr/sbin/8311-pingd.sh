#!/bin/sh

_lib_8311 2>/dev/null || . /lib/8311.sh

while true ; do
	PINGD_ENABLED=$(fwenv_get_8311 "pingd" "1")
	# Ping host to help management work
	PING_HOST=$(get_8311_ping_host)

	echo "Starting ping to: $PING_HOST" | to_console

	if [ "$PINGD_ENABLED" -ne "0" ] 2>/dev/null; then
		ping -i 5 "$PING_HOST" &> /dev/null < /dev/null
		ping_pid=$!
		# 等待指定 PID 的进程完成
		wait $ping_pid
		# 获取返回值（0=成功，非0=失败）
		ping_result=$?
		if [ "$ping_result" -eq 1 ]; then
			echo "100% packet loss detected,try to restart lct port" | to_console
			ifup "lct"
			[ "$LCT_VLAN" -gt 0 ] && ifup "mgmt"
		fi

		sleep 5
	else
		sleep 30
	fi
done
