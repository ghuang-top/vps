#!/bin/bash
# chmod +x 06-Rustdesk.sh && ./06-Rustdesk.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/06-Rustdesk.sh && chmod +x 06-Rustdesk.sh && ./06-Rustdesk.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8061


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建 `Rustdesk` 安装目录
mkdir -p /root/data/docker_data/Rustdesk
cd /root/data/docker_data/Rustdesk


# 3、配置Duplicati的docker-compose
cat <<EOF > docker-compose.yml
version: '3'

networks:
  rustdesk-net:
    external: false

services:
  hbbs:
    container_name: hbbs
    ports:
      - 8060:21115
      - $port80:21116
      - $port80:21116/udp
      - 8063:21118
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r rustdesk2.ghuang.top:8062   # hbbs.example.com改成
    volumes:
      - ./hbbs:/root
    networks:
      - rustdesk-net
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    ports:
      - 8062:21117
      - 8064:21119
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    volumes:
      - ./hbbr:/root
    networks:
      - rustdesk-net
    restart: unless-stopped
EOF


# 6、安装
docker-compose up -d 

# 7、打开防火墙的端口
ufw allow 8060
ufw allow 8061
ufw allow 8062
ufw allow 8063
ufw allow 8064
ufw allow 8061/udp
ufw status


# 打印访问链接
echo "------------------------"
echo "访问链接:"
echo "http://$ipv4_address:$port80"
echo "------------------------"