# 8311 WAS-110 固件构建器 - 国内优化版

这是一个用于构建和自定义华为8311 WAS-110 XGS-PON光猫棒固件的工具。该固件基于Azores固件，进行了多项优化和改进，特别针对国内网络环境进行了适配。

## 项目介绍

本项目提供了构建8311 WAS-110固件的完整工具链，允许用户自定义固件特性，包括网络配置、VLAN设置、管理接口等。该固件支持XGS-PON/XG-PON网络，并提供了WebUI界面用于配置。

## 主要特性

- 支持XGS-PON和XG-PON模式
- 提供中文WebUI界面
- 支持VLAN修复功能（特别是对Bell/山东联通等ISP的支持）
- 可自定义PON参数（SN、Vendor ID、Equipment ID等）
- 可配置管理网络参数（IP、网关、DNS等）
- 支持SSH访问和持久化认证
- 支持多种固件环境变量配置
- 内置故障诊断工具

更多详细信息请参考恩山论坛帖子：<https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=8423574&page=1&extra=#pid21495681>

## 固件环境变量配置

### ISP修复相关配置
```
8311_fix_vlans=1
8311_internet_vlan=0
8311_services_vlan=36
```

- `8311_fix_vlans` - **VLAN修复**  
  设置为`0`禁用自动VLAN修复功能。

- `8311_internet_vlan` - **上网VLAN**  
  设置本地使用的上网VLAN ID，设置为`0`表示无标签（同时移除VLAN 0）（范围0-4095）。默认为`0`（无标签）。

- `8311_services_vlan` - **业务VLAN**  
  设置本地使用的业务（如IPTV/电话）VLAN ID（范围1-4095）。修复Bell等运营商的多业务支持。

### 管理网络配置
```
8311_ipaddr=192.168.11.1
8311_netmask=255.255.255.0
8311_gateway=192.168.11.254
8311_ping_ip=192.168.11.2
```

- `8311_ipaddr` - **IP地址**  
  设置管理IP地址。默认为`192.168.11.1`

- `8311_netmask` - **子网掩码**  
  设置管理子网掩码。默认为`255.255.255.0`

- `8311_gateway` - **网关**  
  设置管理网关。默认与IP地址相同（即无默认网关）

- `8311_ping_ip` - **Ping测试IP**  
  设置每5秒ping一次的IP地址，这有助于保持设备连接。默认为配置的管理网络中的第二个IP地址（如192.168.11.2）。

### 设备相关配置
```
8311_console_en=1
8311_ethtool_speed=speed 2500 autoneg off duplex full
8311_failsafe_delay=30
8311_persist_root=0
8311_root_pwhash=$1$BghTQV7M$ZhWWiCgQptC1hpUdIfa0e.
8311_rx_los=0
```

- `8311_console_en` - **串口控制台**  
  设置为`1`启用串口控制台，这将导致TX_FAULT被置于高电平，因为它们共用同一个SFP引脚。

- `8311_ethtool_speed` - **Ethtool速度设置**  
  在eth0_0接口上设置ethtool速度参数（ethtool -s）。

- `8311_factory_mode` - **工厂模式**  
  设置为1启用工厂模式，否则工厂模式将在启动时自动禁用。

- `8311_failsafe_delay` - **故障保护延迟**  
  设置启动时omcid延迟启动的秒数（30到300）。默认为30秒。

- `8311_lct_mac` - **LCT MAC地址**  
  设置LCT管理接口的MAC地址。

- `8311_persist_root` - **持久化根文件系统**  
  设置为`1`允许根文件系统保持持久化（同时需要修改bootcmd固件环境变量）。不推荐使用，仅用于调试/测试目的。

- `8311_root_pwhash` - **Root密码哈希**  
  允许通过设置哈希值来自定义root密码。

- `8311_rx_los` - **RX_LOS解决方案**  
  设置为`0`以监控RX_LOS引脚状态并在其被启用时禁用它。这将允许设备在那些会因RX_LOS信号而禁用端口访问的设备中保持可访问状态。

### PON相关配置
```
8311_cp_hw_ver_sync=1
8311_device_sn=DM222XXXXXXXXXX
8311_equipment_id=5690
8311_gpon_sn=SMBSXXXXXXXX
8311_hw_ver=Fast5689EBell
8311_mib_file=/etc/mibs/prx300_1V.ini
8311_reg_id_hex=00
8311_sw_verA=SGC830007C
8311_sw_verB=SGC830006E
8311_vendor_id=SMBS
```

- `8311_cp_hw_ver_sync` - **同步Circuit Pack Version**  
  当设置为`1`且设置了`8311_hw_ver`时，将修改配置的mib文件以使任何Circuit Pack ME的Version字段与硬件版本匹配。

- `8311_device_sn` - **设备序列号**  
  设置物理设备序列号，这基本上只用于显示。

- `8311_equipment_id` - **Equipment ID**  
  设置ONU2-G ME (257)中的PON Equipment ID字段。

- `8311_gpon_sn` - **GPON SN/ONT ID**  
  设置发送给OLT的各个ME中的GPON SN（4个字母，后跟8个十六进制数字）。

- `8311_hw_ver` - **Hardware Version**  
  设置发送给OLT的各个ME中的硬件版本字符串（最多14个字符）。

- `8311_iphost_domain` - **IP主机域名**  
  设置在ME 134中发送给OLT的域名（最多25个字符）。

- `8311_iphost_hostname` - **IP主机名**  
  设置在ME 134中发送给OLT的主机名（最多25个字符）。

- `8311_iphost_mac` - **IP主机MAC地址**  
  设置在ME 134中发送给OLT的MAC地址。

- `8311_loid` - **Logical ONU ID**  
  设置在ME 256中呈现给OLT的LOID（最多24个字符）。

- `8311_lpwd` - **Logical ONU Password**  
  设置在ME 256中呈现给OLT的LOID密码（最多12个字符）。

- `8311_mib_file` - **MIB文件**  
  设置omcid使用的MIB文件。默认为`/etc/mibs/prx300_1U.ini`

- `8311_pon_slot` - **PON槽位**  
  设置UNI端口所在的槽位号，某些ISP需要此设置。

- `8311_reg_id_hex` - **Registration ID**  
  以十六进制格式设置发送给OLT的注册ID（最多36个字符[72个十六进制]）。这里可以设置ploam密码（包含在最后12个字符中）。

- `8311_sw_verA` / `8311_sw_verB` - **软件版本**  
  设置在软件镜像ME (7)中发送的特定镜像软件版本。

- `8311_vendor_id` - **Vendor ID**  
  设置发送给OLT的PON Vendor ID，如果未设置则自动从GPON SN派生（4个字母）。

## 认证

SSH主机密钥（`/etc/dropbear`的所有内容）和authorized_keys（`/root/.ssh`的所有内容）现在都会被持久保存。
之前的UCI设置将被自动迁移。

当前的root密码（使用`passwd`更改）可以使用`8311-persist-root-password.sh`命令进行持久化保存。

## 脚本使用说明

### build.sh - 构建固件镜像
用于构建新的修改版WAS-110固件镜像的工具
```
Usage: ./build.sh [options]

Options:
-i --image <filename>           指定BFW固件的原始本地升级镜像文件。
-I --image-dir <dir>            指定基础固件的镜像目录（必须包含bootcore.bin、kernel.bin和rootfs.img）。
-o --image-out <filename>       指定要输出的本地升级镜像文件。
-O --tar-out <filename>         指定要输出的本地升级tar文件。
-V --image-version <version>    指定自定义镜像版本字符串。
-r --image-revision <revision>  指定自定义镜像修订字符串。
-w --basic                      构建基础变体镜像。
-W --bfw                        构建bfw变体镜像。
-k --basic-kernel               使用基础内核构建镜像。
-K --bfw-kernel                 使用bfw内核构建镜像。
-b --basic-bootcore             使用基础bootcore构建镜像。
-B --bfw-bootcore               使用bfw bootcore构建镜像。
-R --release                    创建发布归档文件。
-h --help                       显示此帮助文本
```

### create.sh - 创建固件镜像
用于创建新的WAS-110本地升级镜像的工具
```
Usage: ./create.sh [options]

Options:
-i --image <filename>                   指定要创建的本地升级（img或tar）文件（必需）。
-w --basic                              构建基础本地升级tar文件。
-W --bfw                                构建bfw本地升级镜像文件。
-H --header <filename>                  指定基于其创建镜像的镜像头文件（默认：header.bin）。
-b --bootcore <filename>                指定要放置在创建的（bfw）镜像中的bootcore镜像文件（默认：bootcore.bin）。
-k --kernel <filename>                  指定要放置在创建的镜像中的内核镜像文件（默认：kernel.bin）。
-r --rootfs <filename>                  指定要放置在创建的镜像中的rootfs镜像文件（默认：rootfs.img）。
-F --version-file <filename>            指定基础固件镜像的8311版本文件。
-V --image-version <version>            指定要在创建的镜像上设置的版本字符串（最多15个字符）。
-L --image-long-version <version>       指定要在创建的bfw镜像上设置的详细版本字符串（最多31个字符）。
-D --date <date>                        指定要在所有文件上使用的日期。有助于重现性。
-h --help                               此帮助文本
```

### extract.sh - 提取固件镜像
用于提取原始WAS-110本地升级镜像的工具
```
Usage: ./extract.sh [options]

Options:
-i --image <filename>           指定要提取的本地升级镜像文件（必需）。
-H --header <filename>          指定要提取镜像头到的文件名（默认：header.bin）。
-b --bootcore <filename>        指定要提取bootcore镜像到的文件名（默认：bootcore.bin）。
-k --kernel <filename>          指定要提取内核镜像到的文件名（默认：kernel.bin）。
-r --rootfs <filename>          指定要提取rootfs镜像到的文件名（默认：rootfs.img）。
-h --help                       此帮助文本
```

## VLAN修复功能

该项目包含一个强大的VLAN修复功能，可以自动检测和修复来自OLT的VLAN配置问题。该功能通过操控extvlan（me171）来实现VLAN转换，具有更好的通用性和更低的学习成本。

更多关于VLAN修复的信息，请查看`8311-xgspon-bypass`目录中的文档。

## 国际化支持

固件支持多语言界面，包括英文和中文。翻译文件位于`i18n/po/`目录中。

## 构建要求

- Linux系统
- squashfs-tools (mksquashfs)
- u-boot-tools (mkimage)
- dos2unix/unix2dos
- jq
- git

## 使用方法

1. 克隆此仓库：
   ```bash
   git clone <repository-url>
   cd 8311-was-110-firmware-builder
   ```

2. 准备原始固件镜像文件（从设备或供应商获取）

3. 使用build.sh脚本构建自定义固件：
   ```bash
   ./build.sh -i <原始固件镜像> -I <基础固件目录> --basic --release -V "<版本号>"
   ```

4. 构建完成的固件将位于`out/`目录中

## 注意事项

- 构建过程需要root权限
- 修改固件可能会影响设备的保修
- 错误的配置可能导致设备无法启动
- 建议在操作前备份原始固件

## 社区和支持

- 8311社区Discord服务器
- 恩山论坛相关讨论贴

## 贡献者

- djGrrr - 原始项目开发者
- Missing - 中文翻译贡献者
- KillerZ - 国内优化版本维护者

## 许可证

本项目基于GPLv3许可证发布。