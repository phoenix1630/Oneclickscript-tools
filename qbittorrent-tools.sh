#!/bin/bash

# qBittorrent 管理脚本
# 功能：重置密码 | 重启服务 | 查看状态
# 版本：v1.0

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
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   qBittorrent 管理脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e " ${YELLOW}1.${NC} 重置密码为 adminadmin"
    echo -e " ${YELLOW}2.${NC} 重启 qBittorrent"
    echo -e " ${YELLOW}3.${NC} 查看运行状态"
    echo -e " ${YELLOW}4.${NC} 查看日志（最近20行）"
    echo -e " ${YELLOW}5.${NC} 停止 qBittorrent"
    echo -e " ${YELLOW}0.${NC} 退出"
    echo -e "${BLUE}========================================${NC}"
    echo -n "请输入选项 [0-5]: "
}

# 重置密码
reset_password() {
    echo -e "${YELLOW}→ 正在重置密码...${NC}"
    
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
        
        # 删除密码相关配置
        sed -i '/Password/d' "$CONFIG_FILE"
        echo -e "${GREEN}✓ 已清除密码配置${NC}"
    fi
    
    # 启动 qBittorrent
    echo -e "${YELLOW}→ 正在启动 qBittorrent...${NC}"
    nohup qbittorrent-nox > /dev/null 2>&1 &
    sleep 2
    
    # 检查是否启动成功
    if pgrep -f qbittorrent-nox > /dev/null; then
        echo -e "${GREEN}✓ qBittorrent 已启动${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "✅ 密码已重置为: ${YELLOW}adminadmin${NC}"
        echo -e "📌 用户名: ${YELLOW}admin${NC}"
        echo -e "📌 密码: ${YELLOW}adminadmin${NC}"
        echo -e "📍 访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):8080${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "${RED}⚠️  登录后请立即修改密码！${NC}"
    else
        echo -e "${RED}✗ qBittorrent 启动失败，请检查日志${NC}"
    fi
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
}

# 查看状态
show_status() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   qBittorrent 运行状态${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # 检查进程
    if pgrep -f qbittorrent-nox > /dev/null; then
        PID=$(pgrep -f qbittorrent-nox)
        echo -e "状态: ${GREEN}● 运行中${NC}"
        echo -e "进程ID: ${YELLOW}$PID${NC}"
        
        # 显示CPU和内存使用
        PS_OUTPUT=$(ps -p $PID -o %cpu,%mem,etime,cmd --no-headers)
        echo -e "CPU使用: ${YELLOW}$(echo $PS_OUTPUT | awk '{print $1}')%${NC}"
        echo -e "内存使用: ${YELLOW}$(echo $PS_OUTPUT | awk '{print $2}')%${NC}"
        echo -e "运行时间: ${YELLOW}$(echo $PS_OUTPUT | awk '{print $3}')${NC}"
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
    else
        echo -e "配置文件: ${RED}✗ 不存在${NC}"
    fi
    
    echo -e "${BLUE}========================================${NC}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   最近日志 (最后20行)${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "nohup.out" ]; then
        tail -20 nohup.out
    else
        echo -e "${YELLOW}未找到 nohup.out 日志文件${NC}"
    fi
    
    echo -e "${BLUE}========================================${NC}"
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
        fi
        echo -e "${GREEN}✓ qBittorrent 已停止${NC}"
    else
        echo -e "${YELLOW}qBittorrent 未运行${NC}"
    fi
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
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                reset_password
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
            0)
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}✗ 无效选项，请重新选择${NC}"
                ;;
        esac
        
        echo ""
        echo -n "按 Enter 继续..."
        read
        clear
    done
}

# 运行主程序
main
