#!/bin/sh

# OMCI抓包脚本
# 适用于MIPS架构的OpenWrt系统

OMCI_LOG="/tmp/omcimsg.txt"
HEX_FILE="/tmp/omci.hex"

# 清理函数
cleanup() {
    echo "\n正在停止抓包..."
    /usr/bin/omci_pipe.sh mdd
    echo "抓包已停止"
    
    # 转换日志为hex格式
    if [ -f "$OMCI_LOG" ]; then
        echo "正在转换日志格式..."
        awk '/^rx\|/ || /^tx\|/ {gsub(/.*\|/, ""); print "000000 " $0}' "$OMCI_LOG" > "$HEX_FILE"
        
        echo "文件生成完成:"
        echo "  原始日志: $OMCI_LOG"
        echo "  Hex文件: $HEX_FILE"
        echo ""
        echo "请使用scp命令回传文件到本地:"
        echo "  scp root@<设备IP>:$OMCI_LOG ."
        echo "  scp root@<设备IP>:$HEX_FILE ."
    else
        echo "错误: 未找到日志文件 $OMCI_LOG"
    fi
    
    exit 0
}



# 设置信号处理
trap cleanup INT TERM

# 清理旧文件
rm -f "$OMCI_LOG" "$HEX_FILE"

# 获取PON状态的函数 - 请根据需要实现


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
    
    # 获取日志信息
    if [ -f "$OMCI_LOG" ]; then
        # 使用 head 和 tail 避免读取过大的文件
        last_line=$(tail -n 1 "$OMCI_LOG" 2>/dev/null || echo "无法读取日志")
        line_count=$(wc -l < "$OMCI_LOG" 2>/dev/null || echo "0")
    else
        last_line="等待日志文件..."
        line_count="0"
    fi
    
    # 获取PON状态
    pon_status=$(pon psg | cut -b21)
    
    # 清屏并显示状态
    printf "\033[2J\033[H"
    echo "================= OMCI抓包状态 ================="
    printf "抓包时长: %02d:%02d:%02d\n" $hours $minutes $seconds
    echo "PON状态: O$pon_status"
    echo "日志行数: $line_count"
    echo "最后一行: $last_line"
    echo ""
    echo "按 Ctrl+C 终止抓包并生成文件"
    echo "==============================================="
    
    # 降低刷新频率以减少资源使用
    sleep 1
done