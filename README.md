# vps
vps脚本


- kejilion
```sh 
curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
```

- 00-logins
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/init/00-logins.sh && chmod +x 00-logins.sh && ./00-logins.sh
```

- 00-Initialization
```sh
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/00-Initialization.sh && chmod +x 00-Initialization.sh && ./00-Initialization.sh
```

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

- All-in-One
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/All-in-One.sh && chmod +x All-in-One.sh && ./All-in-One.sh
```

- Check-docker-compose
```sh 
curl -sS -O https://raw.githubusercontent.com/ghuang-top/vps/main/install/Check-docker-compose.sh && chmod +x Check-docker-compose.sh && ./Check-docker-compose.sh
```


- Docker
  
```yaml
version: '3.8'

services:
  nginx:
    image: nginx
    container_name: nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - ./certs:/etc/nginx/certs
      - ./html:/var/www/html
      - ./log/nginx:/var/log/nginx

  php:
    image: php:fpm
    container_name: php
    restart: always
    volumes:
      - ./html:/var/www/html

  php74:
    image: php:7.4.33-fpm
    container_name: php74
    restart: always
    volumes:
      - ./html:/var/www/html

  mysql:
    image: mysql
    container_name: mysql
    restart: always
    volumes:
      - ./mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: webroot
      MYSQL_USER: kejilion
      MYSQL_PASSWORD: kejilionYYDS

  redis:
    image: redis
    container_name: redis
    restart: always
    volumes:
      - ./redis:/data
```


- 证书申请

```yaml
curl https://get.acme.sh | sh

~/.acme.sh/acme.sh --register-account -m xxxx@gmail.com --issue -d web1.ghuang.top  -d web2.ghuang.top  -d web3.ghuang.top -d web4.ghuang.top -d web5.ghuang.top -d web6.ghuang.top --standalone --key-file /home/web/certs/key.pem --cert-file /home/web/certs/cert.pem  --force

```

```yaml
curl https://get.acme.sh | sh

~/.acme.sh/acme.sh --register-account -m xxxx@gmail.com --issue -d web11.ghuang.top  -d web12.ghuang.top  -d web13.ghuang.top -d web14.ghuang.top -d web15.ghuang.top -d web16.ghuang.top --standalone --key-file /home/web/certs/key.pem --cert-file /home/web/certs/cert.pem  --force

```
