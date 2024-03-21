#!/bin/bash

# VPS Initialization
sudo -i # 切换到root用户
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建EasyImage安装目录
mkdir -p /root/data/docker_data/EasyImage
cd /root/data/docker_data/EasyImage
nano docker-compose.yml

# 配置EasyImage的docker-compose
cat <<EOF > docker-compose.yml
version: '3.3'
services:
  easyimage:
    image: ddsderek/easyimage:latest
    container_name: easyimage
    restart: unless-stopped
    ports:
      - '8110:80'
    environment:
      - TZ=Asia/Shanghai
      - PUID=1000
      - PGID=1000
    volumes:
      - './config:/app/web/config'
      - './i:/app/web/i'
EOF

# ctrl+x退出，按y保存，enter确认

# 运行docker-compose
# 查看端口是否被占用
lsof -i:8110  # 80
lsof -i:8111  # 443

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8110
ufw allow 8111
ufw status

# 打印访问链接
echo "访问 EasyImage 链接:"
echo "IP: 192.168.1.11:8110"
echo "Email: admin"
echo "Password: admin@123"

# 更新 EasyImage
echo "更新 EasyImage:"
cp -r /root/data/docker_data/EasyImage /root/data/docker_data/EasyImage.archive  # 万事先备份，以防万一
cd /root/data/docker_data/EasyImage  # 进入docker-compose所在的文件夹
docker-compose pull    # 拉取最新的镜像
docker-compose up -d   # 重新更新当前镜像
docker exec -it EasyImage rm -rf /app/web/install #因为更新后镜像自带install目录，所以要删除
