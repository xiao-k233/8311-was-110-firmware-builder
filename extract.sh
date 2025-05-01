#!/bin/bash

_help() {
	printf -- 'Tool for extracting stock WAS-110 local upgrade images\n\n'
	printf -- 'Usage: %s [options]\n\n' "$0"
	printf -- 'Options:\n'
	printf -- '-i --image <filename>\t\tSpecify local upgrade image file to extract (required).\n'
	printf -- '-H --header <filename>\t\tSpecify filename to extract image header to (default: header.bin).\n'
	printf -- '-b --bootcore <filename>\tSpecify filename to extract bootcore image to (default: bootcore.bin).\n'
	printf -- '-k --kernel <filename>\t\tSpecify filename to extract kernel image to (default: kernel.bin).\n'
	printf -- '-r --rootfs <filename>\t\tSpecify filename to extract rootfs image to (default: rootfs.img).\n'
	printf -- '-v --verbose\t\t\tShow detailed extraction information.\n'
	printf -- '-h --help\t\t\tThis help text\n'
}

# 初始化变量
LOCAL=
HEADER="header.bin"
BOOTCORE="bootcore.bin"
KERNEL="kernel.bin"
ROOTFS="rootfs.img"
VERBOSE=false

# 处理命令行参数
while [ $# -gt 0 ]; do
	case "$1" in
		-i|--image)
			LOCAL="$2"
			shift
		;;
		-H|--header)
			HEADER="$2"
			shift
		;;
		-b|--bootcore)
			BOOTCORE="$2"
			shift
		;;
		-k|--kernel)
			KERNEL="$2"
			shift
		;;
		-r|--rootfs)
			ROOTFS="$2"
			shift
		;;
		-v|--verbose)
			VERBOSE=true
		;;
		--help|-h)
			_help
			exit 0
		;;
		*)
			_help
			exit 1
		;;
	esac
	shift
done

# 错误处理函数
_err() {
	echo "$1" >&2
	exit ${2:-1}
}

# 信息输出函数
_info() {
	if [ "$VERBOSE" = true ]; then
		echo "INFO: $1"
	fi
}

set -e

# 检查输入参数
[ -n "$LOCAL" ] || _err "Error: Image file to extract must be specified."
[ -f "$LOCAL" ] || _err "Error: Image file '$LOCAL' does not exist."
[ -n "$HEADER" ] || _err "Error: Invalid header file specified."
[ -n "$BOOTCORE" ] || _err "Error: Invalid bootcore file specified."
[ -n "$KERNEL" ] || _err "Error: Invalid kernel file specified."
[ -n "$ROOTFS" ] || _err "Error: Invalid rootfs file specified."

_info "Extraction source file: $LOCAL"
_info "Output files: header=$HEADER, bootcore=$BOOTCORE, kernel=$KERNEL, rootfs=$ROOTFS"

# 检查魔术字符串
[ "$(head -c 16 "$LOCAL")" = '~@$^*)+ATOS!#%&(' ] || _err "Invalid magic string"
_info "Magic string verified"

# 提取头部信息
LEN_HDR=$((0xD00))
if [ "$VERBOSE" = true ]; then
	echo "Extracting image header to '$HEADER' ($LEN_HDR bytes)"
else
	echo "Extracting image header to '$HEADER'"
fi
head -c "$LEN_HDR" "$LOCAL" > "$HEADER"

# 设置提取位置
POS=$LEN_HDR
NUM=0
FILE_OFFSET=$((0x100))
_info "File offset: 0x$(printf '%x' $FILE_OFFSET)"

# 提取镜像文件函数
extract_image() {
	IMAGE="$1"
	OUT="${2:-$1}"

	DETAIL_OFFSET=$((FILE_OFFSET + (NUM + 1) * 48))
	_info "Detail offset for $IMAGE: 0x$(printf '%x' $DETAIL_OFFSET)"
	
	FILE=$(head -c $((DETAIL_OFFSET - 16)) "$HEADER" | tail -c 32 | awk -F'\0+' '{print $1}')
	if ! [ "$FILE" = "$IMAGE" ]; then
		echo "Image '$IMAGE' expected as image #$NUM" >&2
		exit 1
	fi

	LEN=$((0 + $(head -c $DETAIL_OFFSET "$HEADER" | tail -c 16 | awk -F'\0+' '{print $1}')))
	POS=$((POS + LEN))

	if [ "$VERBOSE" = true ]; then
		echo "Extracting image #$NUM ($IMAGE) to '$OUT' ($LEN bytes)"
	else
		echo "Extracting image #$NUM ($IMAGE) to '$OUT'"
	fi
	
	head -c "$POS" "$LOCAL" | tail -c "$LEN" > "$OUT"
	SIZE=$(stat -c "%s" "$OUT")
	if [ "$SIZE" -ne "$LEN" ]; then
		echo "Extracted Image '$OUT' is not the expected size (expected: $LEN, actual: $SIZE)" >&2
		exit 1
	fi
	_info "Successfully extracted $IMAGE ($SIZE bytes)"

	NUM=$((NUM + 1))
}

# 提取各镜像文件
extract_image "bootcore.bin" "$BOOTCORE"
extract_image "kernel.bin" "$KERNEL"
extract_image "rootfs.img" "$ROOTFS"

if [ "$VERBOSE" = true ]; then
	echo "Extraction complete. Extracted files:"
	ls -lh "$HEADER" "$BOOTCORE" "$KERNEL" "$ROOTFS"
fi


