#!/bin/bash
# chmod +x 03-docker.sh && ./03-docker.sh

echo "初始化vps"

# 安装docker
curl -fsSL https://get.docker.com | sudo sh

# 安装 Docker Compose
apt install -y docker-compose

echo "------------------------"
echo "Docker的版本"
docker --version
docker-compose --version
echo "------------------------"