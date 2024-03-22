#!/bin/bash


# 1、判断权限
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/00-NewVPS_optmztn.sh && chmod +x 00-NewVPS_optmztn.sh && ./00-NewVPS_optmztn.sh

curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/00-NewVPS_login.sh && chmod +x 00-NewVPS_login.sh && ./00-NewVPS_login.sh

curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/00-NewVPS_bbr.sh && chmod +x 00-NewVPS_bbr.sh && ./00-NewVPS_bbr.sh