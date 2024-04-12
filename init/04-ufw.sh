#!/bin/bash
# chmod +x 04-ufw.sh && ./04-ufw.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/04-ufw.sh && chmod +x 04-ufw.sh && ./04-ufw.sh

echo "初始化vps"

# 1、安装 ufw
apt update -y && apt install -y ufw
 
# 2、开启防火墙
if ! ufw status | grep -q "Status: active"; then
    echo "开启防火墙"
    ufw --force enable
else
    echo "防火墙已经启用，无需重复开启"
fi

# 3、读取当前的 SSH 端口号
current_port=$(sshd -T | grep -Po 'port \K\d+')
echo "当前端口$current_port"

# 4、开启SSH端口(22)
ufw allow $current_port
ufw allow 80
ufw allow 443

echo "------------------------"
echo "开放的端口"
ufw status
echo "------------------------"


