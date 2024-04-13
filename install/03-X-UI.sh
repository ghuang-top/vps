#!/bin/bash
# chmod +x 03-X-UI.sh && ./03-X-UI.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/03-X-UI.sh && chmod +x 03-X-UI.sh && ./03-X-UI.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=54321
port443=8030


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建X-UI安装目录
mkdir -p /root/data/docker_data/X-UI
cd /root/data/docker_data/X-UI

# 3、配置X-UI的docker-compose
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

# 4、安装
docker-compose up -d 

# 5、打开防火墙的端口
ufw allow $port80
ufw allow $port443
ufw status

# 打印访问链接
echo "------------------------"
echo "访问链接:"
echo "http://$ipv4_address:$port80"
echo "Email: admin"
echo "Password: admin"
echo "注意面板URL根路径: /nSAsXv/"
echo "------------------------"

