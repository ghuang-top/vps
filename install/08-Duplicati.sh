#!/bin/bash
# chmod +x 08-Duplicati.sh && ./08-Duplicati.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/08-Duplicati.sh && chmod +x 08-Duplicati.sh && ./08-Duplicati.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8080
port443=8081


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建Zerotier安装目录
mkdir -p /root/data/docker_data/Duplicati 
cd /root/data/docker_data/Duplicati


# 3、配置Duplicati的docker-compose
cat <<EOF > docker-compose.yml
version: "2.1"
services:
  duplicati:
    image: lscr.io/linuxserver/duplicati
    container_name: duplicati
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - /root/data/docker_data/Duplicati/config:/config
      - /root/data/docker_data/Duplicati/backups:/backups
      - /root/data:/source
    ports:
      - $port80:8200
    restart: unless-stopped
EOF


# 4、安装
docker-compose up -d 

# 5、打开防火墙的端口
ufw allow $port80
ufw allow $port443
ufw status


# 6、打印访问链接
echo "------------------------"
echo "访问链接:"
echo "http://$ipv4_address:$port80"
echo "------------------------"