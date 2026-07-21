#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

TEST_SES_TARGET_DIR="${TEST_SES_TARGET_DIR:-}"

main() {
    require_supported_os
    resolve_managed_paths
    [ -n "$TEST_SES_TARGET_DIR" ] || TEST_SES_TARGET_DIR="$INFRA_ROOT/test-ses"
    remove_target_dir "$TEST_SES_TARGET_DIR"
    print_success "Removed test-ses workspace from $TEST_SES_TARGET_DIR"
}

main "$@"
