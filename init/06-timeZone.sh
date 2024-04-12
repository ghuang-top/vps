#!/bin/bash
# chmod +x 06-timeZone.sh && ./06-timeZone.sh

echo "修改时区为Asia/Shanghai"

timedatectl set-timezone Asia/Shanghai

echo "------------------------"
echo "当前时区为："
echo "$(timedatectl show --property=Timezone --value)"
echo "------------------------"