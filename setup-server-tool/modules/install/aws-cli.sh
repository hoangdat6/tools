#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSET_DIR="$SCRIPT_DIR/../../assets"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/common.sh"

AWS_CLI_VERSION="${AWS_CLI_VERSION:-2.36.4}"
AWS_KEY_FINGERPRINT="FB5DB77FD5C118B80511ADA8A6310ACC4672475C"
AWS_TMP_DIR=""

cleanup() {
    [ -z "$AWS_TMP_DIR" ] || rm -rf -- "$AWS_TMP_DIR"
}

trap cleanup EXIT

installed_version() {
    aws --version 2>&1 | sed -n 's#aws-cli/\([^ ]*\).*#\1#p'
}

main() {
    require_supported_os
    validate_architecture
    ensure_base_packages
    install_packages gnupg

    if has_cmd aws && [ "$(installed_version)" = "$AWS_CLI_VERSION" ] && ! is_true "$SETUP_FORCE"; then
        print_success "AWS CLI $AWS_CLI_VERSION is already installed."
        record_manifest aws-cli "$AWS_CLI_VERSION" system
        return 0
    fi

    local arch tmp_dir url fingerprint
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) fail "Unsupported architecture for AWS CLI: $(uname -m)" ;;
    esac

    AWS_TMP_DIR="$(mktemp -d)"
    tmp_dir="$AWS_TMP_DIR"
    url="https://awscli.amazonaws.com/awscli-exe-linux-${arch}-${AWS_CLI_VERSION}.zip"
    download_file "$url" "$tmp_dir/awscliv2.zip"
    download_file "${url}.sig" "$tmp_dir/awscliv2.sig"

    if is_true "$SETUP_DRY_RUN"; then
        run_cmd gpg --verify "$tmp_dir/awscliv2.sig" "$tmp_dir/awscliv2.zip"
        run_cmd unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
        as_root "$tmp_dir/aws/install" --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
        record_manifest aws-cli "$AWS_CLI_VERSION" system
        return 0
    fi

    mkdir -m 0700 "$tmp_dir/gnupg"
    gpg --batch --homedir "$tmp_dir/gnupg" --import "$ASSET_DIR/aws-cli-public-key.asc" >/dev/null 2>&1
    fingerprint="$(gpg --batch --homedir "$tmp_dir/gnupg" --status-fd 1 --verify \
        "$tmp_dir/awscliv2.sig" "$tmp_dir/awscliv2.zip" 2>/dev/null \
        | awk '$2 == "VALIDSIG" {print $3 " " $12; exit}')"
    case "$fingerprint" in
        *"$AWS_KEY_FINGERPRINT"*) ;;
        *) fail "AWS CLI signature verification failed." ;;
    esac
    print_success "Verified AWS CLI signature."

    unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
    as_root "$tmp_dir/aws/install" --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    aws --version
    record_manifest aws-cli "$AWS_CLI_VERSION" system
    print_success "AWS CLI setup completed."
}

main "$@"
