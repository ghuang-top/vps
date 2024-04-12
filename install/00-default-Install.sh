#!/bin/bash
# chmod +x 00-default install.sh && ./00-default install.sh
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/00-default-Install.sh && chmod +x 00-default-Install.sh && ./00-default-Install.sh


# 初始化 1
apt update -y  && apt install -y curl
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/01-sysUpdate.sh && chmod +x 01-sysUpdate.sh && ./01-sysUpdate.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/02-sysCleanup.sh && chmod +x 02-sysCleanup.sh && ./02-sysCleanup.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/03-docker.sh && chmod +x 03-docker.sh && ./03-docker.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/04-ufw.sh && chmod +x 04-ufw.sh && ./04-ufw.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/05-optimizeDNS.sh && chmod +x 05-optimizeDNS.sh && ./05-optimizeDNS.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/06-timeZone.sh && chmod +x 06-timeZone.sh && ./06-timeZone.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/07-addMemory.sh && chmod +x 07-addMemory.sh && ./07-addMemory.sh
curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh



# 软件安装
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/02-NginxProxy.sh && chmod +x 02-NginxProxy.sh && ./02-NginxProxy.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/03-X-UI.sh && chmod +x 03-X-UI.sh && ./03-X-UI.sh



curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/10-Vaultwarden.sh && chmod +x 10-Vaultwarden.sh && ./10-Vaultwarden.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/11-EasyImage.sh && chmod +x 11-EasyImage.sh && ./11-EasyImage.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/12-Wordpress.sh && chmod +x 12-Wordpress.sh && ./12-Wordpress.sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/13-Nextcloud.sh && chmod +x 13-Nextcloud.sh && ./13-Nextcloud.sh



curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/14-Joplin.sh && chmod +x 14-Joplin.sh && ./14-Joplin.sh



# 9、禁止Ping
#echo "步骤9："
#curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/09-banPing.sh && chmod +x 09-banPing.sh && ./09-banPing.sh


# 8、Fail2ban
echo "步骤10："
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/08-fail2ban.sh && chmod +x 08-fail2ban.sh && ./08-fail2ban.sh


# 10、BBRv3加速
echo "步骤11："
curl -sS -O https://raw.githubusercontent.com/ghuang-top/blog/main/sh/init/10-bbr.sh && chmod +x 10-bbr.sh && ./10-bbr.sh





