#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

SWAP_FILE="${SWAP_FILE:-/swapfile}"

main() {
    require_supported_os
    resolve_managed_paths
    remove_root_file /etc/logrotate.d/setup-server-tool
    if swapon --show=NAME --noheadings 2>/dev/null | grep -Fqx "$SWAP_FILE"; then
        as_root swapoff "$SWAP_FILE" || true
        remove_root_line "$SWAP_FILE none swap sw 0 0" /etc/fstab
        remove_root_file "$SWAP_FILE"
    fi
    print_warning "Timezone and hostname changes are not reverted automatically."
    print_success "Removed managed baseline artifacts"
}

main "$@"
