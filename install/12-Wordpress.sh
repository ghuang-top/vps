#!/bin/bash

# VPS Initialization
apt update -y && apt upgrade -y  #更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建Wordpress安装目录
mkdir -p /root/data/docker_data/Wordpress
cd /root/data/docker_data/Wordpress
nano docker-compose.yml

# 配置Wordpress的docker-compose
cat <<EOF > docker-compose.yml
version: '3.0'
services:
  db:
    image: mysql:5.7 # arm架构的机器请将mysql:5.7改为mysql:oracle
    container_name: wordpress-db
    restart: unless-stopped
    # command: --max-binlog-size=200M --expire-logs-days=2 # 使用mysql 8.0的小伙伴建议使用
    environment:
      MYSQL_ROOT_PASSWORD: password # 按需修改
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: password # 按需修改
    volumes:
      - './db:/var/lib/mysql'
    networks:
      - default

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
      - db:db
    depends_on:
      - redis
      - db
    networks:
      - default

  redis:
    image: redis:alpine
    container_name: wordpress-redis
    restart: unless-stopped
    volumes:
      - ./redis-data:/data
    networks:
      - default

#networks:
 # default:
  #  name: wordpress
EOF

# ctrl+x退出，按y保存，enter确认

# 运行docker-compose
# 查看端口是否被占用
lsof -i:8120  # 80
lsof -i:8121  # 443

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8120
ufw allow 8121
ufw status

# 打印访问链接
echo "访问 Wordpress 链接:"
echo "IP: 192.168.1.1:8120"
echo "Email: eddy"
echo "Password: Asd123wjsw"
echo "Email: ghuang0425@gmail.com"
echo "Password: G&WrOa#TqniQHHVGO6"

# 安装主题
echo "安装主题:"
echo "1、获取主题: https://github.com/owen0o0/WebStack/releases"
echo "2、上传到 Wordpress 安装"

# 更新 Wordpress
echo "更新 Wordpress:"
cp -r /root/data/docker_data/Wordpress /root/data/docker_data/Wordpress.archive  # 万事先备份，以防万一
cd /root/data/docker_data/Wordpress  # 进入docker-compose所在的文件夹
docker-compose pull    # 拉取最新的镜像
docker-compose up -d   # 重新更新当前镜像
