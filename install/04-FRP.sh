#!/bin/bash
# 04-FRP

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install wget curl sudo vim git lsof ufw -y # Debian系统比较干净，安装常用的软件

# 创建Frps安装目录
mkdir -p /root/data/docker_data/Frps 
cd /root/data/docker_data/Frps
nano docker-compose.yml

# 配置Frps的docker-compose
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

# ctrl+x退出，按y保存，enter确认


# 创建frps.toml文件并设置配置
cd /root/data/docker_data/Frps
touch frps.toml
nano frps.toml

cat <<EOF > frps.toml
[common]

# frp 监听端口，与客户端绑定端口
bind_port= 8041
kcp_bind_port = 8041

# dashboard用户名
dashboard_user=ghuang0425@gmail.com

# dashboard密码
dashboard_pwd=gmail.com

# dashboard端口，启动成功后可通过浏览器访问如http://ip:9527
dashboard_port=8040

# 设置客户端token，对应客户端有页需要配置一定要记住，如果客户端不填写你连不上服务端
token=PAioH8syP!82T%
EOF


# 运行
docker-compose up -d 

# 重启docker服务
docker-compose restart

# 打开防火墙的端口
ufw allow 8040
ufw allow 8041
ufw status


# 开启客户端端口
ufw allow 22
ufw allow 222
ufw allow 7020
ufw allow 7021
ufw allow 7050
ufw allow 7051
ufw allow 7060
ufw allow 7061
ufw allow 7070
ufw allow 7071
ufw allow 7080
ufw allow 7081
ufw allow 7090
ufw allow 7091
ufw allow 7100
ufw allow 7101
ufw allow 7110
ufw allow 7111
ufw status

# 打印访问链接
echo "访问 Frps 链接:"
echo "IP: 192.168.1.1:8040"
echo "Email: ghuang0425@gmail.com"
echo "Password: gmail.com"