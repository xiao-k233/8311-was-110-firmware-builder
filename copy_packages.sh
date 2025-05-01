#!/bin/bash

# 公共包列表（对basic版本有效）
COMMON_PACKAGES=(
	"busybox"
	"dropbear"
	"fping"
	"htop"
	"libc"
	"libncurses6"
	"libpcre2"
	"libzstd"
	"lrzsz"
	"mtr"
	"nand-utils"
	"nano"
	"terminfo"
	"zoneinfo-[a-z]+"
	"zstd"
)

# basic版本特有包列表
BASIC_PACKAGES=(
	"liblucihttp"
	"liblucihttp0"
	"libmbedtls12"
	"libuhttpd-mbedtls"
	"libustream-mbedtls[0-9]+"
	"luci-base"
	"luci-lib-ip"
	"luci-lib-nixio"
	"luci-lib-px5g"
	"luci-mod-status"
	"luci-mod-system"
	"luci-theme-bootstrap"
#	"luci-theme-material"
#	"luci-theme-openwrt"
	"px5g-mbedtls"
	"rpcd-mod-luci"
	"uhttpd-mod-lua"
	"uhttpd-mod-ubus"
	"uhttpd"
)

# 需要移除的包列表
REMOVE_PACKAGES=(
	"luci-app-advanced-reboot"
	"luci-app-commands"
	"luci-app-firewall"
	"luci-app-opkg"
	"luci-mod-network"
	"luci-theme-openwrt"
)

# 查找所有ipk包
IPKS=$(find openwrt/bin/ | grep '\.ipk$' | sort -V)

# 根据正则表达式查找匹配的ipk包
find_ipks() {
	pcregrep "/($1)_[A-Za-z0-9._+-]+\.ipk" <<< "$IPKS"
}

# 创建目录结构并清理旧文件
mkdir -p packages/common packages/basic packages/remove
rm -fv packages/common/*.ipk packages/basic/*.ipk packages/remove/*.list

# 复制公共包
for PACKAGE in "${COMMON_PACKAGES[@]}"; do
	IPK=$(find_ipks "$PACKAGE")
	[ -n "$IPK" ] && cp -fv $IPK packages/common/
done

# 复制basic版本包
for PACKAGE in "${BASIC_PACKAGES[@]}"; do
	IPK=$(find_ipks "$PACKAGE")
	[ -n "$IPK" ] && cp -fv $IPK packages/basic/
done

# 生成需要移除的包的文件列表
for PACKAGE in "${REMOVE_PACKAGES[@]}"; do
	for IPK in $(find_ipks "$PACKAGE"); do
		LIST="packages/remove/$(basename "$IPK" ".ipk").list"
		echo "Creating file list '$LIST' from '$(basename "$IPK")'"
		tar xfz "$IPK" -O -- "./data.tar.gz" | tar tz | sed -r 's#^\./##g' > "$LIST"
	done
done
