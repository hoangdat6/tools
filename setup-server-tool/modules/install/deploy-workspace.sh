#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

DEPLOY_TEMPLATE_DIR="${DEPLOY_TEMPLATE_DIR:-$SCRIPT_DIR/../../templates/deploy-workspace}"
SOURCES_ROOT="${SOURCES_ROOT:-}"

install_scaffold_file() {
    local relative_path="$1" mode="$2"
    local source_path="$DEPLOY_TEMPLATE_DIR/$relative_path"
    local destination="$INFRA_ROOT/$relative_path"

    [ -f "$source_path" ] || fail "Deploy template file not found: $source_path"
    if [ -e "$destination" ]; then
        print_warning "Keeping existing file: $destination"
        return 0
    fi
    as_target_user install -D -m "$mode" "$source_path" "$destination"
}

main() {
    require_supported_os
    resolve_managed_paths
    [ -n "$SOURCES_ROOT" ] || SOURCES_ROOT="$TARGET_HOME/sources"

    as_target_user mkdir -p "$INFRA_ROOT/env" "$SOURCES_ROOT/backend" "$SOURCES_ROOT/frontend"
    install_scaffold_file Makefile 0644
    install_scaffold_file env/deploy.env 0600
    install_scaffold_file env/.env.be 0600
    install_scaffold_file env/.env.fe 0600
    install_scaffold_file env/.gitignore 0644
    install_scaffold_file compose.yml.example 0644
    install_scaffold_file README.deploy.md 0644

    record_manifest deploy-workspace "1" "$TARGET_USER"
    print_success "Deploy workspace is ready at $INFRA_ROOT"
    print_info "Application sources belong under $SOURCES_ROOT"
}

main "$@"
