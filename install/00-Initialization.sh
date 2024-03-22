#!/bin/bash
# 00-Initialization

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git ufw -y  # Debian系统比较干净，安装常用的软件

# 1、开启防火墙
ufw --force enable

# 2、开启SSH端口(22)
ufw allow 22
ufw allow 80
ufw allow 443
ufw status

# 3、解决debian sudo问题
apt install -y sudo
sudo usermod -aG sudo root

# 安装docker
curl -fsSL https://get.docker.com | sudo sh

# 安装 Docker Compose
apt install -y docker-compose

# 查看Docker和Docker-Compose的版本
docker --version
docker-compose --version
