#!/bin/sh

# OMCI抓包脚本
# 适用于MIPS架构的OpenWrt系统

OMCI_LOG="/tmp/omcimsg.txt"
HEX_FILE="/tmp/omci.hex"
PCAP_FILE="/tmp/omci.pcap"

# 清理函数
cleanup() {
    echo "\n正在停止抓包..."
    /usr/bin/omci_pipe.sh mdd
    echo "抓包已停止"
    
    # 转换日志为hex格式
    echo "正在转换日志格式..."
    awk '/^rx\|/ || /^tx\|/ {gsub(/.*\|/, ""); print "000000 " $0}' "$OMCI_LOG" > "$HEX_FILE"
    
    # 生成pcap文件
    echo "正在生成pcap文件..."
    generate_pcap
    
    echo "文件生成完成:"
    echo "  原始日志: $OMCI_LOG"
    echo "  Hex文件: $HEX_FILE"
    echo "  PCAP文件: $PCAP_FILE"
    echo ""
    echo "请使用scp命令回传文件到本地:"
    echo "  scp root@<设备IP>:$PCAP_FILE ."
    echo "  scp root@<设备IP>:$HEX_FILE ."
    
    exit 0
}

# 生成pcap文件头
write_pcap_header() {
    local file="$1"
    # PCAP文件头 (24字节)
    # Magic number (4字节): D4 C3 B2 A1 (小端序)
    # Version major (2字节): 02 00
    # Version minor (2字节): 04 00
    # Thiszone (4字节): 00 00 00 00
    # Sigfigs (4字节): 00 00 00 00
    # Snaplen (4字节): FF FF 00 00 (65535)
    # Network (4字节): 01 00 00 00 (以太网)
    printf '\xD4\xC3\xB2\xA1\x02\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\x00\x00\x01\x00\x00\x00' > "$file"
}

# 生成pcap数据包
generate_pcap() {
    write_pcap_header "$PCAP_FILE"
    
    # 读取hex文件并转换为pcap数据包
    while IFS= read -r line; do
        # 跳过空行
        [ -z "$line" ] && continue
        
        # 移除前面的偏移量(000000)和空格
        hex_data=$(echo "$line" | sed 's/^[0-9A-Fa-f]*[[:space:]]*//')
        
        # 跳过无效行
        [ -z "$hex_data" ] && continue
        
        # 构造以太网帧
        # 目标MAC: 20:52:45:43:56:00
        # 源MAC: 20:53:45:4e:44:00  
        # EtherType: 88:b5
        eth_header="205245435600205345454400"
        ethertype="88b5"
        
        # 完整的以太网帧 = 以太网头 + EtherType + OMCI数据
        full_frame="${eth_header}${ethertype}${hex_data}"
        
        # 计算帧长度
        frame_len=$((${#full_frame} / 2))
        
        # 获取当前时间戳
        timestamp=$(date +%s)
        
        # 写入数据包记录头 (16字节)
        # 时间戳秒数 (4字节，小端序)
        printf "\\$(printf '%o' $((timestamp & 0xFF)))"
        printf "\\$(printf '%o' $(((timestamp >> 8) & 0xFF)))"
        printf "\\$(printf '%o' $(((timestamp >> 16) & 0xFF)))"
        printf "\\$(printf '%o' $(((timestamp >> 24) & 0xFF)))"
        # 时间戳微秒数 (4字节): 00 00 00 00
        printf '\x00\x00\x00\x00'
        # 捕获长度 (4字节，小端序)
        printf "\\$(printf '%o' $((frame_len & 0xFF)))"
        printf "\\$(printf '%o' $(((frame_len >> 8) & 0xFF)))"
        printf "\\$(printf '%o' $(((frame_len >> 16) & 0xFF)))"
        printf "\\$(printf '%o' $(((frame_len >> 24) & 0xFF)))"
        # 原始长度 (4字节，小端序)
        printf "\\$(printf '%o' $((frame_len & 0xFF)))"
        printf "\\$(printf '%o' $(((frame_len >> 8) & 0xFF)))"
        printf "\\$(printf '%o' $(((frame_len >> 16) & 0xFF)))"
        printf "\\$(printf '%o' $(((frame_len >> 24) & 0xFF)))"
        
        # 写入数据包内容
        echo "$full_frame" | sed 's/../\\x&/g' | xargs -0 printf
        
    done < "$HEX_FILE" >> "$PCAP_FILE"
}

# 设置信号处理
trap cleanup INT TERM

# 清理旧文件
rm -f "$OMCI_LOG" "$HEX_FILE" "$PCAP_FILE"

# 获取PON状态的函数 - 请根据需要实现
get_pon_status() {
    # TODO: 在这里实现PON状态获取逻辑
    # 返回PON状态字符串，例如: "O5 - 运行状态"
    echo "请实现PON状态获取"
}

# 开始抓包
echo "开始OMCI抓包..."
result=$(/usr/bin/omci_pipe.sh mdfe "$OMCI_LOG")

# 检查命令输出是否包含errorcode=0
if echo "$result" | grep -q "errorcode=0"; then
    echo "OMCI抓包启动成功: $result"
else
    echo "错误: OMCI抓包启动失败: $result"
    exit 1
fi

echo "抓包已启动，日志保存到: $OMCI_LOG"
echo ""

# 主循环 - 显示状态信息
start_time=$(date +%s)
while true; do
    # 计算运行时间
    current_time=$(date +%s)
    duration=$((current_time - start_time))
    hours=$((duration / 3600))
    minutes=$(((duration % 3600) / 60))
    seconds=$((duration % 60))
    
    # 获取日志最后一行
    if [ -f "$OMCI_LOG" ]; then
        last_line=$(tail -n 1 "$OMCI_LOG" 2>/dev/null)
        line_count=$(wc -l < "$OMCI_LOG" 2>/dev/null || echo "0")
    else
        last_line="等待日志文件..."
        line_count="0"
    fi
    
    # 获取PON状态
    pon_status=$(get_pon_status)
    
    # 清屏并显示状态
    printf "\033[2J\033[H"
    echo "================= OMCI抓包状态 ================="
    printf "抓包时长: %02d:%02d:%02d\n" $hours $minutes $seconds
    echo "PON状态: $pon_status"
    echo "日志行数: $line_count"
    echo "最后一行: $last_line"
    echo ""
    echo "按 Ctrl+C 终止抓包并生成文件"
    echo "==============================================="
    
    sleep 1
done