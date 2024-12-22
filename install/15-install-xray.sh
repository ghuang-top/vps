#!/bin/bash
# chmod +x 15-install-xray.sh && ./15-install-xray.sh

set -e  # 遇到错误时退出
XRAY_PATH="/usr/local/bin"
CONFIG_PATH="/usr/local/etc/xray"
PORT="51815"


# 交互式获取端口号
get_port() {
    while true; do
        read -rp "请输入要使用的端口号（1-65535）: " PORT_INPUT

        # 检查是否为数字
        if ! [[ "$PORT_INPUT" =~ ^[0-9]+$ ]]; then
            log_error "端口号必须是数字，请重新输入。"
        fi

        PORT_NUM=$PORT_INPUT

        # 检查端口号范围
        if (( PORT_NUM < 1 || PORT_NUM > 65535 )); then
            log_error "端口号必须在1到65535之间，请重新输入。"
        fi

        # 检查端口是否被占用
        if ss -tuln | grep -q ":$PORT_NUM\b"; then
            log_error "端口 $PORT_NUM 已被占用，请选择其他端口。"
        fi

        PORT=$PORT_NUM
        log_info "选择的端口号: $PORT"
        break
    done
}


log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
    exit 1
}

init() {
    log_info "1. 初始化系统并安装必要软件"
    apt update -y && apt upgrade -y || log_error "系统更新失败"
    apt install -y wget curl sudo vim git || log_error "软件安装失败"
}

install_xray() {
    log_info "2. 安装Xray"
    if ! command -v xray &>/dev/null; then
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install || log_error "Xray 安装失败"
    else
        log_info "Xray 已安装，跳过安装步骤"
    fi
}

generate_keys() {
    log_info "3. 生成UUID及密钥"
    cd "$XRAY_PATH" || log_error "无法进入目录 $XRAY_PATH"
    UUID=$(./xray uuid)
    KEY_PAIR=$(./xray x25519)
    PRIVATE_KEY=$(echo "$KEY_PAIR" | grep 'Private key' | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEY_PAIR" | grep 'Public key' | awk '{print $3}')

    log_info "生成的UUID: $UUID"
    log_info "生成的私钥: $PRIVATE_KEY"
    log_info "生成的公钥: $PUBLIC_KEY"
}


create_config() {
    log_info "4. 创建Xray配置文件"
    mkdir -p "$CONFIG_PATH"
    cat <<EOF > "$CONFIG_PATH/config.json"
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "tag": "VLESSReality",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "vless_reality_vision",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": "31305",
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.shopify.com:443",
          "xver": 0,
          "serverNames": [
            "shopify.com",
            "www.shopify.com"
          ],
          "privateKey": "$PRIVATE_KEY",
          "publicKey": "$PUBLIC_KEY",
          "maxTimeDiff": 70000,
          "shortIds": [
            "99",
            "6ba85179e30d4fc2"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
EOF
}

restart_xray() {
    log_info "5. 重启Xray服务"
    systemctl restart xray || log_error "Xray 服务重启失败，请检查日志！"
}

output_info() {
    log_info "6. xray操作信息"
    echo "------------------------"
    echo -e "systemctl start xray\nsystemctl status xray\nsystemctl restart xray\nsystemctl stop xray\nsystemctl enable xray"
    echo "------------------------"

    log_info "7. 节点信息"
    
    # 获取IPv4地址
    ipv4_address=$(curl -s ipv4.ip.sb)
    if [ -n "$ipv4_address" ]; then
        echo "VLESS链接（IPv4）: vless://$UUID@$ipv4_address:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.shopify.com&fp=chrome&pbk=$PUBLIC_KEY&sid=99&spx=%2F&type=tcp&headerType=none#your_nodeName"
    else
        log_info "无法获取IPv4地址"
    fi
    
    # 获取IPv6地址
    ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
    if [ -n "$ipv6_address" ]; then
        echo "VLESS链接（IPv6）: vless://$UUID@[$ipv6_address]:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.shopify.com&fp=chrome&pbk=$PUBLIC_KEY&sid=99&spx=%2F&type=tcp&headerType=none#your_nodeName"
    else
        log_info "无法获取IPv6地址"
    fi
    
    echo "------------------------"
    systemctl status xray || log_error "无法获取Xray状态"
}


main() {
    get_port
    init
    install_xray
    generate_keys
    create_config
    restart_xray
    output_info
}

main "$@"
