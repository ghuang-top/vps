#!/bin/bash
# chmod +x 08-fail2ban.sh && ./08-fail2ban.sh


# 1. 安装与启动 Fail2ban
apt update -y && apt install -y fail2ban
systemctl start fail2ban
systemctl enable fail2ban
#systemctl status fail2ban --no-pager && echo "Continue with the next script" && exit 0

# 2. 主配置文件操作
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#nano /etc/fail2ban/jail.local
#systemctl restart fail2ban

# 3. 处理状态异常及 SSH 防御
rm -rf /etc/fail2ban/jail.d/*
# nano /etc/fail2ban/jail.d/sshd.local
cat <<EOF > /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled = true
mode   = normal
backend = systemd
EOF

# 4. 重启服务
systemctl restart fail2ban
#fail2ban-client status
#fail2ban-client status sshd

# 解禁指定IP
#fail2ban-client set sshd unbanip 192.0.0.1 


echo "------------------------"
echo "Fail2ban"
fail2ban-client status
fail2ban-client status sshd
systemctl status fail2ban --no-pager && echo "Continue with the next script" && exit 0
echo "------------------------"


