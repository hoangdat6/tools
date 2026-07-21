#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$TEST_DIR/.." && pwd)"

command -v docker >/dev/null 2>&1 || {
    printf 'Docker is required for the OS matrix.\n' >&2
    exit 1
}

run_case() {
    local image="$1" expected_id="$2" expected_manager="$3" result
    result="$(docker run --rm -v "$TOOL_DIR:/tool:ro" "$image" bash -c \
        'SETUP_DRY_RUN=true SETUP_LOG_INITIALIZED=true source /tool/lib/common.sh; detect_os; printf "%s:%s" "$OS_ID" "$PKG_MANAGER"')"
    if [ "$result" != "$expected_id:$expected_manager" ]; then
        printf 'FAIL %-28s expected=%s:%s actual=%s\n' \
            "$image" "$expected_id" "$expected_manager" "$result" >&2
        exit 1
    fi
    printf 'PASS %-28s %s\n' "$image" "$result"
}

run_case ubuntu:20.04 ubuntu apt
run_case ubuntu:24.04 ubuntu apt
run_case debian:12 debian apt
run_case amazonlinux:2 amzn yum
run_case amazonlinux:2023 amzn dnf
