#!/bin/bash

# 服务器初始设置
apt update -y && apt upgrade -y  #更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建安装目录
mkdir -p /root/data/docker_data/Nextcloud
cd /root/data/docker_data/Nextcloud
nano docker-compose.yml

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

# 运行docker-compose
# 查看端口是否被占用
lsof -i:8130  # 80
lsof -i:8131  # 443

# 运行
docker-compose up -d 

# 重启docker服务
docker-compose restart

# 打开防火墙的端口
ufw allow 8130
ufw allow 8131
ufw status

# 打印访问链接
echo "访问 Nextcloud 链接:"
echo "IP: 192.168.1.1:8130"
echo "Email: ghuang0425@gmail.com"
echo "Password: gmail.com"

# 更新 Nextcloud
echo "更新 Nextcloud:"
cp -r /root/data/docker_data/Nextcloud /root/data/docker_data/Nextcloud.archive  # 万事先备份，以防万一
cd /root/data/docker_data/Nextcloud  # 进入docker-compose所在的文件夹
docker-compose pull    # 拉取最新的镜像
docker-compose up -d   # 重新更新当前镜像
