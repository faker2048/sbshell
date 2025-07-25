#!/bin/bash

# 定义颜色
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # 无颜色

# 脚本下载目录
SCRIPT_DIR="/etc/sing-box/scripts"

# 停止 sing-box 服务
stop_singbox() {
    echo -e "${CYAN}正在停止 sing-box 服务...${NC}"
    /etc/init.d/sing-box stop
    result=$?
    if [ $result -ne 0 ]; then
        echo -e "${CYAN}停止 sing-box 服务失败，返回码: $result${NC}"
    else
        echo -e "${GREEN}sing-box 已成功停止。${NC}"
    fi

    read -rp "是否清理防火墙规则？(y/n): " confirm_cleanup
    if [[ "$confirm_cleanup" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}执行清理防火墙规则...${NC}"
        nft list table inet sing-box >/dev/null 2>&1 && nft delete table inet sing-box
        echo -e "${GREEN}防火墙规则清理完毕${NC}"
    else
        echo -e "${CYAN}已取消清理防火墙规则。${NC}"
    fi
}

stop_singbox

