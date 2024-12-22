#!/bin/bash
# chmod +x 00-ssh-disable-password.sh && ./00-ssh-disable-password.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/00-ssh-disable-password.sh && chmod +x 00-ssh-disable-password.sh && ./00-ssh-disable-password.sh


# 用户设置
new_ssh_port="4399" # 根据需求修改端口

echo "1、关闭 SSH 密码登录并启用密钥认证"
disablePasswordLogin() {
    # 备份 SSH 配置文件
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # 修改 SSH 配置文件
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config

    # 确保 PubkeyAuthentication 开启
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

    # 修改端口
    sed -i 's/^#\?Port [0-9]\+/Port '$new_ssh_port'/g' /etc/ssh/sshd_config

    # 重启 SSH 服务
    service sshd restart
}
disablePasswordLogin

echo "2、开启防火墙并允许新的 SSH 端口"
openUfwPort() {
    echo "开启防火墙并允许新的SSH端口: $new_ssh_port"
    apt update -y && apt install -y ufw
    ufw --force enable
    ufw allow $new_ssh_port
    ufw status
}
openUfwPort

echo "------------------------"
echo "修改后的信息："
echo "端口: $new_ssh_port"
echo "SSH 密码登录: 已关闭"
echo "请确保您的公钥已正确上传到服务器的 ~/.ssh/authorized_keys 文件中。"
echo "------------------------"
