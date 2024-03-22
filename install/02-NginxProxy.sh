#!/bin/bash
# 02-NginxProxy

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建Nginx Proxy安装目录
mkdir -p /root/data/docker_data/NginxProxy
cd /root/data/docker_data/NginxProxy
nano docker-compose.yml

# 配置Nginx Proxy的docker-compose
cat <<EOF > docker-compose.yml
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginxproxy
    restart: unless-stopped
    ports:
      - '80:80'  # 保持默认即可，不建议修改左侧的80
      - '443:443' # 保持默认即可，不建议修改左侧的443
      - '8020:81'  # 冒号左边可以改成自己服务器未被占用的端口
    volumes:
      - ./data:/data # 冒号左边可以改路径，现在是表示把数据存放在在当前文件夹下的 data 文件夹中
      - ./letsencrypt:/etc/letsencrypt  # 冒号左边可以改路径，现在是表示把数据存放在在当前文件夹下的 letsencrypt 文件夹中
EOF

# ctrl+x退出，按y保存，enter确认

# 运行docker-compose
# 查看端口是否被占用
lsof -i:80  # 80
lsof -i:443  # 443
lsof -i:8020  # 81

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 80
ufw allow 443
ufw allow 8020
ufw status

# 打印访问链接
echo "访问链接:"
echo "http://your_ip_address:8020"
echo "Email: admin@example.com"
echo "Password: changeme"