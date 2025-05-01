#!/bin/bash

# 加载通用函数
[ -f "mods/common-functions.sh" ] && . mods/common-functions.sh

_mod_info "Starting basic modifications..."

if ls packages/basic/*.ipk &>/dev/null; then
	for IPK in packages/basic/*.ipk; do
		_mod_info "Extracting '$(basename "$IPK")' to '$ROOT_DIR'."
		if [ "$VERBOSE" = true ]; then
			tar xfz "$IPK" -O -- "./data.tar.gz" | tar xvz -C "$ROOT_DIR/"
		else
			tar xfz "$IPK" -O -- "./data.tar.gz" | tar xz -C "$ROOT_DIR/"
		fi
	done
fi

UCI_FW_RULES="$ROOT_DIR/etc/uci-defaults/26-firewall-rules"
_mod_info "Updating firewall rules in $UCI_FW_RULES"

UCI_FW_RULES_HEAD=$(grep -B99999999 '/usr/sbin/ptp4l' "$UCI_FW_RULES" | head -n -1)
UCI_FW_RULES_FOOT=$(grep -A99999999 '/usr/sbin/ptp4l' "$UCI_FW_RULES")

mod_file_change "$UCI_FW_RULES" "Updating firewall rules" "Adding HTTP and HTTPS rules"
echo "$UCI_FW_RULES_HEAD" > "$UCI_FW_RULES"

cat >> "$UCI_FW_RULES" <<'HTTP_RULES'

if [ -f /usr/sbin/uhttpd ]; then
	uci batch << EOF
		add firewall rule
		set firewall.@rule[-1].name='Allow-HTTP'
		set firewall.@rule[-1].src='lan'
		set firewall.@rule[-1].proto='tcp'
		set firewall.@rule[-1].dest_port='80'
		set firewall.@rule[-1].target='ACCEPT'
EOF

	if [ -f /usr/sbin/px5g ]; then
		uci batch << EOF
			add firewall rule
			set firewall.@rule[-1].name='Allow-HTTPs'
			set firewall.@rule[-1].src='lan'
			set firewall.@rule[-1].proto='tcp'
			set firewall.@rule[-1].dest_port='443'
			set firewall.@rule[-1].target='ACCEPT'
EOF
    fi
fi

HTTP_RULES

echo "$UCI_FW_RULES_FOOT" >> "$UCI_FW_RULES"

_mod_info "Patching dropbear init script to run in background"
mod_file_change "$ROOT_DIR/etc/init.d/dropbear" "Modifying dropbear init script" "Ensuring dropbear starts in background"
sed -r 's#(\s+start \"\$@\")$#\1 \&#' -i "$ROOT_DIR/etc/init.d/dropbear"

_mod_info "Updating inittab configuration"
INITTAB="$ROOT_DIR/etc/inittab"
mod_file_change "$INITTAB" "Modifying inittab" "Adding askconsole and disabling ttyLTQ0"
sed -r 's/^(ttyLTQ0)/#\1/g' -i "$INITTAB"
echo "::askconsole:/bin/login" >> "$INITTAB"

_mod_info "Creating 8311 Lua version module"
LUA8311="$ROOT_DIR/usr/lib/lua/8311"
mod_mkdir "$LUA8311"
mod_file_change "$LUA8311/version.lua" "Creating Lua version file" "Adding firmware variant and version information"
cat > "$LUA8311/version.lua" <<8311VER
module "8311.version"

variant = "${FW_VARIANT}"
version = "${FW_VERSION}"
revision = "${FW_REVISION}"
8311VER

_mod_info "Cleaning up unnecessary backup files"
mod_rm "$ROOT_DIR/etc/mibs/prx300_1U.ini.bk"

_mod_info "Patching LuCI menu files to remove unsupported options"
LUCI_MENUD_SYSTEM_JSON="$ROOT_DIR/usr/share/luci/menu.d/luci-mod-system.json"
mod_file_change "$LUCI_MENUD_SYSTEM_JSON" "Patching system menu" "Removing unsupported system menu options"
LUCI_MENUD_SYSTEM=$(jq 'delpaths([["admin/system/flash"], ["admin/system/crontab"], ["admin/system/startup"], ["admin/system/admin/dropbear"], ["admin/system/system"]])' "$LUCI_MENUD_SYSTEM_JSON")
echo "$LUCI_MENUD_SYSTEM" > "$LUCI_MENUD_SYSTEM_JSON"

LUCI_MENUD_STATUS_JSON="$ROOT_DIR/usr/share/luci/menu.d/luci-mod-status.json"
mod_file_change "$LUCI_MENUD_STATUS_JSON" "Patching status menu" "Removing unsupported status menu options"
LUCI_MENUD_STATUS=$(jq 'delpaths([["admin/status/iptables"], ["admin/status/processes"]])' "$LUCI_MENUD_STATUS_JSON")
echo "$LUCI_MENUD_STATUS" > "$LUCI_MENUD_STATUS_JSON"

_mod_info "Patching LuCI RPCD to persist root password"
RPCD_LUCI="$ROOT_DIR/usr/libexec/rpcd/luci"
mod_file_change "$RPCD_LUCI" "Patching RPCD" "Adding persistence for root password"
sed -r 's#passwd %s >/dev/null 2>&1#passwd %s \&>/dev/null \&\& /usr/sbin/8311-persist-root-password.sh \&>/dev/null#' -i "$RPCD_LUCI"

_mod_info "Basic modifications completed"
