#!/bin/bash
# chmod +x 12-ssl-01.sh && ./12-ssl-01.sh
# apt update -y  && apt install -y curl
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/12-ssl-01.sh && chmod +x 12-ssl-01.sh && ./12-ssl-01.sh

# 1、更新包
apt update -y && apt upgrade -y  && apt install -y curl wget sudo socat unzip tar

# 2、创建安装目录
mkdir -p /root/data/docker_data/Nginx/certs
cd /root/data/docker_data/Nginx/certs


# 3、有些VPS没开放端口，先开放端口，防止证书申请失败
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F


# 4、证书申请
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --register-account -m xxxx@gmail.com --issue \
-d nginxproxy1.ghuang.top \
-d vaultwarden1.ghuang.top \
-d easyimage1.ghuang.top \
-d wordpress1.ghuang.top \
-d nextcloud1.ghuang.top \
-d joplin1.ghuang.top \
-d xui1.ghuang.top \
--standalone --key-file /root/data/docker_data/Nginx/certs/key.pem --cert-file /root/data/docker_data/Nginx/certs/cert.pem --force


### 5、nginx站点配置

mkdir -p /root/data/docker_data/Nginx/conf.d
cd /root/data/docker_data/Nginx/conf.d

curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.cof_bwg/vaultwarden1.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.cof_bwg/easyimage1.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.cof_bwg/wordpress1.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.cof_bwg/nextcloud1.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.cof_bwg/joplin1.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.cof_bwg/xui1.ghuang.top.conf


echo "------------------------"
echo "下载nginx站点配置文件到："
echo "/root/data/docker_data/Nginx/conf.d"
echo "------------------------"



