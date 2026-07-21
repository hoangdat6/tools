#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

SERVER_TIMEZONE="${SERVER_TIMEZONE:-UTC}"
SERVER_HOSTNAME="${SERVER_HOSTNAME:-}"
BASELINE_SWAP_SIZE_GB="${BASELINE_SWAP_SIZE_GB:-0}"
SWAP_FILE="${SWAP_FILE:-/swapfile}"

configure_time() {
    install_packages tzdata
    if has_cmd timedatectl; then
        as_root timedatectl set-timezone "$SERVER_TIMEZONE"
        as_root timedatectl set-ntp true
    else
        print_warning "timedatectl is unavailable; timezone was not changed."
    fi
}

configure_hostname() {
    [ -n "$SERVER_HOSTNAME" ] || return 0
    [[ "$SERVER_HOSTNAME" =~ ^[A-Za-z0-9.-]+$ ]] || fail "Invalid SERVER_HOSTNAME."
    as_root hostnamectl set-hostname "$SERVER_HOSTNAME"
}

configure_swap() {
    [[ "$BASELINE_SWAP_SIZE_GB" =~ ^[0-9]+$ ]] || fail "BASELINE_SWAP_SIZE_GB must be an integer."
    [ "$BASELINE_SWAP_SIZE_GB" -gt 0 ] || return 0
    if swapon --show=NAME --noheadings 2>/dev/null | grep -Fqx "$SWAP_FILE"; then
        print_success "Swap is already active at $SWAP_FILE."
        return 0
    fi
    [ ! -e "$SWAP_FILE" ] || fail "$SWAP_FILE exists but is not active; inspect it before continuing."
    as_root fallocate -l "${BASELINE_SWAP_SIZE_GB}G" "$SWAP_FILE"
    as_root chmod 0600 "$SWAP_FILE"
    as_root mkswap "$SWAP_FILE"
    as_root swapon "$SWAP_FILE"
    append_root_line "$SWAP_FILE none swap sw 0 0" /etc/fstab
}

configure_logrotate() {
    install_packages logrotate
    cat <<'EOF' | write_root_file /etc/logrotate.d/setup-server-tool
/var/log/setup-server-tool.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
EOF
}

main() {
    require_supported_os
    ensure_base_packages
    configure_time
    configure_hostname
    configure_swap
    configure_logrotate
    record_manifest baseline "$SETUP_TOOL_VERSION" system
    print_success "System baseline configured."
}

main "$@"
