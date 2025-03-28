#!/bin/bash
# ddns-go 自动安装脚本
# 使用方法: chmod +x ddns-go.sh && ./ddns-go.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/ddns-go.sh && chmod +x ddns-go.sh && ./ddns-go.sh

# 彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
DDNS_VERSION=""  # 当前指定的 ddns-go 版本
DDNS_PATH="/root/ddns"
SCRIPT_VERSION="1.0.0"

# 日志函数
log_info() {
    echo -e "${GREEN}[信息]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 获取最新版本号
get_latest_version() {
    local version=""
    
    # 方法1：利用GitHub重定向特性获取最新版本
    local redirect_url=$(curl -s -L -o /dev/null -w '%{url_effective}' https://github.com/jeessy2/ddns-go/releases/latest 2>/dev/null)
    version=$(echo "$redirect_url" | grep -o 'tag/v[0-9.]*' | cut -d/ -f2 2>/dev/null)
    
    # 如果获取失败，尝试备用方法
    if [[ -z "$version" ]]; then
        # 方法2: 通过API获取
        version=$(curl -s https://api.github.com/repos/jeessy2/ddns-go/releases/latest | grep -o '"tag_name": "v[0-9.]*"' | cut -d'"' -f4 2>/dev/null)
    fi
    
    # 如果还是失败，返回默认版本
    if [[ -z "$version" ]]; then
        version="v6.9.1" # 默认版本
    fi
    
    # 直接返回版本号，不打印任何日志
    echo "$version"
}

# 检测系统架构
detect_arch() {
    # 获取架构
    local arch=$(uname -m)
    local arch_type=""
    
    # 转换架构名称为ddns-go使用的格式
    case "$arch" in
        x86_64)
            arch_type="linux_x86_64"
            ;;
        i386|i686)
            arch_type="linux_x86"
            ;;
        aarch64|arm64)
            arch_type="linux_arm64"
            ;;
        armv7*|armv6*)
            arch_type="linux_armv7"
            ;;
        armv8*)
            arch_type="linux_arm64"
            ;;
        *)
            log_warn "未知架构: $arch，将尝试使用x86_64版本"
            arch_type="linux_x86_64"
            ;;
    esac
    
    # 直接返回结果而不是写入临时文件
    echo "$arch_type"
}

# 获取IP地址信息
get_ip_info() {
    local ipv4=$(curl -s ipv4.ip.sb)
    local ipv6=$(curl -s ipv6.ip.sb 2>/dev/null || echo "无")
    
    echo "$ipv4|$ipv6"
}

# 配置防火墙 - 仅处理 UFW
configure_firewall() {
    local port=$1
    log_info "配置防火墙"
    
    # 检查是否安装了 ufw
    if command -v ufw &>/dev/null; then
        # 检查ufw是否启用
        local ufw_status=$(ufw status | grep -o "Status: active" 2>/dev/null)
        
        if [[ -z "$ufw_status" ]]; then
            log_warn "UFW 防火墙未启用，可能需要手动配置防火墙规则"
            log_info "您可以运行 'sudo ufw enable' 启用 UFW 防火墙"
            return 0
        fi
        
        # 检查端口是否已经开放
        if ufw status | grep -q "$port/tcp"; then
            log_info "端口 $port 已经开放，跳过"
            return 0
        fi
        
        # 开放端口
        echo -n "配置 UFW 防火墙，开放端口 $port... "
        if ufw allow "$port/tcp" &>/dev/null; then
            echo -e "${GREEN}完成${NC}"
            log_info "已在 UFW 防火墙开放端口: $port"
        else
            echo -e "${RED}失败${NC}"
            log_warn "无法开放端口 $port"
        fi
    else
        log_warn "未检测到 UFW 防火墙，跳过防火墙配置"
        log_info "如需管理防火墙规则，请安装 UFW: sudo apt install ufw"
    fi
    
    return 0
}

# 关闭防火墙端口 - 仅处理 UFW
close_firewall_port() {
    local port=$1
    log_info "关闭防火墙端口"
    
    # 检查是否安装了 ufw
    if command -v ufw &>/dev/null; then
        # 检查ufw是否启用
        local ufw_status=$(ufw status | grep -o "Status: active" 2>/dev/null)
        
        if [[ -z "$ufw_status" ]]; then
            log_warn "UFW 防火墙未启用，跳过防火墙配置"
            return 0
        fi
        
        # 检查端口是否已开放在UFW中
        if ! ufw status | grep -q "$port/tcp"; then
            log_info "端口 $port 未在 UFW 中开放，跳过"
            return 0
        fi
        
        # 关闭端口
        echo -n "关闭 UFW 防火墙端口 $port... "
        if ufw delete allow "$port/tcp" &>/dev/null; then
            echo -e "${GREEN}完成${NC}"
            log_info "已关闭 UFW 防火墙端口: $port"
        else
            echo -e "${RED}失败${NC}"
            log_warn "无法关闭端口 $port"
        fi
    else
        log_warn "未检测到 UFW 防火墙，跳过防火墙配置"
    fi
    
    return 0
}

# 安装 ddns-go
install_ddns_go() {
    clear
    echo "=================================================="
    echo -e "${GREEN}开始安装 ddns-go${NC}"
    echo "=================================================="
    
    log_info "开始安装 ddns-go..."
    
    # 询问用户是否自定义端口
    local web_port="9876"  # 默认端口
    read -rp "是否自定义web访问端口? [y/N] " custom_port
    if [[ "$custom_port" =~ ^[yY]$ ]]; then
        while true; do
            read -rp "请输入端口号 (1-65535): " web_port
            if [[ "$web_port" =~ ^[0-9]+$ ]] && [ "$web_port" -ge 1 ] && [ "$web_port" -le 65535 ]; then
                log_info "将使用端口: $web_port"
                break
            else
                log_error "无效的端口号，请输入1-65535之间的数字"
            fi
        done
    else
        log_info "将使用默认端口: $web_port"
    fi
    
    # 更新软件包
    log_info "更新软件包..."
    apt update -y && apt upgrade -y
    
    # 安装必要工具
    log_info "安装必要工具..."
    apt install -y wget curl sudo vim git
    
    # 创建安装目录
    mkdir -p $DDNS_PATH
    
    # 1. 获取版本 - 先获取所有必要变量，不输出日志
    local version=""
    if [[ -n "$DDNS_VERSION" ]]; then
        version="$DDNS_VERSION"
    else
        version=$(get_latest_version)
    fi
    
    # 2. 移除版本号前的 'v'
    local version_num=${version#v}
    
    # 3. 检测系统架构 - 使用改进后的函数，直接返回结果
    local arch_suffix=$(detect_arch)
    
    # 4. 构建下载URL - 使用纯文本变量
    local download_file="ddns-go_${version_num}_${arch_suffix}.tar.gz"
    local download_path="${DDNS_PATH}/${download_file}"
    local download_url="https://github.com/jeessy2/ddns-go/releases/download/${version}/${download_file}"
    
    # 5. 现在安全地输出日志
    log_info "获取到最新版本：$version"
    log_info "检测到系统架构: $(uname -m) (使用: $arch_suffix)"
    log_info "下载链接: $download_url"
    
    # 6. 下载文件 - 统一使用curl下载
    log_info "正在下载 ddns-go..."
    
    if curl -s -L -o "$download_path" "$download_url"; then
        log_info "下载成功"
    else
        log_error "下载失败，请检查网络连接"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 7. 解压文件
    log_info "正在解压文件..."
    if tar -zxf "$download_path" -C $DDNS_PATH; then
        log_info "解压成功"
    else
        log_error "解压失败"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 8. 设置权限
    chmod +x $DDNS_PATH/ddns-go
    
    # 9. 验证可执行文件
    log_info "验证 ddns-go 二进制文件..."
    if [ ! -f $DDNS_PATH/ddns-go ]; then
        log_error "未找到 ddns-go 可执行文件"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 10. 测试运行
    if ! $DDNS_PATH/ddns-go -h > /dev/null 2>&1; then
        log_error "ddns-go 可执行文件无法运行，可能是架构不匹配"
        log_info "尝试检查更多架构版本..."
        
        # 清理之前的文件
        rm -rf $DDNS_PATH/*
        
        # 尝试其他架构版本
        local try_arch_list=("linux_arm64" "linux_armv7" "linux_x86" "linux_x86_64")
        local success=false
        
        for try_arch in "${try_arch_list[@]}"; do
            if [ "$try_arch" != "$arch_suffix" ]; then
                log_info "尝试 $try_arch 架构版本..."
                
                # 构建下载信息
                local try_file="ddns-go_${version_num}_${try_arch}.tar.gz"
                local try_path="${DDNS_PATH}/${try_file}"
                local try_url="https://github.com/jeessy2/ddns-go/releases/download/${version}/${try_file}"
                
                # 下载并解压 - 统一使用curl
                if curl -s -L -o "$try_path" "$try_url" && 
                   tar -zxf "$try_path" -C $DDNS_PATH &&
                   chmod +x $DDNS_PATH/ddns-go; then
                   
                    # 测试是否可运行
                    if $DDNS_PATH/ddns-go -h > /dev/null 2>&1; then
                        log_info "$try_arch 架构版本可以运行"
                        success=true
                        break
                    else
                        log_warn "$try_arch 架构版本不兼容"
                    fi
                else
                    log_warn "$try_arch 架构版本下载或解压失败"
                fi
            fi
        done
        
        # 如果所有架构都尝试失败
        if [ "$success" = false ]; then
            log_error "无法找到合适的版本，安装失败"
            read -rp "按回车键返回主菜单..." temp
            show_menu
            return 1
        fi
    fi
    
    # 11. 安装服务
    log_info "安装系统服务..."
    cd $DDNS_PATH
    ./ddns-go -s install -l 0.0.0.0:$web_port
    
    # 12. 验证服务
    if systemctl status ddns-go > /dev/null 2>&1; then
        log_info "ddns-go 服务已成功安装并运行"
    else
        log_warn "ddns-go 服务可能未正确启动，请手动检查: systemctl status ddns-go"
    fi
    
    # 13. 获取IP信息
    local ip_info=$(get_ip_info)
    local ipv4=$(echo "$ip_info" | cut -d'|' -f1)
    
    # 14. 配置防火墙
    configure_firewall $web_port
    
    log_info "ddns-go 安装完成！"
    echo "=================================================="
    echo -e "${GREEN}安装成功!${NC}"
    echo -e "${CYAN}Web管理界面访问地址: http://$ipv4:$web_port${NC}"
    echo -e "请在浏览器中打开上述地址进行配置"
    echo "=================================================="
    
    # 清理下载文件
    rm -f "$download_path"
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 卸载服务
uninstall_ddns_go() {
    clear
    echo "=================================================="
    echo -e "${RED}开始卸载 ddns-go${NC}"
    echo "=================================================="
    
    # 确认卸载
    echo -e "${YELLOW}警告: 这将卸载 ddns-go 并删除相关文件${NC}"
    read -rp "是否继续? [Y/n] " confirm
    if [[ "$confirm" =~ ^[nN]$ ]]; then
        log_info "卸载已取消"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    log_info "正在卸载 ddns-go 服务..."
    
    # 获取端口信息用于关闭防火墙
    local port=""
    if [ -d "$DDNS_PATH" ] && [ -f "$DDNS_PATH/config.yaml" ]; then
        port=$(grep -o 'listen: 0.0.0.0:[0-9]*' "$DDNS_PATH/config.yaml" 2>/dev/null | grep -o '[0-9]*$' | head -n 1)
    fi
    
    if [[ -z "$port" ]]; then
        port=$(systemctl status ddns-go 2>/dev/null | grep -o '\-l 0.0.0.0:[0-9]*' | grep -o '[0-9]*$' | head -n 1)
    fi
    
    if [ -d "$DDNS_PATH" ]; then
        cd $DDNS_PATH
        if [ -f "./ddns-go" ]; then
            ./ddns-go -s uninstall
            log_info "服务已卸载"
        else
            log_error "找不到 ddns-go 可执行文件"
        fi
        
        # 询问是否删除文件
        read -rp "是否删除所有 ddns-go 文件? [Y/n] " delete_confirm
        if [[ ! "$delete_confirm" =~ ^[nN]$ ]]; then
            rm -rf $DDNS_PATH
            log_info "所有文件已删除"
        else
            log_info "文件已保留"
        fi
    else
        log_error "找不到 ddns-go 安装目录"
    fi
    
    # 关闭防火墙端口
    if [[ -n "$port" ]]; then
        close_firewall_port $port
    fi
    
    log_info "ddns-go 卸载完成！"
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 更新 ddns-go
update_ddns_go() {
    clear
    echo "=================================================="
    echo -e "${YELLOW}更新 ddns-go${NC}"
    echo "=================================================="
    
    # 检查是否已安装
    if [ ! -d "$DDNS_PATH" ] || [ ! -f "$DDNS_PATH/ddns-go" ]; then
        log_error "ddns-go 未安装，请先安装"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    # 获取当前版本
    local current_version=""
    current_version=$($DDNS_PATH/ddns-go -v 2>&1 | grep -o 'v[0-9.]*' | head -n 1)
    
    if [[ -z "$current_version" ]]; then
        log_warn "无法获取当前版本信息"
        current_version="未知"
    fi
    
    log_info "当前版本: $current_version"
    
    # 获取最新版本
    local latest_version=$(get_latest_version)
    log_info "最新版本: $latest_version"
    
    # 比较版本
    if [[ "$current_version" == "$latest_version" ]]; then
        log_info "已经是最新版本"
        read -rp "是否强制更新? [y/N] " force_update
        if [[ ! "$force_update" =~ ^[yY]$ ]]; then
            log_info "更新已取消"
            read -rp "按回车键返回主菜单..." temp
            show_menu
            return 0
        fi
    fi
    
    # 备份配置
    local config_backup="$DDNS_PATH/config.yaml.bak"
    if [ -f "$DDNS_PATH/config.yaml" ]; then
        log_info "备份配置文件..."
        cp "$DDNS_PATH/config.yaml" "$config_backup"
    fi
    
    # 停止服务
    log_info "停止 ddns-go 服务..."
    cd $DDNS_PATH
    ./ddns-go -s uninstall
    
    # 下载新版本
    log_info "下载新版本..."
    
    # 检测系统架构 - 使用改进后的函数，直接返回结果
    local arch_suffix=$(detect_arch)
    local version_num=${latest_version#v}
    
    # 构建下载URL
    local download_file="ddns-go_${version_num}_${arch_suffix}.tar.gz"
    local download_path="${DDNS_PATH}/${download_file}"
    local download_url="https://github.com/jeessy2/ddns-go/releases/download/${latest_version}/${download_file}"
    
    log_info "下载链接: $download_url"
    
    # 删除原来的二进制文件
    rm -f $DDNS_PATH/ddns-go
    
    # 下载文件 - 统一使用curl下载
    if curl -s -L -o "$download_path" "$download_url"; then
        log_info "下载成功"
    else
        log_error "下载失败，请检查网络连接"
        log_warn "将恢复服务"
        if [ -f "$config_backup" ]; then
            cp "$config_backup" "$DDNS_PATH/config.yaml"
        fi
        cd $DDNS_PATH
        ./ddns-go -s install -l 0.0.0.0:9876
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 解压文件
    log_info "解压新版本..."
    if tar -zxf "$download_path" -C $DDNS_PATH; then
        log_info "解压成功"
    else
        log_error "解压失败"
        log_warn "将恢复服务"
        if [ -f "$config_backup" ]; then
            cp "$config_backup" "$DDNS_PATH/config.yaml"
        fi
        cd $DDNS_PATH
        ./ddns-go -s install -l 0.0.0.0:9876
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 设置权限
    chmod +x $DDNS_PATH/ddns-go
    
    # 恢复配置
    if [ -f "$config_backup" ]; then
        log_info "恢复配置文件..."
        cp "$config_backup" "$DDNS_PATH/config.yaml"
    fi
    
    # 获取当前配置的端口
    local port="9876"
    if [ -f "$DDNS_PATH/config.yaml" ]; then
        local config_port=$(grep -o 'listen: 0.0.0.0:[0-9]*' "$DDNS_PATH/config.yaml" 2>/dev/null | grep -o '[0-9]*$' | head -n 1)
        if [[ -n "$config_port" ]]; then
            port="$config_port"
        fi
    fi
    
    # 安装服务
    log_info "重新安装服务..."
    cd $DDNS_PATH
    ./ddns-go -s install -l 0.0.0.0:$port
    
    # 验证更新
    local new_version=$($DDNS_PATH/ddns-go -v 2>&1 | grep -o 'v[0-9.]*' | head -n 1)
    if [[ -z "$new_version" ]]; then
        new_version="未知"
    fi
    log_info "更新完成，当前版本: $new_version"
    
    # 清理下载文件
    rm -f "$download_path"
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 查看状态
check_status() {
    clear
    echo "=================================================="
    echo -e "${BLUE}ddns-go 状态检查${NC}"
    echo "=================================================="
    
    # 检查是否安装
    if [ ! -d "$DDNS_PATH" ] || [ ! -f "$DDNS_PATH/ddns-go" ]; then
        echo -e "${RED}ddns-go 未安装${NC}"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    # 检查版本
    local version=$($DDNS_PATH/ddns-go -v 2>&1 | grep -o 'v[0-9.]*' | head -n 1)
    if [[ -z "$version" ]]; then
        version="未知"
    fi
    echo -e "ddns-go 版本: ${GREEN}$version${NC}"
    
    # 检查服务状态
    echo -n "服务状态: "
    if systemctl is-active ddns-go &>/dev/null; then
        echo -e "${GREEN}运行中${NC}"
    else
        echo -e "${RED}未运行${NC}"
    fi
    
    echo -n "自启动状态: "
    if systemctl is-enabled ddns-go &>/dev/null; then
        echo -e "${GREEN}已启用${NC}"
    else
        echo -e "${RED}未启用${NC}"
    fi
    
    # 检查配置文件
    echo -n "配置文件: "
    if [ -f "$DDNS_PATH/config.yaml" ]; then
        echo -e "${GREEN}存在${NC}"
    else
        echo -e "${RED}不存在${NC}"
    fi
    
    # 获取内存和 CPU 使用情况
    echo "资源使用情况:"
    ps -aux | grep ddns-go | grep -v grep | awk '{print "内存使用: " $4 "%, CPU使用: " $3 "%"}'
    
    # 获取端口信息
    echo -n "端口状态: "
    local port=$(grep -o 'listen: 0.0.0.0:[0-9]*' "$DDNS_PATH/config.yaml" 2>/dev/null | grep -o '[0-9]*$' | head -n 1)
    if [[ -z "$port" ]]; then
        port=$(systemctl status ddns-go 2>/dev/null | grep -o '\-l 0.0.0.0:[0-9]*' | grep -o '[0-9]*$' | head -n 1)
    fi
    
    if [[ -n "$port" ]]; then
        if command -v ss &>/dev/null; then
            if ss -tuln | grep -q ":$port "; then
                echo -e "${GREEN}端口 $port 已开放${NC}"
            else
                echo -e "${RED}端口 $port 未开放${NC}"
            fi
        elif command -v netstat &>/dev/null; then
            if netstat -tuln | grep -q ":$port "; then
                echo -e "${GREEN}端口 $port 已开放${NC}"
            else
                echo -e "${RED}端口 $port 未开放${NC}"
            fi
        else
            echo -e "${YELLOW}无法检查端口状态${NC}"
        fi
    else
        echo -e "${YELLOW}未找到端口信息${NC}"
    fi
    
    # 检查DNS解析记录
    echo -e "\n上次DNS更新信息:"
    if [ -f "$DDNS_PATH/config.yaml" ]; then
        grep -A 10 'ipv4' "$DDNS_PATH/config.yaml" | head -n 10
    else
        echo "未找到配置文件，无法获取DNS更新信息"
    fi
    
    # 显示日志
    echo -e "\n最近日志:"
    if command -v journalctl &>/dev/null; then
        journalctl -u ddns-go --no-pager -n 10
    else
        echo "找不到日志信息"
    fi
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 重启服务
restart_service() {
    clear
    echo "=================================================="
    echo -e "${GREEN}重启 ddns-go 服务${NC}"
    echo "=================================================="
    
    # 检查是否已安装
    if [ ! -d "$DDNS_PATH" ] || [ ! -f "$DDNS_PATH/ddns-go" ]; then
        log_error "ddns-go 未安装，请先安装"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    log_info "正在重启 ddns-go 服务..."
    
    # 尝试使用systemctl重启
    if systemctl restart ddns-go; then
        log_info "服务已重启"
    else
        log_warn "systemctl重启失败，尝试手动重启..."
        cd $DDNS_PATH
        ./ddns-go -s uninstall
        sleep 1
        
        # 获取当前配置的端口
        local web_port="9876"
        if [ -f "$DDNS_PATH/config.yaml" ]; then
            local config_port=$(grep -o 'listen: 0.0.0.0:[0-9]*' "$DDNS_PATH/config.yaml" 2>/dev/null | grep -o '[0-9]*$' | head -n 1)
            if [[ -n "$config_port" ]]; then
                web_port="$config_port"
            fi
        fi
        
        ./ddns-go -s install -l 0.0.0.0:$web_port
        log_info "服务已手动重启"
    fi
    
    # 获取IP信息
    local ip_info=$(get_ip_info)
    local ipv4=$(echo "$ip_info" | cut -d'|' -f1)
    
    log_info "服务已重启，Web管理界面: http://$ipv4:$web_port"
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 显示帮助
show_help() {
    echo "ddns-go 管理脚本 v${SCRIPT_VERSION}"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  install    直接安装 ddns-go"
    echo "  uninstall  直接卸载 ddns-go"
    echo "  restart    重启 ddns-go 服务"
    echo "  status     查看 ddns-go 状态"
    echo "  update     更新 ddns-go"
    echo "  ip         显示当前公网IP地址"
    echo "  help       显示此帮助信息"
    echo ""
    echo "无参数运行脚本将显示交互式菜单"
}

# 菜单函数
show_menu() {
    clear
    echo "=================================================="
    echo -e "${CYAN}ddns-go 管理脚本 v${SCRIPT_VERSION}${NC}"
    echo "=================================================="
    echo -e "1) ${GREEN}安装 ddns-go${NC}"
    echo -e "2) ${RED}卸载 ddns-go${NC}"
    echo -e "3) ${YELLOW}更新 ddns-go${NC}"
    echo -e "4) ${BLUE}查看 ddns-go 状态${NC}"
    echo -e "5) ${GREEN}重启 ddns-go 服务${NC}"
    echo -e "0) ${RED}退出${NC}"
    echo "=================================================="
    echo ""
    read -rp "请输入选项 [0-5]: " choice
    
    case $choice in
        1) install_ddns_go ;;
        2) uninstall_ddns_go ;;
        3) update_ddns_go ;;
        4) check_status ;;
        5) restart_service ;;
        0) exit 0 ;;
        *) log_error "无效选项" && sleep 2 && show_menu ;;
    esac
}

# 主函数
main() {
    # 处理命令行参数
    if [[ $# -gt 0 ]]; then
        case "$1" in
            -h|--help|help)
                show_help
                exit 0
                ;;
            install)
                install_ddns_go
                exit 0
                ;;
            uninstall)
                uninstall_ddns_go
                exit 0
                ;;
            restart)
                restart_service
                exit 0
                ;;
            status)
                check_status
                exit 0
                ;;
            update)
                update_ddns_go
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    fi

    # 无参数则显示菜单
    show_menu
}

# 执行主函数
main "$@"
