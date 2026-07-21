#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    require_supported_os
    resolve_managed_paths
    if [ -x /usr/local/aws-cli/v2/current/bin/aws ]; then
        as_root /usr/local/aws-cli/v2/current/bin/aws --version >/dev/null 2>&1 || true
    fi
    if [ -x /usr/local/aws-cli/v2/current/bin/uninstall ]; then
        as_root /usr/local/aws-cli/v2/current/bin/uninstall
    else
        remove_root_file /usr/local/bin/aws
        remove_root_dir /usr/local/aws-cli
    fi
    print_success "Removed AWS CLI"
}

main "$@"
