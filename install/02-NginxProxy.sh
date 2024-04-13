#!/bin/bash
# chmod +x 02-NginxProxy.sh && ./02-NginxProxy.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/02-NginxProxy.sh && chmod +x 02-NginxProxy.sh && ./02-NginxProxy.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port=8020


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建 Nginx Proxy 安装目录
mkdir -p /root/data/docker_data/NginxProxy
cd /root/data/docker_data/NginxProxy


# 3、配置Nginx Proxy的docker-compose
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginxproxy
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '$port:81'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF

# 4、安装
docker-compose up -d 

# 5、打开防火墙的端口
ufw allow 80
ufw allow 443
ufw allow $port
ufw status

# 打印访问链接
echo "------------------------"
echo "访问链接:"
echo "http://$ipv4_address:$port"
echo "Email: admin@example.com"
echo "Password: changeme"
echo "------------------------"
