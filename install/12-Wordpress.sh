#!/bin/bash
# 12-Wordpress

# VPS Initialization
apt update -y && apt upgrade -y  #更新一下包

# 创建Wordpress安装目录
mkdir -p /root/data/docker_data/Wordpress
cd /root/data/docker_data/Wordpress
# nano docker-compose.yml

# 配置Wordpress的docker-compose
cat <<EOF > docker-compose.yml
version: '3.0'
services:
  app:
    image: wordpress:latest
    container_name: wordpress-app
    restart: unless-stopped
    ports:
      - 8120:80  # 按需修改。与防火墙开放端口一致。
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: password # 按需修改
      WORDPRESS_LANG: zh_CN  # 指定中文语言
    volumes:
      - './app:/var/www/html'
    links:
      - mysql:db
    depends_on:
      - redis
      - db
    networks:
      - default

EOF

# ctrl+x退出，按y保存，enter确认

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8120
ufw allow 8121
ufw status

# 打印访问链接
echo "访问 Wordpress 链接:"
echo "IP: your_ip_address:8120"
echo "Email: admin@gmail.com"
echo "Password: G&WrOa#TqniQHHVGO6"
