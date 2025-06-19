#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${CYAN}开始安装 SingBox Lite 版本...${NC}"

# 创建目标目录
TARGET_DIR="/root/singbox"
mkdir -p "$TARGET_DIR"

# 当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENWRT_DIR="$(dirname "$SCRIPT_DIR")"

# 需要拷贝的文件列表
FILES=(
    "manage_autostart.sh"
    "start_singbox.sh"
    "stop_singbox.sh"
    "configure_tun.sh"
    "configure_tproxy.sh"
    "liteversion/update_config.sh"
    "liteversion/install_singbox.sh"
)

echo -e "${CYAN}拷贝文件到 $TARGET_DIR ...${NC}"

# 拷贝文件
for file in "${FILES[@]}"; do
    src_file="$OPENWRT_DIR/$file"
    if [ -f "$src_file" ]; then
        cp "$src_file" "$TARGET_DIR/"
        chmod +x "$TARGET_DIR/$(basename "$file")"
        echo -e "${GREEN}已拷贝: $(basename "$file")${NC}"
    else
        echo -e "${RED}文件不存在: $src_file${NC}"
    fi
done

echo -e "${GREEN}SingBox Lite 版本安装完成！${NC}"
echo -e "${CYAN}文件已安装到: $TARGET_DIR${NC}"
