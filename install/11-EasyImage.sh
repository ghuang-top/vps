#!/bin/bash
# chmod +x 11-EasyImage.sh && ./11-EasyImage.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/11-EasyImage.sh && chmod +x 11-EasyImage.sh && ./11-EasyImage.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8110
port443=8111


# 1、更新包
apt update -y && apt upgrade -y

# 2、创建EasyImage安装目录
mkdir -p /root/data/docker_data/EasyImage
cd /root/data/docker_data/EasyImage


# 3、配置EasyImage的docker-compose
cat <<EOF > docker-compose.yml
version: '3.3'
services:
  easyimage:
    image: ddsderek/easyimage:latest
    container_name: easyimage
    restart: unless-stopped
    ports:
      - $port80:80
    environment:
      - TZ=Asia/Shanghai
      - PUID=1000
      - PGID=1000
    volumes:
      - './config:/app/web/config'
      - './i:/app/web/i'
EOF


# 4、安装
docker-compose up -d 

# 5、打开防火墙的端口
ufw allow $port80
ufw allow $port433
ufw status

# 打印访问链接
echo "------------------------"
echo "访问链接:"
echo "http://$ipv4_address:$port80"
echo "账号: admin"
echo "密码: admin@123"
echo "------------------------"
