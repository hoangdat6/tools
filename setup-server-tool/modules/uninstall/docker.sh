#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    require_supported_os
    resolve_managed_paths
    if has_cmd systemctl && systemctl list-unit-files | grep -q '^docker\.service'; then
        as_root systemctl disable --now docker || true
    fi
    remove_root_file /usr/local/lib/docker/cli-plugins/docker-compose
    remove_root_file /etc/apt/sources.list.d/docker.list
    remove_root_file /etc/apt/keyrings/docker.gpg
    remove_root_file /etc/yum.repos.d/docker-ce.repo
    remove_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker || true
    print_success "Removed Docker packages managed by the tool"
}

main "$@"
