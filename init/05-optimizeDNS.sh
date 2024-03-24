#!/bin/bash

# 删除旧的DNS地址
sed -i '/^nameserver/d' /etc/resolv.conf

# 添加新的DNS地址
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 172.31.255.2" >> /etc/resolv.conf
echo "nameserver 74.82.42.42" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
