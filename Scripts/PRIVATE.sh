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

# ===========================================================================
# Huawei XG-PON OLT OMCI compatibility patch — vendor ME 350 / 373
#
# 用法：把本段全部内容粘贴到 Scripts/PRIVATE.sh 的最末尾（原文件末尾
#       echo "PRIVATE.sh: optional plugin sources applied." 之后）。
#
# 背景：中国移动华为 OLT 在 ONU 进入 O5 后，下发厂商私有 OMCI 实体
#       class 350 / 373 的 Set。pbs05/openwrt-pon-userspace 的 MIB 未定义
#       这两个类，dispatch() 返回 RESULT_UNKNOWN_ME (0x04)，OLT 随即
#       Deactivate，把 ONU 打回 O2_3，业务起不来。
#       （原厂 V271-20 同光路认证成功，说明身份/光路都没问题。）
# 处理：在 Mib::dispatch() 入口对 350/373 的 Set 请求直接回 success，
#       即 RTL960x 社区 OMCI_FAKE_OK 的思路——原厂固件里这两个 ME 本就是空桩。
# 位置：PRIVATE.sh 由 Packages.sh 在 Custom Packages 步骤 source，
#       此时 Update Feeds 已完成（源码在 wrt/feeds/），make 尚未开始。
# 幂等：已打过会跳过；找不到锚点则 exit 1 中止编译，避免静默产出无效固件。
# ===========================================================================
echo "PRIVATE.sh: applying Huawei OMCI 350/373 compatibility patch..."
MIB_RS=$(find "$GITHUB_WORKSPACE/wrt/feeds" -path '*/airoha-pon-daemons/src/src/omci/mib.rs' 2>/dev/null | head -n 1)
if [ -z "$MIB_RS" ] || [ ! -f "$MIB_RS" ]; then
  echo "PRIVATE.sh: mib.rs not found under wrt/feeds - patch FAILED"
  exit 1
fi
echo "PRIVATE.sh: found $MIB_RS"
python3 - "$MIB_RS" <<'PYEOF'
import sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()
marker = "HUAWEI_VENDOR_ME_FAKE_OK"
if marker in src:
    print("PRIVATE.sh: OMCI patch already applied, skip")
    sys.exit(0)

anchor = "    pub fn dispatch(&mut self, request: &Request<'_>) -> Response {"
if anchor not in src:
    print("PRIVATE.sh: dispatch anchor not found, patch FAILED")
    sys.exit(1)

inject = """    pub fn dispatch(&mut self, request: &Request<'_>) -> Response {
        // HUAWEI_VENDOR_ME_FAKE_OK
        // Huawei XG-PON OLT sends Set to private MEs 350/373 right after O5.
        // This stack has no definition for them and replies RESULT_UNKNOWN_ME
        // (0x04), which makes the OLT deactivate the ONU back to O2_3. Reply
        // success instead (RTL960x OMCI_FAKE_OK; stock ONT stubs these MEs).
        if (request.class_id == 350 || request.class_id == 373)
            && matches!(request.action, ACTION_SET | ACTION_SET_TABLE)
        {
            return Response::set_success(request);
        }
"""
src = src.replace(anchor, inject, 1)
open(path, "w", encoding="utf-8").write(src)
print("PRIVATE.sh: OMCI patch applied to", path)
PYEOF
