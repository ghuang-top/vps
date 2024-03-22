#!/bin/bash

# 检查操作系统类型和架构
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

# 检查是否已安装XanMod内核
if dpkg -l | grep -q 'linux-xanmod'; then
    echo "XanMod内核已经安装，无需重复安装"
else

    # 安装 linux-xanmod-x64v2
    apt update -y  && apt install -y nano
    # 在文件末尾添加以下行：
    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee -a /etc/apt/sources.list
    wget -qO - https://deb.xanmod.org/gpg.key | sudo apt-key --keyring /usr/share/keyrings/xanmod-archive-keyring.gpg add -
    sudo apt update

    # 安装必要的软件并添加存储库
    apt update -y
    apt install -y wget gnupg
    wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    # 安装XanMod内核并启用BBR3
    version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
    apt install -y linux-xanmod-x64v$version
    cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl -p

    # 清理临时文件
    rm -f /etc/apt/sources.list.d/xanmod-release.list
    rm -f check_x86-64_psabi.sh*
fi

# 检查BBR3是否成功开启
congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
queue_algorithm=$(sysctl -n net.core.default_qdisc)

if [[ "$congestion_algorithm" == "bbr" && "$queue_algorithm" == "fq_pie" ]]; then
    echo "网络拥堵算法: $congestion_algorithm $queue_algorithm"
else
    echo "无法启用BBR3，正在重启以应用更改"
    rm -f /etc/apt/sources.list.d/xanmod-release.list
    rm -f check_x86-64_psabi.sh*
    #reboot
fi
