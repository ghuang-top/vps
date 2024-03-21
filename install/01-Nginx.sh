#!/bin/bash
# 01-Nginx

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof ufw -y # Debian系统比较干净，安装常用的软件

# 安装Nginx容器
# 1、创建nginx容器
docker run -d --name nginx -p 8010:80 nginx

# 2、切换文件夹
mkdir -p /root/data/docker_data/Nginx
cd /root/data/docker_data/Nginx

# 3、创建挂载目录
mkdir -p ./conf
mkdir -p ./log
mkdir -p ./www
mkdir -p ./html

# 4、复制Nginx容器中的文件
docker cp nginx:/etc/nginx/nginx.conf ./conf
docker cp nginx:/etc/nginx/conf.d ./conf
docker cp nginx:/var/log/nginx ./log
docker cp nginx:/usr/share/nginx/html ./

# 5、停止nginx容器
docker stop nginx

# 6、删除nginx容器
docker rm nginx

# 7、重新创建容器

# 配置Nginx的docker-compose
# 打开docker-compose
cd /root/data/docker_data/Nginx
nano docker-compose.yml

# 输入docker-compose

cat <<EOF > docker-compose.yml
            version: '3'
            services:
                nginx:
                    image: nginx
                    container_name: nginx
                    restart: always
                    ports:
                      - 8010:80
                      - 8011:443
                    volumes:
                      - ./conf/nginx.conf:/etc/nginx/nginx.conf
                      - ./conf/conf.d:/etc/nginx/conf.d
                      - ./log:/var/log/nginx
                      - ./www:/var/www
                      - ./html:/usr/share/nginx/html
                    environment:
                      - NGINX_PORT=80
                      - TZ=Asia/Shanghai
EOF

# ctrl+x退出，按y保存，enter确认

# 运行docker-compose
# 查看端口是否被占用
lsof -i:8010  # 80
lsof -i:8011  # 443

# 运行
docker-compose up -d

# 访问Nginx
# 打开防火墙的端口
ufw allow 8010
ufw allow 8011
ufw status

# 打印访问链接
echo "访问链接:"
echo "http://your_ip_address:8010"
echo "http://your_ip_address:8010/blog/site/"

