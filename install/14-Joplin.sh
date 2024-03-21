#!/bin/bash

# 服务器初始设置
sudo -i # 切换到root用户
apt update -y && apt upgrade -y  #更新一下包
apt install wget curl sudo vim git lsof -y # Debian系统比较干净，安装常用的软件

# 创建安装目录
mkdir -p /root/data/docker_data/Joplin
cd /root/data/docker_data/Joplin
nano docker-compose.yml

# 填写docker-compose配置
cat <<EOF > docker-compose.yml
version: '3'

services:
    db:
        image: postgres:13
        container_name: joplin-db
        restart: unless-stopped
        ports:
            - "8141:5432"  # 左边的端口可以更换，右边不要动！
        volumes:
            - ./data/postgres:/var/lib/postgresql/data
        environment:
            - POSTGRES_USER=ghuang0425@gmail.com  # 改成你自己的用户名
            - POSTGRES_PASSWORD=gmail.com # 改成你自己的密码
            - POSTGRES_DB=joplin

    app:
        image: joplin/server:latest
        container_name: joplin-app
        restart: unless-stopped
        ports:
            - "8140:22300" # 左边的端口可以更换，右边不要动！
        depends_on:
            - db
        environment:
            - APP_PORT=22300
            - APP_BASE_URL=https://joplin1.ghuang.top # 改成反代的域名
            - DB_CLIENT=pg
            - POSTGRES_USER=ghuang0425@gmail.com  # 与上面的用户名对应！
            - POSTGRES_PASSWORD=gmail.com # 与上面的密码对应！
            - POSTGRES_DATABASE=joplin
            - POSTGRES_PORT=5432 # 与上面右边的对应！
            - POSTGRES_HOST=db
EOF

# ctrl+x退出，按y保存，enter确认

# 运行docker-compose
# 查看端口是否被占用
lsof -i:8140  # 80
lsof -i:8141  # 443

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8140
ufw allow 8141
ufw status

# 打印访问链接
echo "访问 Joplin 链接:"
echo "IP: 192.168.1.11:8140"
echo "Email: ghuang0425@gmail.com"
echo "Password: gmail.com"

# 更新 Joplin
echo "更新 Joplin:"
cp -r /root/data/docker_data/Joplin /root/data/docker_data/Joplin.archive  # 万事先备份，以防万一
cd /root/data/docker_data/Joplin  # 进入docker-compose所在的文件夹
docker-compose pull    # 拉取最新的镜像
docker-compose up -d   # 重新更新当前镜像
