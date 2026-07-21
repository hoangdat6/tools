#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

NPM_DIR="${NPM_DIR:-}"
NPM_IMAGE="${NPM_IMAGE:-jc21/nginx-proxy-manager:2.15.0}"
NPM_HTTP_PORT="${NPM_HTTP_PORT:-80}"
NPM_HTTPS_PORT="${NPM_HTTPS_PORT:-443}"
NPM_ADMIN_PORT="${NPM_ADMIN_PORT:-81}"
NPM_ADMIN_BIND="${NPM_ADMIN_BIND:-}"
NPM_CONTAINER_NAME="${NPM_CONTAINER_NAME:-nginx-proxy-manager}"

validate_admin_bind() {
    [[ "$NPM_ADMIN_BIND" =~ ^([0-9]{1,3}(\.[0-9]{1,3}){3}|[A-Za-z0-9.-]+)$ ]] \
        || fail "Invalid NPM_ADMIN_BIND: $NPM_ADMIN_BIND"
}

resolve_admin_bind() {
    if [ -n "$NPM_ADMIN_BIND" ]; then
        validate_admin_bind
        return 0
    fi
    if is_true "$SETUP_NON_INTERACTIVE"; then
        fail "NPM_ADMIN_BIND is required in non-interactive mode. Example: 0.0.0.0 or your public hostname."
    fi
    read -r -p "Nginx Proxy Manager admin bind address: " NPM_ADMIN_BIND
    [ -n "$NPM_ADMIN_BIND" ] || fail "NPM_ADMIN_BIND cannot be empty."
    validate_admin_bind
}

main() {
    require_supported_os
    ensure_docker_ready
    resolve_managed_paths
    [ -n "$NPM_DIR" ] || NPM_DIR="$INFRA_ROOT/nginx-proxy-manager"
    resolve_admin_bind

    if docker ps -a --format '{{.Names}}' | grep -qx "$NPM_CONTAINER_NAME"; then
        local managed
        managed="$(docker inspect -f '{{ index .Config.Labels "io.setup-server-tool.managed" }}' \
            "$NPM_CONTAINER_NAME" 2>/dev/null || true)"
        [ "$managed" = "true" ] || fail "Container $NPM_CONTAINER_NAME exists but is not managed by this tool."
    else
        assert_ports_available "$NPM_CONTAINER_NAME" "$NPM_HTTP_PORT" "$NPM_HTTPS_PORT" "$NPM_ADMIN_PORT"
    fi

    as_root mkdir -p "$NPM_DIR/data" "$NPM_DIR/letsencrypt"
    [ ! -f "$NPM_DIR/compose.yml" ] || backup_file "$NPM_DIR/compose.yml"
    cat <<EOF | write_root_file "$NPM_DIR/compose.yml"
services:
  app:
    image: ${NPM_IMAGE}
    container_name: ${NPM_CONTAINER_NAME}
    restart: unless-stopped
    labels:
      io.setup-server-tool.managed: "true"
    ports:
      - "${NPM_HTTP_PORT}:80"
      - "${NPM_ADMIN_BIND}:${NPM_ADMIN_PORT}:81"
      - "${NPM_HTTPS_PORT}:443"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF

    as_root docker compose -f "$NPM_DIR/compose.yml" config --quiet
    as_root docker compose -f "$NPM_DIR/compose.yml" up -d
    record_manifest nginx-proxy-manager "$NPM_IMAGE" docker
    print_success "Nginx Proxy Manager is running on http://${NPM_ADMIN_BIND}:${NPM_ADMIN_PORT}"
    print_info "Nginx Proxy Manager manages Let's Encrypt certificates internally."
}

main "$@"
