#!/bin/bash
# 根据 XG-040G-MD-UBI 工作流的插件勾选结果，按需克隆原仓库中默认注释的插件源。
# 此文件由 Scripts/Packages.sh 末尾 source，UPDATE_PACKAGE 函数此时已可用。

has_pkg() {
  printf '%s\n' "$WRT_PACKAGE" | grep -q "CONFIG_PACKAGE_$1=y"
}

has_pkg luci-app-nikki && UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
has_pkg luci-app-openclash && UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
has_pkg luci-app-passwall && UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
has_pkg luci-app-homeproxy && UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
has_pkg luci-app-mosdns && UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
has_pkg luci-app-qbittorrent && UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
has_pkg luci-app-diskman && UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"
has_pkg luci-app-netspeedtest && UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
has_pkg luci-app-timecontrol && UPDATE_PACKAGE "timecontrol" "sirpdboy/luci-app-timecontrol" "main"
has_pkg luci-app-openlist2 && UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"

echo "PRIVATE.sh: optional plugin sources applied."
