#!/bin/bash
# chmod +x 03-docker.sh && ./03-docker.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/03-docker.sh && chmod +x 03-docker.sh && ./03-docker.sh

echo "初始化vps"

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null; then
    # 如果 Docker 未安装，则安装它
    echo "安装 Docker..."
    curl -fsSL https://get.docker.com | sudo sh
else
    echo "Docker 已经安装."
fi

# 安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    # 如果 Docker Compose 未安装，则安装它
    echo "安装 Docker Compose..."
    #apt install -y docker-compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose 已经安装."
fi

echo "------------------------"
echo "Docker的版本"
docker --version
docker-compose --version
echo "------------------------"
