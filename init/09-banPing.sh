#!/bin/bash


# nano /etc/ufw/before.rules
# 替换before.rules文件中的echo-request规则
sudo sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/g' /etc/ufw/before.rules
# 重新加载UFW防火墙规则
sudo ufw reload
