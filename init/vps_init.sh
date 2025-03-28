#!/bin/bash
#
# VPS初始化一键脚本
# 整合了系统更新、登录安全设置、系统清理、Docker安装、防火墙设置、时区设置、
# 内存优化、Fail2ban安装和BBR加速
# 使用方法: chmod +x vps_init.sh && ./vps_init.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/vps_init.sh && chmod +x vps_init.sh && ./vps_init.sh

# ===========================================
# 用户设置区域 - 根据需要修改
# ===========================================
NEW_PASSWORD="d!Fssw97SoALHa"     # root用户新密码
NEW_SSH_PORT="4399"               # SSH新端口号
TIMEZONE="Asia/Shanghai"          # 时区设置
SWAP_SIZE=1024                    # 交换分区大小(MB)
# ===========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 确保脚本以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 必须以root用户运行此脚本!${NC}"
    exit 1
fi

# 显示欢迎信息
echo -e "${GREEN}=============================================${NC}"
echo -e "${BLUE}        VPS初始化一键脚本开始执行             ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# ===========================================
# 交互式设置选项
# ===========================================
echo -e "${BLUE}进行交互式设置...${NC}"

# 询问是否修改SSH端口
echo -e "${YELLOW}1. 是否修改SSH端口? 当前设置为: ${NEW_SSH_PORT}${NC}"
while true; do
    read -p "修改SSH端口? (y/n, 默认n): " CHANGE_SSH_PORT
    # 设置默认值为否，用户按Enter就不修改
    CHANGE_SSH_PORT=${CHANGE_SSH_PORT:-n}
    if [[ "$CHANGE_SSH_PORT" =~ ^[Yy]$ ]] || [[ "$CHANGE_SSH_PORT" =~ ^[Nn]$ ]]; then
        break
    else
        echo -e "${RED}无效的输入，请输入 y 或 n${NC}"
    fi
done

if [[ "$CHANGE_SSH_PORT" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}SSH端口将被修改为: ${NEW_SSH_PORT}${NC}"
else
    echo -e "${GREEN}保持SSH端口不变: $NEW_SSH_PORT${NC}"
fi

# 询问是否修改密码
echo -e "${YELLOW}2. 是否修改root密码?${NC}"
while true; do
    read -p "修改root密码? (y/n, 默认n): " CHANGE_PASSWORD
    # 设置默认值为否，用户按Enter就不修改
    CHANGE_PASSWORD=${CHANGE_PASSWORD:-n}
    if [[ "$CHANGE_PASSWORD" =~ ^[Yy]$ ]] || [[ "$CHANGE_PASSWORD" =~ ^[Nn]$ ]]; then
        break
    else
        echo -e "${RED}无效的输入，请输入 y 或 n${NC}"
    fi
done

if [[ "$CHANGE_PASSWORD" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}root密码将被修改为系统预设值${NC}"
else
    echo -e "${GREEN}保持root密码不变${NC}"
fi

# 询问是否修改主机名
echo -e "${YELLOW}3. 是否修改主机名?${NC}"
while true; do
    read -p "修改主机名? (y/n, 默认n): " CHANGE_HOSTNAME
    # 设置默认值为否，用户按Enter就不修改
    CHANGE_HOSTNAME=${CHANGE_HOSTNAME:-n}
    if [[ "$CHANGE_HOSTNAME" =~ ^[Yy]$ ]] || [[ "$CHANGE_HOSTNAME" =~ ^[Nn]$ ]]; then
        break
    else
        echo -e "${RED}无效的输入，请输入 y 或 n${NC}"
    fi
done

if [[ "$CHANGE_HOSTNAME" =~ ^[Yy]$ ]]; then
    # 显示当前主机名
    CURRENT_HOSTNAME=$(hostname)
    echo -e "${YELLOW}当前主机名: ${CURRENT_HOSTNAME}${NC}"
    
    # 让用户输入新主机名
    read -p "请输入新的主机名: " NEW_HOSTNAME
    if [ -n "$NEW_HOSTNAME" ]; then
        CHANGE_HOSTNAME_FLAG=true
        echo -e "${GREEN}主机名将被修改为: ${NEW_HOSTNAME}${NC}"
    else
        CHANGE_HOSTNAME_FLAG=false
        echo -e "${RED}主机名不能为空，将保持不变${NC}"
    fi
else
    CHANGE_HOSTNAME_FLAG=false
    echo -e "${GREEN}保持主机名不变${NC}"
fi

echo -e "${BLUE}交互式设置完成${NC}"
echo ""

# 记录开始时间
START_TIME=$(date +%s)

# 检查系统类型
if [ -f /etc/debian_version ]; then
    OS_TYPE="debian"
    echo -e "${GREEN}检测到Debian/Ubuntu系统${NC}"
else
    echo -e "${YELLOW}警告: 此脚本主要为Debian/Ubuntu系统设计${NC}"
    echo -e "${YELLOW}部分功能可能在其他系统上不正常工作${NC}"
    OS_TYPE="other"
fi

# 创建日志文件
LOG_FILE="/var/log/vps_init_$(date +%Y%m%d_%H%M%S).log"
touch $LOG_FILE
echo "VPS初始化脚本开始执行: $(date)" > $LOG_FILE

# 定义日志函数
log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# 定义错误处理函数
handle_error() {
    local exit_code=$?
    local line_no=$1
    if [ $exit_code -ne 0 ]; then
        log "${RED}错误: 在第 $line_no 行发生错误，退出代码: $exit_code${NC}"
        log "${RED}请检查日志文件: $LOG_FILE${NC}"
    fi
}

# 设置错误跟踪
trap 'handle_error $LINENO' ERR

# ===========================================
# 1. 系统更新
# ===========================================
log "${BLUE}[1/10] 系统更新开始...${NC}"

# 保存当前的sources.list作为备份
if [ -f "/etc/apt/sources.list" ]; then
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    log "${GREEN}备份了软件源配置文件${NC}"
fi

# 更新系统包
if [ "$OS_TYPE" = "debian" ]; then
    apt update -y || log "${RED}更新软件源失败${NC}"
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y || log "${RED}系统升级失败${NC}"
    apt install -y wget curl sudo vim git ufw net-tools htop iftop || log "${RED}安装基础软件包失败${NC}"
    log "${GREEN}系统更新完成，安装了常用工具${NC}"
else
    log "${YELLOW}非Debian系统，跳过标准更新流程${NC}"
fi

# ===========================================
# 2. 主机名设置（如果用户选择了修改）
# ===========================================
if [ "$CHANGE_HOSTNAME_FLAG" = true ]; then
    log "${BLUE}[2/10] 设置主机名...${NC}"
    
    # 备份当前主机名配置
    cp /etc/hostname /etc/hostname.bak
    cp /etc/hosts /etc/hosts.bak
    
    # 修改主机名
    echo "$NEW_HOSTNAME" > /etc/hostname
    hostname "$NEW_HOSTNAME"
    
    # 更新hosts文件
    sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    
    # 检查是否修改成功
    CURRENT_HOSTNAME=$(hostname)
    if [ "$CURRENT_HOSTNAME" = "$NEW_HOSTNAME" ]; then
        log "${GREEN}主机名已成功修改为: $NEW_HOSTNAME${NC}"
    else
        log "${RED}主机名修改失败，当前名称: $CURRENT_HOSTNAME${NC}"
    fi
    
    log "${GREEN}主机名设置完成${NC}"
else
    log "${YELLOW}[2/10] 跳过主机名设置...${NC}"
fi

# ===========================================
# 3. 登录安全设置
# ===========================================
log "${BLUE}[3/10] 设置登录安全...${NC}"

# 根据用户选择修改root密码
if [[ "$CHANGE_PASSWORD" =~ ^[Yy]$ ]]; then
    echo "root:$NEW_PASSWORD" | chpasswd
    if [ $? -eq 0 ]; then
        log "${GREEN}Root密码修改成功${NC}"
    else
        log "${RED}Root密码修改失败${NC}"
    fi
else
    log "${YELLOW}根据用户选择，保持root密码不变${NC}"
fi

# 根据用户选择修改SSH端口
if [[ "$CHANGE_SSH_PORT" =~ ^[Yy]$ ]]; then
    # 备份SSH配置文件
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    log "${GREEN}SSH配置已备份${NC}"

    # 修改SSH配置
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/#Port/Port/' /etc/ssh/sshd_config
    sed -i "s/Port [0-9]\+/Port $NEW_SSH_PORT/g" /etc/ssh/sshd_config

    # 读取修改后的SSH端口以确认更改
    NEW_PORT_CONFIGURED=$(grep -P "^Port\s+\d+" /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$NEW_PORT_CONFIGURED" = "$NEW_SSH_PORT" ]; then
        log "${GREEN}SSH端口已修改为: $NEW_SSH_PORT${NC}"
    else
        log "${RED}SSH端口修改失败，当前设置: $NEW_PORT_CONFIGURED${NC}"
        # 尝试使用另一种方法修改
        echo "Port $NEW_SSH_PORT" >> /etc/ssh/sshd_config
        log "${YELLOW}尝试使用备选方法添加端口设置${NC}"
    fi

    # 重启SSH服务
    systemctl restart sshd
    if [ $? -eq 0 ]; then
        log "${GREEN}SSH服务重启成功${NC}"
    else
        log "${RED}SSH服务重启失败${NC}"
        # 尝试使用service命令
        service sshd restart || service ssh restart
    fi

    # 检查SSH服务状态
    systemctl status sshd --no-pager || service sshd status || service ssh status
    log "${GREEN}SSH配置更改完成${NC}"
    log "${YELLOW}注意：新的SSH连接端口为 $NEW_SSH_PORT${NC}"
else
    log "${YELLOW}根据用户选择，保持SSH端口不变${NC}"
    
    # 即使不修改端口，仍然应该确保其他SSH安全设置
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    
    log "${GREEN}SSH基本安全设置完成${NC}"
fi

# ===========================================
# 4. 系统清理
# ===========================================
log "${BLUE}[4/10] 系统清理开始...${NC}"

# 清理不需要的软件包
if [ "$OS_TYPE" = "debian" ]; then
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
    apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y 2>/dev/null || log "${YELLOW}没有需要清理的软件包配置${NC}"
    
    # 清理日志
    journalctl --rotate
    journalctl --vacuum-time=1d
    journalctl --vacuum-size=50M
    log "${GREEN}系统日志已清理${NC}"
    
    # 清理旧内核(保留当前运行的内核)
    apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y 2>/dev/null || log "${YELLOW}没有可清理的旧内核${NC}"
    
    log "${GREEN}系统清理完成${NC}"
else
    log "${YELLOW}非Debian系统，跳过系统清理流程${NC}"
fi

# ===========================================
# 5. Docker安装
# ===========================================
log "${BLUE}[5/10] Docker安装开始...${NC}"

# 检查Docker是否已安装
if command -v docker &> /dev/null; then
    log "${GREEN}Docker已经安装，版本信息:${NC}"
    docker --version
else
    # 安装Docker
    if [ "$OS_TYPE" = "debian" ]; then
        # 使用官方安装脚本
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        systemctl enable docker
        
        # 安装Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            log "${GREEN}Docker Compose 安装完成${NC}"
        fi
        
        log "${GREEN}Docker安装完成，版本信息:${NC}"
        docker --version
        docker-compose --version
    else
        log "${YELLOW}非Debian系统，请手动安装Docker${NC}"
    fi
fi

# ===========================================
# 6. 防火墙设置
# ===========================================
log "${BLUE}[6/10] 防火墙设置开始...${NC}"

# 安装UFW
if [ "$OS_TYPE" = "debian" ]; then
    apt update -y && apt install -y ufw net-tools lsof

    # 确保防火墙默认策略
    ufw default deny incoming
    ufw default allow outgoing
    
    # 获取当前SSH端口（如果有多个SSH端口，获取所有）
    CURRENT_SSH_PORT=$(grep -P "^Port\s+\d+" /etc/ssh/sshd_config | awk '{print $2}')
    if [ -z "$CURRENT_SSH_PORT" ]; then
        # 如果没找到，使用默认端口22
        CURRENT_SSH_PORT="22"
    fi
    
    # 总是添加新配置的SSH端口（防止被锁在系统之外）
    log "${GREEN}允许SSH端口 $NEW_SSH_PORT${NC}"
    ufw allow $NEW_SSH_PORT/tcp comment 'New SSH Port'
    
    # 如果当前SSH端口与新端口不同，添加当前SSH端口作为备份
    if [ "$CURRENT_SSH_PORT" != "$NEW_SSH_PORT" ]; then
        log "${GREEN}允许当前SSH端口 $CURRENT_SSH_PORT (备份)${NC}"
        ufw allow $CURRENT_SSH_PORT/tcp comment 'Current SSH Port (Backup)'
    fi
    
    # 添加基本Web服务端口
    log "${GREEN}允许HTTP/HTTPS端口${NC}"
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    
    # 检测活跃的网络连接和正在监听的端口
    log "${YELLOW}检测当前活跃的服务端口...${NC}"
    
    # 使用netstat查找监听的TCP端口
    LISTENING_PORTS=$(netstat -tlnp 2>/dev/null | grep "LISTEN" | awk '{print $4}' | awk -F: '{print $NF}' | sort -n | uniq)
    
    # 使用lsof作为备选方法
    if [ -z "$LISTENING_PORTS" ]; then
        LISTENING_PORTS=$(lsof -i -P -n | grep LISTEN | awk '{print $9}' | awk -F: '{print $NF}' | sort -n | uniq)
    fi
    
    # 如果仍然为空，提示手动检查
    if [ -z "$LISTENING_PORTS" ]; then
        log "${YELLOW}未检测到活跃端口，只开放SSH、HTTP和HTTPS端口${NC}"
    else
        log "${GREEN}检测到以下活跃端口:${NC}"
        for PORT in $LISTENING_PORTS; do
            # 跳过SSH端口(已经添加过)，以及常见的本地服务端口
            if [[ "$PORT" != "$NEW_SSH_PORT" && "$PORT" != "$CURRENT_SSH_PORT" && 
                  "$PORT" != "80" && "$PORT" != "443" && 
                  "$PORT" -lt "65535" && "$PORT" -gt "1024" ]]; then
                
                # 尝试找出服务名称
                SERVICE=$(lsof -i:$PORT -sTCP:LISTEN | grep -v "COMMAND" | awk '{print $1}' | head -1)
                if [ -z "$SERVICE" ]; then
                    SERVICE=$(netstat -tlnp 2>/dev/null | grep ":$PORT" | awk '{print $7}' | cut -d"/" -f2 | head -1)
                fi
                
                if [ -n "$SERVICE" ]; then
                    COMMENT="Service: $SERVICE"
                else
                    COMMENT="Unknown Service"
                fi
                
                log "${GREEN}允许端口 $PORT/tcp ($COMMENT)${NC}"
                ufw allow $PORT/tcp comment "$COMMENT"
            fi
        done
    fi
    
    # 删除询问用户是否手动开放端口的部分
    log "${GREEN}已自动开放SSH、HTTP、HTTPS端口和检测到的活跃服务端口${NC}"
    
    # 启用防火墙
    if ! ufw status | grep -q "Status: active"; then
        log "${YELLOW}启用UFW防火墙...${NC}"
        echo "y" | ufw enable || log "${RED}UFW启用失败${NC}"
    else
        log "${GREEN}UFW防火墙已启用${NC}"
    fi
    
    # 显示防火墙状态
    ufw status numbered | tee -a $LOG_FILE
    log "${GREEN}防火墙设置完成，已使用最小化原则开放端口${NC}"
else
    log "${YELLOW}非Debian系统，请手动配置防火墙${NC}"
fi

# ===========================================
# 7. 时区设置
# ===========================================
log "${BLUE}[7/10] 时区设置开始...${NC}"

# 设置时区
timedatectl set-timezone $TIMEZONE
if [ $? -eq 0 ]; then
    CURRENT_TZ=$(timedatectl show --property=Timezone --value)
    log "${GREEN}时区设置为: $CURRENT_TZ${NC}"
else
    log "${RED}时区设置失败${NC}"
fi

# ===========================================
# 8. 内存优化 - 添加交换空间
# ===========================================
log "${BLUE}[8/10] 内存优化开始...${NC}"

# 获取当前所有交换空间信息
CURRENT_SWAP_TOTAL=$(free -m | grep "Swap:" | awk '{print $2}')
log "${YELLOW}当前系统交换空间总大小: ${CURRENT_SWAP_TOTAL}MB${NC}"

# 检查是否存在交换空间且大小与设定值相同
if [ "$CURRENT_SWAP_TOTAL" -eq "$SWAP_SIZE" ]; then
    log "${GREEN}当前交换空间大小(${CURRENT_SWAP_TOTAL}MB)与设定值一致，无需修改${NC}"
    # 显示交换空间信息
    free -h | tee -a $LOG_FILE
else
    # 如果不存在交换空间或大小不同，则进行处理
    if [ "$CURRENT_SWAP_TOTAL" -gt "0" ]; then
        log "${YELLOW}系统已有交换空间但大小不符(${CURRENT_SWAP_TOTAL}MB)，准备清理现有交换空间...${NC}"
        
        # 获取所有交换设备
        SWAP_DEVICES=$(swapon --show=NAME --noheadings)
        
        # 清理所有活跃的交换空间
        for DEVICE in $SWAP_DEVICES; do
            log "${YELLOW}关闭交换空间: $DEVICE${NC}"
            swapoff "$DEVICE"
        done
        
        # 从fstab中移除所有交换空间条目(保留备份)
        cp /etc/fstab /etc/fstab.bak
        log "${GREEN}备份了/etc/fstab文件${NC}"
        sed -i '/swap/d' /etc/fstab
        
        # 删除交换文件
        if [ -f /swapfile ]; then
            log "${YELLOW}删除现有交换文件...${NC}"
            rm -f /swapfile
        fi
        
        log "${GREEN}所有现有交换空间已清理${NC}"
    else
        log "${YELLOW}系统未配置交换空间，准备创建...${NC}"
    fi

    # 创建新的交换文件
    log "${GREEN}创建${SWAP_SIZE}MB大小的交换文件...${NC}"
    dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE status=progress
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # 设置开机自动挂载
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
        log "${GREEN}已添加到fstab，开机将自动挂载${NC}"
    fi

    # 调整swappiness参数(控制系统对交换空间的使用倾向)
    echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
    sysctl -p /etc/sysctl.d/99-swappiness.conf

    # 显示交换空间信息
    log "${GREEN}交换分区配置完成，当前内存和交换空间状态:${NC}"
    free -h | tee -a $LOG_FILE
fi

# ===========================================
# 9. Fail2ban安装和配置
# ===========================================
log "${BLUE}[9/10] Fail2ban安装开始...${NC}"

if [ "$OS_TYPE" = "debian" ]; then
    # 安装Fail2ban
    apt update -y && apt install -y fail2ban
    systemctl start fail2ban
    systemctl enable fail2ban
    
    # 配置Fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    
    # 清理任何现有配置
    rm -rf /etc/fail2ban/jail.d/* 2>/dev/null || true
    
    # 创建SSH防护配置
    cat <<EOF > /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled = true
mode = normal
port = $NEW_SSH_PORT
logpath = %(sshd_log)s
backend = systemd
maxretry = 5
bantime = 1h
findtime = 10m
EOF
    
    # 重启Fail2ban
    log "${YELLOW}重启Fail2ban服务...${NC}"
    systemctl restart fail2ban
    
    # 等待服务启动完成
    log "${YELLOW}等待Fail2ban服务完全启动...${NC}"
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet fail2ban; then
        log "${GREEN}Fail2ban服务已成功启动${NC}"
        
        # 显示Fail2ban状态（使用错误处理避免脚本终止）
        log "${YELLOW}获取Fail2ban状态信息...${NC}"
        
        # 尝试获取fail2ban状态，忽略可能的错误
        fail2ban-client status >/dev/null 2>&1 || log "${YELLOW}无法获取fail2ban综合状态，但这不影响功能${NC}"
        
        # 尝试获取sshd监狱状态
        if fail2ban-client status sshd >/dev/null 2>&1; then
            log "${GREEN}SSH防护已成功配置${NC}"
            # 只有在前面成功的情况下才显示详细信息
            fail2ban-client status sshd
        else
            log "${YELLOW}无法获取SSH监狱状态，这可能是因为服务刚刚启动或配置需要更多时间生效${NC}"
            log "${YELLOW}如果在重启后仍有问题，请检查 /var/log/fail2ban.log${NC}"
        fi
        
        # 显示服务状态
        systemctl status fail2ban --no-pager || true
    else
        log "${RED}Fail2ban服务启动失败，请检查错误日志${NC}"
        log "${YELLOW}尝试查看Fail2ban日志获取错误详情:${NC}"
        tail -n 20 /var/log/fail2ban.log 2>/dev/null || log "${RED}无法读取Fail2ban日志${NC}"
    fi
    
    log "${GREEN}Fail2ban安装和配置完成${NC}"
    log "${YELLOW}如果出现临时错误，服务器重启后通常会正常工作${NC}"
else
    log "${YELLOW}非Debian系统，请手动安装Fail2ban${NC}"
fi

# ===========================================
# 10. BBR加速配置
# ===========================================
log "${BLUE}[10/10] BBR配置开始...${NC}"

# 检查BBR是否已启用
if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    log "${GREEN}BBR已经启用${NC}"
else
    log "${YELLOW}配置BBR...${NC}"
    # 添加BBR配置
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    
    # 应用设置
    sysctl -p
    
    # 验证设置
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        log "${GREEN}BBR启用成功${NC}"
    else
        log "${RED}BBR启用失败${NC}"
    fi
fi

# 显示可用的拥塞控制算法
log "${GREEN}当前系统支持的TCP拥塞控制算法:${NC}"
sysctl net.ipv4.tcp_available_congestion_control

# 验证模块是否加载
lsmod | grep bbr

# ===========================================
# 完成处理
# ===========================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

log "${GREEN}=======================================================${NC}"
log "${GREEN}VPS初始化完成！用时: ${MINUTES}分${SECONDS}秒${NC}"
log "${GREEN}=======================================================${NC}"
log "${YELLOW}重要提示:${NC}"

# 根据用户选择显示相应的提示信息
TIP_COUNT=1

# 如果用户选择了修改SSH端口，显示端口信息
if [[ "$CHANGE_SSH_PORT" =~ ^[Yy]$ ]]; then
    log "${YELLOW}$TIP_COUNT. SSH端口已更改为: ${NEW_SSH_PORT}${NC}"
    TIP_COUNT=$((TIP_COUNT + 1))
fi

# 如果用户选择了修改root密码，显示密码信息
if [[ "$CHANGE_PASSWORD" =~ ^[Yy]$ ]]; then
    log "${YELLOW}$TIP_COUNT. root密码已更改为: ${NEW_PASSWORD}${NC}"
    TIP_COUNT=$((TIP_COUNT + 1))
fi

# 如果用户选择了修改主机名，显示主机名信息
if [ "$CHANGE_HOSTNAME_FLAG" = true ]; then
    log "${YELLOW}$TIP_COUNT. 主机名已更改为: ${NEW_HOSTNAME}${NC}"
    TIP_COUNT=$((TIP_COUNT + 1))
fi

# 始终显示防火墙和日志文件信息
log "${YELLOW}$TIP_COUNT. 防火墙已启用，只开放了必要端口${NC}"
TIP_COUNT=$((TIP_COUNT + 1))
log "${YELLOW}$TIP_COUNT. 日志文件保存在: ${LOG_FILE}${NC}"

# 如果已启用BBR，显示BBR信息
if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q "bbr"; then
    TIP_COUNT=$((TIP_COUNT + 1))
    log "${YELLOW}$TIP_COUNT. BBR加速已成功启用${NC}"
fi

# 如果配置了交换空间，显示交换空间信息
if [ "$CURRENT_SWAP_TOTAL" -gt "0" ]; then
    TIP_COUNT=$((TIP_COUNT + 1))
    log "${YELLOW}$TIP_COUNT. 交换空间大小: $(free -m | grep "Swap:" | awk '{print $2}')MB${NC}"
fi

log "${GREEN}=======================================================${NC}"
log "${BLUE}建议您现在重启服务器以应用所有更改${NC}"
log "${GREEN}=======================================================${NC}"

# 提示用户是否立即重启
while true; do
    read -p "是否立即重启服务器？(y/n, 默认n): " REBOOT_NOW
    # 设置默认值为否
    REBOOT_NOW=${REBOOT_NOW:-n}
    if [[ "$REBOOT_NOW" =~ ^[Yy]$ ]] || [[ "$REBOOT_NOW" =~ ^[Nn]$ ]]; then
        break
    else
        echo -e "${RED}无效的输入，请输入 y 或 n${NC}"
    fi
done

if [[ "$REBOOT_NOW" =~ ^[Yy]$ ]]; then
    log "${GREEN}服务器将在5秒后重启...${NC}"
    sleep 5
    reboot
else
    log "${YELLOW}请稍后手动重启服务器以应用所有更改${NC}"
fi 