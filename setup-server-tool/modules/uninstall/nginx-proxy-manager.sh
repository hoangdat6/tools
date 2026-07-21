#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

NPM_DIR="${NPM_DIR:-}"
NPM_CONTAINER_NAME="${NPM_CONTAINER_NAME:-nginx-proxy-manager}"

main() {
    require_supported_os
    resolve_managed_paths
    [ -n "$NPM_DIR" ] || NPM_DIR="$INFRA_ROOT/nginx-proxy-manager"
    if has_cmd docker && docker ps -a --format '{{.Names}}' | grep -qx "$NPM_CONTAINER_NAME"; then
        as_root docker compose -f "$NPM_DIR/compose.yml" down || true
    fi
    remove_root_dir "$NPM_DIR"
    print_success "Removed Nginx Proxy Manager artifacts from $NPM_DIR"
}

main "$@"
