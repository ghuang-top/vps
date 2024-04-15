#!/bin/bash
# chmod +x 08-InstallAlist.sh && ./08-InstallAlist.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/08-InstallAlist.sh && chmod +x 08-InstallAlist.sh && ./08-InstallAlist.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8080
port443=8081


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建Zerotier安装目录
mkdir -p /root/data/docker_data/AList
cd /root/data/docker_data/AList


# 3、配置Duplicati的docker-compose
cat <<EOF > docker-compose.yml
version: '3.3'
services:
    alist:
        restart: always
        volumes:
            - ./data:/opt/alist/data
        ports:
            - $port80:5244
        environment:
            - PUID=0
            - PGID=0
            - UMASK=022
        container_name: alist
        image: xhofe/alist:latest
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