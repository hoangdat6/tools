#!/usr/bin/env bash
# Test doubles are invoked indirectly by functions sourced from common.sh.
# shellcheck disable=SC2034,SC2329
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$TEST_DIR/.." && pwd)"
PASS=0

ok() {
    PASS=$((PASS + 1))
    printf 'ok %d - %s\n' "$PASS" "$1"
}

assert_eq() {
    local expected="$1" actual="$2" label="$3"
    [ "$expected" = "$actual" ] || {
        printf 'not ok - %s: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    }
    ok "$label"
}

SETUP_DRY_RUN=true
# shellcheck disable=SC2034
SETUP_LOG_INITIALIZED=true
# shellcheck disable=SC1091
source "$TOOL_DIR/lib/common.sh"

test_os() {
    local fixture="$1" expected_id="$2" expected_manager="$3"
    OS_RELEASE_FILE="$TEST_DIR/fixtures/$fixture"
    detect_os
    assert_eq "$expected_id" "$OS_ID" "detect $fixture id"
    assert_eq "$expected_manager" "$PKG_MANAGER" "detect $fixture package manager"
}

test_os ubuntu-24.04 ubuntu apt
test_os ubuntu-20.04 ubuntu apt
test_os debian-12 debian apt
test_os amazon-linux-2 amzn yum
test_os amazon-linux-2023 amzn dnf

# shellcheck disable=SC2034
if (OS_RELEASE_FILE="$TEST_DIR/fixtures/unsupported"; detect_os) >/dev/null 2>&1; then
    printf 'not ok - unsupported OS should fail\n' >&2
    exit 1
fi
ok "unsupported OS fails"

# shellcheck disable=SC1091
source "$TOOL_DIR/setup.sh"
ACTION=""
MODULE_QUEUE=()
SETUP_DRY_RUN=false
NODE_VERSIONS=22
TARGET_USER=""
parse_args --all --target-user deploy --dry-run --node-versions "20 22"
assert_eq all "$ACTION" "profile parsing is order independent"
assert_eq true "$SETUP_DRY_RUN" "dry-run parsing"
assert_eq deploy "$TARGET_USER" "target-user parsing"
assert_eq "20 22" "$NODE_VERSIONS" "node version parsing"

# shellcheck disable=SC2034
if (ACTION=""; MODULE_QUEUE=(); parse_args --all --web) >/dev/null 2>&1; then
    printf 'not ok - conflicting profiles should fail\n' >&2
    exit 1
fi
ok "conflicting profiles fail"

if declare -f install_web_stack | grep -q 'run_module certbot'; then
    printf 'not ok - web stack must not install standalone Certbot\n' >&2
    exit 1
fi
ok "web stack delegates certificates to Nginx Proxy Manager"

if grep -R ':latest' "$TOOL_DIR/modules" >/dev/null 2>&1; then
    printf 'not ok - installer image tags must be pinned\n' >&2
    exit 1
fi
ok "container image tags are pinned"

if grep -R -E 'curl .*[|][[:space:]]*(ba)?sh' "$TOOL_DIR/modules" >/dev/null 2>&1; then
    printf 'not ok - remote scripts must not be piped to a shell\n' >&2
    exit 1
fi
ok "remote scripts are not piped to a shell"

bash -n "$TOOL_DIR/setup.sh" "$TOOL_DIR/lib/common.sh" \
    "$TOOL_DIR"/modules/install/*.sh "$TOOL_DIR"/modules/utils/*.sh
ok "all Bash files pass syntax validation"

aws_dry_output="$(TARGET_USER="$(id -un)" "$TOOL_DIR/setup.sh" --dry-run aws-cli 2>&1)"
if grep -q 'unbound variable' <<<"$aws_dry_output"; then
    printf 'not ok - AWS CLI dry-run cleanup emitted an unbound-variable error\n' >&2
    exit 1
fi
ok "AWS CLI dry-run cleanup is clean"

(
    package_is_installed() { return 0; }
    package_update() { fail "package_update must not run when base packages exist"; }
    install_packages() { fail "install_packages must not run when base packages exist"; }
    ensure_base_packages >/dev/null
)
ok "base packages skip package-manager work when already installed"

apt_calls="$(mktemp)"
(
    SETUP_DRY_RUN=false
    SETUP_ASSUME_YES=true
    PKG_MANAGER=apt
    as_root() {
        printf '%s\n' "$*" >> "$apt_calls"
        if [ "$*" = "apt-get update" ]; then
            printf '%s\n' "E: Repository 'test' changed its 'Label' value from 'old' to 'new'"
            return 100
        fi
        return 0
    }
    apt_package_update >/dev/null
)
if ! grep -Fqx 'apt-get update --allow-releaseinfo-change-label' "$apt_calls"; then
    printf 'not ok - APT metadata retry must allow only the changed Label field\n' >&2
    rm -f "$apt_calls"
    exit 1
fi
rm -f "$apt_calls"
ok "APT metadata retry is scoped to the changed field"

old_curl_output="$(
    SETUP_DRY_RUN=true
    curl_supports_retry_all_errors() { return 1; }
    download_file https://example.com/archive /tmp/setup-server-tool-test-download
)"
if grep -q -- '--retry-all-errors' <<<"$old_curl_output"; then
    printf 'not ok - old curl fallback must omit --retry-all-errors\n' >&2
    exit 1
fi
ok "old curl fallback omits unsupported retry option"

new_curl_output="$(
    SETUP_DRY_RUN=true
    curl_supports_retry_all_errors() { return 0; }
    download_file https://example.com/archive /tmp/setup-server-tool-test-download
)"
if ! grep -q -- '--retry-all-errors' <<<"$new_curl_output"; then
    printf 'not ok - modern curl should use --retry-all-errors\n' >&2
    exit 1
fi
ok "modern curl enables retry-all-errors"

if command -v gpg >/dev/null 2>&1; then
    fingerprint="$(gpg --show-keys --with-colons "$TOOL_DIR/assets/aws-cli-public-key.asc" \
        | awk -F: '$1 == "fpr" {print $10; exit}')"
    assert_eq FB5DB77FD5C118B80511ADA8A6310ACC4672475C "$fingerprint" "AWS CLI signing key fingerprint"
fi

printf '1..%d\n' "$PASS"
