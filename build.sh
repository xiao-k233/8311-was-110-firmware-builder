#!/bin/bash

# 8311 WAS-110 Firmware Builder
# 用于ONU/ONT/OLT设备的固件重新打包

# 默认参数
IN_IMG=""
IN_DIR=""
KEEP_TMP=false
RELEASE=false
VERBOSE=false
OPTS=""

# 帮助信息
usage() {
	echo "用法: $0 [-i 输入镜像文件] [-I 输入目录] [-r 版本] [-k] [-v]"
	echo "选项:"
	echo "  -i|--in-image <file>   输入镜像文件"
	echo "  -I|--in-dir <dir>      输入目录（解压后的镜像文件）"
	echo "  -r|--release <ver>     发布版本"
	echo "  -k|--keep              保留临时文件"
	echo "  -v|--verbose           显示详细输出"
	echo "  -h|--help              显示帮助信息"
}

# 处理命令行参数
while [ $# -gt 0 ]; do
	key="$1"
	case $key in
		-i|--in-image)
			IN_IMG="$2"
			shift
		;;
		-I|--in-dir)
			IN_DIR="$2"
			shift
		;;
		-r|--release)
			RELEASE=true
			FW_REVISION="$2"
			shift
		;;
		-k|--keep)
			KEEP_TMP=true
		;;
		-v|--verbose)
			VERBOSE=true
			OPTS+=" -v"
		;;
		-h|--help)
			usage
			exit 0
		;;
		*)
			usage
			exit 1
		;;
	esac
	shift
done

if [ "$VERBOSE" = true ]; then
    echo "执行时使用详细输出模式。"
    export VERBOSE=true
else
    export VERBOSE=false
fi

# 检查参数
if [ -z "$IN_IMG" ] && [ -z "$IN_DIR" ]; then
	usage
	exit 1
fi

# 设置工作目录
BASE_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$BASE_DIR" || exit 1

# 设置工具目录
TOOLS_DIR="$BASE_DIR/tools"
PATH="$TOOLS_DIR:$PATH"

# 设置固件信息
FW_VERSION="1.0.0"
if [ "$RELEASE" = true ]; then
	FW_LONG_VERSION="$FW_VERSION-release-r$FW_REVISION"
else
	GIT_EPOCH=$(git log -1 --format=%ct 2>/dev/null || date +%s)
	FW_REVISION=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
	FW_LONG_VERSION="$FW_VERSION-dev-r${FW_REVISION:0:7}-$GIT_EPOCH"
fi

# 设置基本信息
FW_VARIANT="basic"
KERNEL_VARIANT="basic"
VERSION_FILE="version.ini"
GIT_EPOCH=$(git log -1 --format=%ct 2>/dev/null || date +%s)

# 设置输出目录和文件
IMG_DIR="$BASE_DIR/img"
TMP_DIR="$BASE_DIR/tmp"
CREATE_DIR="$BASE_DIR/create"

mkdir -p "$IMG_DIR" "$TMP_DIR" "$CREATE_DIR"

# 设置输出文件名
FW_VER="$(echo "$FW_LONG_VERSION" | tr -s '-' '_')"
TAR_OUT="$CREATE_DIR/8311-basic-rootfs-${FW_VER}.tar.gz"
ROOT_DIR="$TMP_DIR/8311-basic-rootfs-${FW_VER}"

echo "正在构建固件 $FW_LONG_VERSION..."

# 导出变量
export VERSION_FILE
export FW_VERSION
export FW_REVISION
export FW_VARIANT
export FW_LONG_VERSION
export KERNEL_VARIANT
export GIT_EPOCH
export BASE_DIR
export TOOLS_DIR
export IMG_DIR
export TMP_DIR
export CREATE_DIR
export ROOT_DIR
export VERBOSE

# 清理前一次构建的文件
if [ -d "$ROOT_DIR" ]; then
	echo "清理前一次构建的文件..."
	rm -rf "$ROOT_DIR" "$TAR_OUT"
fi

# 创建输出目录
mkdir -p "$ROOT_DIR"

# 提取镜像
if [ -n "$IN_IMG" ]; then
	echo "提取镜像文件..."
	if [ "$VERBOSE" = true ]; then
		./extract.sh -v -i "$IN_IMG" -o "$ROOT_DIR"
	else
		./extract.sh -i "$IN_IMG" -o "$ROOT_DIR" > /dev/null
	fi
fi

# 从输入目录复制文件
if [ -n "$IN_DIR" ]; then
	echo "从输入目录复制文件..."
	cp -a "$IN_DIR/." "$ROOT_DIR/"
fi

# 应用修改
echo "应用预常规修改..."
. mods/pre-common-mods.sh

echo "应用常规修改..."
. mods/common-mods.sh

echo "应用基本修改..."
. mods/basic-mods.sh

echo "应用国际化..."
. mods/basic-i18n.sh

echo "应用二进制修改..."
. mods/binary-mods.sh

echo "应用恢复修改..."
. mods/reset-mods.sh

# 添加版本文件
echo "添加版本信息..."
mkdir -p "$(dirname "$ROOT_DIR/$VERSION_FILE")"

cat > "$ROOT_DIR/$VERSION_FILE" <<VERSION
[Version]
fw_version=$FW_VERSION
fw_variant=$FW_VARIANT
fw_revision=$FW_REVISION
fw_long_version=$FW_LONG_VERSION
build_epoch=$GIT_EPOCH
VERSION

# 检查二进制文件权限
echo "检查二进制文件权限..."
find "$ROOT_DIR" -type f -exec file {} \; | grep "ELF.*executable" | cut -d':' -f1 | xargs -r chmod +x

# 创建目标文件
CREATE=()

# 创建最终镜像
echo "创建最终镜像..."
if [ "$VERBOSE" = true ]; then
    ./create.sh -v --basic -i "$TAR_OUT" -F "$VERSION_FILE" "${CREATE[@]}"
else
    ./create.sh --basic -i "$TAR_OUT" -F "$VERSION_FILE" "${CREATE[@]}" > /dev/null
    echo "创建了基本TAR包: $TAR_OUT"
fi

echo "创建完整镜像..."
if [ "$VERBOSE" = true ]; then
    ./wholeImage.sh -v "$GIT_EPOCH"
else
    ./wholeImage.sh "$GIT_EPOCH" > /dev/null
    echo "创建了完整镜像: whole-image.img 和 whole-image-endian.img"
fi

# 清理临时文件
if [ "$KEEP_TMP" = false ]; then
	echo "清理临时文件..."
	rm -rf "$ROOT_DIR"
else
	echo "保留临时文件。"
fi

echo "固件构建 $FW_LONG_VERSION 完成。"
