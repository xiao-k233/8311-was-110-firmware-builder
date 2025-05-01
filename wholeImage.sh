#!/bin/bash

# 初始化变量
VERBOSE=false

# 处理命令行参数
if [ "$1" = "-v" ] || [ "$1" = "--verbose" ]; then
    VERBOSE=true
    shift
fi

# 处理时间戳参数或使用当前时间
if { [ "$1" -lt 0 ] || [ "$1" -ge 0 ]; } 2>/dev/null; then
	TIMESTAMP="$1"
else
	TIMESTAMP=$(date '+%s')
fi
TIMESTAMP=$(($TIMESTAMP & 0xffffffff))

# 信息输出函数
_info() {
	if [ "$VERBOSE" = true ]; then
		echo "INFO: $1"
	fi
}

_info "Using timestamp: $TIMESTAMP (hex: 0x$(printf '%x' $TIMESTAMP))"

# 数据处理函数：用于填充或拷贝指定大小的数据
cat_data() {
	local max=false
	local size=
	local file=
	while [ $# -gt 0 ]; do
		case "$1" in
			-m)
				max=true
			;;
			*)
				if [ -z "$size" ]; then
					size="$((${1}))"
				elif [ -z "$file" ]; then
					file="${1}"
				fi
			;;
		esac
		shift
	done
	file="${file:-/dev/null}"
	
	_info "cat_data: size=$size, file=$file, max=$max"
	
	{ cat "$file" ; $max || { cat /dev/zero | LC_ALL=C tr "\000" "\377"; }; } | head -c "$size"
}

# 创建system_sw.img
rm -f whole_image/system_sw.img
echo "Creating system_sw.img..."
if [ "$VERBOSE" = true ]; then
    ubinize -o whole_image/system_sw.img -p 128KiB -m 2048 -s 2048 -v system_sw.ini -Q "$TIMESTAMP"
else
    ubinize -o whole_image/system_sw.img -p 128KiB -m 2048 -s 2048 -v system_sw.ini -Q "$TIMESTAMP" > /dev/null
fi
_info "Created system_sw.img ($(stat -c '%s' whole_image/system_sw.img) bytes)"
echo

# 创建完整镜像
OUTIMG="out/whole-image.img"
echo "Building '$OUTIMG'..."

# 组装各部分到完整镜像
echo "Assembling image components..."
if [ "$VERBOSE" = true ]; then
    echo "  - Adding uboot (0x00100000 bytes)"
    cat_data	0x00100000 "whole_image/uboot-azores-1.0.24.bin"	> "$OUTIMG"		# uboot
    echo "  - Adding ubootconfigA (0x00040000 bytes)"
    cat_data	0x00040000 "whole_image/ubootenv-azores.img"		>> "$OUTIMG"	# ubootconfigA
    echo "  - Adding ubootconfigB (0x00040000 bytes)"
    cat_data	0x00040000 "whole_image/ubootenv-azores.img"		>> "$OUTIMG"	# ubootconfigB
    echo "  - Adding gphyfirmware (0x00040000 bytes)"
    cat_data	0x00040000											>> "$OUTIMG"	# gphyfirmware
    echo "  - Adding calibration (0x00100000 bytes)"
    cat_data	0x00100000											>> "$OUTIMG"	# calibration
    echo "  - Adding bootcore (0x01000000 bytes)"
    cat_data 	0x01000000											>> "$OUTIMG"	# bootcore
    echo "  - Adding system_sw (0x06600000 bytes)"
    cat_data -m	0x06600000 "whole_image/system_sw.img"				>> "$OUTIMG" 	# system_sw
else
    cat_data	0x00100000 "whole_image/uboot-azores-1.0.24.bin"	> "$OUTIMG"		# uboot
    cat_data	0x00040000 "whole_image/ubootenv-azores.img"		>> "$OUTIMG"	# ubootconfigA
    cat_data	0x00040000 "whole_image/ubootenv-azores.img"		>> "$OUTIMG"	# ubootconfigB
    cat_data	0x00040000											>> "$OUTIMG"	# gphyfirmware
    cat_data	0x00100000											>> "$OUTIMG"	# calibration
    cat_data 	0x01000000											>> "$OUTIMG"	# bootcore
    cat_data -m	0x06600000 "whole_image/system_sw.img"				>> "$OUTIMG" 	# system_sw
fi

#cat_data	0x00600000											>> "$OUTIMG"	# ptdata
#cat_data	0x00140000 "whole_image/res.bin"					>> "$OUTIMG"    # res

_info "Whole image created: $OUTIMG ($(stat -c '%s' "$OUTIMG") bytes)"
echo "Whole image build complete."

# 创建字节序反转的镜像文件
FLSIMG="out/whole-image-endian.img"

echo "Creating endian reversed flash image '$FLSIMG'..."
if [ "$VERBOSE" = true ]; then
    tools/endianess_swap.sh "$OUTIMG" "$FLSIMG"
else
    tools/endianess_swap.sh "$OUTIMG" "$FLSIMG" > /dev/null
fi
_info "Endian reversed image created: $FLSIMG ($(stat -c '%s' "$FLSIMG") bytes)"
echo "Endian reversed image created."

# 设置文件时间戳
touch -d "@$TIMESTAMP" "$OUTIMG" "$FLSIMG"
_info "Set timestamps to @$TIMESTAMP"

# 8311镜像构建部分 (已注释掉)
#OUTIMG="out/whole-8311.img"
#echo -n "Building '$OUTIMG'..."

#cat_data	0x00100000 "whole_image/uboot-8311.bin"				> "$OUTIMG"		# uboot
#cat_data	0x00040000 "whole_image/ubootenv-8311.img"			>> "$OUTIMG"	# ubootconfigA
#cat_data	0x00040000 "whole_image/ubootenv-8311.img"			>> "$OUTIMG"	# ubootconfigB
#cat_data	0x00040000											>> "$OUTIMG"	# gphyfirmware
#cat_data	0x00100000											>> "$OUTIMG"	# calibration
#cat_data	0x01000000											>> "$OUTIMG"	# bootcore
#cat_data -m	0x06C00000 "whole_image/system_sw.img"				>> "$OUTIMG"	# system_sw
#cat_data	0x00140000 "whole_image/res.bin"					>> "$OUTIMG"	# res

#touch -d "@$TIMESTAMP" "$OUTIMG"
#echo " done"
