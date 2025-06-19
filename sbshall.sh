#!/bin/bash
# 定义主脚本的下载URL
DEBIAN_MAIN_SCRIPT_URL="https://gh-proxy.com/https://raw.githubusercontent.com/faker2048/sbshell/refs/heads/main/debian/menu.sh"
OPENWRT_MAIN_SCRIPT_URL="https://gh-proxy.com/https://raw.githubusercontent.com/faker2048/sbshell/refs/heads/main/openwrt/menu.sh"
GITHUB_API_URL="https://gh-proxy.com/https://api.github.com/repos/faker2048/sbshell/commits/main"
 
# 脚本下载目录
SCRIPT_DIR="/etc/sing-box/scripts"

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 获取最后一次commit时间
get_last_commit_time() {
    echo -e "${CYAN}获取项目最新更新信息...${NC}"
    
    # 使用gh-proxy.com加速访问GitHub API
    COMMIT_INFO=$(curl -s --connect-timeout 10 --max-time 15 "$GITHUB_API_URL" 2>/dev/null)
    
    if [ $? -eq 0 ] && echo "$COMMIT_INFO" | grep -q "commit"; then
        # 提取commit时间和消息
        COMMIT_DATE=$(echo "$COMMIT_INFO" | grep -o '"date":"[^"]*"' | head -1 | cut -d'"' -f4)
        COMMIT_MESSAGE=$(echo "$COMMIT_INFO" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        if [ -n "$COMMIT_DATE" ]; then
            # 转换UTC时间为可读格式
            if command -v date &> /dev/null; then
                LOCAL_TIME=$(date -d "$COMMIT_DATE" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$COMMIT_DATE")
            else
                LOCAL_TIME="$COMMIT_DATE"
            fi
            echo -e "${GREEN}最新更新时间: ${LOCAL_TIME}${NC}"
            [ -n "$COMMIT_MESSAGE" ] && echo -e "${GREEN}更新内容: ${COMMIT_MESSAGE}${NC}"
        fi
    else
        echo -e "${YELLOW}无法获取更新信息，继续安装...${NC}"
    fi
    echo ""
}

# 检查系统是否支持
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}当前系统不支持运行此脚本。${NC}"
    exit 1
fi

# 显示commit信息
get_last_commit_time

# 检查发行版并下载相应的主脚本
if grep -qi 'debian\|ubuntu\|armbian' /etc/os-release; then
    echo -e "${GREEN}系统为Debian/Ubuntu/Armbian,支持运行此脚本。${NC}"
    MAIN_SCRIPT_URL="$DEBIAN_MAIN_SCRIPT_URL"
    DEPENDENCIES=("wget" "nftables")

    # 检查 sudo 是否安装
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}sudo 未安装。${NC}"
        read -rp "是否安装 sudo?(y/n): " install_sudo
        if [[ "$install_sudo" =~ ^[Yy]$ ]]; then
            apt-get update
            apt-get install -y sudo
            if ! command -v sudo &> /dev/null; then
                echo -e "${RED}安装 sudo 失败，请手动安装 sudo 并重新运行此脚本。${NC}"
                exit 1
            fi
            echo -e "${GREEN}sudo 安装成功。${NC}"
        else
            echo -e "${RED}由于未安装 sudo,脚本无法继续运行。${NC}"
            exit 1
        fi
    fi

    # 检查并安装缺失的依赖项
    for DEP in "${DEPENDENCIES[@]}"; do
        if [ "$DEP" == "nftables" ]; then
            CHECK_CMD="nft --version"
        else
            CHECK_CMD="wget --version"
        fi

        if ! $CHECK_CMD &> /dev/null; then
            echo -e "${RED}$DEP 未安装。${NC}"
            read -rp "是否安装 $DEP?(y/n): " install_dep
            if [[ "$install_dep" =~ ^[Yy]$ ]]; then
                sudo apt-get update
                sudo apt-get install -y "$DEP"
                if ! $CHECK_CMD &> /dev/null; then
                    echo -e "${RED}安装 $DEP 失败，请手动安装 $DEP 并重新运行此脚本。${NC}"
                    exit 1
                fi
                echo -e "${GREEN}$DEP 安装成功。${NC}"
            else
                echo -e "${RED}由于未安装 $DEP,脚本无法继续运行。${NC}"
                exit 1
            fi
        fi
    done
elif grep -qi 'openwrt' /etc/os-release; then
    echo -e "${GREEN}系统为OpenWRT,支持运行此脚本。${NC}"
    MAIN_SCRIPT_URL="$OPENWRT_MAIN_SCRIPT_URL"
    DEPENDENCIES=("nftables")

    # 检查并安装缺失的依赖项
    for DEP in "${DEPENDENCIES[@]}"; do
        if [ "$DEP" == "nftables" ]; then
            CHECK_CMD="nft --version"
        fi

        if ! $CHECK_CMD &> /dev/null; then
            echo -e "${RED}$DEP 未安装。${NC}"
            read -rp "是否安装 $DEP?(y/n): " install_dep
            if [[ "$install_dep" =~ ^[Yy]$ ]]; then
                opkg update
                opkg install "$DEP"
                if ! $CHECK_CMD &> /dev/null; then
                    echo -e "${RED}安装 $DEP 失败，请手动安装 $DEP 并重新运行此脚本。${NC}"
                    exit 1
                fi
                echo -e "${GREEN}$DEP 安装成功。${NC}"
            else
                echo -e "${RED}由于未安装 $DEP,脚本无法继续运行。${NC}"
                exit 1
            fi
        fi
    done
else
    echo -e "${RED}当前系统不是Debian/Ubuntu/Armbian/OpenWRT,不支持运行此脚本。${NC}"
    exit 1
fi

# 确保脚本目录存在并设置权限
if grep -qi 'openwrt' /etc/os-release; then
    mkdir -p "$SCRIPT_DIR"
else
    sudo mkdir -p "$SCRIPT_DIR"
    sudo chown "$(whoami)":"$(whoami)" "$SCRIPT_DIR"
fi

# 显示菜单选项
show_menu() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}     SingBox Shell 管理脚本${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}1. 进入完整版菜单${NC}"
    echo -e "${YELLOW}2. 安装 Lite 版本到 /root/singbox${NC}"
    echo -e "${YELLOW}3. 退出${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -n -e "${GREEN}请选择操作 [1-3]: ${NC}"
}

# 安装 lite version 功能
install_lite_version() {
    echo -e "${CYAN}开始安装 SingBox Lite 版本...${NC}"
    
    # 检查是否为 OpenWRT 系统
    if ! grep -qi 'openwrt' /etc/os-release; then
        echo -e "${RED}Lite 版本仅支持 OpenWRT 系统${NC}"
        return 1
    fi
    
    # 创建目标目录
    TARGET_DIR="/root/singbox"
    mkdir -p "$TARGET_DIR"
    
    # GitHub 原始文件 URL 前缀
    GITHUB_RAW_URL="https://gh-proxy.com/https://raw.githubusercontent.com/faker2048/sbshell/refs/heads/main"
    
    # 需要下载的文件列表及其目标文件名
    declare -A FILES=(
        ["$GITHUB_RAW_URL/openwrt/install_singbox.sh"]="install_singbox.sh"
        ["$GITHUB_RAW_URL/openwrt/manage_autostart.sh"]="manage_autostart.sh"
        ["$GITHUB_RAW_URL/openwrt/start_singbox.sh"]="start_singbox.sh"
        ["$GITHUB_RAW_URL/openwrt/stop_singbox.sh"]="stop_singbox.sh"
        ["$GITHUB_RAW_URL/openwrt/liteversion/install_lite_version.sh"]="install_lite_version.sh"
    )
    
    echo -e "${CYAN}下载文件到 $TARGET_DIR ...${NC}"
    
    # 下载文件
    for url in "${!FILES[@]}"; do
        filename="${FILES[$url]}"
        target_file="$TARGET_DIR/$filename"
        
        echo -e "${YELLOW}正在下载: $filename${NC}"
        if curl -s -o "$target_file" "$url"; then
            if [ -f "$target_file" ] && [ -s "$target_file" ]; then
                chmod +x "$target_file"
                echo -e "${GREEN}已下载: $filename${NC}"
            else
                echo -e "${RED}下载失败: $filename (文件为空或不存在)${NC}"
            fi
        else
            echo -e "${RED}下载失败: $filename${NC}"
        fi
    done
    
    echo -e "${GREEN}SingBox Lite 版本安装完成！${NC}"
    echo -e "${CYAN}文件已安装到: $TARGET_DIR${NC}"
}

# 显示菜单并处理用户选择
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            # 下载并执行主脚本
            if grep -qi 'openwrt' /etc/os-release; then
                curl -s -o "$SCRIPT_DIR/menu.sh" "$MAIN_SCRIPT_URL"
            else
                wget -q -O "$SCRIPT_DIR/menu.sh" "$MAIN_SCRIPT_URL"
            fi

            echo -e "${GREEN}脚本下载中,请耐心等待...${NC}"
            echo -e "${YELLOW}注意:安装更新singbox尽量使用代理环境,运行singbox切记关闭代理!${NC}"

            if ! [ -f "$SCRIPT_DIR/menu.sh" ]; then
                echo -e "${RED}下载主脚本失败,请检查网络连接。${NC}"
                exit 1
            fi

            chmod +x "$SCRIPT_DIR/menu.sh"
            bash "$SCRIPT_DIR/menu.sh"
            break
            ;;
        2)
            install_lite_version
            echo -n -e "${GREEN}按任意键继续...${NC}"
            read -r
            ;;
        3)
            echo -e "${GREEN}退出程序${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入${NC}"
            sleep 1
            ;;
    esac
done