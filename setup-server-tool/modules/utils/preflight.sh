#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

check_disk() {
    local available_mb
    available_mb="$(df -Pm / | awk 'NR==2 {print $4}')"
    if [ "$available_mb" -lt "$SETUP_MIN_DISK_MB" ]; then
        fail "Only ${available_mb}MB is free on /; ${SETUP_MIN_DISK_MB}MB is required."
    fi
    print_success "Disk space: ${available_mb}MB available"
}

check_dns() {
    if has_cmd getent && getent hosts github.com >/dev/null 2>&1; then
        print_success "DNS resolution works"
    elif is_true "$SETUP_DRY_RUN"; then
        print_warning "DNS could not be verified in dry-run environment"
    else
        fail "DNS resolution failed for github.com"
    fi
}

check_internet() {
    if ! has_cmd curl; then
        print_warning "curl is unavailable; HTTPS connectivity will be checked after base packages install."
        return 0
    fi
    if curl -fsSI --max-time 10 https://github.com >/dev/null 2>&1; then
        print_success "Outbound HTTPS connectivity works"
    elif is_true "$SETUP_DRY_RUN"; then
        print_warning "Outbound HTTPS connectivity could not be verified"
    else
        fail "Outbound HTTPS connectivity failed"
    fi
}

check_selinux() {
    if has_cmd getenforce; then
        print_info "SELinux mode: $(getenforce)"
    fi
}

check_time() {
    if has_cmd timedatectl; then
        local synced
        synced="$(timedatectl show -p NTPSynchronized --value 2>/dev/null || true)"
        if [ "$synced" = "yes" ]; then
            print_success "System clock is synchronized"
        else
            print_warning "System clock is not reported as synchronized"
        fi
    fi
}

main() {
    require_supported_os
    validate_architecture
    has_cmd systemctl || fail "systemd is required by this tool"
    check_disk
    check_dns
    check_internet
    check_time
    check_selinux
    has_cmd curl || print_warning "curl is not installed yet; installers will add it"
    has_cmd ss || print_warning "ss is unavailable; port conflict checks will be limited"
    print_success "Preflight checks passed for $OS_PRETTY_NAME"
}

main "$@"
