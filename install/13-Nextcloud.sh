#!/bin/bash
# 13-Nextcloud

# 服务器初始设置
apt update -y && apt upgrade -y  #更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建安装目录
mkdir -p /root/data/docker_data/Nextcloud
cd /root/data/docker_data/Nextcloud
# nano docker-compose.yml

# 填写docker-compose配置
cat <<EOF > docker-compose.yml
version: "3"
services:
  nextcloud:
    container_name: nextcloud-app
    image: nextcloud:latest
    restart: unless-stopped
    ports:
      - 8130:80
      - 8131:443
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - MYSQL_HOST=mysql
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud
    volumes:
      - ./data:/var/www/html

  mysql:
    image: mysql:8.0
    container_name: nextcloud-db
    restart: unless-stopped
    environment:
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud
      - MYSQL_ROOT_PASSWORD=nextcloud
    volumes:
      - ./db:/var/lib/mysql
EOF

# ctrl+x退出，按y保存，enter确认

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8130
ufw allow 8131
ufw status

# 打印访问链接
echo "访问 Nextcloud 链接:"
echo "IP: your_ip_address:8130"
echo "Email: admin@gmail.com"
echo "Password: gmail.com"