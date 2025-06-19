#!/bin/bash

# 定义颜色
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

CONFIG_FILE="/etc/sing-box/config.json"
BACKUP_FILE="/etc/sing-box/config.json.backup"

echo -e "${CYAN}手动更新 sing-box 配置文件${NC}"
echo ""

# 备份当前配置
backup_config() {
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}已备份当前配置到: $BACKUP_FILE${NC}"
    fi
}

# 恢复备份配置
restore_backup() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        echo -e "${GREEN}已恢复备份配置${NC}"
    fi
}

# 验证配置文件
validate_config() {
    if ! sing-box check -c "$CONFIG_FILE"; then
        echo -e "${RED}配置文件验证失败，恢复备份...${NC}"
        restore_backup
        return 1
    fi
    return 0
}

# 处理本地文件
handle_local_file() {
    local source_path="$1"
    
    if [ ! -f "$source_path" ]; then
        echo -e "${RED}本地文件不存在: $source_path${NC}"
        return 1
    fi
    
    backup_config
    cp "$source_path" "$CONFIG_FILE"
    echo -e "${GREEN}已复制本地文件到配置目录${NC}"
    
    if validate_config; then
        echo -e "${GREEN}配置文件更新成功！${NC}"
        return 0
    else
        return 1
    fi
}

# 处理远程文件
handle_remote_file() {
    local url="$1"
    
    backup_config
    
    if wget -O "$CONFIG_FILE" "$url" --timeout=30; then
        echo -e "${GREEN}已下载远程配置文件${NC}"
        
        if validate_config; then
            echo -e "${GREEN}配置文件更新成功！${NC}"
            return 0
        else
            return 1
        fi
    else
        echo -e "${RED}下载失败，恢复备份...${NC}"
        restore_backup
        return 1
    fi
}

# 主逻辑
while true; do
    read -rp "请输入配置文件路径或URL: " input_path
    
    if [ -z "$input_path" ]; then
        echo -e "${RED}路径不能为空${NC}"
        continue
    fi
    
    # 判断是本地文件还是远程URL
    if [[ "$input_path" =~ ^https?:// ]]; then
        echo -e "${CYAN}检测到远程URL，开始下载...${NC}"
        if handle_remote_file "$input_path"; then
            break
        fi
    else
        echo -e "${CYAN}检测到本地路径，开始复制...${NC}"
        if handle_local_file "$input_path"; then
            break
        fi
    fi
    
    read -rp "操作失败，是否重试？(y/n): " retry
    if [[ ! "$retry" =~ ^[Yy]$ ]]; then
        echo -e "${RED}操作已取消${NC}"
        exit 1
    fi
done

# 重启sing-box
echo -e "${CYAN}重启 sing-box 服务...${NC}"
/etc/init.d/sing-box restart

if /etc/init.d/sing-box status | grep -q "running"; then
    echo -e "${GREEN}sing-box 启动成功${NC}"
else
    echo -e "${RED}sing-box 启动失败${NC}"
fi
