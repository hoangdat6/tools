#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

TEST_SES_SOURCE_DIR="${TEST_SES_SOURCE_DIR:-$SCRIPT_DIR/../../../test-ses}"
TEST_SES_TARGET_DIR="${TEST_SES_TARGET_DIR:-}"

test_ses_version() {
    sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$TEST_SES_SOURCE_DIR/package.json" | head -n 1
}

ensure_node_runtime() {
    if as_target_user_read bash -lc 'command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1'; then
        return 0
    fi

    print_info "Node.js is not available for $TARGET_USER; running the nodejs module first."
    bash "$SCRIPT_DIR/nodejs.sh"
}

sync_workspace() {
    local target_dir="$1" archive tmp_dir
    tmp_dir="$(mktemp -d)"
    archive="$tmp_dir/test-ses.tar"

    tar \
        --exclude='./node_modules' \
        --exclude='./.node' \
        --exclude='./.node_tmp' \
        -cf "$archive" -C "$TEST_SES_SOURCE_DIR" .

    as_root mkdir -p "$target_dir"
    as_root tar -xf "$archive" -C "$target_dir"
    as_root chown -R "$TARGET_USER:$(id -gn "$TARGET_USER")" "$target_dir"
    rm -rf "$tmp_dir"
}

install_dependencies() {
    local target_dir="$1"
    if [ -f "$target_dir/package-lock.json" ]; then
        as_target_user bash -lc 'cd "$1" && npm ci --no-fund --no-audit' _ "$target_dir"
    else
        as_target_user bash -lc 'cd "$1" && npm install --no-fund --no-audit' _ "$target_dir"
    fi
}

main() {
    require_supported_os
    ensure_base_packages
    resolve_managed_paths

    [ -d "$TEST_SES_SOURCE_DIR" ] || fail "test-ses source directory not found: $TEST_SES_SOURCE_DIR"
    [ -f "$TEST_SES_SOURCE_DIR/package.json" ] || fail "test-ses package.json not found: $TEST_SES_SOURCE_DIR/package.json"

    if [ -z "$TEST_SES_TARGET_DIR" ]; then
        TEST_SES_TARGET_DIR="$INFRA_ROOT/test-ses"
    fi
    export TEST_SES_TARGET_DIR

    ensure_node_runtime

    print_info "Deploying test-ses to $TEST_SES_TARGET_DIR"
    sync_workspace "$TEST_SES_TARGET_DIR"
    install_dependencies "$TEST_SES_TARGET_DIR"

    record_manifest test-ses "$(test_ses_version)" "$TARGET_USER"
    print_success "test-ses is ready at $TEST_SES_TARGET_DIR"
}

main "$@"
