#!/bin/bash
# chmod +x 01-Nginx.sh && ./01-Nginx.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/01-Nginx.sh && chmod +x 01-Nginx.sh && ./01-Nginx.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=80
port443=443


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建 Nginx 安装目录
mkdir -p /root/data/docker_data/Nginx
cd /root/data/docker_data/Nginx

# 3、配置X-UI的docker-compose
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  nginx:
    image: nginx
    container_name: nginx
    restart: always
    ports:
      - $port80:80
      - $port443:443
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - ./certs:/etc/nginx/certs
      - ./html:/var/www/html
      - ./log/nginx:/var/log/nginx
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
echo "http://$ipv4_address:$port443"
echo "------------------------"

