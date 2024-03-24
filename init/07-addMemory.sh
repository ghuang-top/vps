#!/bin/bash
# chmod +x 07-addMemory.sh && ./07-addMemory.sh

echo "添加虚拟内存大小为1024MB"

# 如果当前有 swap 文件在使用，先关闭它
if swapon -s | grep -q '/swapfile'; then
    swapoff /swapfile
fi

# 删除旧的 /swapfile
rm -f /swapfile

# 创建新的 swap 分区
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 根据不同系统添加相应配置
if [ -f /etc/alpine-release ]; then
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
    chmod +x /etc/local.d/swap.start
    rc-update add local
else
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

echo "------------------------"
echo "当前虚拟内存大小为：$(du -m /swapfile | awk '{print $1}')MB"
echo "------------------------"