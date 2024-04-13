#!/bin/bash
# chmod +x 05-Zerotier.sh && ./05-Zerotier.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/05-Zerotier.sh && chmod +x 05-Zerotier.sh && ./05-Zerotier.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8050
port443=8051


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建Zerotier安装目录
mkdir -p /root/data/docker_data/Zerotier 
cd /root/data/docker_data/Zerotier


# 3、配置Zerotier的docker-compose
cat <<EOF > docker-compose.yml
version: '3.3'
services:
    ztncui:
        image: keynetworks/ztncui
        container_name: ztncui
        restart: always
        ports:
            - $port80:4000
        environment:
            - HTTP_PORT=4000
            - HTTP_ALL_INTERFACES=yes
            - ZTNCUI_PASSWD=mrdoc.fun

    zerotier-moon:
        image: jonnyan404/zerotier-moon
        container_name: zerotier-moon
        restart: always
        ports:
            - $port443:9993
            - $port443:9993/udp
        command: -4 192.168.1.1  # 改成服务器的IP
        volumes:
            - ./etc/ztconf/:/var/lib/zerotier-one
EOF


# 6、安装
docker-compose up -d 

# 7、打开防火墙的端口
ufw allow $port80
ufw allow $port443
ufw status


# 打印访问链接
echo "------------------------"
echo "访问链接:"
echo "http://$ipv4_address:$port80"
echo "user: admin"
echo "Password: mrdoc.fun"
echo "------------------------"
echo "查看moon ID:"
echo "docker logs zerotier-moon"
echo "------------------------"
echo "Windows 客户端加入moon服务器:"
echo "cd C:\ProgramData\ZeroTier\One:"
echo "zerotier-cli orbit [moon_id] [moon_id]:"
echo "------------------------"