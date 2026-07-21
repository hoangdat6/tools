#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

strip_nvm_snippet() {
    local profile="$1" tmp_file
    [ -f "$profile" ] || return 0
    tmp_file="$(mktemp)"
    awk '
        BEGIN {skip = 0}
        /^# setup-server-tool: nvm$/ {skip = 1; next}
        skip == 1 && /^export NVM_DIR=\"\$HOME\/\.nvm\"$/ {next}
        skip == 1 && /^\[ -s \"\$NVM_DIR\/nvm\.sh\" \] && \. \"\$NVM_DIR\/nvm\.sh\"$/ {next}
        skip == 1 && /^\[ -s \"\$NVM_DIR\/bash_completion\" \] && \. \"\$NVM_DIR\/bash_completion\"$/ {skip = 0; next}
        {print}
    ' "$profile" > "$tmp_file"
    as_target_user bash -lc 'install -m 0644 "$1" "$2"' _ "$tmp_file" "$profile"
    rm -f "$tmp_file"
}

main() {
    require_supported_os
    resolve_managed_paths
    remove_target_dir "$TARGET_HOME/.nvm"
    strip_nvm_snippet "$TARGET_HOME/.bashrc"
    strip_nvm_snippet "$TARGET_HOME/.zshrc"
    print_success "Removed NVM and Node.js environment for $TARGET_USER"
}

main "$@"
