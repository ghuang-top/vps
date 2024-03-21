#!/bin/bash
# 00-Initialization

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git -y  # Debian系统比较干净，安装常用的软件

# 安装防火墙
# 1、安装防火墙软件ufw
apt install -y ufw

# 2、开启防火墙
ufw --force enable

# 3、开启SSH端口(22)
ufw allow 22
ufw allow 80
ufw allow 443
ufw status

# 解决debian sudo问题
apt install -y sudo
sudo usermod -aG sudo root

# 检查Docker和Docker-Compose是否已安装，如果未安装则安装它们
if ! command -v docker &> /dev/null
then
    # 安装docker
    curl -fsSL https://get.docker.com | sudo sh
fi

if ! command -v docker-compose &> /dev/null
then
    # 安装 Docker Compose
    apt install -y docker-compose
fi

# 查看Docker和Docker-Compose的版本
docker --version
docker-compose --version
