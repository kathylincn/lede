#!/bin/bash
sudo apt-get update
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3.5 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget swig rsync
if [ ! -d "openwrt" ]; then
  git clone https://github.com/coolsnowwolf openwrt
  cd openwrt
else
  cd openwrt

  # 还原版本
  git reset HEAD --hard

  # git 删除未跟踪文件
  git clean -fd

  # 更新代码
  git pull
fi

# 更新并安装源
./scripts/feeds clean
./scripts/feeds update -a && ./scripts/feeds install -a

# 添加第三方软件包
svn co https://github.com/kenzok8/openwrt-packages/trunk/luci-app-openclash package/luci-app-openclash
svn co https://github.com/kenzok8/openwrt-packages/trunk/luci-app-eqos package/luci-app-eqos
svn co https://github.com/kenzok8/openwrt-packages/trunk/luci-app-adguardhome package/luci-app-adguardhome
svn co https://github.com/kenzok8/openwrt-packages/trunk/luci-theme-atmaterial package/luci-theme-atmaterial
svn co https://github.com/jerrykuku/node-request/trunk package/node-request
svn co https://github.com/jerrykuku/luci-app-jd-dailybonus/trunk package/luci-app-jd-dailybonus
svn co https://github.com/destan19/OpenAppFilter/trunk package/OpenAppFilter
svn co https://github.com/tty228/luci-app-serverchan/trunk package/luci-app-serverchan
svn co https://github.com/pymumu/luci-app-smartdns/branches/lede package/luci-app-smartdns
svn co https://github.com/garypang13/luci-theme-edge/branches/18.06 package/luci-theme-edge

# 替换更新默认 argon 主题
rm -rf package/lean/luci-theme-argon && svn co https://github.com/jerrykuku/luci-theme-argon/branches/18.06 package/luci-theme-argon

# 替换更新 passwall 和 ssrplus+
rm -rf package/openwrt-packages/luci-app-passwall && svn co https://github.com/Lienol/openwrt-package/trunk/lienol/luci-app-passwall package/openwrt-packages/luci-app-passwall
rm -rf package/openwrt-packages/luci-app-ssr-plus && svn co https://github.com/fw876/helloworld package/openwrt-packages/helloworld

# 添加 passwall 依赖库
svn co https://github.com/Lienol/openwrt-package/trunk/package package/small

# 替换更新 haproxy 默认版本
rm -rf feeds/packages/net/haproxy && svn co https://github.com/Lienol/openwrt-packages/trunk/net/haproxy feeds/packages/net/haproxy

# 自定义定制选项
sed -i 's#192.168.1.1#10.10.10.1#g' package/base-files/files/bin/config_generate # 定制默认 IP
sed -i 's@.*CYXluq4wUazHjmCDBCqXF*@#&@g' package/lean/default-settings/files/zzz-default-settings # 取消系统默认密码
sed -i 's@background-color: #e5effd@background-color: #f8fbfe@g' package/luci-theme-edge/htdocs/luci-static/edge/cascade.css # luci-theme-edge 主题颜色微调
sed -i 's#rgba(223, 56, 18, 0.04)#rgba(223, 56, 18, 0.02)#g' package/luci-theme-edge/htdocs/luci-static/edge/cascade.css # luci-theme-edge 主题颜色微调

# 创建自定义配置文件 - OpenWrt-x86-64

rm -f ./.config*
touch ./.config

#
# ========================固件定制部分========================
#

#
# 如果不对本区块做出任何编辑, 则生成默认配置固件.
#

# 以下为定制化固件选项和说明:
#

#
# 有些插件 / 选项是默认开启的, 如果想要关闭, 请参照以下示例进行编写:
#
#          =========================================
#         |  # 取消编译 VMware 镜像:                   |
#         |  cat >> .config <<EOF                   |
#         |  # CONFIG_VMDK_IMAGES is not set        |
#         |  EOF                                    |
#          =========================================
#

#
# 以下是一些提前准备好的一些插件选项.
# 直接取消注释相应代码块即可应用. 不要取消注释代码块上的汉字说明.
# 如果不需要代码块里的某一项配置, 只需要删除相应行.
#
# 如果需要其他插件, 请按照示例自行添加.
# 注意, 只需添加依赖链顶端的包. 如果你需要插件 A, 同时 A 依赖 B, 即只需要添加 A.
#
# 无论你想要对固件进行怎样的定制, 都需要且只需要修改 EOF 回环内的内容.
#

# 编译 x64 固件:
cat >> .config <<EOF
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_Generic=y
EOF

# 设置固件大小:
cat >> .config <<EOF
CONFIG_TARGET_KERNEL_PARTSIZE=16
CONFIG_TARGET_ROOTFS_PARTSIZE=160
EOF

# 固件压缩:
cat >> .config <<EOF
CONFIG_TARGET_IMAGES_GZIP=y
EOF

# 编译 UEFI 固件:
cat >> .config <<EOF
CONFIG_EFI_IMAGES=y
EOF

# IPv6 支持:
cat >> .config <<EOF
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_ipv6helper=y
EOF

# 多文件系统支持:
# cat >> .config <<EOF
# CONFIG_PACKAGE_kmod-fs-nfs=y
# CONFIG_PACKAGE_kmod-fs-nfs-common=y
# CONFIG_PACKAGE_kmod-fs-nfs-v3=y
# CONFIG_PACKAGE_kmod-fs-nfs-v4=y
# CONFIG_PACKAGE_kmod-fs-ntfs=y
# CONFIG_PACKAGE_kmod-fs-squashfs=y
# EOF

# USB3.0 支持:
# cat >> .config <<EOF
# CONFIG_PACKAGE_kmod-usb-ohci=y
# CONFIG_PACKAGE_kmod-usb-ohci-pci=y
# CONFIG_PACKAGE_kmod-usb2=y
# CONFIG_PACKAGE_kmod-usb2-pci=y
# CONFIG_PACKAGE_kmod-usb3=y
# EOF

# 第三方插件选择:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-oaf=y # 应用过滤
CONFIG_PACKAGE_luci-app-openclash=y # OpenClash
CONFIG_PACKAGE_luci-app-serverchan=y # 微信推送
CONFIG_PACKAGE_luci-app-eqos=y # IP 限速
CONFIG_PACKAGE_luci-app-smartdns=y # smartdns 服务器
CONFIG_PACKAGE_luci-app-adguardhome=y # adguard home
CONFIG_PACKAGE_luci-app-jd-dailybonus=y # 京东签到插件
EOF

# ShadowsocksR 插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Socks=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Kcptun=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_V2ray=y
EOF

# Passwall 插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ipt2socks=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ChinaDNS_NG=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_v2ray-plugin=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_simple-obfs=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Brook=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_kcptun=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_haproxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_dns2socks=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_pdnsd=y
CONFIG_PACKAGE_kcptun-client=y
CONFIG_PACKAGE_chinadns-ng=y
CONFIG_PACKAGE_haproxy=y
CONFIG_PACKAGE_v2ray=y
CONFIG_PACKAGE_v2ray-plugin=y
CONFIG_PACKAGE_simple-obfs=y
CONFIG_PACKAGE_trojan=y
CONFIG_PACKAGE_trojan-go=y
CONFIG_PACKAGE_brook=y
CONFIG_PACKAGE_ipt2socks=y
CONFIG_PACKAGE_shadowsocks-libev-config=y
CONFIG_PACKAGE_shadowsocks-libev-ss-local=y
CONFIG_PACKAGE_shadowsocks-libev-ss-redir=y
CONFIG_PACKAGE_shadowsocksr-libev-alt=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-local=y
CONFIG_PACKAGE_pdnsd-alt=y
CONFIG_PACKAGE_dns2socks=y
EOF

# 常用 LuCI 插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-adbyby-plus=y # adbyby 去广告
CONFIG_PACKAGE_luci-app-webadmin=y # Web 管理页面设置
CONFIG_PACKAGE_luci-app-ddns=y # DDNS 服务
CONFIG_DEFAULT_luci-app-vlmcsd=y # KMS 激活服务器
CONFIG_PACKAGE_luci-app-filetransfer=y # 系统-文件传输
CONFIG_PACKAGE_luci-app-autoreboot=y # 定时重启
CONFIG_PACKAGE_luci-app-upnp=y # 通用即插即用 UPnP (端口自动转发)
CONFIG_PACKAGE_luci-app-accesscontrol=y # 上网时间控制
CONFIG_PACKAGE_luci-app-wol=y # 网络唤醒
CONFIG_PACKAGE_luci-app-frpc=y # Frp 内网穿透
CONFIG_PACKAGE_luci-app-nlbwmon=y # 宽带流量监控
CONFIG_PACKAGE_luci-app-sfe=y # 高通开源的 Shortcut FE 转发加速引擎
CONFIG_PACKAGE_luci-app-xlnetacc=y # 迅雷快鸟
# CONFIG_PACKAGE_luci-app-flowoffload is not set # 开源 Linux Flow Offload 驱动
# CONFIG_PACKAGE_luci-app-haproxy-tcp is not set # Haproxy负载均衡
# CONFIG_PACKAGE_luci-app-diskman is not set # 磁盘管理磁盘信息
# CONFIG_PACKAGE_luci-app-transmission is not set # TR 离线下载
# CONFIG_PACKAGE_luci-app-qbittorrent is not set # QB 离线下载
# CONFIG_PACKAGE_luci-app-amule is not set # 电驴离线下载
# CONFIG_PACKAGE_luci-app-hd-idle is not set # 磁盘休眠
# CONFIG_PACKAGE_luci-app-wrtbwmon is not set # 实时流量监测
# CONFIG_PACKAGE_luci-app-unblockmusic is not set # 解锁网易云灰色歌曲
# CONFIG_PACKAGE_luci-app-airplay2 is not set # Apple AirPlay2 音频接收服务器
# CONFIG_PACKAGE_luci-app-music-remote-center is not set # PCHiFi 数字转盘遥控
# CONFIG_PACKAGE_luci-app-usb-printer is not set # USB 打印机
# CONFIG_PACKAGE_luci-app-sqm is not set # SQM 智能队列管理
#
# VPN 相关插件(禁用):
#
# CONFIG_PACKAGE_luci-app-v2ray-server is not set # V2ray 服务器
# CONFIG_PACKAGE_luci-app-pptp-server is not set # PPTP VPN 服务器
# CONFIG_PACKAGE_luci-app-ipsec-vpnd is not set # ipsec VPN 服务
# CONFIG_PACKAGE_luci-app-openvpn-server is not set # openvpn 服务
# CONFIG_PACKAGE_luci-app-softethervpn is not set # SoftEtherVPN 服务器
# CONFIG_PACKAGE_luci-app-zerotier is not set # zerotier 内网穿透
#
# 文件共享相关(禁用):
#
# CONFIG_PACKAGE_luci-app-minidlna is not set # miniDLNA 服务
# CONFIG_PACKAGE_luci-app-vsftpd is not set # FTP 服务器
# CONFIG_PACKAGE_luci-app-samba is not set # 网络共享
# CONFIG_PACKAGE_autosamba is not set # 网络共享
# CONFIG_PACKAGE_samba36-server is not set # 网络共享
EOF

# LuCI主题:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-theme-atmaterial=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-theme-netgear=y
CONFIG_PACKAGE_luci-theme-edge=y
EOF

# 常用软件包:
cat >> .config <<EOF
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=y
# CONFIG_PACKAGE_screen=y
# CONFIG_PACKAGE_tree=y
# CONFIG_PACKAGE_vim-fuller=y
CONFIG_PACKAGE_wget=y
EOF

# 其他软件包:
cat >> .config <<EOF
CONFIG_HAS_FPU=y
EOF

# 取消编译 VMware 镜像以及镜像填充 (不要删除被缩进的注释符号):
# cat >> .config <<EOF
# CONFIG_TARGET_IMAGES_PAD is not set
# CONFIG_VMDK_IMAGES is not set
# EOF

#
# ========================固件定制部分结束========================
#


sed -i 's/^[ \t]*//g' ./.config

# 配置文件创建完成

make defconfig
make download -j8
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;
make -j$(nproc) || make -j1 V=s
