#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

CERTBOT_DOMAINS="${CERTBOT_DOMAINS:-}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"
CERTBOT_MODE="${CERTBOT_MODE:-nginx}"

install_certbot_packages() {
    case "$PKG_MANAGER" in
        apt) install_packages certbot python3-certbot-nginx ;;
        dnf|yum)
            if ! install_packages certbot python3-certbot-nginx; then
                print_warning "Nginx plugin is unavailable; installing core Certbot only."
                install_packages certbot
            fi
            ;;
        *) fail "Unsupported package manager: $PKG_MANAGER" ;;
    esac
}

ensure_renewal_timer() {
    if has_cmd systemctl && systemctl list-unit-files | grep -q '^certbot\.timer'; then
        as_root systemctl enable --now certbot.timer
    elif has_cmd systemctl && systemctl list-unit-files | grep -q '^snap\.certbot\.renew\.timer'; then
        as_root systemctl enable --now snap.certbot.renew.timer
    else
        printf '%s\n' '17 3,15 * * * root certbot renew --quiet' \
            | write_root_file /etc/cron.d/certbot-renew
    fi
}

install_deploy_hook() {
    cat <<'EOF' | write_root_file /etc/letsencrypt/renewal-hooks/deploy/reload-web-server.sh 0755
#!/usr/bin/env bash
set -euo pipefail
if systemctl is-active --quiet nginx 2>/dev/null; then
    systemctl reload nginx
elif docker ps --format '{{.Names}}' 2>/dev/null | grep -qx setup-server-nginx; then
    docker exec setup-server-nginx nginx -s reload
fi
EOF
}

issue_certificate() {
    [ -n "$CERTBOT_DOMAINS" ] || return 0
    [ -n "$CERTBOT_EMAIL" ] || fail "CERTBOT_EMAIL is required when CERTBOT_DOMAINS is set."

    local domain args=()
    for domain in $CERTBOT_DOMAINS; do
        [[ "$domain" =~ ^[A-Za-z0-9.*-]+$ ]] || fail "Invalid certificate domain: $domain"
        args+=( -d "$domain" )
    done

    case "$CERTBOT_MODE" in
        nginx)
            has_cmd nginx || fail "Native Nginx is required for CERTBOT_MODE=nginx."
            as_root certbot --nginx --non-interactive --agree-tos --email "$CERTBOT_EMAIL" "${args[@]}"
            ;;
        standalone)
            assert_ports_available "Certbot standalone challenge" 80
            as_root certbot certonly --standalone --non-interactive --agree-tos \
                --email "$CERTBOT_EMAIL" "${args[@]}"
            ;;
        *) fail "Unsupported CERTBOT_MODE=$CERTBOT_MODE. Use nginx or standalone." ;;
    esac
}

main() {
    require_supported_os
    ensure_base_packages
    install_certbot_packages
    ensure_renewal_timer
    install_deploy_hook
    issue_certificate

    if ! is_true "$SETUP_DRY_RUN" && [ -d /etc/letsencrypt/live ] \
        && find /etc/letsencrypt/live -mindepth 1 -maxdepth 1 -type d | grep -q .; then
        as_root certbot renew --dry-run
    fi
    if is_true "$SETUP_DRY_RUN"; then
        record_manifest certbot planned system
    else
        record_manifest certbot "$(certbot --version 2>&1 | awk '{print $2}')" system
    fi
    print_success "Certbot setup and renewal automation completed."
}

main "$@"
