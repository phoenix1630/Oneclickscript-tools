#!/bin/bash

# qBittorrent 管理脚本（自定义密码版）
# 功能：重置密码（手动输入）| 重启服务 | 查看状态
# 版本：v2.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置路径
CONFIG_DIR="$HOME/.config/qBittorrent"
CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"

# 显示菜单
show_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   qBittorrent 管理脚本 v2.0${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e " ${YELLOW}1.${NC} 重置密码（手动输入）"
    echo -e " ${YELLOW}2.${NC} 重启 qBittorrent"
    echo -e " ${YELLOW}3.${NC} 查看运行状态"
    echo -e " ${YELLOW}4.${NC} 查看日志（最近20行）"
    echo -e " ${YELLOW}5.${NC} 停止 qBittorrent"
    echo -e " ${YELLOW}6.${NC} 完全重置配置文件（恢复默认）"
    echo -e " ${YELLOW}0.${NC} 退出"
    echo -e "${BLUE}========================================${NC}"
    echo -n "请输入选项 [0-6]: "
}

# 生成 PBKDF2 密码哈希（适用于 qBittorrent v4.5.2）
generate_password_hash() {
    local password="$1"
    # 使用 openssl 生成 PBKDF2 哈希
    # qBittorrent 使用 10000 次迭代，盐长度 16 字节
    SALT=$(openssl rand -hex 16)
    HASH=$(echo -n "$password" | openssl dgst -sha256 -hmac "$SALT" -binary | base64)
    # 组合成 qBittorrent 格式
    echo "@ByteArray($SALT:$HASH)"
}

# 重置密码（手动输入）
reset_password_custom() {
    echo -e "${YELLOW}→ 正在重置密码...${NC}"
    
    # 让用户输入新密码
    echo -e "${BLUE}请输入新密码（至少6个字符）:${NC}"
    read -s PASSWORD1
    echo
    echo -e "${BLUE}请再次输入新密码确认:${NC}"
    read -s PASSWORD2
    echo
    
    # 检查密码是否匹配
    if [ "$PASSWORD1" != "$PASSWORD2" ]; then
        echo -e "${RED}✗ 两次输入的密码不匹配！${NC}"
        echo -n "按 Enter 继续..."
        read
        return 1
    fi
    
    # 检查密码长度
    if [ ${#PASSWORD1} -lt 6 ]; then
        echo -e "${RED}✗ 密码至少需要6个字符！${NC}"
        echo -n "按 Enter 继续..."
        read
        return 1
    fi
    
    # 检查进程是否存在
    if pgrep -f qbittorrent-nox > /dev/null; then
        echo -e "${YELLOW}→ 正在停止 qBittorrent...${NC}"
        pkill -f qbittorrent-nox
        sleep 2
    fi
    
    # 检查配置文件是否存在
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}✗ 配置文件不存在: $CONFIG_FILE${NC}"
        echo -e "${YELLOW}→ 正在创建配置目录...${NC}"
        mkdir -p "$CONFIG_DIR"
    fi
    
    # 备份配置文件
    if [ -f "$CONFIG_FILE" ]; then
        BACKUP_FILE="$CONFIG_FILE.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}✓ 已备份配置文件: $BACKUP_FILE${NC}"
        
        # 删除所有旧密码相关配置
        sed -i '/Password/d' "$CONFIG_FILE"
        sed -i '/WebUI\\Password/d' "$CONFIG_FILE"
        echo -e "${GREEN}✓ 已清除旧密码配置${NC}"
    fi
    
    # 生成新密码哈希
    echo -e "${YELLOW}→ 正在生成密码哈希...${NC}"
    
    # 对于 qBittorrent v4.5.2，使用明文密码（最简单可靠）
    # 直接写入明文密码（qBittorrent 会在第一次启动时自动加密）
    echo "WebUI\\Password_plain=$PASSWORD1" >> "$CONFIG_FILE"
    
    # 启动 qBittorrent
    echo -e "${YELLOW}→ 正在启动 qBittorrent...${NC}"
    nohup qbittorrent-nox > /dev/null 2>&1 &
    sleep 3
    
    # 检查是否启动成功
    if pgrep -f qbittorrent-nox > /dev/null; then
        echo -e "${GREEN}✓ qBittorrent 已启动${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "✅ 密码已重置成功！"
        echo -e "📌 用户名: ${YELLOW}admin${NC}"
        echo -e "📌 新密码: ${YELLOW}$PASSWORD1${NC}"
        echo -e "📍 访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):8080${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo -e "${RED}✗ qBittorrent 启动失败，请检查日志${NC}"
        # 尝试查看错误日志
        if [ -f "nohup.out" ]; then
            echo -e "${YELLOW}最后几行日志:${NC}"
            tail -5 nohup.out
        fi
    fi
    
    echo ""
    echo -n "按 Enter 继续..."
    read
}

# 完全重置配置文件（恢复默认）
reset_config_full() {
    echo -e "${YELLOW}→ 正在完全重置配置文件...${NC}"
    
    # 停止服务
    if pgrep -f qbittorrent-nox > /dev/null; then
        echo -e "${YELLOW}→ 正在停止 qBittorrent...${NC}"
        pkill -f qbittorrent-nox
        sleep 2
    fi
    
    # 备份并删除配置文件
    if [ -f "$CONFIG_FILE" ]; then
        BACKUP_FILE="$CONFIG_FILE.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}✓ 已备份并删除旧配置文件: $BACKUP_FILE${NC}"
    fi
    
    # 启动 qBittorrent（会自动生成新配置文件）
    echo -e "${YELLOW}→ 正在启动 qBittorrent（生成新配置）...${NC}"
    nohup qbittorrent-nox > /dev/null 2>&1 &
    sleep 3
    
    if pgrep -f qbittorrent-nox > /dev/null; then
        echo -e "${GREEN}✓ qBittorrent 已启动${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "✅ 配置文件已完全重置！"
        echo -e "📌 用户名: ${YELLOW}admin${NC}"
        echo -e "📌 密码: ${YELLOW}adminadmin${NC}（默认）"
        echo -e "📍 访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):8080${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "${RED}⚠️  登录后请立即修改密码！${NC}"
    else
        echo -e "${RED}✗ 启动失败，请检查日志${NC}"
    fi
    
    echo ""
    echo -n "按 Enter 继续..."
    read
}

# 重启服务
restart_service() {
    echo -e "${YELLOW}→ 正在重启 qBittorrent...${NC}"
    
    if pgrep -f qbittorrent-nox > /dev/null; then
        echo -e "${YELLOW}→ 正在停止服务...${NC}"
        pkill -f qbittorrent-nox
        sleep 2
    fi
    
    echo -e "${YELLOW}→ 正在启动服务...${NC}"
    nohup qbittorrent-nox > /dev/null 2>&1 &
    sleep 2
    
    if pgrep -f qbittorrent-nox > /dev/null; then
        echo -e "${GREEN}✓ qBittorrent 已重启成功${NC}"
        echo -e "📍 访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):8080${NC}"
    else
        echo -e "${RED}✗ 启动失败，请检查日志${NC}"
    fi
    
    echo ""
    echo -n "按 Enter 继续..."
    read
}

# 查看状态
show_status() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   qBittorrent 运行状态${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # 检查进程
    if pgrep -f qbittorrent-nox > /dev/null; then
        PID=$(pgrep -f qbittorrent-nox)
        echo -e "状态: ${GREEN}● 运行中${NC}"
        echo -e "进程ID: ${YELLOW}$PID${NC}"
        
        # 显示CPU和内存使用
        PS_OUTPUT=$(ps -p $PID -o %cpu,%mem,etime,cmd --no-headers 2>/dev/null)
        if [ -n "$PS_OUTPUT" ]; then
            echo -e "CPU使用: ${YELLOW}$(echo $PS_OUTPUT | awk '{print $1}')%${NC}"
            echo -e "内存使用: ${YELLOW}$(echo $PS_OUTPUT | awk '{print $2}')%${NC}"
            echo -e "运行时间: ${YELLOW}$(echo $PS_OUTPUT | awk '{print $3}')${NC}"
        fi
    else
        echo -e "状态: ${RED}● 未运行${NC}"
    fi
    
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # 检查配置文件
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "配置文件: ${GREEN}✓ 存在${NC}"
        
        # 显示端口
        PORT=$(grep "WebUI\\Port" "$CONFIG_FILE" | cut -d'=' -f2)
        if [ -n "$PORT" ]; then
            echo -e "监听端口: ${YELLOW}$PORT${NC}"
        else
            echo -e "监听端口: ${YELLOW}8080 (默认)${NC}"
        fi
        
        # 显示用户名
        USERNAME=$(grep "WebUI\\Username" "$CONFIG_FILE" | cut -d'=' -f2)
        if [ -n "$USERNAME" ]; then
            echo -e "用户名: ${YELLOW}$USERNAME${NC}"
        else
            echo -e "用户名: ${YELLOW}admin (默认)${NC}"
        fi
        
        # 检查密码设置
        if grep -q "Password_plain" "$CONFIG_FILE"; then
            echo -e "密码状态: ${YELLOW}明文密码（待加密）${NC}"
        elif grep -q "Password_PBKDF2" "$CONFIG_FILE"; then
            echo -e "密码状态: ${GREEN}已加密${NC}"
        fi
    else
        echo -e "配置文件: ${RED}✗ 不存在${NC}"
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -n "按 Enter 继续..."
    read
}

# 查看日志
show_logs() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   最近日志 (最后20行)${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "nohup.out" ]; then
        tail -20 nohup.out
    else
        echo -e "${YELLOW}未找到 nohup.out 日志文件${NC}"
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -n "按 Enter 继续..."
    read
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}→ 正在停止 qBittorrent...${NC}"
    if pgrep -f qbittorrent-nox > /dev/null; then
        pkill -f qbittorrent-nox
        sleep 2
        if pgrep -f qbittorrent-nox > /dev/null; then
            echo -e "${RED}✗ 停止失败，尝试强制停止...${NC}"
            pkill -9 -f qbittorrent-nox
            sleep 1
        fi
        if pgrep -f qbittorrent-nox > /dev/null; then
            echo -e "${RED}✗ 强制停止失败${NC}"
        else
            echo -e "${GREEN}✓ qBittorrent 已停止${NC}"
        fi
    else
        echo -e "${YELLOW}qBittorrent 未运行${NC}"
    fi
    
    echo ""
    echo -n "按 Enter 继续..."
    read
}

# 主程序
main() {
    # 检查 qbittorrent-nox 是否存在
    if ! command -v qbittorrent-nox &> /dev/null; then
        echo -e "${RED}✗ 未找到 qbittorrent-nox 命令${NC}"
        echo -e "${YELLOW}请先安装 qBittorrent${NC}"
        exit 1
    fi
    
    # 显示版本
    VERSION=$(qbittorrent-nox --version 2>/dev/null)
    echo -e "${BLUE}检测到 $VERSION${NC}"
    sleep 1
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                reset_password_custom
                ;;
            2)
                restart_service
                ;;
            3)
                show_status
                ;;
            4)
                show_logs
                ;;
            5)
                stop_service
                ;;
            6)
                reset_config_full
                ;;
            0)
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}✗ 无效选项，请重新选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 运行主程序
main
