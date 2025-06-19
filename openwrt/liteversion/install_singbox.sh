#!/bin/bash

# 定义颜色
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

if command -v sing-box &> /dev/null; then
    echo -e "${CYAN}sing-box 已安装，跳过安装步骤${NC}"
else
    echo "正在更新包列表并安装 sing-box,请稍候..."
    opkg update >/dev/null 2>&1
    opkg install kmod-nft-tproxy >/dev/null 2>&1
    opkg install sing-box >/dev/null 2>&1

    if command -v sing-box &> /dev/null; then
        echo -e "${CYAN}sing-box 安装成功${NC}"
    else
        echo -e "${RED}sing-box 安装失败，请检查日志或网络配置${NC}"
        exit 1
    fi
fi

# 创建lite版本目录结构
mkdir -p /etc/sing-box/config
mkdir -p /etc/sing-box/ui

# 创建完整的OpenWrt init脚本
cat << 'EOF' > /etc/init.d/sing-box
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/bin/sing-box run -c /etc/sing-box/config.json
    procd_set_param respawn
    procd_set_param stderr 1
    procd_set_param stdout 1
    procd_close_instance
    
    # 等待服务完全启动
    sleep 3
    
    # 读取模式并应用防火墙规则
    if [ -f /etc/sing-box/mode.conf ]; then
        MODE=$(grep -oE '^MODE=.*' /etc/sing-box/mode.conf | cut -d'=' -f2)
        if [ "$MODE" = "TProxy" ]; then
            /root/singbox/configure_tproxy.sh
        elif [ "$MODE" = "TUN" ]; then
            /root/singbox/configure_tun.sh
        fi
    fi
}

stop_service() {
    procd_kill "sing-box" 2>/dev/null
}
EOF

chmod +x /etc/init.d/sing-box

/etc/init.d/sing-box enable
/etc/init.d/sing-box start

echo -e "${CYAN}sing-box 服务已启用并启动 (Lite版本)${NC}" 