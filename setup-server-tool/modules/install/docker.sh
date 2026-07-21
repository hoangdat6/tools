#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION:-v5.1.4}"
DOCKER_GPG_FINGERPRINT="9DC858229FC7DD38854AE2D88D81803C0EBFCD88"

install_docker_apt() {
    local key_file keyring codename fingerprint
    install_packages gnupg
    key_file="$(mktemp)"
    keyring="$(mktemp)"
    download_file "https://download.docker.com/linux/${OS_ID}/gpg" "$key_file"
    if ! is_true "$SETUP_DRY_RUN"; then
        fingerprint="$(gpg --show-keys --with-colons "$key_file" | awk -F: '$1 == "fpr" {print $10; exit}')"
        [ "$fingerprint" = "$DOCKER_GPG_FINGERPRINT" ] || fail "Unexpected Docker repository signing key."
        gpg --dearmor --yes --output "$keyring" "$key_file"
        as_root install -D -m 0644 "$keyring" /etc/apt/keyrings/docker.gpg
    fi

    # shellcheck disable=SC1090
    codename="$(. "$OS_RELEASE_FILE" && printf '%s' "${VERSION_CODENAME:-}")"
    [ -n "$codename" ] || fail "Cannot determine distribution codename."
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/%s %s stable\n' \
        "$(dpkg --print-architecture)" "$OS_ID" "$codename" \
        | write_root_file /etc/apt/sources.list.d/docker.list
    package_update
    install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    rm -f "$key_file" "$keyring"
}

install_docker_amazon() {
    if [ "$OS_VERSION_ID" = "2" ] && has_cmd amazon-linux-extras; then
        as_root amazon-linux-extras install -y docker
    else
        install_packages docker
    fi
}

install_docker_rhel_family() {
    local repo_id
    case "$OS_ID" in
        fedora) repo_id="fedora" ;;
        rhel) repo_id="rhel" ;;
        rocky|almalinux|centos) repo_id="centos" ;;
        *) fail "No Docker CE repository mapping for $OS_ID" ;;
    esac

    # The literal is written to the repository file for yum/dnf expansion.
    # shellcheck disable=SC2016
    printf '%s\n' \
        '[docker-ce-stable]' \
        'name=Docker CE Stable - $basearch' \
        "baseurl=https://download.docker.com/linux/${repo_id}/\$releasever/\$basearch/stable" \
        'enabled=1' \
        'gpgcheck=1' \
        "gpgkey=https://download.docker.com/linux/${repo_id}/gpg" \
        | write_root_file /etc/yum.repos.d/docker-ce.repo
    package_update
    install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_compose_plugin_binary() {
    docker compose version >/dev/null 2>&1 && return 0

    local arch version plugin_dir tmp_dir binary checksums expected
    version="$DOCKER_COMPOSE_VERSION"
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) fail "Unsupported architecture for Docker Compose: $(uname -m)" ;;
    esac

    tmp_dir="$(mktemp -d)"
    binary="docker-compose-linux-${arch}"
    checksums="$tmp_dir/checksums.txt"
    download_file "https://github.com/docker/compose/releases/download/${version}/${binary}" "$tmp_dir/$binary"
    download_file "https://github.com/docker/compose/releases/download/${version}/checksums.txt" "$checksums"
    if ! is_true "$SETUP_DRY_RUN"; then
        expected="$(awk -v name="*$binary" '$2 == name || $2 == substr(name, 2) {print $1}' "$checksums")"
        [ -n "$expected" ] || fail "Checksum for $binary was not found."
        verify_sha256 "$tmp_dir/$binary" "$expected"
        plugin_dir="/usr/local/lib/docker/cli-plugins"
        as_root install -D -m 0755 "$tmp_dir/$binary" "$plugin_dir/docker-compose"
    fi
    rm -rf "$tmp_dir"
}

main() {
    require_supported_os
    validate_architecture
    ensure_base_packages
    resolve_managed_paths

    if has_cmd docker && docker compose version >/dev/null 2>&1 && ! is_true "$SETUP_FORCE"; then
        print_success "Docker and Docker Compose are already installed."
    else
        case "$OS_ID" in
            ubuntu|debian) install_docker_apt ;;
            amzn|amazon) install_docker_amazon ;;
            rhel|rocky|almalinux|centos|fedora) install_docker_rhel_family ;;
            *) fail "Docker installer does not support $OS_PRETTY_NAME" ;;
        esac
    fi

    enable_service docker
    install_compose_plugin_binary

    resolve_target_user
    if [ "$TARGET_USER" != "root" ] && ! id -nG "$TARGET_USER" | grep -qw docker; then
        as_root usermod -aG docker "$TARGET_USER"
        print_warning "Added $TARGET_USER to docker group. Re-login or run 'newgrp docker' before using docker without sudo in the current shell."
    fi
    as_target_user mkdir -p "$TARGET_HOME/.docker"

    if is_true "$SETUP_DRY_RUN"; then
        record_manifest docker planned system
    else
        docker --version
        docker compose version
        record_manifest docker "$(docker --version | awk '{gsub(/,/, "", $3); print $3}')" system
    fi
    print_success "Docker setup completed."
}

main "$@"
