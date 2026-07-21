#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

DEPLOY_TEMPLATE_DIR="${DEPLOY_TEMPLATE_DIR:-$SCRIPT_DIR/../../templates/deploy-workspace}"

remove_if_unmodified() {
    local relative_path="$1"
    local template_path="$DEPLOY_TEMPLATE_DIR/$relative_path"
    local installed_path="$INFRA_ROOT/$relative_path"

    [ -f "$installed_path" ] || return 0
    if [ -f "$template_path" ] && cmp -s "$template_path" "$installed_path"; then
        remove_target_file "$installed_path"
    else
        print_warning "Keeping modified file: $installed_path"
    fi
}

main() {
    require_supported_os
    resolve_managed_paths

    remove_if_unmodified Makefile
    remove_if_unmodified env/deploy.env
    remove_if_unmodified env/.env.be
    remove_if_unmodified env/.env.fe
    remove_if_unmodified env/.gitignore
    remove_if_unmodified compose.yml.example
    remove_if_unmodified README.deploy.md

    if ! is_true "$SETUP_DRY_RUN"; then
        as_target_user rmdir "$INFRA_ROOT/env" 2>/dev/null || true
    fi
    print_warning "Source directories, app Compose files, and modified environment files were preserved."
}

main "$@"
