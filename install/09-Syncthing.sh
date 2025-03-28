#!/bin/bash
# chmod +x 09-Syncthing.sh && ./09-Syncthing.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/09-Syncthing.sh && chmod +x 09-Syncthing.sh && ./09-Syncthing.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8090

# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建Zerotier安装目录
mkdir -p /root/data/docker_data/Syncthing 
cd /root/data/docker_data/Syncthing


# 3、配置Duplicati的docker-compose
cat <<EOF > docker-compose.yml
version: "3.5"
services:
  syncthing:
    image: lscr.io/linuxserver/syncthing
    container_name: syncthing
    hostname: syncthing #optional
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - ./config:/config
      - ./Documents:/Documents
      - ./Media:/Media
      - ./Nextcloud:/Nextcloud
    ports:
      - 8090:8384
      - 8091:22000/tcp
      - 8091:22000/udp
      - 8092:21027/udp
    restart: unless-stopped
EOF


# 4、安装
docker-compose up -d 

# 5、打开防火墙的端口
ufw allow 8090
ufw allow 8091
ufw allow 8092
ufw status


# 6、打印访问链接
echo "------------------------"
echo "访问链接:"
echo "http://$ipv4_address:$port80"
echo "------------------------"