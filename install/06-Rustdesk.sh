#!/bin/bash
# 06-Rustdesk

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建Rustdesk安装目录
mkdir -p /root/data/docker_data/Rustdesk
cd /root/data/docker_data/Rustdesk
# nano docker-compose.yml

# 配置Rustdesk的docker-compose
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
      - 8061:21116
      - 8061:21116/udp
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

# ctrl+x退出，按y保存，enter确认

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8060/tcp
ufw allow 8061/tcp
ufw allow 8062/tcp
ufw allow 8063/tcp
ufw allow 8064/tcp
ufw allow 8061/udp
ufw status

# 打印访问链接
echo "访问 Rustdesk 链接:"
echo "中继服务器IP: 74.48.16.14:8061"
