#!/bin/bash

# 加载通用函数
[ -f "mods/common-functions.sh" ] && . mods/common-functions.sh

_mod_info "Starting common modifications..."

BANNER="$ROOT_DIR/etc/banner"
mod_file_change "$BANNER" "Updating banner" "Adding 8311 Community Firmware MOD banner"
sed -E "s#(^\s+OpenWrt\s+.+$)#\1\n\n 8311 Community Firmware MOD [$FW_VARIANT] - $FW_VERSION ($FW_REVISION)\n https://github.com/xiao-k233/8311-was-110-firmware-builder#g" -i "$BANNER"

UBIMGVARS="$ROOT_DIR/sbin/uboot_img_vars.sh"
echo "Patching '$UBIMGVARS'..."
_mod_info "Modifying uboot_img_vars.sh to handle custom variables"

UBIMGVARS_HEAD=$(grep -B99999999  -P '^_get_uboot_vars\(\)' "$UBIMGVARS")
UBIMGVARS_FOOT=$(grep -B3 -A99999999 -P '^get_uboot_vars\(\)' "$UBIMGVARS")

echo "$UBIMGVARS_HEAD" > "$UBIMGVARS"
cat >> "$UBIMGVARS" <<'UBIMGVARS_MOD'
	vars="active_bank:8311_override_active img_validA:8311_sw_valA img_validB:8311_sw_valB img_versionA:8311_sw_verA img_versionB:8311_sw_verB commit_bank:8311_override_commit img_activate:8311_override_activate"

	printf "{"
	for var in $vars; do
		v=$(echo "$var" | cut -d: -f1)
		o=$(echo "$var" | cut -d: -f2)

		val=$([ -n "$o" ] && fw_printenv -n "$o" 2>/dev/null || fw_printenv -n "$v" 2>/dev/null)
		printf '"%s":"%s"' "$v" "$val"
		[ "$v" != "img_activate" ] && printf ","
	done
	printf "}\n"
UBIMGVARS_MOD
echo "$UBIMGVARS_FOOT" >> "$UBIMGVARS"
_mod_info "uboot_img_vars.sh patched successfully"

VEIP_MIB="$ROOT_DIR/etc/mibs/prx300_1V.ini"
mod_file_change "$VEIP_MIB" "Modifying VEIP MIB" "Enabling LCT Management interface in VEIP mode"

VEIP_HEAD=$(grep -P -B99999999 '^# Virtual Ethernet Interface Point$' "$VEIP_MIB" | head -n -1)
VEIP_FOOT=$(grep -P -A99999999 '^# Virtual Ethernet Interface Point$' "$VEIP_MIB")

echo "$VEIP_HEAD" > "$VEIP_MIB"
# Enable LCT Management interface in VEIP mode
cat >> "$VEIP_MIB" <<'VEIP_LCT'

# PPTP Ethernet UNI
? 11 0x0101 0 0 0 0x00 1 1 0 2000 0 0xffff 0 0 0 0 0

VEIP_LCT
echo "$VEIP_FOOT" >> "$VEIP_MIB"
_mod_info "VEIP MIB modified successfully"

# Copy custom files
echo "Copying custom files..."
if [ "$VERBOSE" = true ]; then
    cp -va "files/common/." "$ROOT_DIR/"
    cp -va "files/${FW_VARIANT}/." "$ROOT_DIR/"
else
    cp -a "files/common/." "$ROOT_DIR/"
    cp -a "files/${FW_VARIANT}/." "$ROOT_DIR/"
fi
_mod_info "Custom files copied to rootfs"

mod_file_change "$ROOT_DIR/lib/preinit/06_create_rootfs_data" "Modifying rootfs_data creation" "Always try to create rootfs_data at ID 6 first"
sed -r 's#^(\s+)(.+ )(\|\| ubimkvol /dev/ubi0 -N rootfs_data)( .+$)#\1\# 8311 MOD: Always try to create rootfs_data at ID 6 first\n\1\2\3 -n 6\4 \3\4#g' -i "$ROOT_DIR/lib/preinit/06_create_rootfs_data"

# Remove dumb defaults for loid and lpwd
CONFIG_OMCI="$ROOT_DIR/etc/config/omci"
mod_file_change "$CONFIG_OMCI" "Removing default LOID/LPWD" "Removing unnecessary default credentials"
CONFIG_OMCI_FILTERED=$(grep -v -E '(loid|lpwd)' "$CONFIG_OMCI")
echo "$CONFIG_OMCI_FILTERED" > "$CONFIG_OMCI"

RC_LOCAL="$ROOT_DIR/etc/rc.local"
mod_file_change "$RC_LOCAL" "Modifying rc.local" "Adding delayed omcid start for failsafe mode"

RC_LOCAL_HEAD=$(grep -P -B99999999 '^exit 0$' "$RC_LOCAL" | head -n -1)
RC_LOCAL_FOOT=$(grep -P -A99999999 '^exit 0$' "$RC_LOCAL")

DEFAULT_DELAY=15
MIN_DELAY=10
_mod_info "Using failsafe DEFAULT_DELAY=$DEFAULT_DELAY, MIN_DELAY=$MIN_DELAY"

# 添加Failsafe处理
echo "$RC_LOCAL_HEAD" > "$RC_LOCAL"
cat >> "$RC_LOCAL" <<FAILSAFE

# 8311 MOD: Failsafe, delay omcid start
DELAY=\$(fw_printenv -n 8311_failsafe_delay 2>/dev/null || echo "$DEFAULT_DELAY")
[ "\$DELAY" -ge $MIN_DELAY ] 2>/dev/null || DELAY=$MIN_DELAY
[ "\$DELAY" -le "300" ] || DELAY=300
sleep "\$DELAY" && [ ! -f /root/.failsafe ] && [ ! -f /tmp/.failsafe ] && [ ! -f /ptconf/.failsafe ] && /etc/init.d/omcid.sh start

FAILSAFE
echo "$RC_LOCAL_FOOT" >> "$RC_LOCAL"
chmod +x "$RC_LOCAL"
_mod_info "rc.local modified with failsafe delay=$DEFAULT_DELAY"

LIB_PON_SH="$ROOT_DIR/lib/pon.sh"
mod_file_change "$LIB_PON_SH" "Modifying pon.sh" "Updating MAC address handling"

LIB_PON_SH_HEAD=$(grep -P -m 1 -B99999999 '^$' "$LIB_PON_SH")
LIB_PON_SH_TOP=$(grep -P -m 1 -A99999999 '^$' "$LIB_PON_SH" | grep -P -B99999999 '^pon_base_mac_get\(\)')
LIB_PON_SH_FOOT=$(grep -P -A99999999 '^\s+echo \$mac_addr$' "$LIB_PON_SH")

echo "$LIB_PON_SH_HEAD" > "$LIB_PON_SH"
cat >> "$LIB_PON_SH" <<'PONSHLIB'

_lib_8311 2>/dev/null || . /lib/8311.sh
PONSHLIB
echo "$LIB_PON_SH_TOP" >> "$LIB_PON_SH"
cat >> "$LIB_PON_SH" <<'PONSHMAC'
	# 8311 MOD: Use proper base MAC
	local mac_addr="$(get_8311_base_mac)"

PONSHMAC
echo "$LIB_PON_SH_FOOT" >> "$LIB_PON_SH"
_mod_info "pon.sh modified to use proper base MAC"

echo "Installing VLAN fix scripts..."
if [ "$VERBOSE" = true ]; then
    cp -fv "8311-xgspon-bypass/8311-fix-vlans.sh" "$ROOT_DIR/usr/sbin/"
    ln -fsv "/usr/sbin/8311-fix-vlans.sh" "$ROOT_DIR/root/8311-fix-vlans.sh"
else
    cp -f "8311-xgspon-bypass/8311-fix-vlans.sh" "$ROOT_DIR/usr/sbin/"
    ln -fs "/usr/sbin/8311-fix-vlans.sh" "$ROOT_DIR/root/8311-fix-vlans.sh"
fi
_mod_info "VLAN fix scripts installed"

# 创建crontabs目录并设置根用户的crontab文件
if [ "$VERBOSE" = true ]; then
    mkdir -pv "$ROOT_DIR/etc/crontabs"
else
    mkdir -p "$ROOT_DIR/etc/crontabs"
fi

touch "$ROOT_DIR/etc/crontabs/root"
_mod_info "Created empty root crontab"

# 修改omcid.sh启动脚本，避免自动启动
mod_file_change "$ROOT_DIR/etc/init.d/omcid.sh" "Modifying omcid.sh" "Preventing auto-start and redirecting output"
sed -r 's#^(\s+)(start.+)$#\1\# 8311 MOD: Do not auto start omcid\n\1\# \2#g' -i "$ROOT_DIR/etc/init.d/omcid.sh"
sed -r 's/(stdout|stderr)=2/\1=1/g' -i "$ROOT_DIR/etc/init.d/omcid.sh"
_mod_info "omcid.sh modified to prevent auto-start"

# 修改光模块配置
CONFIG_OPTIC="$ROOT_DIR/etc/config/optic"
mod_file_change "$CONFIG_OPTIC" "Modifying optic config" "Setting tx_en_mode to 0 and tx_pup_mode to 1"
sed -r "s#(option 'tx_en_mode' ').*(')#\10\2#" -i "$CONFIG_OPTIC"
sed -r "s#(option 'tx_pup_mode' ').*(')#\11\2#" -i "$CONFIG_OPTIC"

OPTICDB_DEFAULT="$ROOT_DIR/etc/optic-db/default"
mod_file_change "$OPTICDB_DEFAULT" "Modifying optic-db default" "Setting tx_en_mode to 0, tx_pup_mode to 1, and removing dg_dis"
sed -r "s#(option 'tx_en_mode' ').*(')#\10\2#" -i "$OPTICDB_DEFAULT"
sed -r "s#(option 'tx_pup_mode' ').*(')#\11\2#" -i "$OPTICDB_DEFAULT"
sed "/option 'dg_dis'/d" -i "$OPTICDB_DEFAULT"
_mod_info "Optic configurations modified"

# 创建ptconf目录
if [ "$VERBOSE" = true ]; then
    mkdir -pv "$ROOT_DIR/ptconf"
else
    mkdir -p "$ROOT_DIR/ptconf"
fi
_mod_info "Created ptconf directory"

# 修改SFP i2c模块加载顺序，并添加虚拟EEPROM内容的hack
echo "Setting up SFP EEPROM hack..."
if [ "$VERBOSE" = true ]; then
    rm -fv "$ROOT_DIR/etc/modules.d/20-pon-sfp-i2c"
else
    rm -f "$ROOT_DIR/etc/modules.d/20-pon-sfp-i2c"
fi
ln -sf "/sys/bus/platform/devices/18100000.ponmbox/eeprom50" "$ROOT_DIR/lib/firmware/sfp_eeprom0_hack.bin"
_mod_info "SFP EEPROM hack setup completed"

# 安装通用包
if ls packages/common/busybox_*.ipk &>/dev/null; then
    echo "Removing all links to busybox..."
    if [ "$VERBOSE" = true ]; then
        find -L "$ROOT_DIR/" -samefile "$ROOT_DIR/bin/busybox" -exec rm -fv {} +
    else
        find -L "$ROOT_DIR/" -samefile "$ROOT_DIR/bin/busybox" -exec rm -f {} +
    fi
    _mod_info "Removed all links to busybox"
fi

if ls packages/common/*.ipk &>/dev/null; then
    echo "Installing common packages..."
    for IPK in packages/common/*.ipk; do
        if [ "$VERBOSE" = true ]; then
            echo "Extracting '$(basename "$IPK")' to '$ROOT_DIR'."
            tar xfz "$IPK" -O -- "./data.tar.gz" | tar xvz -C "$ROOT_DIR/"
        else
            tar xfz "$IPK" -O -- "./data.tar.gz" | tar xz -C "$ROOT_DIR/"
        fi
        _mod_info "Installed package $(basename "$IPK")"
    done
fi

# 修复来自较新OpenWRT的dropbear初始化脚本
DROPBEAR="$ROOT_DIR/etc/init.d/dropbear"
mod_file_change "$DROPBEAR" "Fixing dropbear init script" "Updating for compatibility with newer OpenWRT"
sed -r 's/^extra_command "killclients" .+$/EXTRA_COMMANDS="killclients"\nEXTRA_HELP="    killclients Kill ${NAME} processes except servers and yourself"/' -i "$DROPBEAR"

# 设置自定义dropbear配置链接
echo "Setting up dropbear and SSH configurations..."
if [ "$VERBOSE" = true ]; then
    rm -rfv "$ROOT_DIR/etc/dropbear"
    ln -fsv "/ptconf/8311/.ssh" "$ROOT_DIR/root/.ssh"
    ln -fsv "/ptconf/8311/dropbear" "$ROOT_DIR/etc/dropbear"
    ln -fsv "../init.d/sysntpd" "$ROOT_DIR/etc/rc.d/S98sysntpd"
else
    rm -rf "$ROOT_DIR/etc/dropbear"
    ln -fs "/ptconf/8311/.ssh" "$ROOT_DIR/root/.ssh"
    ln -fs "/ptconf/8311/dropbear" "$ROOT_DIR/etc/dropbear"
    ln -fs "../init.d/sysntpd" "$ROOT_DIR/etc/rc.d/S98sysntpd"
fi
_mod_info "SSH and dropbear configurations set up"

_mod_info "Common modifications completed successfully"
