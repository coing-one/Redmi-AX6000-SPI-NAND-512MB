# honk 集成说明

## 这套集成做了什么

旧底子是 padavanonly/immortalwrt-mt798x-6.6（ImmortalWrt 24.10、内核 6.6、opkg），
honk 要求内核 6.12+ 且官方只支持 25.12（apk），6.6 底子无论如何装不进去。
本仓库底子已换成 chasey-dev/immortalwrt-mt798x-rebase 的 25.12 分支
（ImmortalWrt 25.12、内核 6.12、闭源 mt_wifi 驱动、stock 布局），其余尽量沿用现行定格：

- 设备只编 `xiaomi_redmi-router-ax6000-stock` 单设备；512MB 闪存的 ubi 扩容保留
  （新底子是 ubi_kernel 30MB + ubi 两段式，只把 ubi 段从 80MB 扩到 476MB，diy-2512.sh 里带校验，扩不上就停工报错）。
- 内核显式打开 `CONFIG_KERNEL_DEBUG_INFO_BTF=y` 并关掉 `DEBUG_INFO_REDUCED`：
  上游默认只在官方 BUILDBOT 构建时开 BTF，自编译不开的话 honk 启动时拿不到 BTF 直接失败；
  同时选 `vmlinux-btf-builtin` 占位包满足 honk 的依赖（内核自带 BTF，不用外挂 blob）。
- honk 本体经 daeuniverse 官方源代码仓库（daeuniverse/openwrt-packages，仓库根目录即 OpenWrt feed）
  以源码包形式编进固件：`honk` + `luci-app-honk` + 中文包；workflow 另检出 honk v0.1.0-beta.6 源码、
  按其钉版装两套 Rust 工具链与 bpf-linker（照官方 feed 的 CI 做法）。
- 路由器侧预装 daeuniverse 的 apk 软件源与公钥，刷机后可单独 `apk upgrade honk@daeuniverse` 升级 honk，不必整包重刷。
- SmartDNS + Nikki 开箱脚本（97-smartdns-nikki）原样保留；passwall2、Proton2025 主题、常用 LuCI 应用按旧配置迁移。
  旧底子专属的包名有出入时以 release 里的 config.buildinfo 为准核对（已知差异：UPnP 用回官方 luci-app-upnp；
  gecoosac、cpu-status-mini 是旧底子源里的包，新底子无此源，未迁移）。

## 预置配置（firmware_build/honk/config.dae）

编译时覆盖包自带骨架，装到 `/etc/honk/config.dae`，口径：

- DNS：阿里 DoH 直连 + Google DoH 走代理；请求路由把 gfw 与油管全家
  （googlevideo.com / youtube.com / ytimg.com / ggpht.com）直接送 Google，
  其余先问阿里；响应校验只采信「国外上游的答复」和「解析到国内 IP 的答复」，其余换 Google 重查（防污染）。
- 缓存：optimistic 600 秒、5 万条，`cache_file.store_dns` 落盘，重启不凉。
- 拨号 domain++、`client_subnet: auto`（直连带 ECS 让国内 CDN 就近命中）、健康检查 30 秒。
- 代理组 proxy 用 score 策略（按真实流量表现自动选节点，免调参）；路由国内与私网直连、其余走 proxy。
- doona 管理界面 9527 端口、密码登录、可写配置，与包默认一致。
- 订阅只留占位注释：本仓库公开，真实订阅链接只在路由器上填，禁止提交进仓库。

## 刷机与启用（重要）

- 这是跨底子升级（分区布局从单 ubi 变 ubi_kernel + ubi、opkg 变 apk）：
  不要用旧系统里的 sysupgrade 保留配置升级，按新底子 stock 布局走 U-Boot 刷入，配置重新开箱。
- 刷完默认状态与现在一致：Nikki + SmartDNS 工作，honk 已装但不开机自启，互不影响。
- 切 honk 的步骤：LuCI 里停用并关闭 Nikki、SmartDNS 的开机自启 →
  打开 `http://路由器IP:9527` 建管理员账号 → 在 doona 里加订阅（或改 /etc/honk/config.dae 的 subscription 段）→
  `/etc/init.d/honk enable && /etc/init.d/honk start`（或 LuCI 的 Services → honk 里开）。
  切回就是反着来：停 honk、启 Nikki 与 SmartDNS。

## 未验证项（首编后按此核对）

1. 首次编译未经实跑：honk 的 Rust 工具链步骤照官方 feed CI 移植，仍可能有宿主依赖出入，看 Actions 日志定位。
2. 编完对 release 里的 config.buildinfo 核对：honk、luci-app-honk、vmlinux-btf-builtin、nikki、passwall2、smartdns 是否都在。
3. honk 配置的真机解析与启动、与 dnsmasq/SmartDNS 的端口接管关系，要刷机后在设备上验，本仓库层面只能保证语法与上游示例一致。
4. 每周自动编译已切到 25.12 底子跟进。
