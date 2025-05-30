#!/bin/sh

awk '
BEGIN {
    in_eth0_block = 0
    vlans = ""
    sep = ""
    current_vlan = ""
    has_mirred = 0
}
/--------------- tc filter show dev eth0_0 ingress ---------------/ {
    in_eth0_block = 1
    next
}
in_eth0_block && /^---------------/ {
    in_eth0_block = 0
    # 处理最后一个规则块
    if (has_mirred && current_vlan != "") {
        vlans = vlans sep current_vlan
        sep = ","
    }
    next
}
in_eth0_block {
    # 检测规则块开始（非缩进行）
    if ($0 !~ /^[[:space:]]/) {
        # 处理前一个规则块
        if (has_mirred && current_vlan != "") {
            vlans = vlans sep current_vlan
            sep = ","
        }
        # 重置当前规则状态
        current_vlan = ""
        has_mirred = 0
    }
    
    # 提取 VLAN ID
    if (/vlan_id[[:space:]]+[0-9]+/) {
        split($0, parts, " ")
        for (i=1; i<=length(parts); i++) {
            if (parts[i] == "vlan_id" && i < length(parts)) {
                current_vlan = parts[i+1]
                break
            }
        }
    }
    
    # 检测重定向动作
    if (/mirred \(Egress Redirect/) {
        has_mirred = 1
    }
}
END {
    # 处理最后一个规则块
    if (has_mirred && current_vlan != "") {
        vlans = vlans sep current_vlan
    }
    print vlans
}
' "$@"
