#!/bin/bash
# 红米AX6000 单段UBI变体：在共享 diy.sh 之前，先给源码树打单段补丁
# 底子与 stock 同为 ImmortalWrt 25.12；本脚本只负责机型变体，软件包与预置全部复用 diy.sh

FW_DIR=$(cd "$(dirname "$0")" && pwd)

# 单段补丁：新增 xiaomi_redmi-router-ax6000-single 机型（单 UBI 490MiB）
# 内容：新 DTS + filogic.mk 机型定义 + platform.sh 单 UBI 升级分支 + board.d/preinit 名单
git apply --check "$FW_DIR/tree-single-ubi.patch" || { echo "ERROR: 单段补丁与上游树对不上，停工检查"; exit 1; }
git apply "$FW_DIR/tree-single-ubi.patch" || { echo "ERROR: 单段补丁应用失败，停工"; exit 1; }
grep -q 'xiaomi_redmi-router-ax6000-single' target/linux/mediatek/image/filogic.mk || { echo "ERROR: 单段机型未注入 filogic.mk，停工"; exit 1; }
grep -q 'reg = <0x600000 0x1ea00000>' target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-single.dts || { echo "ERROR: 单段 DTS 未就位，停工"; exit 1; }

# 其余注入（stock DTS 扩容、追加 feeds、主题/Lucky、全部预置）与 stock 共用同一脚本，不另维护一份
bash "$FW_DIR/diy.sh"
