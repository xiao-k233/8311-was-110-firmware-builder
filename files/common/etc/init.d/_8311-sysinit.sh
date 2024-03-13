#!/bin/sh /etc/rc.common

_lib_8311 2>/dev/null || . /lib/8311.sh

START=18

start() {
	CONSOLE_EN=$(get_8311_console_en)
	DYING_GASP_EN=$(get_8311_dying_gasp_en)

	if [ "$CONSOLE_EN" != "1" ]; then
		echo "Disabling serial console output, set fwenv 8311_console_en to 1 to re-enable" | to_console
		UART_TX="0"
	else
		UART_TX="1"
	fi

	if [ "$DYING_GASP_EN" = "1" ]; then
		echo "Enabling dying gasp. This will disable serial console input, set fwenv 8311_dying_gasp_en to 0 to re-enable" | to_console
		UART_RX="0"
	else
		UART_RX="1"
	fi

	# Delay to give enough time to write to console if UART TX is being disabled
	[ "$UART_TX" -eq 0 ] && sleep 1

	[ -e "/sys/class/gpio/gpio508" ] || echo 508 > "/sys/class/gpio/export"
	echo "out" > "/sys/class/gpio/gpio508/direction"
	echo "$UART_RX" > "/sys/class/gpio/gpio508/value"

	[ -e "/sys/class/gpio/gpio510" ] || echo 510 > "/sys/class/gpio/export"
	echo "out" > "/sys/class/gpio/gpio510/direction"
	echo "$UART_TX" > "/sys/class/gpio/gpio510/value"

	# Move cursor to begining of line to hide garbage created by setting UART_TX
	[ "$UART_TX" = "1" ] && echo -n -e "\r" | to_console


	# Custom hostname suppport
	SYS_HOSTNAME=$(get_8311_hostname)
	[ -n "$SYS_HOSTNAME" ] && set_8311_hostname "$SYS_HOSTNAME"

	# fwenv for setting the root account password hash
	ROOT_PWHASH=$(get_8311_root_pwhash)
	[ -n "$ROOT_PWHASH" ] && set_8311_root_pwhash "$ROOT_PWHASH"

	# 8311 MOD: set LCT MAC
	LCT_MAC=$(get_8311_lct_mac)
	set_8311_lct_mac "$LCT_MAC"

	# 8311 MOD: set IP Host MAC
	IPHOST_MAC=$(get_8311_iphost_mac)
	set_8311_iphost_mac "$IPHOST_MAC"
}

boot() {
	# 8311 MOD: Remove persistent root
	_8311_check_persistent_root

	# 8311 MOD: persistent server and client key
	DROPBEAR_RSA_KEY=$(uci -qc /ptconf/8311 get dropbear.rsa_key.value)
	DROPBEAR_PUBKEY=$(uci -qc /ptconf/8311 get dropbear.public_key.value)
	DROPBEAR_PUBKEY_BASE64=$(uci -qc /ptconf/8311 get dropbear.public_key.encryflag)

	[ -f "/ptconf/8311/dropbear" ] && rm -fv "/ptconf/8311/dropbear"
	mkdir -p /ptconf/8311 /ptconf/8311/dropbear /ptconf/8311/.ssh
	chmod 700 /ptconf/8311/dropbear /ptconf/8311/.ssh
	ln -fsv /ptconf/8311/.ssh/authorized_keys /ptconf/8311/dropbear/authorized_keys

	if [ -n "$DROPBEAR_RSA_KEY" ]; then
		echo "Migrating dropbear.rsa_key to /ptconf/8311/dropbear/dropbear_rsa_host_key" | tee -a /dev/console

		echo "$DROPBEAR_RSA_KEY" | base64 -d > /ptconf/8311/dropbear/dropbear_rsa_host_key
		chmod 600 /ptconf/8311/dropbear/dropbear_rsa_host_key
	fi

	if [ -n "$DROPBEAR_PUBKEY" ]; then
		echo "Migrating dropbear.public_key to /ptconf/8311/.ssh/authorized_keys" | tee -a /dev/console

		if [ "$DROPBEAR_PUBKEY_BASE64" = "1" ]; then
			echo "$DROPBEAR_PUBKEY" | base64 -d > /ptconf/8311/.ssh/authorized_keys
		else
			echo "$DROPBEAR_PUBKEY" > /ptconf/8311/.ssh/authorized_keys
		fi

		chmod 600 /ptconf/8311/.ssh/authorized_keys
	fi

	start "$@"

	# 8311 MOD: start rx_los script
	/usr/sbin/8311-rx_los.sh &
}
