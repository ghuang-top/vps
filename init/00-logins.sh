#!/bin/bash
# chmod +x 00-logins.sh && ./00-logins.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/00-logins.sh && chmod +x 00-logins.sh && ./00-logins.sh

# 用户设置
new_passwd="d!Fssw97SoALHa"
new_ssh_port="4399"

echo "1、修改密码"
modifyPassword() {
    echo "root:$new_passwd" | chpasswd
}
modifyPassword


echo "2、修改端口"
modifyPort() {

    # 去掉 #Port 的注释
    sed -i 's/#Port/Port/' /etc/ssh/sshd_config


    # 备份 SSH 配置文件
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # 修改SSH配置文件
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/#Port/Port/' /etc/ssh/sshd_config
    sed -i "s/Port [0-9]\+/Port $new_ssh_port/g" /etc/ssh/sshd_config

    # 重启 SSH 服务
    service sshd restart
}
modifyPort

echo "3、开启防火墙并允许新的SSH端口"
openUfwPort() {
    echo "开启防火墙并允许新的SSH端口: $new_ssh_port"
    apt update -y && apt install -y ufw
    ufw --force enable
    ufw allow $new_ssh_port
    ufw status
}
openUfwPort


echo "修改后的信息："
echo "用户: $USER"
echo "密码: $new_passwd"
echo "端口: $new_ssh_port"
echo "------------------------"

