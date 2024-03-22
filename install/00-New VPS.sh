#!/bin/bash

# 1、优化DNS地址为Cloudflare和Google
cloudflare_ipv4="1.1.1.1"
google_ipv4="8.8.8.8"

# 设置DNS地址为Cloudflare和Google（IPv4）
echo "设置DNS为Cloudflare和Google"
echo "nameserver $cloudflare_ipv4" > /etc/resolv.conf
echo "nameserver $google_ipv4" >> /etc/resolv.conf

# 2、修改时区为Asia/Shanghai
timedatectl set-timezone Asia/Shanghai

# 3、添加虚拟内存大小为1024MB
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

# 删除旧的 /swapfile
rm -f /swapfile

# 创建新的 swap 分区
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile


# 4、开启BBR3加速（如果已安装linux-xanmod内核）
if dpkg -l | grep -q 'linux-xanmod'; then
    apt purge -y 'linux-*xanmod1*'
    update-grub

    wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

    apt update -y
    apt install -y linux-xanmod-x64v$version

else
    apt update -y
    apt install -y wget gnupg

    wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

fi

echo "1、优化DNS地址为Cloudflare和Google"
echo "DNS地址已更新"
echo "------------------------"
cat /etc/resolv.conf
echo "------------------------"

echo "2、修改时区为Asia/Shanghai"
echo "3、添加虚拟内存大小为1024MB"
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
echo "虚拟内存大小已调整为1024MB"

echo "BBR3加速已成功启用。重启后生效"
#reboot