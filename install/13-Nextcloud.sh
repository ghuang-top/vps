#!/bin/bash
# chmod +x 13-Nextcloud.sh && ./13-Nextcloud.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/13-Nextcloud.sh && chmod +x 13-Nextcloud.sh && ./13-Nextcloud.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8130
port443=8131


# 1、更新包
apt update -y && apt upgrade -y  #更新一下包

# 创建安装目录
mkdir -p /root/data/docker_data/Nextcloud
cd /root/data/docker_data/Nextcloud

# 3、填写docker-compose配置
cat <<EOF > docker-compose.yml
version: "3"

services:
  nextcloud:
    container_name: nextcloud-app
    image: nextcloud:latest
    restart: unless-stopped
    ports:
      - $port80:80
    environment:
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

#volumes:
#  mysql:
#  nextcloud:

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
echo "Email: admin@gmail.com"
echo "Password: gmail.com"
echo "------------------------"