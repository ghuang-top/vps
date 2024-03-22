#!/bin/bash
# 11-EasyImage

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建EasyImage安装目录
mkdir -p /root/data/docker_data/EasyImage
cd /root/data/docker_data/EasyImage
# nano docker-compose.yml

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

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8110
ufw allow 8111
ufw status

# 打印访问链接
echo "访问 EasyImage 链接:"
echo "IP: your_ip_address:8110"
echo "Email: admin"
echo "Password: admin@123"
