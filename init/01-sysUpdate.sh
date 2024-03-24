#!/bin/bash

if [ -f "/etc/debian_version" ]; then
    apt update -y && DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
fi

# 1、VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install -y wget curl sudo vim git ufw # Debian系统比较干净，安装常用的软件
sudo usermod -aG sudo root

