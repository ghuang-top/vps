#!/bin/bash
# chmod +x 04-ufw.sh && ./04-ufw.sh

# 1、安装 ufw
apt update -y && apt install -y ufw
 
# 2、开启防火墙
ufw --force enable

# 3、读取当前的 SSH 端口号
current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
echo "当前端口$current_port"

# 4、开启SSH端口(22)
ufw allow $current_port
ufw allow 80
ufw allow 443

echo "------------------------"
echo "开放的端口"
ufw status
echo "------------------------"