#!/bin/bash
#All-in-One

# 下载并执行01-Nginx脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/01-Nginx.sh && chmod +x 01-Nginx.sh && ./01-Nginx.sh

# 下载并执行02-NginxProxy脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/02-NginxProxy.sh && chmod +x 02-NginxProxy.sh && ./02-NginxProxy.sh

# 下载并执行03-X-UI脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/03-X-UI.sh && chmod +x 03-X-UI.sh && ./03-X-UI.sh

# 下载并执行04-FRP脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/04-FRP.sh && chmod +x 04-FRP.sh && ./04-FRP.sh

# 下载并执行05-ZeroTier脚本
# curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/05-ZeroTier.sh && chmod +x 05-ZeroTier.sh && ./05-ZeroTier.sh

# 下载并执行06-Rustdesk脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/06-Rustdesk.sh && chmod +x 06-Rustdesk.sh && ./06-Rustdesk.sh

# 下载并执行10-Vaultwarden脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/10-Vaultwarden.sh && chmod +x 10-Vaultwarden.sh && ./10-Vaultwarden.sh

# 下载并执行11-EasyImage脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/11-EasyImage.sh && chmod +x 11-EasyImage.sh && ./11-EasyImage.sh

# 下载并执行12-Wordpress脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/12-Wordpress.sh && chmod +x 12-Wordpress.sh && ./12-Wordpress.sh

# 下载并执行13-Nextcloud脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/13-Nextcloud.sh && chmod +x 13-Nextcloud.sh && ./13-Nextcloud.sh

# 下载并执行14-Joplin脚本
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/14-Joplin.sh && chmod +x 14-Joplin.sh && ./14-Joplin.sh
