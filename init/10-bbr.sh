#!/bin/bash


if dpkg -l | grep -q 'linux-xanmod'; then
    while true; do
        #clear
        kernel_version=$(uname -r)
        echo "您已安装xanmod的BBRv3内核"
        echo "当前内核版本: $kernel_version"

        echo ""
        echo "内核管理"
        echo "------------------------"
        echo "1. 更新BBRv3内核              2. 卸载BBRv3内核"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p "请输入你的选择: " sub_choice

        case $sub_choice in
            1)
                apt purge -y 'linux-*xanmod1*'
                update-grub

                wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

                echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

                version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

                apt update -y
                apt install -y linux-xanmod-x64v$version

                echo "XanMod内核已更新。重启后生效"
                rm -f /etc/apt/sources.list.d/xanmod-release.list
                rm -f check_x86-64_psabi.sh*

                reboot
                ;;
            2)
                apt purge -y 'linux-*xanmod1*'
                update-grub
                echo "XanMod内核已卸载。重启后生效"
                reboot
                ;;
            0)
                break  # 跳出循环，退出菜单
                ;;
            *)
                break  # 跳出循环，退出菜单
                ;;
        esac
    done
else
    #clear
    echo "请备份数据，将为你升级Linux内核开启BBR3"
    echo "官网介绍: https://xanmod.org/"
    echo "------------------------------------------------"
    echo "仅支持Debian/Ubuntu 仅支持x86_64架构"
    echo "VPS是512M内存的，请提前添加1G虚拟内存，防止因内存不足失联！"
    echo "------------------------------------------------"

    # 直接安装，无需询问
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
            echo "当前环境不支持，仅支持Debian和Ubuntu系统"
            exit 1
        fi
    else
        echo "无法确定操作系统类型"
        exit 1
    fi

    arch=$(dpkg --print-architecture)
    if [ "$arch" != "amd64" ]; then
        echo "当前环境不支持，仅支持x86_64架构"
        exit 1
    fi

    apt-get update
    apt-get install -y wget gnupg

    wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

    apt-get update
    apt-get install -y linux-xanmod-x64v$version

    cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl -p
    echo "XanMod内核安装并BBR3启用成功。重启后生效"
    rm -f /etc/apt/sources.list.d/xanmod-release.list
    rm -f check_x86-64_psabi.sh*
    reboot
fi
