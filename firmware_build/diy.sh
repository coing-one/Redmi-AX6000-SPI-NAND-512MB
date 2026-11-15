#!/bin/bash
# 红米AX6000 自定义修改（feeds 更新之前执行）
# 底子：ImmortalWrt 25.12（主线式 mediatek/filogic 目标、内核 6.12、apk 包管理）

# stock 布局：512MB 闪存颗粒下把 ubi 分区从 80MB 扩到 476MB（0x2400000 起至闪存末尾 0x20000000）
# 新底子分区为 ubi_kernel(30MB) + ubi 两段式，与旧底子的单段 ubi 不同，只扩 ubi 段
DTS=target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-stock.dts
sed -i 's/reg = <0x2400000 0x5000000>/reg = <0x2400000 0x1dc00000>/' "$DTS"
grep -q 'reg = <0x2400000 0x1dc00000>' "$DTS" || { echo "ERROR: ubi 分区扩容未生效，停工检查 DTS"; exit 1; }

# 追加软件源（代理类 + honk/dae 的 daeuniverse 源，仓库根目录即 OpenWrt feed）
echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki' >> feeds.conf.default
echo 'src-git daeuniverse https://github.com/daeuniverse/openwrt-packages' >> feeds.conf.default
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default

# 主题（clone 进 package 编译）：Proton2025（默认）+ Vantage + 7Dollar + Carbon + Mono
git clone --depth 1 https://github.com/ChesterGoodiny/luci-theme-proton2025 package/luci-theme-proton2025
git clone --depth 1 https://github.com/itsmaiGe/luci-theme-7dollar package/luci-theme-7dollar
git clone --depth 1 https://github.com/mrjoechen/luci-theme-carbon package/luci-theme-carbon
git clone --depth 1 https://github.com/wizcheu/luci-theme-mono package/luci-theme-mono
# Mono 的 Makefile 缺 BuildPackage 签名行，包扫描扫不到它，补上签名注释（上游惯例写法）
printf '\n# call BuildPackage - OpenWrt buildroot signature\n' >> package/luci-theme-mono/Makefile
# Vantage 是多包仓库（主题与仪表盘应用在子目录），整仓 clone 后把两个包搬进 package/
git clone --depth 1 https://github.com/anothaDev/luci-theme-vantage vantage-src
mv vantage-src/luci-theme-vantage package/luci-theme-vantage
mv vantage-src/luci-app-vantage package/luci-app-vantage
rm -rf vantage-src

# Lucky（DDNS 等）：25.12 的 feeds 里已无此包，从作者仓库引入（应用与守护进程两个包）
git clone --depth 1 https://github.com/gdy666/luci-app-lucky lucky-src
mv lucky-src/luci-app-lucky package/luci-app-lucky
mv lucky-src/lucky package/lucky
rm -rf lucky-src

# 默认主题：Vantage（首启 uci-defaults 生效）
cat > package/base-files/files/etc/uci-defaults/96-default-theme << 'EOF'
#!/bin/sh
uci set luci.main.mediaurlbase='/luci-static/vantage'
uci commit luci
EOF

# 默认后台地址：LAN 改 1.2.3.4/24（首启 uci-defaults 生效，DHCP 池自动跟随网段）；主机名设 ax6000（ax6000.lan / 配 umdns 的 ax6000.local 均可达）
# 预置无线配置（照用户现行机同驱动配置原样落盘：5G 名 G + 密码已定，2.4G 保持关闭）
mkdir -p package/base-files/files/etc/config
cat > package/base-files/files/etc/config/wireless << 'XEOF'
config wifi-device 'MT7986_1_1'
	option type 'mtwifi'
	option phy 'ra0'
	option hwmode '11g'
	option band '2g'
	option dbdc_main '1'
	option channel 'auto'
	option txpower '100'
	option htmode 'HE40'
	option country 'CN'
	option mu_beamformer '1'
	option noscan '1'
	option serialize '1'
	option disabled '1'

config wifi-iface 'default_MT7986_1_1'
	option device 'MT7986_1_1'
	option network 'lan'
	option mode 'ap'
	option ssid 'ImmortalWrt-2.4G'
	option encryption 'none'
	option disabled '1'

config wifi-device 'MT7986_1_2'
	option type 'mtwifi'
	option phy 'rax0'
	option hwmode '11a'
	option band '5g'
	option dbdc_main '0'
	option channel 'auto'
	option txpower '100'
	option htmode 'HE80'
	option country 'CN'
	option mu_beamformer '1'
	option serialize '1'

config wifi-iface 'default_MT7986_1_2'
	option device 'MT7986_1_2'
	option network 'lan'
	option mode 'ap'
	option ssid 'G'
	option encryption 'psk-mixed'
	option key '11112222'
XEOF

# 预置 root 密码（LuCI 后台与 SSH 共用同一个 root 密码；用户明知仓库公开、自行接受风险）
cat > package/base-files/files/etc/uci-defaults/95-root-password << 'XEOF'
#!/bin/sh
sed -i 's|^root:[^:]*:|root:$6$mg0xovHjaWJ2g.Eu$j7HEKD8IcJ.sVyDMaEFo5pqFzkt9D1wpA9.dzXM3FFaHdC5iPn19GVkpcImCVLUzqau.PqhjV5HWD3bSBZlhD1:|' /etc/shadow
exit 0
XEOF

cat > package/base-files/files/etc/uci-defaults/98-lan-ip << 'EOF'
#!/bin/sh
uci set network.lan.ipaddr='1.2.3.4'
uci set network.lan.netmask='255.255.255.0'
uci commit network
uci set system.@system[0].hostname='ax6000'
uci commit system
EOF

# 刷机后内置 apk 软件源换国内 USTC 镜像（25.12 起包管理是 apk，源文件为 /etc/apk/repositories.d/distfeeds.list）
# daeuniverse 源的公钥与列表由 workflow 在 feeds 更新后另行装入 base-files（见 firmware-build.yml）
cat > package/base-files/files/etc/uci-defaults/99-custom-distfeeds << 'EOF'
#!/bin/sh
CFG=/etc/apk/repositories.d/distfeeds.list
[ -f "$CFG" ] || exit 0
# 三个国内源（中科大/清华/上海交大），apk 按文件顺序取源：默认走最快的中科大，失败自动落下一源
cp "$CFG" /tmp/distfeeds.orig
: > "$CFG"
for M in mirrors.ustc.edu.cn/immortalwrt mirrors.tuna.tsinghua.edu.cn/immortalwrt mirror.sjtu.edu.cn/immortalwrt; do
	sed "s#https://downloads.immortalwrt.org#https://$M#g" /tmp/distfeeds.orig >> "$CFG"
done
rm -f /tmp/distfeeds.orig
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-distfeeds

# SmartDNS + Nikki 开箱配置（现行定格）
cat > package/base-files/files/etc/uci-defaults/97-smartdns-nikki << 'EOF'
#!/bin/sh
# 97-smartdns-nikki：SmartDNS + Nikki 开箱配置

# ============ SmartDNS 主配置 ============
uci set smartdns.@smartdns[0].enabled='1'
uci set smartdns.@smartdns[0].server_name='AX6000'
uci set smartdns.@smartdns[0].port='5353'
uci set smartdns.@smartdns[0].auto_set_dnsmasq='1'
uci set smartdns.@smartdns[0].tcp_server='1'
uci set smartdns.@smartdns[0].ipv6_server='1'
uci set smartdns.@smartdns[0].speed_check_mode='ping,tcp:80,tcp:443'
uci set smartdns.@smartdns[0].response_mode='fastest-response'
uci set smartdns.@smartdns[0].dualstack_ip_selection='1'
uci set smartdns.@smartdns[0].prefetch_domain='1'
uci set smartdns.@smartdns[0].serve_expired='1'
uci set smartdns.@smartdns[0].cache_size='32768'
uci set smartdns.@smartdns[0].rr_ttl_min='60'
uci set smartdns.@smartdns[0].rr_ttl_max='86400'
uci set smartdns.@smartdns[0].force_aaaa_soa='0'
uci commit smartdns

# 上游服务器：国内组（UDP + DoT，并发测速取最快），全部移出默认组
add_srv() {
	local s
	s=$(uci add smartdns server)
	uci set smartdns."$s".enabled='1'
	uci set smartdns."$s".name="$1"
	uci set smartdns."$s".ip="$2"
	[ -n "$3" ] && uci set smartdns."$s".port="$3"
	uci set smartdns."$s".type="$4"
	uci set smartdns."$s".server_group="$5"
	uci set smartdns."$s".exclude_default_group='1'
	[ -n "$6" ] && uci set smartdns."$s".tls_host_verify="$6"
}
add_srv 'Tencent' '119.29.29.29' '' 'udp' 'domestic'
add_srv 'AliDNS' '223.5.5.5' '' 'udp' 'domestic'
add_srv 'Baidu' '180.76.76.76' '' 'udp' 'domestic'
add_srv '114DNS' '114.114.114.114' '' 'udp' 'domestic'
add_srv 'AliDNS-DoT' '223.5.5.5' '853' 'tls' 'domestic' 'dot.alidns.com'
add_srv 'Tencent-DoT' '120.53.53.53' '853' 'tls' 'domestic' 'dot.pub'
# 国外组：转发给 Nikki/Mihomo 的 fake-ip DNS（127.0.0.1:1053），即时返回不走外网
add_srv 'Nikki' '127.0.0.1' '1053' 'udp' 'foreign'
uci commit smartdns

# 国内域名表 -> domestic 组；其它域名默认走 foreign 组（fake-ip）
mkdir -p /etc/smartdns/domain-set
LIST=/etc/smartdns/domain-set/china.txt
if [ ! -f "$LIST" ]; then
cat > "$LIST" << 'XEOF'
baidu.com
qq.com
taobao.com
tmall.com
jd.com
163.com
126.com
sina.com.cn
sohu.com
weibo.com
bilibili.com
douyin.com
kuaishou.com
zhihu.com
csdn.net
alipay.com
tenpay.com
12306.cn
10086.cn
10010.com
189.cn
icbc.com.cn
ccb.com
boc.cn
abchina.com
bankcomm.com
cmbchina.com
amap.com
meituan.com
ele.me
pinduoduo.com
xiaomi.com
huawei.com
oppo.com
vivo.com
lenovo.com.cn
suning.com
vip.com
youku.com
iqiyi.com
douyu.com
huya.com
58.com
zhaopin.com
51job.com
xueqiu.com
eastmoney.com
gov.cn
edu.cn
ctrip.com
qunar.com
xiaohongshu.com
dewu.com
smzdm.com
v2ex.com
jianshu.com
douban.com
XEOF
fi
r=$(uci add smartdns domain-rule-list)
uci set smartdns."$r".enabled='1'
uci set smartdns."$r".name='china'
uci set smartdns."$r".server_group='domestic'
uci set smartdns."$r".domain_list_file="$LIST"
uci commit smartdns

# ============ 国内域名表自动更新 ============
cat > /etc/smartdns/update-china-list.sh << 'XEOF'
#!/bin/sh
# 从 felixonmars/dnsmasq-china-list 拉取国内域名表，转为 SmartDNS domain-set 格式
DST=/etc/smartdns/domain-set/china.txt
TMP=/tmp/china.txt.update
for u in \
	"https://cdn.jsdelivr.net/gh/felixonmars/dnsmasq-china-list@master/accelerated-domains.china.conf" \
	"https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf" ; do
	curl -sSfL --max-time 90 "$u" -o "$TMP.src" 2>/dev/null || continue
	sed -e 's/^server=\///' -e 's|/[^/]*$||' "$TMP.src" | grep -E '^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | sort -u > "$TMP" 2>/dev/null
	if [ -s "$TMP" ]; then
		mv "$TMP" "$DST"
		rm -f "$TMP.src"
		/etc/init.d/smartdns reload >/dev/null 2>&1
		date +%s > /etc/smartdns/china.txt.updated 2>/dev/null
		exit 0
	fi
done
rm -f "$TMP" "$TMP.src"
exit 1
XEOF
chmod +x /etc/smartdns/update-china-list.sh
# 每周日 04:17 自动刷新
grep -q 'update-china-list' /etc/crontabs/root 2>/dev/null || echo '17 4 * * 0 /etc/smartdns/update-china-list.sh' >> /etc/crontabs/root
# 首次启动后台重试拉取（等 WAN 就绪，最多约 10 分钟）
nohup sh -c 'for i in $(seq 1 12); do sleep 50; /etc/smartdns/update-china-list.sh && break; done' >/dev/null 2>&1 &

# ============ Nikki（Mihomo）开箱 ============
uci set nikki.config.enabled='1'
# 低延迟调优：单次 RTT 测速 + TCP 并发拨号抢最快
uci set nikki.mixin.unify_delay='1'
uci set nikki.mixin.tcp_concurrent='1'
# 叠加规则：国内直连（prepend 到订阅自带规则之前，优先级最高）
uci set nikki.mixin.rule='1'
r=$(uci add nikki rule)
uci set nikki."$r".enabled='1'
uci set nikki."$r".type='GEOSITE'
uci set nikki."$r".matcher='cn'
uci set nikki."$r".node='DIRECT'
r=$(uci add nikki rule)
uci set nikki."$r".enabled='1'
uci set nikki."$r".type='GEOIP'
uci set nikki."$r".matcher='CN'
uci set nikki."$r".node='DIRECT'
uci set nikki."$r".no_resolve='1'
# 路由器本机 DNS 不劫持（保护 SmartDNS 上游查询直连；LAN 侧 53 端口劫持保留，硬编码 DNS 的客户端照样正确分流）
for s in $(uci show nikki 2>/dev/null | sed -n 's/^\(nikki\.@router_access_control\[[0-9]*\]\)\.dns=.*/\1/p'); do
	if [ -z "$(uci -q get "$s".user)" ] && [ -z "$(uci -q get "$s".group)" ] && [ -z "$(uci -q get "$s".cgroup)" ]; then
		uci set "$s".dns='0'
	fi
done
uci commit nikki

# ============ IPv4/IPv6 双栈 ============
# wan6（如缺失则补 DHCPv6）
if [ -z "$(uci -q get network.wan6.proto)" ]; then
	uci set network.wan6='interface' 2>/dev/null
	uci set network.wan6.proto='dhcpv6'
	uci set network.wan6.device='wan'
	uci set network.wan6.reqaddress='try'
	uci set network.wan6.reqprefix='auto'
	uci commit network
fi
# LAN IPv6 中继（上级路由/房东网关下游场景开箱即用；若改作主路由拨号，把这三项改回 server 并配 PD）
uci set dhcp.lan.ra='relay'
uci set dhcp.lan.dhcpv6='relay'
uci set dhcp.lan.ndp='relay'
uci commit dhcp

exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/97-smartdns-nikki
