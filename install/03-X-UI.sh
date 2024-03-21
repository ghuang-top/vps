#!/bin/bash

# VPS Initialization
sudo -i # 切换到root用户
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建X-UI安装目录
mkdir -p /root/data/docker_data/X-UI
cd /root/data/docker_data/X-UI
nano docker-compose.yml

# 配置X-UI的docker-compose
cat <<EOF > docker-compose.yml
version: "3"
services:
    x-ui:
        image: enwaiax/x-ui:alpha-zh
        container_name: x-ui
        restart: unless-stopped
        volumes:
          - ./db/:/etc/x-ui/
          - ./cert/:/root/cert/
        network_mode: host
        stdin_open: true
        tty: true
EOF

# ctrl+x退出，按y保存，enter确认

# 运行docker-compose
# 查看端口是否被占用
lsof -i:8030  # 80
lsof -i:54321  # 80

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8030
ufw allow 54321
ufw status

# 打印访问链接
echo "访问链接:"
echo "IP: ip:54321"
echo "Email: admin"
echo "Password: admin"
echo "修改X-UI账号信息:"
echo "面板监听端口: 8030"
echo "面板URL根路径: /nSAsXv/"
echo "Email: ghuang0425@gmail.com"
echo "Password: gmail.com"
echo "IP: ip:8030/nSAsXv"
echo "http://74.48.16.14:8030/nSAsXv/xui/"
echo "反向代理链接:"
echo "根路径:/GbRY2nq/ https://xui.ghuang.top/nSAsXv/"
