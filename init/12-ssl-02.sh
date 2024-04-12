#!/bin/bash
# chmod +x 12-ssl-02.sh && ./12-ssl-02.sh
# apt update -y  && apt install -y curl
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/12-ssl-02.sh && chmod +x 12-ssl-02.sh && ./12-ssl-02.sh

# 1、更新包
apt update -y && apt upgrade -y  && apt install -y curl wget sudo socat unzip tar

# 2、创建X-UI安装目录
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
-d web1.ghuang.top \
-d web2.ghuang.top \
-d web3.ghuang.top \
-d web4.ghuang.top \
-d web5.ghuang.top \
-d web6.ghuang.top \
--standalone --key-file /root/data/docker_data/Nginx/certs/key.pem --cert-file /root/data/docker_data/Nginx/certs/cert.pem --force


### 5、nginx站点配置

mkdir -p /root/data/docker_data/Nginx/conf.d
cd /root/data/docker_data/Nginx/conf.d

curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.conf3/web1.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.conf3/web2.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.conf3/web3.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.conf3/web4.ghuang.top.conf
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/.conf3/web5.ghuang.top.conf



echo "------------------------"
echo "下载nginx站点配置文件到："
echo "/root/data/docker_data/Nginx/conf.d"
echo "------------------------"