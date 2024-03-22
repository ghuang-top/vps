#!/bin/bash

# 用户设置
new_passwd="2345uh1yPo"
new_ssh_port="4399"

# 修改密码
modifyPassword() {
    echo "root:$new_passwd" | chpasswd
}
modifyPassword

# 修改SSH配置
modifyPort() {
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

# 开启防火墙并允许新的SSH端口
openUfwPort() {
    echo "开启防火墙并允许新的SSH端口: $new_ssh_port"
    apt update -y && apt install -y ufw
    ufw --force enable
    ufw allow $new_ssh_port
    ufw status
}
openUfwPort

# 显示相关信息
echo "修改后的信息"
echo "用户: $USER"
echo "密码: $new_passwd"
echo "端口: $new_ssh_port"
