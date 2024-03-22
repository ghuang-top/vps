#!/bin/bash

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

echo "4、优化DNS地址为Cloudflare和Google"
optimize_DNS(){
    cloudflare_ipv4="1.1.1.1"
    google_ipv4="8.8.8.8"
    echo "nameserver $cloudflare_ipv4" > /etc/resolv.conf
    echo "nameserver $google_ipv4" >> /etc/resolv.conf
}
optimize_DNS

echo "5、修改时区为Asia/Shanghai"
run_timeZone(){
    timedatectl set-timezone Asia/Shanghai
}
run_timeZone

echo "6、添加虚拟内存大小为1024MB"
add_memory(){
    # 删除旧的 /swapfile
    rm -f /swapfil
    # 创建新的 swap 分区
    dd if=/dev/zero of=/swapfile bs=1M count=1024
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
}
add_memory


# 用户设置
new_passwd="2345uh1yPo"
new_ssh_port="4399"

echo "7、修改密码"
modifyPassword() {
    echo "root:$new_passwd" | chpasswd
}
modifyPassword


echo "8、修改端口"
modifyPort() {
    # 备份 SSH 配置文件
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # 修改SSH配置文件
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/#Port/Port/' /etc/ssh/sshd_config
    sed -i "s/Port [0-9]\+/Port $new_ssh_port/g" /etc/ssh/sshd_config

    # 重启 SSH 服务
    service sshd restart
}
modifyPort

echo "9、开启防火墙并允许新的SSH端口"
openUfwPort() {
    echo "开启防火墙并允许新的SSH端口: $new_ssh_port"
    apt update -y && apt install -y ufw
    ufw --force enable
    ufw allow $new_ssh_port
    ufw status
}
openUfwPort


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

echo "4、修改后的信息："
echo "用户: $USER"
echo "密码: $new_passwd"
echo "端口: $new_ssh_port"
echo "------------------------"

curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/00-NewVPS_bbr.sh && chmod +x 00-NewVPS_bbr.sh && ./00-NewVPS_bbr.sh



