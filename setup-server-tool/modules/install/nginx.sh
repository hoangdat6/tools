#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

NGINX_MODE="${NGINX_MODE:-apt}"
NGINX_DIR="${NGINX_DIR:-}"
NGINX_IMAGE="${NGINX_IMAGE:-nginx:1.28.0-alpine}"
NGINX_CONTAINER_NAME="${NGINX_CONTAINER_NAME:-setup-server-nginx}"
NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-80}"
NGINX_HTTPS_PORT="${NGINX_HTTPS_PORT:-443}"

container_is_managed() {
    docker inspect -f '{{ index .Config.Labels "io.setup-server-tool.managed" }}' \
        "$NGINX_CONTAINER_NAME" 2>/dev/null | grep -qx true
}

install_native_nginx() {
    if has_cmd docker && docker ps --format '{{.Names}}' | grep -Eq '^(nginx-proxy-manager|setup-server-nginx)$'; then
        fail "A managed Docker proxy already owns the web ports. Stop it before installing native Nginx."
    fi
    if ! has_cmd nginx || is_true "$SETUP_FORCE"; then
        assert_ports_available "native Nginx" "$NGINX_HTTP_PORT" "$NGINX_HTTPS_PORT"
        install_packages nginx
    fi
    as_root nginx -t
    enable_service nginx
    if is_true "$SETUP_DRY_RUN"; then
        record_manifest nginx planned native
    else
        record_manifest nginx "$(nginx -v 2>&1 | sed 's#nginx/##')" native
    fi
}

write_default_docker_config() {
    if [ ! -f "$NGINX_DIR/conf.d/default.conf" ] || is_true "$SETUP_FORCE"; then
        cat <<'EOF' | write_root_file "$NGINX_DIR/conf.d/default.conf"
server {
    listen 80 default_server;
    server_name _;
    root /usr/share/nginx/html;
    location /healthz {
        access_log off;
        return 200 "ok\n";
        add_header Content-Type text/plain;
    }
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
    fi
    if [ ! -f "$NGINX_DIR/html/index.html" ]; then
        printf '%s\n' '<!doctype html><title>Server ready</title><h1>Server ready</h1>' \
            | write_root_file "$NGINX_DIR/html/index.html"
    fi
}

install_docker_nginx() {
    ensure_docker_ready
    [ -n "$NGINX_DIR" ] || NGINX_DIR="$INFRA_ROOT/nginx"
    if docker ps -a --format '{{.Names}}' | grep -qx "$NGINX_CONTAINER_NAME"; then
        container_is_managed || fail "Container $NGINX_CONTAINER_NAME exists but is not managed by this tool."
    else
        assert_ports_available "$NGINX_CONTAINER_NAME" "$NGINX_HTTP_PORT" "$NGINX_HTTPS_PORT"
    fi

    as_root mkdir -p "$NGINX_DIR/conf.d" "$NGINX_DIR/html" "$NGINX_DIR/certs"
    write_default_docker_config
    [ ! -f "$NGINX_DIR/compose.yml" ] || backup_file "$NGINX_DIR/compose.yml"
    cat <<EOF | write_root_file "$NGINX_DIR/compose.yml"
services:
  nginx:
    image: ${NGINX_IMAGE}
    container_name: ${NGINX_CONTAINER_NAME}
    restart: unless-stopped
    labels:
      io.setup-server-tool.managed: "true"
    ports:
      - "${NGINX_HTTP_PORT}:80"
      - "${NGINX_HTTPS_PORT}:443"
    volumes:
      - ./conf.d:/etc/nginx/conf.d:ro
      - ./html:/usr/share/nginx/html:ro
      - ./certs:/etc/nginx/certs:ro
EOF

    as_root docker run --rm -v "$NGINX_DIR/conf.d:/etc/nginx/conf.d:ro" "$NGINX_IMAGE" nginx -t
    as_root docker compose -f "$NGINX_DIR/compose.yml" config --quiet
    as_root docker compose -f "$NGINX_DIR/compose.yml" up -d
    record_manifest nginx "$NGINX_IMAGE" docker
}

main() {
    require_supported_os
    ensure_base_packages
    resolve_managed_paths
    case "$NGINX_MODE" in
        apt|native|system) install_native_nginx ;;
        docker) install_docker_nginx ;;
        *) fail "Unknown NGINX_MODE=$NGINX_MODE. Use apt or docker." ;;
    esac
    print_success "Nginx setup completed in $NGINX_MODE mode."
}

main "$@"
