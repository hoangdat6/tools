#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

NVM_VERSION="${NVM_VERSION:-v0.40.6}"
NVM_SHA256="${NVM_SHA256:-17302cad7feedb1ad33ba738f93d2176a90970724f22de119603624fcbdec1a2}"
NODE_VERSIONS="${NODE_VERSIONS:-22}"
NODE_DEFAULT_VERSION="${NODE_DEFAULT_VERSION:-}"

validate_versions() {
    local version
    for version in $NODE_VERSIONS; do
        [[ "$version" =~ ^[A-Za-z0-9._/*-]+$ ]] || fail "Invalid Node.js version: $version"
    done
}

install_nvm() {
    local tmp_dir archive source_dir
    tmp_dir="$(mktemp -d)"
    archive="$tmp_dir/nvm.tar.gz"
    download_file "https://github.com/nvm-sh/nvm/archive/refs/tags/${NVM_VERSION}.tar.gz" "$archive"
    if is_true "$SETUP_DRY_RUN"; then
        run_cmd tar -xzf "$archive" -C "$tmp_dir"
        as_target_user mkdir -p "$NVM_DIR"
        rm -rf "$tmp_dir"
        return 0
    fi

    verify_sha256 "$archive" "$NVM_SHA256"
    tar -xzf "$archive" -C "$tmp_dir"
    source_dir="$tmp_dir/nvm-${NVM_VERSION#v}"
    as_target_user mkdir -p "$NVM_DIR"
    # Positional parameters are expanded by the target user's shell.
    # shellcheck disable=SC2016
    as_target_user bash -c 'cp -a "$1"/. "$2"/' _ "$source_dir" "$NVM_DIR"
    rm -rf "$tmp_dir"
}

configure_shell_profile() {
    local profile="$1" snippet
    if [ -f "$profile" ] && grep -q 'setup-server-tool: nvm' "$profile" 2>/dev/null; then
        return 0
    fi
    snippet="$(mktemp)"
    cat > "$snippet" <<'EOF'

# setup-server-tool: nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
EOF
    # shellcheck disable=SC2016
    as_target_user bash -c 'touch "$1"; cat "$2" >> "$1"' _ "$profile" "$snippet"
    rm -f "$snippet"
    print_success "Added NVM config to $profile"
}

nvm_run() {
    # shellcheck disable=SC2016
    as_target_user bash -c 'export NVM_DIR="$1"; shift; . "$NVM_DIR/nvm.sh"; nvm "$@"' _ "$NVM_DIR" "$@"
}

main() {
    require_supported_os
    ensure_base_packages
    resolve_target_user
    NVM_DIR="${NVM_DIR:-$TARGET_HOME/.nvm}"
    export NVM_DIR
    validate_versions

    local current_nvm=""
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        current_nvm="$(nvm_run --version 2>/dev/null || true)"
    fi
    if [ "$current_nvm" != "${NVM_VERSION#v}" ] || is_true "$SETUP_FORCE"; then
        install_nvm
    else
        print_success "NVM $NVM_VERSION is already installed for $TARGET_USER."
    fi

    local version default_version
    for version in $NODE_VERSIONS; do
        print_info "Installing Node.js $version for $TARGET_USER"
        nvm_run install "$version"
    done
    default_version="${NODE_DEFAULT_VERSION:-$(printf '%s\n' "$NODE_VERSIONS" | awk '{print $NF}')}"
    nvm_run alias default "$default_version"

    configure_shell_profile "$TARGET_HOME/.bashrc"
    [ -f "$TARGET_HOME/.zshrc" ] && configure_shell_profile "$TARGET_HOME/.zshrc"

    record_manifest nvm "${NVM_VERSION#v}" "$TARGET_USER"
    record_manifest nodejs "$default_version" "$TARGET_USER"
    print_success "Node.js setup completed for $TARGET_USER."
}

main "$@"
