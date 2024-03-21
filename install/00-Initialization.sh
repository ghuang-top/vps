#!/bin/bash

# VPS Initialization
# sudo -i # 切换到root用户
apt update -y && apt upgrade -y  #更新一下包
apt install wget curl sudo vim git -y  # Debian系统比较干净，安装常用的软件

# 安装防火墙
# 1、安装防火墙软件ufw
apt install -y ufw

# 2、开启防火墙
ufw enable

# 3、开启SSH端口(22)
ufw allow 22
ufw allow 80
ufw allow 443
ufw status

# 解决debian sudo问题
apt install sudo
sudo usermod -aG sudo root

# 安装Docker
# 1、安装docker
curl -fsSL https://get.docker.com | sudo sh

# 2、安装 Docker Compose
apt install docker-compose -y

# 3、查看Docker和Docker-Compose的版本
docker --version
docker-compose --version
