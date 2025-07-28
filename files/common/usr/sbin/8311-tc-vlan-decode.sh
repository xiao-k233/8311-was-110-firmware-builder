#!/bin/sh
# 优化版：只处理eth0_0 ingress，直接输出VLAN ID，合并原有功能，极简高效

# 只处理eth0_0 ingress，避免遍历所有接口和方向
TC_OUTPUT=$(tc filter show dev eth0_0 ingress)

# 只在有输出时处理
if [ -n "$TC_OUTPUT" ]; then
    echo "$TC_OUTPUT" | awk '
    BEGIN {
        vlans = ""; sep = ""; current_vlan = ""; has_mirred = 0;
    }
    # 检测规则块开始（非缩进行）
    /^[^[:space:]]/ {
        if (has_mirred && current_vlan != "") {
            vlans = vlans sep current_vlan; sep = ",";
        }
        current_vlan = ""; has_mirred = 0;
    }
    /vlan_id[[:space:]]+[0-9]+/ {
        for (i=1; i<=NF; i++) {
            if ($i == "vlan_id" && (i+1)<=NF) {
                current_vlan = $(i+1);
                break;
            }
        }
    }
    /mirred \(Egress Redirect/ { has_mirred = 1; }
    END {
        if (has_mirred && current_vlan != "") {
            vlans = vlans sep current_vlan;
        }
        print vlans;
    }'
else
    echo ""
fi
