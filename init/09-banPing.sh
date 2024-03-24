#!/bin/bash
#chmod +x 09-banPing.sh && ./09-banPing.sh


# nano /etc/ufw/before.rules
# 替换before.rules文件中的echo-request规则
sudo sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/g' /etc/ufw/before.rules
# 重新加载UFW防火墙规则
sudo ufw reload


echo "------------------------"
echo "禁止Ping,用以下命令查看是否更改"
echo "nano /etc/ufw/before.rules"
echo "------------------------"