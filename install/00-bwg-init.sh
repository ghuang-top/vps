#!/bin/bash
# chmod +x 00-default install.sh && ./00-default install.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/00-default-Install.sh && chmod +x 00-default-Install.sh && ./00-default-Install.sh

# 初始化 1
apt update -y  && apt install -y curl
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/01-sysUpdate.sh && chmod +x 01-sysUpdate.sh && ./01-sysUpdate.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/02-sysCleanup.sh && chmod +x 02-sysCleanup.sh && ./02-sysCleanup.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/03-docker.sh && chmod +x 03-docker.sh && ./03-docker.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/04-ufw.sh && chmod +x 04-ufw.sh && ./04-ufw.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/05-optimizeDNS.sh && chmod +x 05-optimizeDNS.sh && ./05-optimizeDNS.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/06-timeZone.sh && chmod +x 06-timeZone.sh && ./06-timeZone.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/07-addMemory.sh && chmod +x 07-addMemory.sh && ./07-addMemory.sh
curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh


# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/00-logins.sh && chmod +x 00-logins.sh && ./00-logins.sh


# 软件安装
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/02-NginxProxy.sh && chmod +x 02-NginxProxy.sh && ./02-NginxProxy.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/03-X-UI.sh && chmod +x 03-X-UI.sh && ./03-X-UI.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/12-Wordpress.sh && chmod +x 12-Wordpress.sh && ./12-Wordpress.sh


# xui:/BeLSuJZE/  8030
# http://64.64.236.71:8030/BeLSuJZE/xui/setting
ufw allow 8100
ufw allow 8101

ufw allow 8110
ufw allow 8111

ufw allow 8120
ufw allow 8121

ufw allow 8130
ufw allow 8131

ufw allow 8140
ufw allow 8141
ufw status


-d nginxproxy1.ghuang.top \
-d vaultwarden1.ghuang.top \ 8100
-d easyimage1.ghuang.top \ 8110
-d wordpress1.ghuang.top \ 8120
-d nextcloud1.ghuang.top \ 8130
-d joplin1.ghuang.top \ 8140
-d xui1.ghuang.top \ 8030

# https://web2.sprinkle.life/1qpz/xui/

docker restart nginx
docker restart nginxproxy
docker exec -it nginxproxy nginx -s reload

# bbr
wget -O tcpx.sh "https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh" && chmod +x tcpx.sh && ./tcpx.sh



# 0、释放80端口
docker restart nginxproxy

# 1、更新系统
apt update -y  && apt upgrade -y && apt install -y curl wget sudo socat unzip tar htop


# 2、创建站点数据存放目录
mkdir /home/web
cd /home/web
mkdir certs

# 3、有些VPS没开放端口，先开放端口，防止证书申请失败
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

# 4、证书申请
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --register-account -m xxxx@gmail.com --issue \
-d wpastra.sprinkle.life \
--standalone --key-file /home/web/certs/key.pem --cert-file /home/web/certs/cert.pem --force

# 5、开放端口
ufw allow 16244
ufw status


ufw allow 51401
ufw allow 51412
ufw status

cd /root/data/docker_data/NginxProxy
docker-compose up -d




Reality寻找适合的目标网站
查询ASN：https://tools.ipip.net/as.php

寻找目标：https://fofa.info

asn=="20473" && country=="US" && port=="443" && cert!="Let's Encrypt" && cert.issuer!="ZeroSSL" && status_code="200"


##3
https://v2rayssr.com/reality.html
https://www.ssllabs.com/ssltest/index.html




## 目标网站
https://www.shopify.com/










    location ^~ /1qpz {              #fuckgfw换成你前面设置的面板的url根路径
      proxy_pass http://45.77.125.181:54321/1qpz;  # IP填服务器IP，这边不能填127.0.0.1，因为是在容器里，54331换成你xui面板的端口
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

    location /lifeok {                 # plogger填你前面设置的ws的路径
          proxy_redirect off;
          proxy_pass http://45.77.125.181:51540;    # IP填服务器IP，这边不能填127.0.0.1，因为是在容器里，13997换成你入站规则那边的IP
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $http_host;
          proxy_read_timeout 300s;
          # Show realip in v2ray access.log
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }