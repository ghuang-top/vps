#!/bin/bash
# chmod +x 02-sysCleanup.sh && ./02-sysCleanup.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/02-sysCleanup.sh && chmod +x 02-sysCleanup.sh && ./02-sysCleanup.sh

echo "系统清理"

apt autoremove --purge -y
apt clean -y
apt autoclean -y
apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
journalctl --rotate
journalctl --vacuum-time=1s
journalctl --vacuum-size=50M
apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
