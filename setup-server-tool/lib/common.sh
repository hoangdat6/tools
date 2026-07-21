#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SETUP_TOOL_VERSION="${SETUP_TOOL_VERSION:-1.0.0}"
SETUP_DRY_RUN="${SETUP_DRY_RUN:-false}"
SETUP_ASSUME_YES="${SETUP_ASSUME_YES:-false}"
SETUP_NON_INTERACTIVE="${SETUP_NON_INTERACTIVE:-false}"
SETUP_FORCE="${SETUP_FORCE:-false}"
SETUP_RETRY_COUNT="${SETUP_RETRY_COUNT:-3}"
SETUP_MIN_DISK_MB="${SETUP_MIN_DISK_MB:-2048}"
SETUP_LOG_INITIALIZED="${SETUP_LOG_INITIALIZED:-false}"
SETUP_MANIFEST_FILE="${SETUP_MANIFEST_FILE:-/var/lib/setup-server-tool/manifest.tsv}"
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"
TARGET_USER="${TARGET_USER:-}"

if [ -z "${SETUP_LOG_FILE:-}" ]; then
    if [ "$(id -u)" -eq 0 ]; then
        SETUP_LOG_FILE="/var/log/setup-server-tool.log"
    else
        SETUP_LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/setup-server-tool/setup.log"
    fi
fi

OS_ID=""
OS_VERSION_ID=""
OS_PRETTY_NAME=""
PKG_MANAGER=""
TARGET_HOME=""

is_true() {
    case "${1:-false}" in
        1|true|TRUE|yes|YES|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

print_header() {
    printf '%b\n' "$CYAN"
    printf '%s\n' '╔════════════════════════════════════════════════════════════════════╗'
    printf '%s\n' '║                    SETUP SERVER TOOL                              ║'
    printf '%s\n' '╚════════════════════════════════════════════════════════════════════╝'
    printf '%b\n' "$NC"
}

print_success() { printf '%bOK  %s%b\n' "$GREEN" "$1" "$NC"; }
print_info() { printf '%b=>  %s%b\n' "$BLUE" "$1" "$NC"; }
print_warning() { printf '%b!!  %s%b\n' "$YELLOW" "$1" "$NC"; }
print_error() { printf '%bERR %s%b\n' "$RED" "$1" "$NC" >&2; }

fail() {
    print_error "$1"
    exit 1
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

format_command() {
    printf '%q ' "$@"
    printf '\n'
}

run_cmd() {
    if is_true "$SETUP_DRY_RUN"; then
        printf '[dry-run] '
        format_command "$@"
        return 0
    fi
    "$@"
}

need_root() {
    if [ "$(id -u)" -ne 0 ] && ! has_cmd sudo; then
        fail "This action needs root privileges. Install sudo or run as root."
    fi
}

as_root() {
    if is_true "$SETUP_DRY_RUN"; then
        if [ "$(id -u)" -eq 0 ]; then
            run_cmd "$@"
        else
            run_cmd sudo "$@"
        fi
        return 0
    fi

    need_root
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

init_runtime() {
    is_true "$SETUP_LOG_INITIALIZED" && return 0
    SETUP_LOG_INITIALIZED=true
    export SETUP_LOG_INITIALIZED SETUP_LOG_FILE

    if is_true "$SETUP_DRY_RUN"; then
        print_info "Dry-run enabled; no system changes will be made."
        return 0
    fi

    local log_dir
    log_dir="$(dirname "$SETUP_LOG_FILE")"
    mkdir -p "$log_dir"
    touch "$SETUP_LOG_FILE"
    exec > >(tee -a "$SETUP_LOG_FILE") 2>&1
    print_info "Log file: $SETUP_LOG_FILE"
}

retry() {
    local attempt=1 delay=2
    while true; do
        if "$@"; then
            return 0
        fi
        if [ "$attempt" -ge "$SETUP_RETRY_COUNT" ]; then
            return 1
        fi
        print_warning "Command failed (attempt $attempt/$SETUP_RETRY_COUNT); retrying in ${delay}s."
        sleep "$delay"
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done
}

download_file() {
    local url="$1" output="$2"
    local -a curl_args=(-fL --connect-timeout 15 --retry "$SETUP_RETRY_COUNT")
    if curl_supports_retry_all_errors; then
        curl_args+=(--retry-all-errors)
    fi
    if is_true "$SETUP_DRY_RUN"; then
        run_cmd curl "${curl_args[@]}" "$url" -o "$output"
        return 0
    fi
    retry curl "${curl_args[@]}" "$url" -o "$output"
}

curl_supports_retry_all_errors() {
    curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'
}

verify_sha256() {
    local file="$1" expected="$2" actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    [ "$actual" = "$expected" ] || fail "SHA256 mismatch for $file: expected $expected, got $actual"
    print_success "Verified SHA256 for $(basename "$file")"
}

confirm() {
    local prompt="$1" answer
    is_true "$SETUP_DRY_RUN" && return 0
    is_true "$SETUP_ASSUME_YES" && return 0
    if is_true "$SETUP_NON_INTERACTIVE"; then
        fail "$prompt Use --yes to approve this operation."
    fi
    read -r -p "$prompt [y/N] " answer
    is_true "$answer"
}

detect_os() {
    [ -r "$OS_RELEASE_FILE" ] || fail "$OS_RELEASE_FILE not found; cannot detect OS."

    # shellcheck disable=SC1090
    . "$OS_RELEASE_FILE"
    OS_ID="${ID:-unknown}"
    OS_VERSION_ID="${VERSION_ID:-unknown}"
    OS_PRETTY_NAME="${PRETTY_NAME:-$OS_ID $OS_VERSION_ID}"

    case "$OS_ID" in
        ubuntu|debian) PKG_MANAGER="apt" ;;
        amzn|amazon)
            case "$OS_VERSION_ID" in
                2023*) PKG_MANAGER="dnf" ;;
                2) PKG_MANAGER="yum" ;;
                *) fail "Unsupported Amazon Linux release: $OS_PRETTY_NAME" ;;
            esac
            ;;
        rhel|rocky|almalinux|centos|fedora)
            if has_cmd dnf; then PKG_MANAGER="dnf"; else PKG_MANAGER="yum"; fi
            ;;
        *) fail "Unsupported OS: $OS_PRETTY_NAME" ;;
    esac
}

require_supported_os() {
    init_runtime
    detect_os
    print_info "Detected OS: $OS_PRETTY_NAME ($PKG_MANAGER)"
}

package_update() {
    case "$PKG_MANAGER" in
        apt) apt_package_update ;;
        dnf) as_root dnf makecache -y ;;
        yum) as_root yum makecache -y ;;
        *) fail "Unsupported package manager: $PKG_MANAGER" ;;
    esac
}

apt_package_update() {
    local update_log field normalized
    local -a changed_fields=() allow_options=()
    update_log="$(mktemp)"

    if as_root apt-get update 2>&1 | tee "$update_log"; then
        rm -f "$update_log"
        return 0
    fi

    mapfile -t changed_fields < <(
        sed -n "s/.*changed its '\([^']*\)' value.*/\1/p" "$update_log" | sort -u
    )
    if [ "${#changed_fields[@]}" -eq 0 ]; then
        rm -f "$update_log"
        fail "APT package index update failed. Review the repository errors above."
    fi

    for field in "${changed_fields[@]}"; do
        normalized="$(printf '%s' "$field" | tr '[:upper:]' '[:lower:]')"
        case "$normalized" in
            origin|label|codename|suite|version|defaultpin)
                allow_options+=("--allow-releaseinfo-change-$normalized")
                ;;
            *)
                rm -f "$update_log"
                fail "APT repository changed unsupported release field: $field"
                ;;
        esac
    done

    print_warning "APT repository metadata changed: ${changed_fields[*]}"
    if ! confirm "Accept only the detected APT release metadata changes?"; then
        rm -f "$update_log"
        fail "APT repository metadata change was not accepted."
    fi
    rm -f "$update_log"
    as_root apt-get update "${allow_options[@]}"
}

package_is_installed() {
    local package="$1"
    case "$PKG_MANAGER" in
        apt)
            dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii'
            ;;
        dnf|yum)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

install_packages() {
    [ "$#" -gt 0 ] || return 0
    case "$PKG_MANAGER" in
        apt) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        dnf) as_root dnf install -y "$@" ;;
        yum) as_root yum install -y "$@" ;;
        *) fail "Unsupported package manager: $PKG_MANAGER" ;;
    esac
}

enable_service() {
    local service="$1"
    has_cmd systemctl || fail "systemctl is required to manage $service"
    as_root systemctl enable --now "$service"
}

reload_service() {
    local service="$1"
    has_cmd systemctl || return 0
    as_root systemctl reload "$service"
}

ensure_base_packages() {
    local package
    local -a required=(ca-certificates curl tar unzip gzip) missing=()
    for package in "${required[@]}"; do
        package_is_installed "$package" || missing+=("$package")
    done
    if [ "${#missing[@]}" -eq 0 ]; then
        print_success "Base packages are already installed."
        return 0
    fi
    print_info "Missing base packages: ${missing[*]}"
    package_update
    install_packages "${missing[@]}"
}

ensure_docker_ready() {
    if ! has_cmd docker; then
        is_true "$SETUP_DRY_RUN" && print_info "Docker would be required by this module." && return 0
        fail "Docker is not installed. Run: ./setup.sh docker"
    fi
    if ! docker info >/dev/null 2>&1; then
        as_root docker info >/dev/null 2>&1 || fail "Docker daemon is not reachable."
    fi
}

resolve_target_user() {
    if [ -z "$TARGET_USER" ]; then
        if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
            TARGET_USER="$SUDO_USER"
        else
            TARGET_USER="$(id -un)"
        fi
    fi
    id "$TARGET_USER" >/dev/null 2>&1 || fail "Target user does not exist: $TARGET_USER"
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
    [ -n "$TARGET_HOME" ] || fail "Cannot determine home directory for $TARGET_USER"
    export TARGET_USER TARGET_HOME
}

as_target_user() {
    resolve_target_user
    if [ "$(id -un)" = "$TARGET_USER" ]; then
        run_cmd env HOME="$TARGET_HOME" "$@"
    elif [ "$(id -u)" -eq 0 ]; then
        run_cmd runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" "$@"
    else
        run_cmd sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" "$@"
    fi
}

as_target_user_read() {
    resolve_target_user
    if [ "$(id -un)" = "$TARGET_USER" ]; then
        env HOME="$TARGET_HOME" "$@"
    elif [ "$(id -u)" -eq 0 ]; then
        runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" "$@"
    else
        sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" "$@"
    fi
}

write_root_file() {
    local destination="$1" mode="${2:-0644}" tmp_file
    tmp_file="$(mktemp)"
    cat > "$tmp_file"
    as_root install -D -m "$mode" "$tmp_file" "$destination"
    rm -f "$tmp_file"
}

append_root_line() {
    local line="$1" destination="$2" tmp_file
    if [ -f "$destination" ] && as_root grep -Fqx "$line" "$destination"; then
        return 0
    fi
    tmp_file="$(mktemp)"
    [ ! -f "$destination" ] || as_root cp "$destination" "$tmp_file"
    printf '%s\n' "$line" >> "$tmp_file"
    as_root install -D -m 0644 "$tmp_file" "$destination"
    rm -f "$tmp_file"
}

backup_file() {
    local path="$1" backup
    [ -e "$path" ] || return 0
    backup="${path}.bak.$(date '+%Y%m%d%H%M%S')"
    as_root cp -a "$path" "$backup"
    print_info "Backup created: $backup"
}

port_in_use() {
    local port="$1"
    if has_cmd ss; then
        ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)$port$"
    elif has_cmd lsof; then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    else
        return 1
    fi
}

assert_ports_available() {
    local owner="$1" port
    shift
    for port in "$@"; do
        if port_in_use "$port"; then
            fail "Port $port is already in use; cannot start $owner."
        fi
    done
}

validate_architecture() {
    case "$(uname -m)" in
        x86_64|amd64|aarch64|arm64) return 0 ;;
        *) fail "Unsupported architecture: $(uname -m)" ;;
    esac
}

record_manifest() {
    local component="$1" version="$2" mode="${3:-system}" line
    detect_os
    line="$(timestamp)\t${component}\t${version}\t${mode}\t${OS_ID}\t${OS_VERSION_ID}"
    if is_true "$SETUP_DRY_RUN"; then
        print_info "Manifest: $line"
        return 0
    fi

    local tmp_file
    tmp_file="$(mktemp)"
    printf '%b\n' "$line" > "$tmp_file"
    as_root mkdir -p "$(dirname "$SETUP_MANIFEST_FILE")"
    if [ "$(id -u)" -eq 0 ]; then
        cat "$tmp_file" >> "$SETUP_MANIFEST_FILE"
    else
        as_root tee -a "$SETUP_MANIFEST_FILE" < "$tmp_file" >/dev/null
    fi
    rm -f "$tmp_file"
}
