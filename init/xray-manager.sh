
# Xray 管理脚本 - 集成安装、卸载和管理功能
# 专门支持 VLESS+REALITY 协议
# 使用方法: chmod +x xray-manager.sh && ./xray-manager.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/xray-manager.sh && chmod +x xray-manager.sh && ./xray-manager.sh

# 全局变量
XRAY_PATH="/usr/local/bin"
CONFIG_PATH="/usr/local/etc/xray"
REALITY_PORT=""      # VLESS+REALITY 端口
LOG_PATH="/var/log/xray"
LOG_FILE="/var/log/xray-manager.log"
SCRIPT_VERSION="1.0.0"
XRAY_VERSION="v25.3.6"  # 当前固定的Xray版本
UUID=""
PRIVATE_KEY=""
PUBLIC_KEY=""
CONFIG_BACKUP=""
SERVER_IP=""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 进度条函数
show_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local temp
    local count=0
    local start_time=$(date +%s)
    echo -n " "

    while ps -p $pid > /dev/null; do
        temp=${spinstr#?}
        printf "\r[%c] %s 已进行 %ds" "$spinstr" "$2" "$(($(date +%s) - start_time))"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        count=$((count + 1))
    done
    printf "\r\033[K"
}

# 进度条显示函数 - 适用于apt操作
apt_progress() {
    local cmd="$1"
    local msg="$2"
    local logfile="$LOG_FILE.tmp"
    
    echo -e "${CYAN}开始 $msg...${NC}"
    touch "$logfile"
    ($cmd 2>&1 | tee -a "$LOG_FILE" > "$logfile") &
    local pid=$!
    
    # 显示进度条
    local start_time=$(date +%s)
    local dots=""
    local status=""
    local progress=0
    local last_line=""
    local delay=0.2
    
    while ps -p $pid > /dev/null; do
        # 读取最后一行日志
        if [[ -f "$logfile" ]]; then
            last_line=$(tail -n 1 "$logfile")
            
            # 尝试从输出中提取进度信息
            if [[ $last_line == *%* ]]; then
                status="${last_line%%(*}"
                progress="${last_line#*(}"
                progress="${progress%%)*}"
                printf "\r\033[K${CYAN}[$msg]${NC} %s %s " "$status" "$progress"
            else
                dots="${dots}."
                if [[ ${#dots} -gt 5 ]]; then dots="."; fi
                elapsed=$(($(date +%s) - start_time))
                printf "\r\033[K${CYAN}[$msg]${NC} 进行中%s (%ds)" "$dots" "$elapsed"
            fi
        fi
        sleep $delay
    done
    
    if wait $pid; then
        printf "\r\033[K${GREEN}[$msg]${NC} 完成! 用时: %ds\n" "$(($(date +%s) - start_time))"
        rm -f "$logfile"
        return 0
    else
        printf "\r\033[K${RED}[$msg]${NC} 失败! 查看日志: $LOG_FILE\n"
        rm -f "$logfile"
        return 1
    fi
}

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2 | tee -a "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查是否有 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        exit 1
    fi
}

# 检查系统环境
check_system() {
    # 显示系统信息
    echo "系统信息:"
    echo "------------------------"
    if [ -f /etc/os-release ]; then
        cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2- | tr -d '"'
    fi
    echo "内核版本: $(uname -r)"
    echo "架构: $(uname -m)"
    echo "------------------------"
    
    # 检查是否为 Debian/Ubuntu 系统
    if [[ ! -f /etc/debian_version && ! -f /etc/lsb-release ]]; then
        log_warn "未检测到 Debian/Ubuntu 系统，脚本可能无法正常工作"
        read -rp "是否继续? [y/N] " response
        if [[ ! "$response" =~ ^[yY]$ ]]; then
            exit 1
        fi
    fi
    
    # 检查网络连接
    echo -n "检查网络连接... "
    if ping -c 1 -W 2 github.com &>/dev/null; then
        echo -e "${GREEN}连接正常${NC}"
    else
        echo -e "${YELLOW}无法连接到 GitHub${NC}"
        log_warn "无法连接到 GitHub，请检查网络连接"
        read -rp "是否继续? [y/N] " response
        if [[ ! "$response" =~ ^[yY]$ ]]; then
            exit 1
        fi
    fi
} 

# 获取最新版本号
get_latest_version() {
    # 利用GitHub重定向特性获取最新版本
    local redirect_url=$(curl -s -L -o /dev/null -w '%{url_effective}' https://github.com/XTLS/Xray-core/releases/latest 2>/dev/null)
    local version=$(echo "$redirect_url" | grep -o 'tag/v[0-9.]*' | cut -d/ -f2 2>/dev/null)
    
    # 如果获取失败，尝试备用方法
    if [[ -z "$version" ]]; then
        # 方法2: 通过API获取
        version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep -o '"tag_name": "v[0-9.]*"' | cut -d'"' -f4 2>/dev/null)
    fi
    
    # 如果还是失败，返回当前全局版本
    if [[ -z "$version" ]]; then
        version="$XRAY_VERSION"
    else
        # 更新全局变量
        XRAY_VERSION="$version"
    fi
    
    echo "$version"
}

# 备份函数
backup_config() {
    if [[ -d "$CONFIG_PATH" ]]; then
        CONFIG_BACKUP="${CONFIG_PATH}_backup_$(date +%Y%m%d%H%M%S)"
        log_info "备份现有配置到 $CONFIG_BACKUP"
        cp -r "$CONFIG_PATH" "$CONFIG_BACKUP" || log_warn "配置备份失败"
        
        # 备份 Xray 信息文件
        if [[ -f "/root/xray_info.txt" ]]; then
            cp "/root/xray_info.txt" "${CONFIG_BACKUP}/xray_info.txt.bak" || log_warn "Xray 信息文件备份失败"
        fi
    else
        log_warn "找不到配置目录，跳过备份"
    fi
}

# 显示帮助信息
show_help() {
    echo "Xray 管理脚本 v${SCRIPT_VERSION}"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -i, --install  直接运行安装"
    echo "  -u, --uninstall 直接运行卸载"
    echo "  -s, --status   查看 Xray 状态"
    echo "  -up, --update  更新 Xray"
    echo ""
    echo "无参数运行脚本将显示交互式菜单"
}

# 菜单函数
show_menu() {
    clear
    echo "=================================================="
    echo -e "${CYAN}Xray REALITY管理脚本 v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}(VLESS+REALITY 协议)${NC}"
    echo "=================================================="
    echo -e "1) ${GREEN}安装 Xray${NC}"
    echo -e "2) ${RED}卸载 Xray${NC}"
    echo -e "3) ${YELLOW}更新 Xray${NC}"
    echo -e "4) ${BLUE}查看 Xray 状态${NC}"
    echo -e "5) ${CYAN}查看 Xray 配置信息${NC}"
    echo -e "6) ${GREEN}重启 Xray 服务${NC}"
    echo -e "7) ${YELLOW}手动设置 Xray 版本号${NC}"
    echo -e "0) ${RED}退出${NC}"
    echo "=================================================="
    echo ""
    read -rp "请输入选项 [0-7]: " choice
    
    case $choice in
        1) install_xray ;;
        2) uninstall_xray ;;
        3) update_xray ;;
        4) check_status ;;
        5) show_config ;;
        6) restart_service ;;
        7) set_xray_version ;;
        0) exit 0 ;;
        *) log_error "无效选项" && sleep 2 && show_menu ;;
    esac
}

# 设置Xray版本号
set_xray_version() {
    clear
    echo "=================================================="
    echo -e "${YELLOW}手动设置 Xray 版本号${NC}"
    echo "=================================================="
    
    echo "当前Xray版本号: $XRAY_VERSION"
    echo ""
    echo "1) 自动获取最新版本"
    echo "2) 手动输入版本号"
    echo "0) 返回主菜单"
    echo ""
    
    read -rp "请选择操作 [0-2]: " version_choice
    
    case $version_choice in
        1)
            echo -n "正在获取最新版本... "
            local latest_version=$(get_latest_version)
            
            if [[ "$latest_version" == "$XRAY_VERSION" && ! -z "$latest_version" ]]; then
                echo -e "${GREEN}成功${NC}"
                log_info "当前已是最新版本: $XRAY_VERSION"
            elif [[ -z "$latest_version" || "$latest_version" == "v1.8.4" ]]; then
                echo -e "${RED}失败${NC}"
                log_error "无法自动获取最新版本"
            else
                echo -e "${GREEN}成功${NC}"
                XRAY_VERSION="$latest_version"
                log_info "Xray版本已自动更新为: $XRAY_VERSION"
            fi
            ;;
        2)
            echo "请访问 https://github.com/XTLS/Xray-core/releases 查看可用版本"
            read -rp "请输入新的版本号(例如 v25.3.6): " new_version
            
            if [[ -z "$new_version" ]]; then
                log_error "版本号不能为空"
            elif [[ ! "$new_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                log_error "版本号格式不正确，请使用类似 v25.3.6 的格式"
            else
                XRAY_VERSION="$new_version"
                log_info "Xray版本已更新为: $XRAY_VERSION"
            fi
            ;;
        0)
            # 直接返回
            ;;
        *)
            log_error "无效选项"
            ;;
    esac
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 安装依赖
install_dependencies() {
    log_info "安装必要依赖"
    
    # 更新软件包列表
    apt_progress "apt-get update" "更新软件包列表" || {
        log_error "更新软件包列表失败"
        return 1
    }
    
    # 安装必要工具
    local deps=(curl wget jq unzip)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            apt_progress "apt-get install -y $dep" "安装 $dep" || {
                log_error "安装 $dep 失败"
                return 1
            }
        else
            log_info "$dep 已安装，跳过"
        fi
    done
    
    # 检查安装结果
    local all_installed=true
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "$dep 安装失败"
            all_installed=false
        fi
    done
    
    if [ "$all_installed" = true ]; then
        log_info "所有依赖安装完成"
        return 0
    else
        log_error "部分依赖安装失败"
        return 1
    fi
}

# 下载 Xray
download_xray() {
    log_info "开始下载 Xray"
    
    # 检查Xray服务是否正在运行，如果是则停止
    if systemctl is-active xray &>/dev/null; then
        log_info "检测到Xray服务正在运行，先停止服务"
        echo -n "停止 Xray 服务... "
        if systemctl stop xray &>/dev/null; then
            echo -e "${GREEN}成功${NC}"
        else
            echo -e "${RED}失败${NC}"
            log_warn "无法停止 Xray 服务，可能会影响安装"
        fi
        
        # 等待进程完全停止
        echo -n "等待进程释放资源... "
        sleep 2
        if pgrep -x "xray" > /dev/null; then
            # 如果进程仍在运行，尝试强制终止
            pkill -9 -x "xray" &>/dev/null
            sleep 1
        fi
        echo -e "${GREEN}完成${NC}"
    fi
    
    # 创建临时目录
    local tmp_dir="/tmp/xray_install"
    mkdir -p "$tmp_dir"
    
    # 获取最新版本
    echo -n "获取 Xray 最新版本... "
    local latest_version=$(get_latest_version)
    echo -e "${GREEN}$latest_version${NC}"
    
    # 确定系统架构
    local arch
    case $(uname -m) in
        x86_64|amd64) arch="64" ;;
        armv7l|armv8l) arch="arm32-v7a" ;;
        aarch64) arch="arm64-v8a" ;;
        *) arch="64" ;;  # 默认使用64位版本
    esac
    
    # 构建下载URL
    local download_url="https://github.com/XTLS/Xray-core/releases/download/$latest_version/Xray-linux-$arch.zip"
    log_info "下载链接: $download_url"
    
    # 下载Xray
    echo -n "下载 Xray... "
    if wget -q --show-progress -O "$tmp_dir/xray.zip" "$download_url"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "下载 Xray 失败"
        return 1
    fi
    
    # 解压文件
    echo -n "解压 Xray... "
    if unzip -q -o "$tmp_dir/xray.zip" -d "$tmp_dir"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "解压 Xray 失败"
        return 1
    fi
    
    # 创建目录
    mkdir -p "$XRAY_PATH" "$CONFIG_PATH" "$LOG_PATH"
    
    # 复制文件前确保目标文件不被占用
    if [[ -f "$XRAY_PATH/xray" ]]; then
        # 如果文件存在，先尝试重命名它
        mv "$XRAY_PATH/xray" "$XRAY_PATH/xray.old" 2>/dev/null
    fi
    
    # 复制文件
    echo -n "安装 Xray 核心文件... "
    if cp "$tmp_dir/xray" "$XRAY_PATH/xray" && chmod +x "$XRAY_PATH/xray"; then
        echo -e "${GREEN}成功${NC}"
        # 删除旧文件
        rm -f "$XRAY_PATH/xray.old" 2>/dev/null
    else
        echo -e "${RED}失败${NC}"
        log_error "安装 Xray 核心文件失败"
        # 恢复旧文件
        if [[ -f "$XRAY_PATH/xray.old" ]]; then
            mv "$XRAY_PATH/xray.old" "$XRAY_PATH/xray" 2>/dev/null
        fi
        return 1
    fi
    
    # 复制 geoip.dat 和 geosite.dat
    echo -n "安装 GeoIP 和 GeoSite 数据... "
    if cp "$tmp_dir/geoip.dat" "$XRAY_PATH/geoip.dat" && \
       cp "$tmp_dir/geosite.dat" "$XRAY_PATH/geosite.dat"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_warn "安装 GeoIP 和 GeoSite 数据失败，将在配置时下载"
    fi
    
    # 清理临时文件
    rm -rf "$tmp_dir"
    
    log_info "Xray $latest_version 安装完成"
    return 0
}

# 生成随机 PORT 和 UUID
generate_random_values() {
    log_info "生成随机配置值"
    
    # 询问用户是否指定端口
    if [[ -z "$REALITY_PORT" ]]; then
        read -rp "是否指定端口? [y/N] " specify_port
        if [[ "$specify_port" =~ ^[yY]$ ]]; then
            # 用户选择指定端口
            while true; do
                read -rp "请输入端口号 (1-65535): " REALITY_PORT
                # 验证端口是否为有效数字
                if ! [[ "$REALITY_PORT" =~ ^[0-9]+$ ]] || [ "$REALITY_PORT" -lt 1 ] || [ "$REALITY_PORT" -gt 65535 ]; then
                    log_error "无效的端口号，请输入1-65535之间的数字"
                    continue
                fi
                
                # 检查端口是否被占用
                if ss -tuln | grep -q ":$REALITY_PORT "; then
                    log_warn "端口 $REALITY_PORT 已被占用，请选择其他端口"
                    continue
                fi
                
                log_info "将使用指定端口: $REALITY_PORT"
                break
            done
        else
            # 用户选择随机端口，继续原来的逻辑
            # 尝试找一个未被占用的端口
            local attempts=0
            while [[ "$attempts" -lt 10 ]]; do
                REALITY_PORT=$(shuf -i 10000-60000 -n 1)
                # 检查端口是否被占用
                if ! ss -tuln | grep -q ":$REALITY_PORT "; then
                    log_info "生成随机端口: $REALITY_PORT"
                    break
                fi
                attempts=$((attempts + 1))
            done
            if [[ "$attempts" -eq 10 ]]; then
                log_warn "无法找到未占用的端口，使用随机端口: $REALITY_PORT"
            fi
        fi
    else
        # 验证端口是否为有效数字
        if ! [[ "$REALITY_PORT" =~ ^[0-9]+$ ]]; then
            log_warn "无效的端口: $REALITY_PORT，生成新的随机端口"
            REALITY_PORT=$(shuf -i 10000-60000 -n 1)
        fi
    fi
    
    # 生成 UUID
    if [[ -z "$UUID" ]]; then
        # 检查xray命令是否可用
        if [[ -f "$XRAY_PATH/xray" && -x "$XRAY_PATH/xray" ]]; then
            UUID=$($XRAY_PATH/xray uuid)
            log_info "生成 UUID: $UUID"
        else
            # 如果xray不可用，使用uuidgen或者随机生成
            if command -v uuidgen &>/dev/null; then
                UUID=$(uuidgen)
            else
                # 简单的UUID生成方法（不完全符合标准但足够使用）
                UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || 
                       (date +%s%N | sha256sum | head -c 32 | 
                       sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-/'))
            fi
            log_info "生成 UUID: $UUID"
        fi
    else
        # 验证UUID格式
        if ! [[ "$UUID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
            log_warn "无效的 UUID 格式: $UUID，生成新的 UUID"
            if [[ -f "$XRAY_PATH/xray" && -x "$XRAY_PATH/xray" ]]; then
                UUID=$($XRAY_PATH/xray uuid)
            else
                UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || 
                       (date +%s%N | sha256sum | head -c 32 | 
                       sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-/'))
            fi
            log_info "生成新的 UUID: $UUID"
        fi
    fi
    
    # 生成 REALITY 密钥对
    log_info "生成 REALITY 密钥对"
    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        local key_pair
        if [[ -f "$XRAY_PATH/xray" && -x "$XRAY_PATH/xray" ]]; then
            key_pair=$($XRAY_PATH/xray x25519)
            PRIVATE_KEY=$(echo "$key_pair" | grep "Private" | awk '{print $3}')
            PUBLIC_KEY=$(echo "$key_pair" | grep "Public" | awk '{print $3}')
        else
            log_warn "无法使用 xray 生成密钥对，将跳过密钥生成"
            log_info "安装完成后，将自动生成密钥对"
        fi
    fi
    
    # 获取服务器IP
    get_server_ip
    
    log_debug "私钥: $PRIVATE_KEY"
    log_debug "公钥: $PUBLIC_KEY"
}

# 获取服务器IP
get_server_ip() {
    log_info "获取服务器IP地址"
    
    if [[ -n "$SERVER_IP" ]]; then
        log_info "使用已设置的IP: $SERVER_IP"
        return 0
    fi
    
    # 尝试首选方法获取公网IP
    SERVER_IP=$(curl -s -m 5 https://api.ipify.org 2>/dev/null)
    
    # 验证获取到的IP是否为有效IPv4地址
    if [[ -n "$SERVER_IP" && "$SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        log_info "成功获取公网IP: $SERVER_IP"
        return 0
    fi
    
    # 如果第一个方法失败，尝试备用方法
    local backup_services=("https://ifconfig.me" "https://ip.sb" "https://ipinfo.io/ip")
    
    for service in "${backup_services[@]}"; do
        SERVER_IP=$(curl -s -m 3 "$service" 2>/dev/null)
        if [[ -n "$SERVER_IP" && "$SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            log_info "成功从 $service 获取公网IP: $SERVER_IP"
            return 0
        fi
    done
    
    # 如果所有公网IP获取方式都失败，则使用本地IP
    if command -v hostname &>/dev/null; then
        SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # 如果hostname命令失败，尝试使用ip命令
    if [[ -z "$SERVER_IP" && -x "$(command -v ip)" ]]; then
        SERVER_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    fi
    
    # 如果还是失败，尝试使用ifconfig命令
    if [[ -z "$SERVER_IP" && -x "$(command -v ifconfig)" ]]; then
        SERVER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
    fi
    
    if [[ -n "$SERVER_IP" ]]; then
        log_warn "无法获取公网IP，使用本地IP: $SERVER_IP"
        return 0
    else
        log_error "无法获取任何有效IP地址，将使用127.0.0.1作为占位符"
        SERVER_IP="127.0.0.1"
        return 1
    fi
}

# 配置 Xray - 修改为 VLESS+REALITY 并支持 TUN 模式
configure_xray() {
    log_info "配置 Xray"
    
    # 生成随机值
    generate_random_values
    
    # 创建配置目录
    mkdir -p "$CONFIG_PATH"
    
    # 创建示例目录
    mkdir -p "$CONFIG_PATH/examples"
    
    log_info "创建 VLESS+REALITY 配置文件（支持TUN模式）"
    
    # VLESS + REALITY 配置 (添加支持TUN模式的DNS和路由配置)
    cat > "$CONFIG_PATH/config.json" << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "$LOG_PATH/access.log",
    "error": "$LOG_PATH/error.log"
  },
  "inbounds": [
    {
      "port": $REALITY_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.shopify.com:443",
          "xver": 0,
          "serverNames": [
            "shopify.com",
            "www.shopify.com"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "",
            "6ba85179e30d"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ],
        "routeOnly": false
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "dns": {
    "hosts": {
      "dns.google": "8.8.8.8",
      "proxy.example.com": "127.0.0.1"
    },
    "servers": [
      {
        "address": "1.1.1.1",
        "domains": [
          "geosite:geolocation-!cn"
        ],
        "expectIPs": [
          "geoip:!cn"
        ]
      },
      {
        "address": "223.5.5.5",
        "domains": [
          "geosite:cn"
        ],
        "expectIPs": [
          "geoip:cn"
        ]
      },
      "8.8.8.8",
      "https://dns.google/dns-query"
    ]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "outboundTag": "block",
        "domain": [
          "geosite:category-ads-all"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:private"
        ]
      },
      {
        "type": "field",
        "port": "443",
        "network": "udp",
        "outboundTag": "block"
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:cn"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:cn"
        ]
      }
    ]
  }
}
EOF
    
    if [[ -f "$CONFIG_PATH/config.json" ]]; then
        log_info "配置文件创建成功"
    else
        log_error "配置文件创建失败"
        return 1
    fi
    
    return 0
}

# 配置防火墙 - 简化只处理 REALITY 端口
configure_firewall() {
    log_info "配置防火墙"
    
    # 检测和关闭旧端口
    local old_ports=()
    
    # 从备份中查找旧端口
    if [[ -n "$CONFIG_BACKUP" && -f "$CONFIG_BACKUP/config.json" ]]; then
        log_info "检测旧配置中的端口"
        if command -v jq &>/dev/null; then
            # 使用jq查找所有inbounds的端口
            local detected_ports=$(jq '.inbounds[].port' "$CONFIG_BACKUP/config.json" 2>/dev/null)
            for port in $detected_ports; do
                if [[ "$port" != "null" && -n "$port" ]]; then
                    old_ports+=("$port")
                    log_info "检测到旧端口: $port"
                fi
            done
        else
            # 使用grep查找端口
            local detected_ports=$(grep -o '"port": [0-9]*' "$CONFIG_BACKUP/config.json" | awk '{print $2}')
            for port in $detected_ports; do
                if [[ -n "$port" ]]; then
                    old_ports+=("$port")
                    log_info "检测到旧端口: $port"
                fi
            done
        fi
    fi
    
    # 如果找不到旧端口，也查找默认位置
    if [[ ${#old_ports[@]} -eq 0 && -f "$CONFIG_PATH/config.json" && "$CONFIG_PATH/config.json" != "$(readlink -f "$CONFIG_BACKUP/config.json")" ]]; then
        if command -v jq &>/dev/null; then
            # 使用jq查找所有inbounds的端口
            local detected_ports=$(jq '.inbounds[].port' "$CONFIG_PATH/config.json" 2>/dev/null)
            for port in $detected_ports; do
                if [[ "$port" != "null" && -n "$port" ]]; then
                    old_ports+=("$port")
                    log_info "检测到当前配置的端口: $port"
                fi
            done
        else
            # 使用grep查找端口
            local detected_ports=$(grep -o '"port": [0-9]*' "$CONFIG_PATH/config.json" | awk '{print $2}')
            for port in $detected_ports; do
                if [[ -n "$port" ]]; then
                    old_ports+=("$port")
                    log_info "检测到当前配置的端口: $port"
                fi
            done
        fi
    fi
    
    # 从旧端口列表中过滤掉当前端口
    local filtered_ports=()
    for port in "${old_ports[@]}"; do
        # 检查端口是否为有效数字
        if ! [[ "$port" =~ ^[0-9]+$ ]]; then
            log_warn "无效的端口号: $port，已跳过"
            continue
        fi
        
        # 检查是否与当前端口相同
        if [[ "$port" -eq "$REALITY_PORT" ]]; then
            log_info "端口 $port 与当前端口相同，已跳过"
            continue
        fi
        
        filtered_ports+=("$port")
    done
    old_ports=("${filtered_ports[@]}")
    
    # 检查是否安装了 ufw
    if command -v ufw &>/dev/null; then
        # 检查ufw是否启用
        local ufw_status=$(ufw status | grep -o "Status: active" 2>/dev/null)
        
        if [[ -z "$ufw_status" ]]; then
            log_warn "UFW 防火墙未启用，可能需要手动配置防火墙规则"
            log_info "您可以运行 'sudo ufw enable' 启用 UFW 防火墙"
            return 0
        fi
        
        # 关闭旧端口
        if [[ ${#old_ports[@]} -gt 0 ]]; then
            log_info "开始关闭旧端口"
            local closed_ports=()
            
            for port in "${old_ports[@]}"; do
                # 检查端口是否已开放在UFW中
                if ! ufw status | grep -q "$port/tcp"; then
                    log_info "端口 $port 未在 UFW 中开放，跳过"
                    continue
                fi
                
                echo -n "关闭 UFW 防火墙端口 $port... "
                if ufw delete allow "$port/tcp" &>/dev/null; then
                    echo -e "${GREEN}完成${NC}"
                    closed_ports+=("$port")
                else
                    echo -e "${RED}失败${NC}"
                    log_warn "无法关闭端口 $port"
                fi
            done
            
            # 打印关闭的端口
            if [[ ${#closed_ports[@]} -gt 0 ]]; then
                local closed_list=$(printf ", %s" "${closed_ports[@]}")
                closed_list=${closed_list:2}  # 移除开头的逗号和空格
                log_info "已关闭 UFW 防火墙中的旧端口: $closed_list"
            else
                log_info "没有需要关闭的旧端口"
            fi
        else
            log_info "未检测到旧端口，跳过关闭端口步骤"
        fi
        
        # 确定需要开放的端口
        local ports=("$REALITY_PORT")
        
        echo -n "配置 UFW 防火墙... "
        local opened_ports=()
        for port in "${ports[@]}"; do
            # 检查端口是否为有效数字
            if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                log_warn "端口 '$port' 不是有效数字，已跳过"
                continue
            fi
            
            # 检查端口是否已经开放
            if ufw status | grep -q "$port/tcp"; then
                log_info "端口 $port 已经开放，跳过"
                opened_ports+=("$port")
                continue
            fi
            
            # 开放端口
            if ufw allow "$port/tcp" &>/dev/null; then
                opened_ports+=("$port")
            else
                log_warn "无法开放端口 $port"
            fi
        done
        echo -e "${GREEN}完成${NC}"
        
        # 打印开放的端口
        if [[ ${#opened_ports[@]} -gt 0 ]]; then
            local port_list=$(printf ", %s" "${opened_ports[@]}")
            port_list=${port_list:2}  # 移除开头的逗号和空格
            log_info "已在 UFW 防火墙开放端口: $port_list"
        else
            log_warn "没有成功开放任何端口"
        fi
    else
        log_warn "未检测到 UFW 防火墙，跳过防火墙配置"
        log_info "如需管理防火墙规则，请安装 UFW: sudo apt install ufw"
    fi
    
    return 0
}

# 生成客户端配置 - 更新为只提供 VLESS+REALITY
generate_client_info() {
    log_info "生成客户端信息"
    
    # 确保IP地址已获取
    if [[ -z "$SERVER_IP" ]]; then
        get_server_ip
    fi
    
    # 生成 VLESS + REALITY 分享链接
    local share_link="vless://${UUID}@${SERVER_IP}:${REALITY_PORT}?security=reality&encryption=none&pbk=${PUBLIC_KEY}&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=www.shopify.com&sid=6ba85179e30d#Xray-Reality"
    
    # 保存客户端信息
    cat > /root/xray_info.txt << EOF
========================= Xray Reality 配置信息 =========================
服务器地址: ${SERVER_IP}
端口: ${REALITY_PORT}
UUID: ${UUID}
协议: vless
传输协议: tcp
加密方式: none
流控: xtls-rprx-vision
安全: reality
公钥: ${PUBLIC_KEY}
私钥: ${PRIVATE_KEY}
SNI: www.shopify.com
指纹: chrome
短 ID: 6ba85179e30d
==================================================================

分享链接:
${share_link}

二维码链接:
https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${share_link}
==================================================================

TUN模式支持:
REALITY 协议已配置支持 TUN 模式，客户端配置示例文件已生成:
1. REALITY-TUN配置: ${CONFIG_PATH}/examples/reality_tun_example.json

将配置文件导入到支持TUN模式的客户端后:
1. 切换到"TUN模式"选项卡
2. 点击"启用TUN模式" 
3. 选择"系统代理"或"全局代理"
4. 重启客户端并允许管理员权限

==================================================================

配置文件路径: ${CONFIG_PATH}/config.json
服务控制:
启动: systemctl start xray
停止: systemctl stop xray
重启: systemctl restart xray
状态: systemctl status xray
==================================================================
EOF

    # 生成 REALITY TUN 模式配置示例
    generate_reality_tun_config
    
    log_info "客户端信息已保存到 /root/xray_info.txt"
    
    # 打印信息
    cat /root/xray_info.txt
    
    log_info "安装完成！Xray REALITY 已成功部署"
    return 0
}

# 新增：生成 REALITY TUN 模式配置
generate_reality_tun_config() {
    log_info "生成 REALITY TUN 模式配置示例"
    
    # 确保IP地址已设置
    if [[ -z "$SERVER_IP" ]]; then
        get_server_ip
    fi
    
    # 创建 TUN 配置示例目录
    local example_dir="$CONFIG_PATH/examples"
    mkdir -p "$example_dir"
    
    # 生成客户端配置示例，用于TUN模式
    cat > "$example_dir/reality_tun_example.json" << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ],
        "routeOnly": false
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "allowTransparent": false
      }
    },
    {
      "tag": "tun",
      "protocol": "tun",
      "settings": {
        "network": "all"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ],
        "routeOnly": false
      }
    }
  ],
  "tun": {
    "enable": true,
    "stack": "gvisor",
    "mtu": 9000,
    "strict_route": true
  },
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "${SERVER_IP}",
            "port": ${REALITY_PORT},
            "users": [
              {
                "id": "${UUID}",
                "flow": "xtls-rprx-vision",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "fingerprint": "chrome",
          "serverName": "www.shopify.com",
          "publicKey": "${PUBLIC_KEY}",
          "shortId": "6ba85179e30d"
        }
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "dns": {
    "hosts": {
      "dns.google": "8.8.8.8",
      "proxy.example.com": "127.0.0.1"
    },
    "servers": [
      {
        "address": "1.1.1.1",
        "domains": [
          "geosite:geolocation-!cn"
        ],
        "expectIPs": [
          "geoip:!cn"
        ]
      },
      {
        "address": "223.5.5.5",
        "domains": [
          "geosite:cn"
        ],
        "expectIPs": [
          "geoip:cn"
        ]
      },
      "8.8.8.8",
      "https://dns.google/dns-query"
    ]
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "outboundTag": "proxy",
        "domain": [
          "domain:google.com",
          "domain:googleapis.cn",
          "domain:gstatic.com"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:cn"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:private",
          "geoip:cn"
        ]
      }
    ]
  }
}
EOF
    
    log_info "REALITY TUN 模式配置示例已保存到 $example_dir/reality_tun_example.json"
    log_info "使用方法: 将配置导入到支持TUN模式的客户端，然后开启TUN模式"
    
    return 0
}

# 创建系统服务
create_service() {
    log_info "创建 Xray 系统服务"
    
    # 创建服务文件
    cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=$XRAY_PATH/xray run -config $CONFIG_PATH/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载 systemd 配置并启用服务
    systemctl daemon-reload
    
    echo -n "启用 Xray 服务... "
    if systemctl enable xray &>/dev/null; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "无法启用 Xray 服务"
        return 1
    fi
    
    echo -n "启动 Xray 服务... "
    if systemctl start xray; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "无法启动 Xray 服务"
        return 1
    fi
    
    return 0
}

# 安装完整流程 - 更新为直接安装 VLESS+REALITY
install_xray() {
    clear
    echo "=================================================="
    echo -e "${GREEN}开始安装 Xray REALITY 协议${NC}"
    echo "=================================================="
    
    # 检查是否为 root
    check_root
    
    # 检查系统环境
    check_system
    
    # 备份现有配置
    backup_config
    
    # 安装依赖
    install_dependencies || {
        log_error "安装依赖失败，退出安装"
        return 1
    }
    
    # 下载和安装 Xray
    download_xray || {
        log_error "下载 Xray 失败，退出安装"
        return 1
    }
    
    # 配置 Xray
    configure_xray || {
        log_error "配置 Xray 失败，退出安装"
        return 1
    }
    
    # 创建系统服务
    create_service || {
        log_error "创建系统服务失败，但会继续安装过程"
    }
    
    # 配置防火墙
    configure_firewall
    
    # 生成客户端信息
    generate_client_info
    
    echo ""
    log_info "Xray REALITY 协议安装成功！"
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 停止 Xray 服务
stop_xray_service() {
    log_info "停止 Xray 服务"
    
    if systemctl is-active xray &>/dev/null; then
        echo -n "正在停止 Xray 服务... "
        if systemctl stop xray &>/dev/null; then
            echo -e "${GREEN}成功${NC}"
        else
            echo -e "${RED}失败${NC}"
            log_warn "无法停止 Xray 服务，将尝试继续卸载"
        fi
    else
        log_info "Xray 服务未运行"
    fi
    
    echo -n "禁用 Xray 服务自启动... "
    if systemctl disable xray &>/dev/null; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${YELLOW}失败${NC}"
        log_warn "无法禁用 Xray 服务自启动，服务可能不存在"
    fi
}

# 读取并关闭防火墙端口
close_firewall_port() {
    log_info "尝试关闭之前开放的防火墙端口"
    
    # 检查是否安装了 ufw
    if ! command -v ufw &>/dev/null; then
        log_warn "未检测到 UFW 防火墙，跳过防火墙配置关闭"
        return 0
    fi
    
    # 检查ufw是否启用
    local ufw_status=$(ufw status | grep -o "Status: active" 2>/dev/null)
    if [[ -z "$ufw_status" ]]; then
        log_warn "UFW 防火墙未启用，跳过防火墙规则关闭"
        return 0
    fi
    
    # 尝试从配置或备份文件中读取端口
    local ports=()
    
    # 从当前配置中查找端口
    if [[ -f "$CONFIG_PATH/config.json" ]]; then
        if command -v jq &>/dev/null; then
            # 使用jq查找所有inbounds的端口
            local all_ports=$(jq '.inbounds[].port' "$CONFIG_PATH/config.json" 2>/dev/null)
            for port in $all_ports; do
                if [[ "$port" != "null" && -n "$port" ]]; then
                    ports+=("$port")
                fi
            done
        else
            # 使用grep查找端口
            local all_ports=$(grep -o '"port": [0-9]*' "$CONFIG_PATH/config.json" | awk '{print $2}')
            for port in $all_ports; do
                if [[ -n "$port" ]]; then
                    ports+=("$port")
                fi
            done
        fi
    fi
    
    # 如果找不到端口，从备份中查找
    if [[ ${#ports[@]} -eq 0 && -n "$CONFIG_BACKUP" && -f "$CONFIG_BACKUP/config.json" ]]; then
        if command -v jq &>/dev/null; then
            local all_ports=$(jq '.inbounds[].port' "$CONFIG_BACKUP/config.json" 2>/dev/null)
            for port in $all_ports; do
                if [[ "$port" != "null" && -n "$port" ]]; then
                    ports+=("$port")
                fi
            done
        else
            local all_ports=$(grep -o '"port": [0-9]*' "$CONFIG_BACKUP/config.json" | awk '{print $2}')
            for port in $all_ports; do
                if [[ -n "$port" ]]; then
                    ports+=("$port")
                fi
            done
        fi
    fi
    
    # 如果还是找不到端口，尝试使用全局变量
    if [[ ${#ports[@]} -eq 0 ]]; then
        if [[ -n "$REALITY_PORT" && "$REALITY_PORT" =~ ^[0-9]+$ ]]; then
            ports+=("$REALITY_PORT")
        fi
    fi
    
    # 去除重复的端口
    if [[ ${#ports[@]} -gt 0 ]]; then
        local unique_ports=()
        local port_list=""
        for port in "${ports[@]}"; do
            # 检查端口是否为有效数字
            if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                log_warn "端口 '$port' 不是有效数字，已跳过"
                continue
            fi
            
            # 检查端口是否已在列表中
            if [[ "$port_list" != *",$port,"* ]]; then
                unique_ports+=("$port")
                port_list="$port_list,$port,"
            fi
        done
        ports=("${unique_ports[@]}")
    fi
    
    # 如果找到了端口，关闭防火墙规则
    if [[ ${#ports[@]} -gt 0 ]]; then
        local port_list=$(printf ", %s" "${ports[@]}")
        port_list=${port_list:2}  # 移除开头的逗号和空格
        log_info "找到端口: $port_list，尝试关闭 UFW 防火墙规则"
        
        local closed_ports=()
        for port in "${ports[@]}"; do
            # 检查端口是否已开放在UFW中
            if ! ufw status | grep -q "$port/tcp"; then
                log_info "端口 $port 未在 UFW 中开放，跳过"
                continue
            fi
            
            echo -n "关闭 UFW 防火墙端口 $port... "
            if ufw delete allow "$port/tcp" &>/dev/null; then
                echo -e "${GREEN}完成${NC}"
                closed_ports+=("$port")
            else
                echo -e "${RED}失败${NC}"
                log_warn "无法关闭端口 $port"
            fi
        done
        
        # 打印关闭的端口
        if [[ ${#closed_ports[@]} -gt 0 ]]; then
            local closed_list=$(printf ", %s" "${closed_ports[@]}")
            closed_list=${closed_list:2}  # 移除开头的逗号和空格
            log_info "已关闭 UFW 防火墙中的端口: $closed_list"
        else
            log_warn "没有关闭任何端口"
        fi
    else
        log_warn "无法确定之前使用的端口，跳过防火墙规则关闭"
    fi
}

# 删除 Xray 文件
remove_xray_files() {
    log_info "删除 Xray 文件"
    
    # 删除二进制文件
    echo -n "删除 Xray 核心文件... "
    if rm -f "$XRAY_PATH/xray" "$XRAY_PATH/geoip.dat" "$XRAY_PATH/geosite.dat"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${YELLOW}部分文件未能删除${NC}"
        log_warn "部分 Xray 核心文件可能未能完全删除"
    fi
    
    # 删除配置目录（不删除备份）
    echo -n "删除 Xray 配置目录... "
    if [[ -d "$CONFIG_PATH" ]]; then
        if rm -rf "$CONFIG_PATH"; then
            echo -e "${GREEN}成功${NC}"
        else
            echo -e "${RED}失败${NC}"
            log_warn "无法删除配置目录 $CONFIG_PATH"
        fi
    else
        echo -e "${YELLOW}配置目录不存在${NC}"
    fi
    
    # 删除日志目录
    echo -n "删除 Xray 日志目录... "
    if [[ -d "$LOG_PATH" ]]; then
        if rm -rf "$LOG_PATH"; then
            echo -e "${GREEN}成功${NC}"
        else
            echo -e "${RED}失败${NC}"
            log_warn "无法删除日志目录 $LOG_PATH"
        fi
    else
        echo -e "${YELLOW}日志目录不存在${NC}"
    fi
    
    # 删除服务文件
    echo -n "删除 Xray 服务文件... "
    if rm -f /etc/systemd/system/xray.service; then
        echo -e "${GREEN}成功${NC}"
        systemctl daemon-reload
    else
        echo -e "${YELLOW}服务文件不存在或无法删除${NC}"
    fi
    
    return 0
}

# 完整卸载流程
uninstall_xray() {
    clear
    echo "=================================================="
    echo -e "${RED}开始卸载 Xray${NC}"
    echo "=================================================="
    
    # 确认卸载
    echo -e "${YELLOW}警告: 这将卸载 Xray 并删除相关文件${NC}"
    read -rp "是否继续? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        log_info "卸载已取消"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    # 检查 root 权限
    check_root
    
    # 备份配置
    backup_config
    
    # 停止服务
    stop_xray_service
    
    # 关闭防火墙端口
    close_firewall_port
    
    # 删除文件
    remove_xray_files
    
    echo ""
    log_info "Xray 卸载完成"
    
    # 直接删除备份文件，不询问用户
    if [[ -n "$CONFIG_BACKUP" && -d "$CONFIG_BACKUP" ]]; then
        rm -rf "$CONFIG_BACKUP"
        log_info "备份文件已删除"
    fi
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 检查 Xray 状态
check_status() {
    clear
    echo "=================================================="
    echo -e "${BLUE}Xray 状态检查${NC}"
    echo "=================================================="
    
    # 检查是否安装
    if [[ ! -f "$XRAY_PATH/xray" ]]; then
        echo -e "${RED}Xray 未安装${NC}"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    # 检查版本
    echo -n "Xray 版本: "
    $XRAY_PATH/xray version | head -n 1
    
    # 检查服务状态
    echo -n "服务状态: "
    if systemctl is-active xray &>/dev/null; then
        echo -e "${GREEN}运行中${NC}"
    else
        echo -e "${RED}未运行${NC}"
    fi
    
    echo -n "自启动状态: "
    if systemctl is-enabled xray &>/dev/null; then
        echo -e "${GREEN}已启用${NC}"
    else
        echo -e "${RED}未启用${NC}"
    fi
    
    # 获取内存和 CPU 使用情况
    echo "资源使用情况:"
    ps -aux | grep xray | grep -v grep | awk '{print "内存使用: " $4 "%, CPU使用: " $3 "%"}'
    
    # 检查端口
    if [[ -f "$CONFIG_PATH/config.json" ]]; then
        local current_port=""
        if command -v jq &>/dev/null; then
            current_port=$(jq '.inbounds[0].port' "$CONFIG_PATH/config.json" 2>/dev/null)
        else
            current_port=$(grep -o '"port": [0-9]*' "$CONFIG_PATH/config.json" | head -1 | awk '{print $2}')
        fi
        
        if [[ -n "$current_port" && "$current_port" != "null" ]]; then
            echo -n "端口 $current_port 状态: "
            if command -v ss &>/dev/null; then
                if ss -tuln | grep -q ":$current_port "; then
                    echo -e "${GREEN}已开放${NC}"
                else
                    echo -e "${RED}未开放${NC}"
                fi
            elif command -v netstat &>/dev/null; then
                if netstat -tuln | grep -q ":$current_port "; then
                    echo -e "${GREEN}已开放${NC}"
                else
                    echo -e "${RED}未开放${NC}"
                fi
            else
                echo -e "${YELLOW}无法检查${NC}"
            fi
            
            # 显示链接数
            echo "当前连接:"
            if command -v ss &>/dev/null; then
                ss -tn | grep ":$current_port" | wc -l | awk '{print "活跃连接数: " $1}'
            elif command -v netstat &>/dev/null; then
                netstat -tn | grep ":$current_port" | wc -l | awk '{print "活跃连接数: " $1}'
            else
                echo "无法获取连接信息"
            fi
        fi
    fi
    
    echo -e "\n最近的日志:"
    if [[ -f "$LOG_PATH/error.log" ]]; then
        tail -n 10 "$LOG_PATH/error.log"
    else
        echo "找不到错误日志文件"
    fi
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 显示配置信息
show_config() {
    clear
    echo "=================================================="
    echo -e "${CYAN}Xray 配置信息${NC}"
    echo "=================================================="
    
    # 检查是否已安装
    if [[ ! -f "$XRAY_PATH/xray" ]]; then
        echo -e "${RED}Xray 未安装${NC}"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    # 显示配置文件内容
    if [[ -f "$CONFIG_PATH/config.json" ]]; then
        if command -v jq &>/dev/null; then
            echo "配置信息 (美化格式):"
            jq . "$CONFIG_PATH/config.json"
        else
            echo "配置文件内容:"
            cat "$CONFIG_PATH/config.json"
        fi
    else
        echo -e "${RED}找不到配置文件${NC}"
    fi
    
    # 显示客户端信息
    if [[ -f "/root/xray_info.txt" ]]; then
        echo -e "\n客户端信息:"
        cat /root/xray_info.txt
    else
        echo -e "\n${RED}找不到客户端信息文件${NC}"
    fi
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 重启 Xray 服务
restart_service() {
    clear
    echo "=================================================="
    echo -e "${GREEN}重启 Xray 服务${NC}"
    echo "=================================================="
    
    # 检查是否已安装
    if [[ ! -f "$XRAY_PATH/xray" ]]; then
        echo -e "${RED}Xray 未安装${NC}"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    echo -n "重启 Xray 服务... "
    if systemctl restart xray; then
        echo -e "${GREEN}成功${NC}"
        log_info "Xray 服务已重启"
    else
        echo -e "${RED}失败${NC}"
        log_error "无法重启 Xray 服务"
    fi
    
    # 检查服务状态
    echo -n "Xray 服务状态: "
    if systemctl is-active xray &>/dev/null; then
        echo -e "${GREEN}运行中${NC}"
    else
        echo -e "${RED}未运行${NC}"
    fi
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 更新 Xray
update_xray() {
    clear
    echo "=================================================="
    echo -e "${YELLOW}更新 Xray${NC}"
    echo "=================================================="
    
    # 检查是否已安装
    if [[ ! -f "$XRAY_PATH/xray" ]]; then
        echo -e "${RED}Xray 未安装，请先安装${NC}"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 0
    fi
    
    # 获取当前版本
    local current_version
    current_version=$($XRAY_PATH/xray version | head -n 1 | cut -d ' ' -f 2)
    echo "当前版本: $current_version"
    
    # 获取最新版本
    echo -n "获取最新版本... "
    local latest_version=$(get_latest_version)
    echo -e "${GREEN}$latest_version${NC}"
    
    # 比较版本
    if [[ "$current_version" == "$latest_version" ]]; then
        echo -e "${GREEN}已经是最新版本${NC}"
        read -rp "是否强制更新? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
            log_info "更新已取消"
            read -rp "按回车键返回主菜单..." temp
            show_menu
            return 0
        fi
    fi
    
    # 备份配置
    backup_config
    
    # 停止服务
    echo -n "停止 Xray 服务... "
    if systemctl stop xray &>/dev/null; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_warn "无法停止 Xray 服务，将尝试继续更新"
    fi
    
    # 下载新版本
    log_info "开始下载新版本"
    
    # 创建临时目录
    local tmp_dir="/tmp/xray_update"
    mkdir -p "$tmp_dir"
    
    # 确定系统架构
    local arch
    case $(uname -m) in
        x86_64|amd64) arch="64" ;;
        armv7l|armv8l) arch="arm32-v7a" ;;
        aarch64) arch="arm64-v8a" ;;
        *) arch="64" ;;  # 默认使用64位版本
    esac
    
    # 构建下载URL
    local download_url="https://github.com/XTLS/Xray-core/releases/download/$latest_version/Xray-linux-$arch.zip"
    log_info "下载链接: $download_url"
    
    # 下载Xray
    echo -n "下载 Xray... "
    if wget -q --show-progress -O "$tmp_dir/xray.zip" "$download_url"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "下载 Xray 失败"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 解压文件
    echo -n "解压 Xray... "
    if unzip -q -o "$tmp_dir/xray.zip" -d "$tmp_dir"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "解压 Xray 失败"
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 备份旧的二进制文件
    mv "$XRAY_PATH/xray" "$XRAY_PATH/xray.old" 2>/dev/null
    
    # 复制新文件
    echo -n "更新 Xray 核心文件... "
    if cp "$tmp_dir/xray" "$XRAY_PATH/xray" && chmod +x "$XRAY_PATH/xray"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "更新 Xray 核心文件失败"
        
        # 恢复旧文件
        if [[ -f "$XRAY_PATH/xray.old" ]]; then
            mv "$XRAY_PATH/xray.old" "$XRAY_PATH/xray"
            log_warn "已恢复为旧版本"
        fi
        
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 更新 geoip.dat 和 geosite.dat
    echo -n "更新 GeoIP 和 GeoSite 数据... "
    if cp "$tmp_dir/geoip.dat" "$XRAY_PATH/geoip.dat" && \
       cp "$tmp_dir/geosite.dat" "$XRAY_PATH/geosite.dat"; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${YELLOW}失败${NC}"
        log_warn "更新 GeoIP 和 GeoSite 数据失败，但不影响核心功能"
    fi
    
    # 删除旧备份和临时文件
    rm -f "$XRAY_PATH/xray.old"
    rm -rf "$tmp_dir"
    
    # 启动服务
    echo -n "启动 Xray 服务... "
    if systemctl start xray; then
        echo -e "${GREEN}成功${NC}"
    else
        echo -e "${RED}失败${NC}"
        log_error "启动 Xray 服务失败，请检查配置"
        systemctl status xray
        read -rp "按回车键返回主菜单..." temp
        show_menu
        return 1
    fi
    
    # 检查更新后的版本
    local new_version
    new_version=$($XRAY_PATH/xray version | head -n 1 | cut -d ' ' -f 2)
    
    log_info "Xray 更新完成，版本: $new_version"
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 更新脚本版本信息
update_script_version() {
    clear
    echo "=================================================="
    echo -e "${GREEN}更新脚本版本信息${NC}"
    echo "=================================================="
    
    # 显示当前脚本版本
    echo "当前脚本版本: $SCRIPT_VERSION"
    
    # 获取最新脚本版本
    echo -n "获取最新脚本版本... "
    local latest_version
    latest_version=$(curl -s https://raw.githubusercontent.com/XTLS/Xray-core/main/xray-manager.sh | grep -o 'SCRIPT_VERSION="[^"]*"' | cut -d'"' -f2)

    if [[ -z "$latest_version" ]]; then
        echo -e "${RED}失败${NC}"
        log_error "无法获取最新脚本版本信息"
        read -rp "是否继续更新? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
            log_info "更新已取消"
            read -rp "按回车键返回主菜单..." temp
            show_menu
            return 0
        fi
        latest_version="1.0.0"  # 设置一个固定版本作为备用
        log_info "将使用固定版本: $latest_version"
    else
        echo -e "${GREEN}$latest_version${NC}"
        
        # 比较版本
        if [[ "$SCRIPT_VERSION" == "$latest_version" ]]; then
            echo -e "${GREEN}已经是最新版本${NC}"
            read -rp "是否强制更新? [y/N] " confirm
            if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                log_info "更新已取消"
                read -rp "按回车键返回主菜单..." temp
                show_menu
                return 0
            fi
        fi
    fi
    
    # 更新脚本版本
    echo -n "更新脚本版本... "
    sed -i "s/SCRIPT_VERSION=\"[^\"]*\"/SCRIPT_VERSION=\"$latest_version\"/" "$0"
    echo -e "${GREEN}成功${NC}"
    
    log_info "脚本版本已更新为 $latest_version"
    
    read -rp "按回车键返回主菜单..." temp
    show_menu
}

# 主函数
main() {
    # 处理命令行参数
    if [[ $# -gt 0 ]]; then
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--install)
                check_root
                install_xray
                exit 0
                ;;
            -u|--uninstall)
                check_root
                uninstall_xray
                exit 0
                ;;
            -s|--status)
                check_root
                check_status
                exit 0
                ;;
            -up|--update)
                check_root
                update_xray
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
    check_root
    show_menu
}

# 执行主函数
main "$@" 