#!/bin/bash

echo "1、优化DNS地址为Cloudflare和Google"
#========================
cloudflare_ipv4="1.1.1.1"
google_ipv4="8.8.8.8"
echo "nameserver $cloudflare_ipv4" > /etc/resolv.conf
echo "nameserver $google_ipv4" >> /etc/resolv.conf

echo "2、修改时区为Asia/Shanghai"
#========================
timedatectl set-timezone Asia/Shanghai

echo "3、添加虚拟内存大小为1024MB"
#========================
# 删除旧的 /swapfile
rm -f /swapfil
# 创建新的 swap 分区
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo "------------------------"
echo "1、优化后的DNS地址为："
cat /etc/resolv.conf
echo "------------------------"

echo "------------------------"
echo "2、当前时区为："
current_timezone=$(timedatectl show --property=Timezone --value)
echo "$current_timezone"
echo "------------------------"

echo "------------------------"
echo "3、当前虚拟内存大小为："
# 获取虚拟内存文件的大小
swapfile_size=$(du -m /swapfile | awk '{print $1}')
# 显示虚拟内存大小
echo "虚拟内存大小为：${swapfile_size}MB"
echo "------------------------"

