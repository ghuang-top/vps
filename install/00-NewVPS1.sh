# 开启BBR3加速
echo "4、开启BBR3加速"
#========================
if dpkg -l | grep -q 'linux-xanmod'; then
    apt purge -y 'linux-*xanmod1*'
    update-grub

    wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

    apt update -y
    apt install -y linux-xanmod-x64v$version

else
    apt update -y
    apt install -y wget gnupg

    wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

fi


# 显示加速状态
echo "------------------------"
echo "BBR3加速状态："
if dpkg -l | grep -q 'linux-xanmod'; then
    # 已安装 xanmod 内核，已开启加速
    echo "已开启加速"
else
    # 未安装 xanmod 内核，未开启加速
    echo "未开启加速"
    #echo "BBR3加速已成功启用。重启后生效"
    #reboot
fi
echo "------------------------"