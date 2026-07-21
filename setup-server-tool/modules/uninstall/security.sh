#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    require_supported_os
    resolve_managed_paths
    remove_root_file /etc/fail2ban/jail.d/setup-server-tool.local
    remove_root_file /etc/ssh/sshd_config.d/99-setup-server-tool.conf
    remove_root_file /etc/apt/apt.conf.d/20auto-upgrades
    if has_cmd systemctl; then
        as_root systemctl disable --now fail2ban || true
        as_root systemctl disable --now dnf-automatic.timer || true
        as_root systemctl disable --now yum-cron || true
    fi
    remove_packages fail2ban unattended-upgrades apt-listchanges dnf-automatic yum-cron ufw firewalld || true
    print_warning "Firewall rules and administrative users are not removed automatically. Review them manually."
    print_success "Removed managed security profile artifacts"
}

main "$@"
