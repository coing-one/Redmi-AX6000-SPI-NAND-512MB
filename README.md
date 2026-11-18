# Redmi AX6000 · 512MB ImmortalWrt固件（单段 UBI）

[![编译状态](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB/actions/workflows/firmware-build-single.yml/badge.svg)](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB/actions)
[![最新版本](https://img.shields.io/github/v/release/coing-one/Redmi-AX6000-SPI-NAND-512MB?include_prereleases)](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB/releases)
[![GitHub Stars](https://img.shields.io/github/stars/coing-one/Redmi-AX6000-SPI-NAND-512MB?style=social)](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB)

> 红米 AX6000（RB06）更换 512MB SPI NAND 后的 ImmortalWrt 固件：单个 490MiB 的 ubi 分区，GitHub Actions 云编译。刷法已在真机实刷验证（2026-11-18）。

## 📌 适用前提

- 已将 SPI NAND 从 **128MB 更换为 512MB** 颗粒（内存 2GB 改装机同理）
- 已刷入 hanwckf **bl-mt798x U-Boot**，且其恢复页提供 **`512rom-490m`** 分区布局
- 追求 MTK **闭源 WiFi 驱动**的信号与性能

> 原厂 128MB 机器、原厂 bootloader 的机器请勿使用。

## ✨ 特点

| 特性 | 说明 |
|---|---|
| 底子 | ImmortalWrt 25.12（内核 6.12、apk 包管理），MTK 官方 feeds 闭源驱动 |
| 闭源 WiFi 驱动 | MTK mt_wifi，信号与性能优于开源驱动 |
| 单段 UBI 布局 | 单个 490MiB 的 ubi 分区（内核与文件系统同区），512MB 颗粒用满 |
| 开箱预置 | Vantage 默认主题、后台 1.2.3.4、SmartDNS 双组分流与 Nikki 已调好，刷完即用 |
| 云编译 | Actions 手动一键编译，发布版本号 `v25.12s.*` |

## 🚀 刷机方法（唯一正确路线）

刷机只用一个文件：**`ax6000-single-squashfs-sysupgrade.bin`**（从 [Release](https://github.com/coing-one/Redmi-AX6000-SPI-NAND-512MB/releases) 下载，`v25.12s.*` 标签）。

首刷**不能保留配置**：刷前先在旧后台备份一份配置作人工对照，并抄下宽带账号与 WiFi 密码。

1. 电脑用网线接路由器 **LAN 2–4 口**，电脑设静态 IP **192.168.31.100/24**。
2. 路由器断电，**按住 Reset 再上电约 15 秒**松开，浏览器打开 **http://192.168.31.1** 进 U-Boot 恢复页。
3. 分区布局选 **`512rom-490m`**，上传 `ax6000-single-squashfs-sysupgrade.bin` 刷入，**等路由器亮白灯**重启（页面转圈不用理，以白灯为准）。
4. 电脑 IP 改回自动获取，打开 **http://1.2.3.4** 验收：后台地址 1.2.3.4、主机名 ax6000、root 密码已预置（见 `firmware_build/diy.sh`）；5G WiFi 名为 G、密码已预置，2.4G 默认关闭。刷完直接可用。

本线后续升级同样用这个 sysupgrade 文件（恢复页或后台「系统 → 备份/升级」均可，升级可保留配置）。

> ⚠️ **不要刷 initramfs-factory.ubi**：该形态的启动镜像总长超过 32MiB，在这类 U-Boot 上 bootm 阶段必然触发复位、系统永不启动（已实刷证伪）。本仓库的 Release 不再提供任何 initramfs 类文件，见到别处流传的同名文件也不要刷。

若刷后系统没有起来（刷机只写 ubi 区，FIP 与恢复页不受影响，入口一直在）：

1. 重新进恢复页，布局保持 `512rom-490m`，重新上传 sysupgrade 包刷入，等白灯重启后再试。
2. 仍起不来时，同样进恢复页、同一布局，刷入 XVega 救活包 `2025.06.28-1409-hanwckf-xiaomi_redmi-router-ax6000-spi_nand-512m-squashfs-factory.bin`（SHA256：`c7b869c80d66f8041cd5d5c1bcbe81c5eebf9fd94710210e3a683741477f22fc`），回到刷机前的现行系统（后台 http://192.168.1.1 ，root 空密码）。
3. 两步走完仍异常就先停手，不要改刷其他布局或来历不明的文件。

## 🧩 内置功能

- **性能与无线**：TurboACC MTK 硬件加速、EQoS 限速、mtwifi-cfg 无线管理
- **DNS**：SmartDNS 双上游组分流——国内组（阿里 223.5.5.5、腾讯 119.29.29.29 及两家 DoH，只服务国内域名）与国外组（Nikki 核心 DNS 127.0.0.1:1053，进默认组承接其余查询）；国内域名清单随固件出厂（来源 [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)，2026-11-18 版，运行时每周自动刷新）。Nikki 停掉时国内组仍可独立解析，不会全网断 DNS
- **出海**：Nikki（Mihomo）、honk。Nikki 的 GeoX 数据库（MMDB / GeoSite / GeoIP / ASN）下载源已预置为 fastly.jsdelivr.net 镜像并开启每日自动更新——默认 GitHub 源在国内线路上会超时、导致核心因缺数据库反复启动失败，刷完无需再手动改
- **远程管理**：Lucky（DDNS / 内网穿透）、Cloudflared 隧道
- **文件与商店**：FileBrowser 文件管理、iStore 应用商店
- **运维监控**：ttyd 网页终端、应用过滤、UPnP
- **主题（6 套）**：[Vantage](https://github.com/anothaDev/luci-theme-vantage)（默认）、Proton2025、Argon、[7Dollar](https://github.com/itsmaiGe/luci-theme-7dollar)、[Carbon](https://github.com/mrjoechen/luci-theme-carbon)、[Mono](https://github.com/wizcheu/luci-theme-mono)

软件包在 [`firmware_build/ax6000-single.config`](firmware_build/ax6000-single.config) 中按需增减；预置在 [`firmware_build/diy.sh`](firmware_build/diy.sh)。

## 🔨 编译

1. **Fork** 本仓库到你的 GitHub 账号（或直接在本仓库操作）
2. 进入 **Actions** → 选择「**编译红米AX6000固件（单段UBI）**」→ **Run workflow**
3. 等待编译完成（通常 1–2 小时）
4. 从 **Release**（`v25.12s.*` 标签，版本号自动续号）下载固件；Release 只发布刷机要用的 sysupgrade 包及校验/清单文件

## 📁 目录结构

```
├── .github/workflows/
│   ├── firmware-build-single.yml  # 单段线编译工作流（现行）
│   ├── firmware-build.yml         # 旧 stock 线工作流（非本机路线，勿用它刷本机）
│   └── update-checker.yml         # 旧 stock 线的自动检查
├── atf_uboot_build/               # 512MB 闪存 BL2/FIP 补丁（救砖用）
└── firmware_build/
    ├── ax6000-single.config       # 单段线编译配置（设备、驱动、软件包）
    ├── diy-single.sh              # 单段线注入：打单段补丁后调用 diy.sh
    ├── tree-single-ubi.patch      # 单段机型补丁（新 DTS + 机型定义 + 升级分支）
    ├── diy.sh                     # 共享自定义（软件源、主题、全部预置）
    ├── files/etc/smartdns/domain-set/china.txt  # 国内域名清单（随固件出厂）
    ├── ax6000-stock.config        # 旧 stock 线配置（非本机路线）
    └── fix-rust-orig.py           # rust host 构建修复脚本
```

## 🧱 救砖

刷机只写 ubi 区，bootloader 与恢复页不受影响：按住 Reset 上电即可重进 192.168.31.1 恢复页重刷或退回救活包。bootloader 本身损坏时，串口连上后用 [`atf_uboot_build/`](atf_uboot_build) 里的 512MB BL2/FIP 补丁重新写入。

## 🙏 致谢

- [immortalwrt-mt798x-rebase](https://github.com/chasey-dev/immortalwrt-mt798x-rebase) — chasey-dev 将 ImmortalWrt 25.12 与 MTK 官方 feeds 合并的源码（本仓库基于其 25.12 分支）
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) — OpenWrt 分支
- [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list) — 国内域名清单
- [luci-theme-proton2025](https://github.com/ChesterGoodiny/luci-theme-proton2025)、[luci-theme-vantage](https://github.com/anothaDev/luci-theme-vantage)、[luci-theme-7dollar](https://github.com/itsmaiGe/luci-theme-7dollar)、[luci-theme-carbon](https://github.com/mrjoechen/luci-theme-carbon)、[luci-theme-mono](https://github.com/wizcheu/luci-theme-mono) — LuCI 主题

## ⚖️ 许可

OpenWrt / ImmortalWrt 相关代码沿用上游 [GPL-2.1](https://github.com/immortalwrt/immortalwrt/blob/master/COPYING) 许可，仅供学习交流使用。

---

如果这个仓库帮到你了，欢迎点个 **⭐ Star** 支持一下。
