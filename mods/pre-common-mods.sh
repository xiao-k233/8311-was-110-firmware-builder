#!/bin/bash

# 加载通用函数
[ -f "mods/common-functions.sh" ] && . mods/common-functions.sh

_mod_info "Starting pre-common modifications..."

# 创建8311.sh库文件
LIB8311="$ROOT_DIR/lib/8311.sh"
mod_file_change "$LIB8311" "Creating 8311.sh library" "Setting up MAC address handling functions"

cat > "$LIB8311" <<'LIB8311_CONTENT'
#!/bin/bash
# 8311 Support Library

_lib_8311() {
	return 0
}

# Get the real SoC MAC address (fixed to match original hardware OUI)
get_8311_base_mac() {
	local mac_addr="$(cat /proc/device-tree/ocp/ethernet@48480000/local-mac-address 2>/dev/null | hexdump -ve '1/1 "%.2X:"' 2>/dev/null | sed 's/\:$//')"
	[ -n "$mac_addr" ] || mac_addr="$(cat /sys/devices/ocp@40000000/ethernet@48480000/net/eth0_0/address 2>/dev/null)"
	[ -n "$mac_addr" ] || mac_addr="$(cat /sys/class/net/eth0_0/address 2>/dev/null)"
	[ -n "$mac_addr" ] || mac_addr="$(fw_printenv -n ethaddr 2>/dev/null)"
	[ -n "$mac_addr" ] || mac_addr="$(hexdump -ve '1/1 "%.2X:"' /sys/bus/platform/devices/18100000.ponmbox/eeprom50 2>/dev/null | head -n 1 | cut -c1-14)50:00"
	[ -n "$mac_addr" ] || mac_addr="00:00:00:00:00:00"
	echo "$mac_addr"
}
LIB8311_CONTENT

chmod +x "$LIB8311"
_mod_info "8311.sh library created successfully"

# 备份原始升级脚本
echo "Backing up secure_upgrade.sh..."
if [ "$VERBOSE" = true ]; then
    mv -fv "$ROOT_DIR/sbin/secure_upgrade.sh" "$ROOT_DIR/sbin/secure_upgrade-original.sh"
else
    mv -f "$ROOT_DIR/sbin/secure_upgrade.sh" "$ROOT_DIR/sbin/secure_upgrade-original.sh"
fi
_mod_info "Backed up original secure_upgrade.sh"

_mod_info "Pre-common modifications completed"

mv -fv "$ROOT_DIR/sbin/secure_upgrade.sh" "$ROOT_DIR/sbin/secure_upgrade-original.sh"

if ls packages/remove/*.list &>/dev/null; then
	for LIST in packages/remove/*.list; do
		echo "Removing files from '$LIST'"
		FILES=$(cat "$LIST" | grep -v '/$')

		IFS=$'\n'
		for FILE in $(cat "$LIST" | grep -v '/$'); do
			rm -fv "$ROOT_DIR/$FILE" || true
		done

		for DIR in $(cat "$LIST" | grep '/$' | sort -r -V); do
			DIR="$ROOT_DIR/$DIR"
			CONTENTS=$(find "$DIR" -mindepth 1 -maxdepth 1 2>/dev/null) && [ -z "$CONTENTS" ] && rmdir -v "$DIR" || true
		done
		IFS=
	done
fi
