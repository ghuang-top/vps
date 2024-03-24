#!/bin/bash
# 00-Initialization

echo "1、判断权限"
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

mkdir -p /root/init
cd /root/init

echo "2、系统更新"


echo "3. 系统清理"


echo "4、初始化vps"


echo "5、优化DNS地址为Cloudflare和Google"


echo "6、修改时区为Asia/Shanghai"


echo "7、添加虚拟内存大小为1024MB"


echo "8、Fail2ban"


echo "9、禁止Ping"


echo "10、BBRv3加速"


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
swapfile_size=$(du -m /swapfile | awk '{print $1}')
echo "虚拟内存大小为：${swapfile_size}MB"
echo "------------------------"

echo "4、查看Docker和Docker-Compose的版本"
docker --version
docker-compose --version
echo "------------------------"

echo "5、开放的端口"
ufw status
echo "------------------------"

echo "7、禁止Ping"
echo "nano /etc/ufw/before.rules"
echo "ufw reload"
echo "------------------------"

echo "6、Fail2ban"
echo "重启服务"
fail2ban-client status
fail2ban-client status sshd
systemctl status fail2ban --no-pager && echo "Continue with the next script" && exit 0
systemctl restart fail2ban
echo "------------------------"

