# vps
vps脚本

## 初始化脚本 (init)

- 00-disable-password
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/00-disable-password.sh && chmod +x 00-disable-password.sh && ./00-disable-password.sh
```

- 01-sysUpdate
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/01-sysUpdate.sh && chmod +x 01-sysUpdate.sh && ./01-sysUpdate.sh
```

- 02-sysCleanup
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/02-sysCleanup.sh && chmod +x 02-sysCleanup.sh && ./02-sysCleanup.sh
```

- 03-docker
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/03-docker.sh && chmod +x 03-docker.sh && ./03-docker.sh
```

- ddns-go
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/ddns-go.sh && chmod +x ddns-go.sh && ./ddns-go.sh
```

- vps_init
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/vps_init.sh && chmod +x vps_init.sh && ./vps_init.sh
```

- xray-manager
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/xray-manager.sh && chmod +x xray-manager.sh && ./xray-manager.sh
```

## 安装脚本 (install)

- 01-Nginx
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/01-Nginx.sh && chmod +x 01-Nginx.sh && ./01-Nginx.sh
```

- 02-NginxProxy
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/02-NginxProxy.sh && chmod +x 02-NginxProxy.sh && ./02-NginxProxy.sh
```

- 03-X-UI
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/03-X-UI.sh && chmod +x 03-X-UI.sh && ./03-X-UI.sh
```

- 04-FRP
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/04-FRP.sh && chmod +x 04-FRP.sh && ./04-FRP.sh
```

- 05-ZeroTier
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/05-ZeroTier.sh && chmod +x 05-ZeroTier.sh && ./05-ZeroTier.sh
```

- 06-Rustdesk
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/06-Rustdesk.sh && chmod +x 06-Rustdesk.sh && ./06-Rustdesk.sh
```

- 07-Alist
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/07-Alist.sh && chmod +x 07-Alist.sh && ./07-Alist.sh
```

- 08-Duplicati
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/08-Duplicati.sh && chmod +x 08-Duplicati.sh && ./08-Duplicati.sh
```

- 09-Syncthing
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/09-Syncthing.sh && chmod +x 09-Syncthing.sh && ./09-Syncthing.sh
```

- 10-Vaultwarden
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/10-Vaultwarden.sh && chmod +x 10-Vaultwarden.sh && ./10-Vaultwarden.sh
```

- 11-EasyImage
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/11-EasyImage.sh && chmod +x 11-EasyImage.sh && ./11-EasyImage.sh
```

- 12-Wordpress
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/12-Wordpress.sh && chmod +x 12-Wordpress.sh && ./12-Wordpress.sh
```

- 13-Nextcloud
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/13-Nextcloud.sh && chmod +x 13-Nextcloud.sh && ./13-Nextcloud.sh
```

- 14-Joplin
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/14-Joplin.sh && chmod +x 14-Joplin.sh && ./14-Joplin.sh
```
