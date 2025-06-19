#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法: $0 <新配置文件路径>"
    exit 1
fi

CONFIG_FILE="/etc/sing-box/config.json"

# 备份现有配置
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    echo "已备份配置文件"
fi

# 复制新配置
cp "$1" "$CONFIG_FILE"
echo "配置文件已更新"
