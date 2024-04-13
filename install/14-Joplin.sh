#!/bin/bash
# chmod +x 14-Joplin.sh && ./14-Joplin.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/14-Joplin.sh && chmod +x 14-Joplin.sh && ./14-Joplin.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8140
port443=8141


# 1、更新包
apt update -y && apt upgrade -y  #更新一下包

# 2、创建安装目录
mkdir -p /root/data/docker_data/Joplin
cd /root/data/docker_data/Joplin

# 3、填写docker-compose配置
cat <<EOF > docker-compose.yml
version: '3'
services:
    db:
        image: postgres:13
        container_name: joplin-db
        restart: unless-stopped
        ports:
            - "$port433:5432"  # 左边的端口可以更换，右边不要动！
        volumes:
            - ./data/postgres:/var/lib/postgresql/data
        environment:
            - POSTGRES_PASSWORD=changeme # 改成你自己的密码
            - POSTGRES_USER=username  # 改成你自己的用户名
            - POSTGRES_DB=joplin

    app:
        image: joplin/server:latest
        container_name: joplin-app
        restart: unless-stopped
        ports:
            - "$port80:22300" # 左边的端口可以更换，右边不要动！
        depends_on:
            - db
        environment:
            - APP_PORT=22300
            - APP_BASE_URL=https://joplin.ghuang.top # 改成反代的域名
            - DB_CLIENT=pg
            - POSTGRES_PASSWORD=changeme # 与上面的密码对应！
            - POSTGRES_USER=username  # 与上面的用户名对应！
            - POSTGRES_DATABASE=joplin
            - POSTGRES_PORT=5432 # 与上面右边的对应！
            - POSTGRES_HOST=db
EOF

# 4、安装
docker-compose up -d 

# 5、打开防火墙的端口
ufw allow $port80
ufw allow $port433
ufw status

# 打印访问链接
echo "------------------------"
echo "访问链接:"
echo "https://joplin.ghuang.top"
echo "User: admin@localhost"
echo "Password: admin"
echo "------------------------"
