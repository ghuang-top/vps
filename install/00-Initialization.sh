#!/bin/bash
# 00-Initialization

echo "1、判断权限"
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

echo "2、系统更新"
sys_update(){
    if [ -f "/etc/debian_version" ]; then
        apt update -y && DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    fi
}
sys_update

echo "3. 系统清理"
sys_cleanup() {
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
    apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=50M
    apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
}
sys_cleanup

echo "4、初始化vps"
vps_init(){
# 1、VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install -y wget curl sudo vim git ufw # Debian系统比较干净，安装常用的软件

# 2、开启防火墙
ufw --force enable

# 3、读取当前的 SSH 端口号
current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
echo "当前端口$current_port"

# 4、开启SSH端口(22)
ufw allow $current_port
ufw allow 80
ufw allow 443


# 5、解决debian sudo问题
apt install -y sudo
sudo usermod -aG sudo root

# 6、安装docker
curl -fsSL https://get.docker.com | sudo sh

# 7、安装 Docker Compose
apt install -y docker-compose
}
vps_init


echo "5、优化DNS地址为Cloudflare和Google"
optimize_DNS(){
# 删除旧的DNS地址
sed -i '/^nameserver/d' /etc/resolv.conf

# 添加新的DNS地址
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 172.31.255.2" >> /etc/resolv.conf
echo "nameserver 74.82.42.42" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
}
optimize_DNS

echo "6、修改时区为Asia/Shanghai"
run_timeZone(){
    timedatectl set-timezone Asia/Shanghai
}
run_timeZone

echo "7、添加虚拟内存大小为1024MB"
add_memory(){
# 如果当前有 swap 文件在使用，先关闭它
if swapon -s | grep -q '/swapfile'; then
    swapoff /swapfile
fi

# 删除旧的 /swapfile
rm -f /swapfile

# 创建新的 swap 分区
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 根据不同系统添加相应配置
if [ -f /etc/alpine-release ]; then
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
    chmod +x /etc/local.d/swap.start
    rc-update add local
else
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

echo "虚拟内存大小已设置为1024MB"
}
add_memory

echo "8、Fail2ban"
run_Fail2ban(){
# 1. 安装与启动 Fail2ban
apt update -y && apt install -y fail2ban
systemctl start fail2ban
systemctl enable fail2ban
#systemctl status fail2ban --no-pager && echo "Continue with the next script" && exit 0

# 2. 主配置文件操作
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#nano /etc/fail2ban/jail.local
#systemctl restart fail2ban

# 3. 处理状态异常及 SSH 防御
rm -rf /etc/fail2ban/jail.d/*
# nano /etc/fail2ban/jail.d/sshd.local
cat <<EOF > /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled = true
mode   = normal
backend = systemd
EOF

# 4. 重启服务
#systemctl restart fail2ban
#fail2ban-client status
#fail2ban-client status sshd

# 解禁指定IP
#fail2ban-client set sshd unbanip 192.0.0.1 

}
run_Fail2ban


echo "9、禁止Ping"
run_banPing(){
# nano /etc/ufw/before.rules
# 替换before.rules文件中的echo-request规则
sudo sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/g' /etc/ufw/before.rules
# 重新加载UFW防火墙规则
sudo ufw reload
}
run_banPing


echo "10、BBRv3加速"
run_bbr(){
if dpkg -l | grep -q 'linux-xanmod'; then
    while true; do
        #clear
        kernel_version=$(uname -r)
        echo "您已安装xanmod的BBRv3内核"
        echo "当前内核版本: $kernel_version"

        echo ""
        echo "内核管理"
        echo "------------------------"
        echo "1. 更新BBRv3内核              2. 卸载BBRv3内核"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p "请输入你的选择: " sub_choice

        case $sub_choice in
            1)
                apt purge -y 'linux-*xanmod1*'
                update-grub

                wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

                echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

                version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

                apt update -y
                apt install -y linux-xanmod-x64v$version

                echo "XanMod内核已更新。重启后生效"
                rm -f /etc/apt/sources.list.d/xanmod-release.list
                rm -f check_x86-64_psabi.sh*

                reboot
                ;;
            2)
                apt purge -y 'linux-*xanmod1*'
                update-grub
                echo "XanMod内核已卸载。重启后生效"
                reboot
                ;;
            0)
                break  # 跳出循环，退出菜单
                ;;
            *)
                break  # 跳出循环，退出菜单
                ;;
        esac
    done
else
    #clear
    echo "请备份数据，将为你升级Linux内核开启BBR3"
    echo "官网介绍: https://xanmod.org/"
    echo "------------------------------------------------"
    echo "仅支持Debian/Ubuntu 仅支持x86_64架构"
    echo "VPS是512M内存的，请提前添加1G虚拟内存，防止因内存不足失联！"
    echo "------------------------------------------------"

    # 直接安装，无需询问
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
            echo "当前环境不支持，仅支持Debian和Ubuntu系统"
            exit 1
        fi
    else
        echo "无法确定操作系统类型"
        exit 1
    fi

    arch=$(dpkg --print-architecture)
    if [ "$arch" != "amd64" ]; then
        echo "当前环境不支持，仅支持x86_64架构"
        exit 1
    fi

    apt-get update
    apt-get install -y wget gnupg

    wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

    apt-get update
    apt-get install -y linux-xanmod-x64v$version

    cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl -p
    echo "XanMod内核安装并BBR3启用成功。重启后生效"
    rm -f /etc/apt/sources.list.d/xanmod-release.list
    rm -f check_x86-64_psabi.sh*
    reboot
fi
}
run_bbr


echo "--------输出信息----------"
echo "------------------------"
echo "1、优化后的DNS地址为："
cat /etc/resolv.conf
echo "------------------------"

echo "2、当前时区为："
current_timezone=$(timedatectl show --property=Timezone --value)
echo "$current_timezone"
echo "------------------------"

echo "3、当前虚拟内存大小为："
swapfile_size=$(du -m /swapfile | awk '{print $1}')
echo "虚拟内存大小为：${swapfile_size}MB"
echo "------------------------"

echo "4、查看Docker和Docker-Compose的版本"
docker --version
docker-compose --version
echo "------------------------"

echo "5、开放的端口"
ufw status
echo "------------------------"

echo "6、Fail2ban"
echo "重启服务"
fail2ban-client status
fail2ban-client status sshd
systemctl status fail2ban --no-pager && echo "Continue with the next script" && exit 0
systemctl restart fail2ban
echo "------------------------"

echo "7、禁止Ping"
echo "------------------------"
