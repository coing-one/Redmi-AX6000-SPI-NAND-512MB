# Redmi AX6000 · 512MB ImmortalWrt固件

[![编译状态](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB/actions/workflows/firmware-build.yml/badge.svg)](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB/actions/workflows/firmware-build.yml)
[![最新版本](https://img.shields.io/github/v/release/coing-one/Redmi-AX6000-SPI-NAND-512MB?include_prereleases)](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB/releases)
[![GitHub Stars](https://img.shields.io/github/stars/coing-one/Redmi-AX6000-SPI-NAND-512MB?style=social)](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB)

> 红米 AX6000（RB06）更换 512MB SPI NAND 后的 ImmortalWrt 固件，GitHub Actions 云编译，Fork 即用，每周自动跟进上游。

## 📌 适用前提

- 已将 SPI NAND 从 **128MB 更换为 512MB** 颗粒
- 保留**原厂 stock 分区**，不换 bootloader
- 追求 MTK **闭源 WiFi 驱动**的信号与性能

> 原厂 128MB 机器请勿使用，请直接刷上游的 stock 固件。

## ✨ 特点

| 特性 | 说明 |
|---|---|
| 底子 | ImmortalWrt 25.12（内核 6.12、apk 包管理），MTK 官方 feeds 闭源驱动 |
| 闭源 WiFi 驱动 | MTK mt_wifi，信号与性能优于开源驱动 |
| stock 分区布局 | ubi_kernel + ubi 两段式，不换 bootloader；ubi 80MB → 476MB，512MB 颗粒全部用上 |
| 开箱预置 | Vantage 默认主题、后台 1.2.3.4、SmartDNS 与 Nikki 已调好，刷完即用 |
| 云编译 | Actions 一键编译，每周一自动检查上游，有更新才编 |

## 🚀 快速开始

1. **Fork** 本仓库到你的 GitHub 账号
2. 进入 **Actions** → 选择「**编译红米AX6000固件**」→ **Run workflow**
3. 等待编译完成（通常 1–2 小时，取决于包数量与 runner 状态）
4. 从 **Release**（`v25.12.*` 标签）或 **Artifacts**（`redmi-ax6000-512m-firmware`）下载固件
5. 刷入：**从旧 24.10 固件升级必须走 U-Boot 按新布局刷入**（分区布局已变，不能 sysupgrade 保留配置）；同为本 25.12 线的后续版本可直接 sysupgrade

> 刷机有风险，动手前请先备份原厂固件。

## 🧩 内置功能

- **性能与无线**：TurboACC MTK 硬件加速、EQoS 限速、mtwifi-cfg 无线管理
- **DNS**：SmartDNS（国内/国外分流、双栈优选、大缓存，低延迟开箱配置）
- **出海**：Nikki（Mihomo）、honk
- **远程管理**：Lucky（DDNS / 内网穿透）、Cloudflared 隧道
- **文件与商店**：FileBrowser 文件管理、iStore 应用商店
- **运维监控**：ttyd 网页终端、应用过滤、UPnP
- **主题（6 套）**：[Vantage](https://github.com/anothaDev/luci-theme-vantage)（默认）、Proton2025、Argon、[7Dollar](https://github.com/itsmaiGe/luci-theme-7dollar)、[Carbon](https://github.com/mrjoechen/luci-theme-carbon)、[Mono](https://github.com/wizcheu/luci-theme-mono)

软件包在 [`firmware_build/ax6000-stock.config`](firmware_build/ax6000-stock.config) 中按需增减。

## 📁 目录结构

```
├── .github/workflows/
│   ├── firmware-build.yml       # 编译工作流
│   └── update-checker.yml       # 每周自动检查上游
├── atf_uboot_build/             # 512MB 闪存 BL2/FIP 补丁（救砖用）
└── firmware_build/
    ├── ax6000-stock.config      # 编译配置（设备、驱动、软件包）
    ├── diy.sh                   # 编译前自定义（分区扩容、软件源、主题）
    └── fix-rust-orig.py         # rust host 构建修复脚本
```

## 🔄 自动更新

`update-checker.yml` 每周一 00:00（北京时间）检查上游 25.12 分支：有新提交才触发编译，没有则跳过，不浪费 Actions 配额。关闭方式：注释或删除该工作流。

## 🧱 救砖

bootloader 未改动，串口连上后用 [`atf_uboot_build/`](atf_uboot_build) 里的 512MB BL2/FIP 补丁重新写入即可。

## 🙏 致谢

- [immortalwrt-mt798x-rebase](https://github.com/chasey-dev/immortalwrt-mt798x-rebase) — chasey-dev 将 ImmortalWrt 25.12 与 MTK 官方 feeds 合并的源码（本仓库基于其 25.12 分支）
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) — OpenWrt 分支
- [luci-theme-proton2025](https://github.com/ChesterGoodiny/luci-theme-proton2025)、[luci-theme-vantage](https://github.com/anothaDev/luci-theme-vantage)、[luci-theme-7dollar](https://github.com/itsmaiGe/luci-theme-7dollar)、[luci-theme-carbon](https://github.com/mrjoechen/luci-theme-carbon)、[luci-theme-mono](https://github.com/wizcheu/luci-theme-mono) — LuCI 主题

## ⚖️ 许可

OpenWrt / ImmortalWrt 相关代码沿用上游 [GPL-2.1](https://github.com/immortalwrt/immortalwrt/blob/master/COPYING) 许可，仅供学习交流使用。

---

如果这个仓库帮到你了，欢迎点个 **⭐ Star** 支持一下。
