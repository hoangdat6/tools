#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

NGINX_DIR="${NGINX_DIR:-}"
NGINX_CONTAINER_NAME="${NGINX_CONTAINER_NAME:-setup-server-nginx}"

remove_native_nginx() {
    if has_cmd nginx || package_is_installed nginx; then
        remove_packages nginx || true
    fi
}

remove_docker_nginx() {
    [ -n "$NGINX_DIR" ] || NGINX_DIR="$INFRA_ROOT/nginx"
    if has_cmd docker && docker ps -a --format '{{.Names}}' | grep -qx "$NGINX_CONTAINER_NAME"; then
        as_root docker compose -f "$NGINX_DIR/compose.yml" down || true
    fi
    remove_root_dir "$NGINX_DIR"
}

main() {
    require_supported_os
    resolve_managed_paths
    remove_docker_nginx
    remove_native_nginx
    print_success "Removed managed Nginx deployment artifacts"
}

main "$@"
