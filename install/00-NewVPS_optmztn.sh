#!/bin/bash


echo "1、系统更新"
sys_update(){
    if [ -f "/etc/debian_version" ]; then
        apt update -y && DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    fi
}
sys_update

echo "2. 系统清理"
sys_cleanup() {
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
    apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=50M
    apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
}
sys_cleanup

echo "3、优化DNS地址为Cloudflare和Google"
optimize_DNS(){
    cloudflare_ipv4="1.1.1.1"
    google_ipv4="8.8.8.8"
    echo "nameserver $cloudflare_ipv4" > /etc/resolv.conf
    echo "nameserver $google_ipv4" >> /etc/resolv.conf
}
optimize_DNS

echo "4、修改时区为Asia/Shanghai"
run_timeZone(){
    timedatectl set-timezone Asia/Shanghai
}
run_timeZone

echo "5、添加虚拟内存大小为1024MB"
add_memory(){
    # 删除旧的 /swapfile
    rm -f /swapfil
    # 创建新的 swap 分区
    dd if=/dev/zero of=/swapfile bs=1M count=1024
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
}
add_memory


echo "--------输出信息----------"
echo "------------------------"
echo "1、优化后的DNS地址为："
cat /etc/resolv.conf
echo "------------------------"
echo "2、当前时区为："
current_timezone=$(timedatectl show --property=Timezone --value)
echo "$current_timezone"
echo "------------------------"
echo "3、当前虚拟内存大小为："
# 获取虚拟内存文件的大小
swapfile_size=$(du -m /swapfile | awk '{print $1}')
# 显示虚拟内存大小
echo "虚拟内存大小为：${swapfile_size}MB"
echo "------------------------"

