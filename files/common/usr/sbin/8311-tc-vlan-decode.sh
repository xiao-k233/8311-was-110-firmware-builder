#!/bin/sh
_lib_8311_omci &>/dev/null || . /lib/8311-omci-lib.sh

me84_parse() {
    local input="$1"                   # 封装输入参数[^2]
    set -- $input                       # 将参数转为位置变量
    while [ $# -ge 2 ]; do              # 持续处理直到参数不足2个
        byte1=$(printf "%d" $1)         # 转换高字节HEX→DEC
        byte2=$(printf "%d" $2)         # 转换低字节HEX→DEC
        total=$(( (byte1 << 8) | byte2 )) # 合并为16位整型
        if [ $total -ne 0 ]; then       # 过滤空条目[^3]
            vid=$(( total & 0x0FFF ))    # 计算各字段
			printf "%s" $vid
        fi
        shift 2                         # 移除已处理的字节对
    done
}
me84_tables=$(mibs 84)
if [ -z "$me84_tables" ]; then
    echo "未检测到VLAN"
fi
if $TABLE; then
	for me84_table in $me84_tables; do
        if [ "$me84_table" != "$(mibs 84 | head -n 1)" ];then
            printf ","
        fi
        me84=$(mibattr 84 $me84_table 1 | sed -n '2p')
        me84_parse "$me84"
	done
fi