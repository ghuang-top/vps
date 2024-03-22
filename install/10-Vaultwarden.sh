#!/bin/bash
# 10-Vaultwarden

# VPS Initialization
apt update -y && apt upgrade -y  # 更新一下包
apt install -y wget curl sudo vim git # Debian系统比较干净，安装常用的软件

# 创建Vaultwarden安装目录
mkdir -p /root/data/docker_data/Vaultwarden
cd /root/data/docker_data/Vaultwarden
# nano docker-compose.yml

# 配置Vaultwarden的docker-compose
cat <<EOF > docker-compose.yml
version: '3'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    volumes:
      - ./data/:/data/
    ports:
      - 8100:80
    environment:
      - DOMAIN=https://vaultwarden.ghuang.top # 这是您希望与您的Vaultwarden实例关联的域名。 
      - LOGIN_RATELIMIT_MAX_BURST=10 # 允许在一阵登录/两步验证尝试中的最大请求次数。
      - LOGIN_RATELIMIT_SECONDS=60 # 这是来自同一IP的登录请求之间的平均秒数，在Vaultwarden限制登录次数之前。
      - ADMIN_RATELIMIT_MAX_BURST=10 # 这与LOGIN_RATELIMIT_MAX_BURST相同，只争对admin面板。
      - ADMIN_RATELIMIT_SECONDS=60 # 这与LOGIN_RATELIMIT_SECONDS相同
      - ADMIN_SESSION_LIFETIME=20 # 会话持续时间
      - ADMIN_TOKEN=FX6wU1n3i1huwVE9zo9zb6hGiX5fS5URTPhSWGK0pBu1weww0Kr0qcv6GbULX7az # 此值是Vaultwarden管理员面板的令牌（一种密码）。为了安全起见，这应该是一个长的随机字符串。如果未设置此值，则管理员面板将被禁用。建议openssl rand -base64 48 生成ADMIN_TOKEN确保安全
      - SENDS_ALLOWED=true  # 此设置决定是否允许用户创建Bitwarden发送 - 一种凭证共享形式。
      - EMERGENCY_ACCESS_ALLOWED=true # 此设置控制用户是否可以启用紧急访问其账户的权限。例如，这样做可以在用户去世后，配偶可以访问密码库以获取账户凭证。可能的值：true / false。
      - WEB_VAULT_ENABLED=true # 此设置决定了网络保险库是否可访问。一旦您配置了您的账户和客户端，停止您的容器，然后将此值切换为false并重启Vaultwarden，可以用来防止未授权访问。可能的值：true/false。
      - SIGNUPS_ALLOWED=true # 此设置控制新用户是否可以在没有邀请的情况下注册账户。可能的值：true / false。
EOF

# ctrl+x退出，按y保存，enter确认

# 运行
docker-compose up -d 

# 打开防火墙的端口
ufw allow 8100
ufw allow 8101
ufw status

# 打印访问链接
echo "访问 Vaultwarden 链接:"
echo "IP: your_ip_address:8100"
echo "admin@example.com"
