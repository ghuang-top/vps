#!/bin/bash
# chmod +x 05-optimizeDNS.sh && ./05-optimizeDNS.sh

echo "优化DNS地址为Cloudflare和Google"

# 删除旧的DNS地址
sed -i '/^nameserver/d' /etc/resolv.conf

# 添加新的DNS地址
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 172.31.255.2" >> /etc/resolv.conf
echo "nameserver 74.82.42.42" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf


echo "------------------------"
echo "优化后的DNS地址为："
cat /etc/resolv.conf
echo "------------------------"

# 10.10.10.10