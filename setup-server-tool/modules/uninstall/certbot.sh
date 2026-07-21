#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

disable_timer_if_present() {
    local unit="$1"
    if has_cmd systemctl && systemctl list-unit-files | grep -q "^${unit}"; then
        as_root systemctl disable --now "$unit" || true
    fi
}

main() {
    require_supported_os
    resolve_managed_paths
    disable_timer_if_present certbot.timer
    disable_timer_if_present snap.certbot.renew.timer
    remove_root_file /etc/cron.d/certbot-renew
    remove_root_file /etc/letsencrypt/renewal-hooks/deploy/reload-web-server.sh
    remove_packages certbot python3-certbot-nginx || true
    print_warning "Certificates under /etc/letsencrypt are left in place. Remove them manually if no longer needed."
    print_success "Removed Certbot automation and packages"
}

main "$@"
