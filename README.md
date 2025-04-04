# 8311 WAS-110 Firmware Builder
## 国内优化版，目前没做太多更改
### 主要特性如下：
- 修改bypass脚本，适配国内运营商，不会瞎把internet绑定到默认GEM1的tr096上（这个因地区而异，在我的印象里大部分运营商GEM1一般是tr096，GEM2一般是internet，GEM3一般是iptv，如果你们地区有很逆天的配置，比如一个GEM走N个VLAN，请告诉我）
- 初步SNMP支持

## Custom fwenvs


8311_fix_vlans=1
8311_internet_vlan=0
8311_services_vlan=36

8311_ipaddr=192.168.11.1
8311_netmask=255.255.255.0
8311_gateway=192.168.11.254
8311_ping_ip=192.168.11.2

8311_console_en=1
8311_ethtool_speed=speed 2500 autoneg off duplex full
8311_failsafe_delay=30
8311_persist_root=0
8311_root_pwhash=$1$BghTQV7M$ZhWWiCgQptC1hpUdIfa0e.
8311_rx_los=0

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

### ISP Fix fwenvs
`8311_fix_vlans` - **Fix VLANs**  
Set to `0` to disable the automatic fixes that are applied to VLANs.  

`8311_internet_vlan` - **Internet VLAN**  
Set the local VLAN ID to use for the Internet or `0` to make the Internet untagged (and also remove VLAN 0) (0 to 4095). Defaults to `0` (untagged).  

`8311_services_vlan` - **Services VLAN**  
Set the local VLAN ID to use for Services (ie TV/Home Phone) (1 to 4095). This fixes multi-service on Bell.  


### Management fwenvs
`8311_ipaddr` - **IP Address**  
Set the management IP address. Defaults to `192.168.11.1`  

`8311_netmask` - **Subnet Mask**  
Set the management subnet mask. Defaults to `255.255.255.0`  

`8311_gateway` - **Gateway**  
Set the management gateway. Defaults to the IP address (ie. no default gateway)  

`8311_ping_ip` - **Ping测试IP**  
设置每5秒ping一次的IP地址，这有助于保持设备连接。默认为配置的管理网络中的第二个IP地址（如192.168.11.2）。

### 设备相关固件环境变量
`8311_console_en` - **串口控制台**  
设置为`1`启用串口控制台，这将导致TX_FAULT被置于高电平，因为它们共用同一个SFP引脚。

`8311_ethtool_speed` - **Ethtool速度设置**  
在eth0_0接口上设置ethtool速度参数（ethtool -s）。

`8311_factory_mode` - **工厂模式**  
设置为1启用工厂模式，否则工厂模式将在启动时自动禁用。

`8311_failsafe_delay` - **故障保护延迟**  
设置启动时omcid延迟启动的秒数（30到300）。默认为30秒。

`8311_lct_mac` - **LCT MAC地址**  
设置LCT管理接口的MAC地址。

`8311_persist_root` - **持久化根文件系统**  
设置为`1`允许根文件系统保持持久化（同时需要修改bootcmd固件环境变量）。不推荐使用，仅用于调试/测试目的。

`8311_root_pwhash` - **Root密码哈希**  
允许通过设置哈希值来自定义root密码。

`8311_rx_los` - **RX_LOS解决方案**  
设置为`0`以监控RX_LOS引脚状态并在其被启用时禁用它。这将允许设备在那些会因RX_LOS信号而禁用端口访问的设备中保持可访问状态。

### PON相关固件环境变量
`8311_cp_hw_ver_sync` - **同步Circuit Pack Version**  
当设置为`1`且设置了`8311_hw_ver`时，将修改配置的mib文件以使任何Circuit Pack ME的Version字段与硬件版本匹配。

`8311_device_sn` - **设备序列号**  
设置物理设备序列号，这基本上只用于显示。

`8311_equipment_id` - **Equipment ID**  
设置ONU2-G ME (257)中的PON Equipment ID字段。

`8311_gpon_sn` - **GPON SN/ONT ID**  
设置发送给OLT的各个ME中的GPON SN（4个字母，后跟8个十六进制数字）。

`8311_hw_ver` - **Hardware Version**  
设置发送给OLT的各个ME中的硬件版本字符串（最多14个字符）。

`8311_iphost_domain` - **IP主机域名**  
设置在ME 134中发送给OLT的域名（最多25个字符）。

`8311_iphost_hostname` - **IP主机名**  
设置在ME 134中发送给OLT的主机名（最多25个字符）。

`8311_iphost_mac` - **IP主机MAC地址**  
设置在ME 134中发送给OLT的MAC地址。

`8311_loid` - **Logical ONU ID**  
设置在ME 256中呈现给OLT的LOID（最多24个字符）。

`8311_lpwd` - **Logical ONU Password**  
设置在ME 256中呈现给OLT的LOID密码（最多12个字符）。

`8311_mib_file` - **MIB文件**  
设置omcid使用的MIB文件。默认为`/etc/mibs/prx300_1U.ini`

`8311_pon_slot` - **PON槽位**  
设置UNI端口所在的槽位号，某些ISP需要此设置。

`8311_reg_id_hex` - **Registration ID**  
以十六进制格式设置发送给OLT的注册ID（最多36个字符[72个十六进制]）。这里可以设置ploam密码（包含在最后12个字符中）。

`8311_sw_verA` / `8311_sw_verB` - **软件版本**  
设置在软件镜像ME (7)中发送的特定镜像软件版本。

`8311_vendor_id` - **Vendor ID**  
设置发送给OLT的PON Vendor ID，如果未设置则自动从GPON SN派生（4个字母）。

## 认证
SSH主机密钥（`/etc/dropbear`的所有内容）和authorized_keys（`/root/.ssh`的所有内容）现在都会被持久保存。
之前的UCI设置将被自动迁移。

当前的root密码（使用`passwd`更改）可以使用`8311-persist-root-password.sh`命令进行持久化保存。

## 脚本

### build.sh
用于构建新的修改版WAS-110固件镜像的工具
```
Usage: ./build.sh [options]

Options:
-i --image <filename>           Specify stock local upgrade image file.
-I --image-dir <dir>            Specify stock image directory (must contain bootcore.bin, kernel.bin, and rootfs.img).
-o --image-out <filename>       Specify local upgrade image to output.
-h --help                       This help text
```

### create.sh
用于创建新的WAS-110本地升级镜像的工具
```
Usage: ./create.sh [options]

Options:
-i --image <filename>           Specify local upgrade image file to create (required).
-H --header <filename>          Specify filename of image header to base image off of (default: header.bin).
-b --bootcore <filename>        Specify filename of bootcore image to place in created image (default: bootcore.bin).
-k --kernel <filename>          Specify filename of kernel image to place in created image (default: kernel.bin).
-r --rootfs <filename>          Specify filename of rootfs image to place in created image (default: rootfs.img).
-V --image-version <version>    Specify version string to set on created image (14 characters max).
-h --help                       This help text
```

### extract.sh
用于提取原始WAS-110本地升级镜像的工具
```
Usage: ./extract.sh [options]

Options:
-i --image <filename>           Specify local upgrade image file to extract (required).
-H --header <filename>          Specify filename to extract image header to (default: header.bin).
-b --bootcore <filename>        Specify filename to extract bootcore image to (default: bootcore.bin).
-k --kernel <filename>          Specify filename to extract kernel image to (default: kernel.bin).
-r --rootfs <filename>          Specify filename to extract rootfs image to (default: rootfs.img).
-h --help                       This help text
