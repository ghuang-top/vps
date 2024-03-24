#!/bin/bash
# 00-Initialization

echo "1、判断权限"
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi


mkdir -p /root/init
cd /root/init

echo "1、修改端口和密码"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/00-logins.sh && chmod +x 00-logins.sh && ./00-logins.sh


echo "2、系统更新"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/01-sysUpdate.sh && chmod +x 01-sysUpdate.sh && ./01-sysUpdate.sh


echo "3. 系统清理"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/02-sysCleanup.sh && chmod +x 02-sysCleanup.sh && ./02-sysCleanup.sh


echo "4、初始化vps"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/03-docker.sh && chmod +x 03-docker.sh && ./03-docker.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/04-ufw.sh && chmod +x 04-ufw.sh && ./04-ufw.sh


echo "5、优化DNS地址为Cloudflare和Google"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/05-optimizeDNS.sh && chmod +x 05-optimizeDNS.sh && ./05-optimizeDNS.sh


echo "6、修改时区为Asia/Shanghai"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/06-timeZone.sh && chmod +x 06-timeZone.sh && ./06-timeZone.sh


echo "7、添加虚拟内存大小为1024MB"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/07-addMemory.sh && chmod +x 07-addMemory.sh && ./07-addMemory.sh


echo "9、禁止Ping"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/09-banPing.sh && chmod +x 09-banPing.sh && ./09-banPing.sh


echo "8、Fail2ban"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/08-fail2ban.sh && chmod +x 08-fail2ban.sh && ./08-fail2ban.sh


echo "10、BBRv3加速"
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/10-bbr.sh && chmod +x 10-bbr.sh && ./10-bbr.sh


echo "--------输出信息----------"
echo "------------------------"
echo "1、优化后的DNS地址为："
cat /etc/resolv.conf
echo "------------------------"

echo "2、当前时区为："
echo "$(timedatectl show --property=Timezone --value)"
echo "------------------------"

echo "3、虚拟内存："
echo "当前虚拟内存大小为：$(du -m /swapfile | awk '{print $1}')MB"
echo "------------------------"

echo "4、查看Docker和Docker-Compose的版本"
docker --version
docker-compose --version
echo "------------------------"

echo "5、开放的端口"
ufw status
echo "------------------------"

echo "7、禁止Ping"
echo "用以下命令查看是否更改"
echo "nano /etc/ufw/before.rules"
# echo "ufw reload"
echo "------------------------"

echo "6、Fail2ban"
echo "重启服务"
fail2ban-client status
fail2ban-client status sshd
systemctl status fail2ban --no-pager && echo "Continue with the next script" && exit 0
systemctl restart fail2ban
echo "------------------------"

