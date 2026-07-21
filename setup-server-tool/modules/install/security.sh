#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

ADMIN_USER="${ADMIN_USER:-}"
ADMIN_SSH_PUBLIC_KEY="${ADMIN_SSH_PUBLIC_KEY:-}"
SSH_PORT="${SSH_PORT:-}"
if [ -z "$SSH_PORT" ] && [ -n "${SSH_CONNECTION:-}" ]; then
    SSH_PORT="${SSH_CONNECTION##* }"
fi
SSH_PORT="${SSH_PORT:-22}"
SSH_DISABLE_PASSWORD_AUTH="${SSH_DISABLE_PASSWORD_AUTH:-true}"
SECURITY_ENABLE_FIREWALL="${SECURITY_ENABLE_FIREWALL:-true}"

configure_admin_user() {
    [ -n "$ADMIN_USER" ] || return 0
    [[ "$ADMIN_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail "Invalid ADMIN_USER."
    if ! id "$ADMIN_USER" >/dev/null 2>&1; then
        as_root useradd --create-home --shell /bin/bash "$ADMIN_USER"
    fi
    install_packages sudo
    as_root usermod -aG sudo "$ADMIN_USER" 2>/dev/null \
        || as_root usermod -aG wheel "$ADMIN_USER"

    if [ -n "$ADMIN_SSH_PUBLIC_KEY" ]; then
        local admin_home auth_file
        [[ "$ADMIN_SSH_PUBLIC_KEY" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521))[[:space:]][A-Za-z0-9+/=]+([[:space:]].*)?$ ]] \
            || fail "ADMIN_SSH_PUBLIC_KEY is not a supported OpenSSH public key."
        admin_home="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"
        [ -n "$admin_home" ] || admin_home="/home/$ADMIN_USER"
        auth_file="$admin_home/.ssh/authorized_keys"
        as_root install -d -m 0700 -o "$ADMIN_USER" -g "$ADMIN_USER" "$admin_home/.ssh"
        append_root_line "$ADMIN_SSH_PUBLIC_KEY" "$auth_file"
        as_root chown "$ADMIN_USER:$ADMIN_USER" "$auth_file"
        as_root chmod 0600 "$auth_file"
    fi
}

configure_fail2ban() {
    if ! install_packages fail2ban; then
        print_warning "fail2ban is unavailable in the configured repositories; skipping it."
        return 0
    fi
    cat <<EOF | write_root_file /etc/fail2ban/jail.d/setup-server-tool.local
[sshd]
enabled = true
port = ${SSH_PORT}
bantime = 1h
findtime = 10m
maxretry = 5
EOF
    enable_service fail2ban
}

configure_firewall() {
    is_true "$SECURITY_ENABLE_FIREWALL" || return 0
    confirm "Enable the firewall and allow SSH/HTTP/HTTPS?" || {
        print_warning "Firewall configuration skipped."
        return 0
    }

    case "$PKG_MANAGER" in
        apt)
            install_packages ufw
            as_root ufw allow "${SSH_PORT}/tcp"
            as_root ufw allow 80/tcp
            as_root ufw allow 443/tcp
            as_root ufw --force enable
            ;;
        dnf|yum)
            install_packages firewalld
            enable_service firewalld
            as_root firewall-cmd --permanent --add-port="${SSH_PORT}/tcp"
            as_root firewall-cmd --permanent --add-service=http
            as_root firewall-cmd --permanent --add-service=https
            as_root firewall-cmd --reload
            ;;
    esac
}

configure_automatic_updates() {
    case "$PKG_MANAGER" in
        apt)
            install_packages unattended-upgrades apt-listchanges
            cat <<'EOF' | write_root_file /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
            ;;
        dnf)
            install_packages dnf-automatic
            as_root sed -i 's/^apply_updates = .*/apply_updates = yes/' /etc/dnf/automatic.conf
            enable_service dnf-automatic.timer
            ;;
        yum)
            install_packages yum-cron
            as_root sed -i 's/^apply_updates = .*/apply_updates = yes/' /etc/yum/yum-cron.conf
            enable_service yum-cron
            ;;
    esac
}

configure_sshd() {
    [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1 ] && [ "$SSH_PORT" -le 65535 ] \
        || fail "SSH_PORT must be between 1 and 65535."
    has_cmd sshd || is_true "$SETUP_DRY_RUN" || fail "OpenSSH server is not installed."
    resolve_target_user
    local ssh_user="$TARGET_USER" ssh_home auth_file password_auth="yes"
    [ -z "$ADMIN_USER" ] || ssh_user="$ADMIN_USER"
    ssh_home="$(getent passwd "$ssh_user" | cut -d: -f6)"
    auth_file="$ssh_home/.ssh/authorized_keys"

    if is_true "$SSH_DISABLE_PASSWORD_AUTH" && [ -s "$auth_file" ]; then
        password_auth="no"
    elif is_true "$SSH_DISABLE_PASSWORD_AUTH"; then
        print_warning "PasswordAuthentication remains enabled because $ssh_user has no authorized_keys."
    fi

    [ ! -f /etc/ssh/sshd_config.d/99-setup-server-tool.conf ] \
        || backup_file /etc/ssh/sshd_config.d/99-setup-server-tool.conf
    cat <<EOF | write_root_file /etc/ssh/sshd_config.d/99-setup-server-tool.conf
Port ${SSH_PORT}
PermitRootLogin prohibit-password
PasswordAuthentication ${password_auth}
KbdInteractiveAuthentication no
MaxAuthTries 4
X11Forwarding no
EOF
    as_root sshd -t
    if systemctl list-unit-files | grep -q '^sshd\.service'; then
        reload_service sshd
    else
        reload_service ssh
    fi
}

main() {
    require_supported_os
    ensure_base_packages
    configure_admin_user
    configure_fail2ban
    configure_firewall
    configure_automatic_updates
    configure_sshd
    record_manifest security "$SETUP_TOOL_VERSION" system
    print_success "Security profile configured."
}

main "$@"
