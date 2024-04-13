#!/bin/bash
# chmod +x 04-FRP.sh && ./04-FRP.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/04-FRP.sh && chmod +x 04-FRP.sh && ./04-FRP.sh

ipv4_address=$(curl -s ipv4.ip.sb)
port80=8040
port443=8041


# 1、更新包
apt update -y && apt upgrade -y  # 更新一下包


# 2、创建Frps安装目录
mkdir -p /root/data/docker_data/Frps 
cd /root/data/docker_data/Frps


# 3、配置Frps的docker-compose
cat <<EOF > docker-compose.yml
version: '3.3'
services:
    frps:
        image: snowdreamtech/frps
        container_name: frps
        restart: always
        network_mode: host
        volumes:
            - './frps.toml:/etc/frp/frps.toml'
EOF


# 4、创建frps.toml文件并设置配置
cd /root/data/docker_data/Frps
touch frps.toml


# 5、配置 frps.toml
cat <<EOF > frps.toml
[common]

# frp 监听端口，与客户端绑定端口
bind_port=$port443
kcp_bind_port=$port443

# dashboard用户名
dashboard_user=admin@gmail.com

# dashboard密码
dashboard_pwd=gmail.com

# dashboard端口，启动成功后可通过浏览器访问如http://ip:9527
dashboard_port=$port80

# 设置客户端token，对应客户端有页需要配置一定要记住，如果客户端不填写你连不上服务端
token=PAioH8syP!82T%
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
echo "Email: admin@gmail.com"
echo "Password: gmail.com"
echo "------------------------"