#!/bin/bash

# VPS Initialization
sudo -i # 切换到root用户
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建Rustdesk安装目录
mkdir -p /root/data/docker_data/Rustdesk
cd /root/data/docker_data/Rustdesk
nano docker-compose.yml

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

# 运行docker-compose
# 查看端口是否被占用
lsof -i:8060
lsof -i:8061
lsof -i:8062
lsof -i:8063
lsof -i:8064
lsof -i udp:8061

# 运行
docker-compose up -d 

# 重启docker服务
docker-compose restart

# 打开防火墙的端口
ufw allow 8060/tcp
ufw allow 8061/tcp
ufw allow 8062/tcp
ufw allow 8063/tcp
ufw allow 8064/tcp
ufw allow 8061/udp

# 查看已开启的端口
ufw status

# 打印访问链接
echo "访问 Rustdesk 链接:"
echo "中继服务器IP: 74.48.16.14:8061"

# 更新 Rustdesk
echo "更新 Rustdesk:"
cp -r /root/data/docker_data/Rustdesk /root/data/docker_data/Rustdesk.archive  # 万事先备份，以防万一
cd /root/data/docker_data/Rustdesk  # 进入docker-compose所在的文件夹
docker-compose pull    # 拉取最新的镜像
docker-compose up -d   # 重新更新当前镜像

# 卸载 Rustdesk
echo "卸载 Rustdesk:"
docker-compose down    # 停止容器，此时不会删除映射到本地的数据
rm -rf /root/data/docker_data/Rustdesk  # 完全删除映射到本地的数据
