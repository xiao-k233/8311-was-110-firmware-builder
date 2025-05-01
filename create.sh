#!/bin/bash

_help() {
	printf -- 'Usage: %s [options]\n\n' "$0"
	printf -- 'Options:\n'
	printf -- '-i --image <filename>\t\tSpecify the TAR or image file to output.\n'
	printf -- '-b --bootcore <filename>\tSpecify bootcore file to include in image (default: bootcore.bin).\n'
	printf -- '-k --kernel <filename>\t\tSpecify kernel file to include in image (default: kernel.bin).\n'
	printf -- '-r --rootfs <filename>\t\tSpecify rootfs file to include in image (default: rootfs.img).\n'
	printf -- '--basic\t\t\tCreate a basic image (TAR).\n'
	printf -- '-F --version-file <filename>\tSpecify version file to include in basic image.\n'
	printf -- '-v --verbose\t\t\tShow detailed build information.\n'
	printf -- '--help|-h\t\t\tThis help text\n'
}

# 初始化变量
VERBOSE=false
VARIANT="basic"
BOOTCORE="bootcore.bin"
KERNEL="kernel.bin"
ROOTFS="rootfs.img"
VERSION_FILE=""
OUT=""

# 处理命令行参数
while [ $# -gt 0 ]; do
	case "$1" in
		-i|--image)
			OUT="$2"
			shift
		;;
		--basic)
			VARIANT="basic"
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
		-F|--version-file)
			VERSION_FILE="$2"
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

# 计算SHA256哈希
sha256() {
	sha256sum "$@" | awk '{print $1}'
}

# 获取文件大小
file_size() {
	stat -c '%s' "$1"
}

# 转义字符串用于sed
sed_escape() {
	sed 's#\\#\\\\#g' | sed 's/#/\\#/g'
}

# 创建tar转换规则
tar_trans() {
	local INPUT="$(echo "$1" | sed_escape)"
	local NAME="$(echo "$2" | sed_escape)"
	echo "s#$INPUT#$NAME#"
}

if [ -z "$OUT" ]; then
	_err "Must specify output file."
fi

if [ "$VARIANT" = "basic" ]; then
	# 创建basic tar包
	if [ -z "$VERSION_FILE" ]; then
		_err "Must specify version file for basic image."
	fi

	_info "Creating basic tar image: $OUT"
	_info "Using version file: $VERSION_FILE"

	BUILD_DIR=$(dirname "$OUT")
	TMP_DIR=$(mktemp -d -p "$BUILD_DIR" create-basic-XXXXXX)
	_info "Created temporary directory: $TMP_DIR"

	# 复制文件到临时目录
	cp "$VERSION_FILE" "$TMP_DIR/"
	_info "Copied version file to $TMP_DIR/"

	# 创建tar包
	(cd "$TMP_DIR" && tar czf "$OUT" *)
	_info "Created tar image: $OUT"

	# 清理临时目录
	rm -rf "$TMP_DIR"
	_info "Removed temporary directory: $TMP_DIR"
	
	# 确保输出文件存在
	if [ ! -f "$OUT" ]; then
		_err "Failed to create basic image: $OUT"
	fi
fi

_info "Image creation completed successfully: $OUT"
echo "Created image: $OUT"
exit 0
