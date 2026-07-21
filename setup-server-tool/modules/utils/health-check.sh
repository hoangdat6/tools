#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

check_cmd() {
    local label="$1" cmd="$2"
    if has_cmd "$cmd"; then
        printf '%-26s %s\n' "$label" "$("$cmd" --version 2>&1 | head -n 1)"
    else
        printf '%-26s %s\n' "$label" "not installed"
    fi
}

check_service() {
    local service="$1"
    if has_cmd systemctl && systemctl list-unit-files | grep -q "^${service}\.service"; then
        printf '%-26s %s\n' "Service $service" "$(systemctl is-active "$service" 2>/dev/null || true)"
    fi
}

check_container() {
    local name="$1"
    has_cmd docker || return 0
    if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
        printf '%-26s %s\n' "Container $name" \
            "$(docker inspect -f '{{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$name")"
    fi
}

check_port() {
    local port="$1"
    if port_in_use "$port"; then
        printf '%-26s %s\n' "TCP port $port" "listening"
    else
        printf '%-26s %s\n' "TCP port $port" "closed"
    fi
}

check_http() {
    local label="$1" url="$2" code
    has_cmd curl || return 0
    code="$(curl -sS --max-time 3 -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)"
    [ -n "$code" ] || code="unreachable"
    printf '%-26s %s\n' "$label" "$code"
}

main() {
    require_supported_os
    printf '\n'
    check_cmd "Docker" docker
    if has_cmd docker && docker compose version >/dev/null 2>&1; then
        printf '%-26s %s\n' "Docker Compose" "$(docker compose version)"
    else
        printf '%-26s %s\n' "Docker Compose" "not installed"
    fi
    check_cmd "AWS CLI" aws
    check_cmd "Nginx" nginx
    check_cmd "Certbot" certbot

    resolve_target_user
    if [ -s "$TARGET_HOME/.nvm/nvm.sh" ]; then
        local nvm_version node_version npm_version
        # shellcheck disable=SC2016
        nvm_version="$(as_target_user_read bash -c '. "$1"; nvm --version' _ "$TARGET_HOME/.nvm/nvm.sh")"
        # shellcheck disable=SC2016
        node_version="$(as_target_user_read bash -c '. "$1"; node --version' _ "$TARGET_HOME/.nvm/nvm.sh")"
        # shellcheck disable=SC2016
        npm_version="$(as_target_user_read bash -c '. "$1"; npm --version' _ "$TARGET_HOME/.nvm/nvm.sh")"
        printf '%-26s %s\n' "NVM ($TARGET_USER)" "$nvm_version"
        printf '%-26s %s\n' "Node.js ($TARGET_USER)" "$node_version"
        printf '%-26s %s\n' "npm ($TARGET_USER)" "$npm_version"
    else
        printf '%-26s %s\n' "NVM ($TARGET_USER)" "not installed"
    fi

    check_service docker
    check_service nginx
    check_service certbot
    check_service fail2ban
    check_container setup-server-nginx
    check_container nginx-proxy-manager
    check_port 22
    check_port 80
    check_port 81
    check_port 443
    port_in_use 80 && check_http "HTTP localhost:80" "http://127.0.0.1/"
    port_in_use 81 && check_http "HTTP NPM admin" "http://127.0.0.1:81/"

    if has_cmd getenforce; then
        printf '%-26s %s\n' "SELinux" "$(getenforce)"
    fi

    if [ -r "$SETUP_MANIFEST_FILE" ]; then
        printf '\nRecent manifest entries:\n'
        tail -n 10 "$SETUP_MANIFEST_FILE"
    fi
}

main "$@"
