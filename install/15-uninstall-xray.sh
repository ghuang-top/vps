#!/bin/bash
# chmod +x 15-uninstall-xray.sh && ./15-uninstall-xray.sh

set -e

LOG_FILE="/var/log/uninstall_xray.log"

log_info() {
    echo -e "\033[32m[INFO]\033[0m $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" | tee -a "$LOG_FILE" >&2
    exit 1
}

stop_service() {
    log_info "1. 停止 Xray 服务..."
    if systemctl is-active --quiet xray; then
        sudo systemctl stop xray || log_error "无法停止 Xray 服务。"
    else
        log_info "Xray 服务未在运行中，跳过。"
    fi
}

disable_service() {
    log_info "2. 禁用 Xray 开机自启..."
    if systemctl is-enabled --quiet xray; then
        sudo systemctl disable xray || log_error "无法禁用 Xray 服务。"
    else
        log_info "Xray 服务未启用，跳过。"
    fi
}

remove_files() {
    log_info "3. 删除 Xray 文件..."

    # 删除二进制文件
    if [ -f "/usr/local/bin/xray" ]; then
        sudo rm -f /usr/local/bin/xray || log_error "无法删除 Xray 二进制文件。"
        log_info "已删除 /usr/local/bin/xray"
    else
        log_info "/usr/local/bin/xray 文件不存在，跳过。"
    fi

    # 删除配置文件
    if [ -d "/usr/local/etc/xray" ]; then
        sudo rm -rf /usr/local/etc/xray || log_error "无法删除 Xray 配置文件。"
        log_info "已删除 /usr/local/etc/xray"
    else
        log_info "/usr/local/etc/xray 目录不存在，跳过。"
    fi

    # 删除服务文件
    if [ -f "/etc/systemd/system/xray.service" ]; then
        sudo rm -f /etc/systemd/system/xray.service || log_error "无法删除 Xray 服务文件。"
        log_info "已删除 /etc/systemd/system/xray.service"
        sudo systemctl daemon-reload || log_error "无法重新加载 systemd 守护进程。"
    else
        log_info "/etc/systemd/system/xray.service 文件不存在，跳过。"
    fi

    # 删除日志文件
    if [ -d "/var/log/xray" ]; then
        sudo rm -rf /var/log/xray || log_error "无法删除 Xray 日志文件。"
        log_info "已删除 /var/log/xray"
    else
        log_info "/var/log/xray 目录不存在，跳过。"
    fi
}

verify_uninstall() {
    log_info "4. 验证 Xray 是否卸载成功..."
    if command -v xray &>/dev/null; then
        log_error "Xray 未成功卸载。"
    else
        log_info "Xray 已成功卸载。"
    fi
}

main() {
    stop_service
    disable_service
    remove_files
    verify_uninstall
    log_info "卸载完成。"
}

main "$@"
