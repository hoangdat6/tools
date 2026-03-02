#!/bin/bash
set -e

#====================================================
# Script tự động tải Node.js portable và chạy test SES
# Chỉ cần copy folder này lên server, rồi chạy:
#   chmod +x run.sh && ./run.sh
#
# Tùy chọn:
#   ./run.sh                  - Gửi mail test SES
#   ./run.sh --install-only   - Chỉ tải Node.js + cài deps
#   ./run.sh --cleanup        - Xóa Node.js portable đã tải
#====================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NODE_VERSION="22.14.0"
NODE_DIR="$SCRIPT_DIR/.node"

# Detect architecture
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "x64" ;;
        aarch64) echo "arm64" ;;
        armv7l)  echo "armv7l" ;;
        *)
            echo "❌ Architecture không được hỗ trợ: $arch" >&2
            exit 1
            ;;
    esac
}

# Download và extract Node.js
install_node() {
    if [ -f "$NODE_DIR/bin/node" ]; then
        echo "✅ Node.js đã có sẵn tại $NODE_DIR"
        return
    fi

    local arch
    arch=$(detect_arch)
    local filename="node-v${NODE_VERSION}-linux-${arch}"
    local url="https://nodejs.org/dist/v${NODE_VERSION}/${filename}.tar.xz"

    echo "📦 Đang tải Node.js v${NODE_VERSION} (${arch})..."
    echo "   URL: $url"

    # Tạo thư mục tạm
    local tmp_dir="$SCRIPT_DIR/.node_tmp"
    mkdir -p "$tmp_dir"

    # Download
    if command -v curl &>/dev/null; then
        curl -fSL --progress-bar "$url" -o "$tmp_dir/${filename}.tar.xz"
    elif command -v wget &>/dev/null; then
        wget -q --show-progress "$url" -O "$tmp_dir/${filename}.tar.xz"
    else
        echo "❌ Cần curl hoặc wget để tải Node.js!" >&2
        exit 1
    fi

    echo "📂 Đang giải nén..."
    tar -xJf "$tmp_dir/${filename}.tar.xz" -C "$tmp_dir"

    # Move vào vị trí
    mv "$tmp_dir/${filename}" "$NODE_DIR"

    # Cleanup
    rm -rf "$tmp_dir"

    echo "✅ Đã cài Node.js v${NODE_VERSION} tại $NODE_DIR"
}

# Cài dependencies
install_deps() {
    if [ -d "$SCRIPT_DIR/node_modules" ]; then
        echo "✅ Dependencies đã được cài"
        return
    fi

    echo "📦 Đang cài dependencies (npm install)..."
    cd "$SCRIPT_DIR"
    "$NODE_DIR/bin/node" "$NODE_DIR/bin/npm" install --no-fund --no-audit
    echo "✅ Đã cài dependencies xong"
}

# Chạy script gửi mail
run_test() {
    echo ""
    echo "🚀 Đang gửi mail test SES..."
    echo "─────────────────────────────"
    cd "$SCRIPT_DIR"
    "$NODE_DIR/bin/node" sendMail.js
    echo "─────────────────────────────"
    echo "✅ Hoàn thành!"
}

# Cleanup
cleanup() {
    echo "🧹 Đang xóa Node.js portable..."
    rm -rf "$NODE_DIR"
    rm -rf "$SCRIPT_DIR/node_modules"
    echo "✅ Đã xóa sạch"
}

# Show info
show_info() {
    echo "════════════════════════════════════"
    echo "  🧪 Test AWS SES - Auto Setup"
    echo "════════════════════════════════════"
    echo ""
}

# ─── Main ──────────────────────────────────
show_info

case "${1:-}" in
    --cleanup)
        cleanup
        ;;
    --install-only)
        install_node
        install_deps
        echo ""
        echo "💡 Chạy './run.sh' để gửi mail test"
        ;;
    *)
        install_node
        install_deps
        run_test
        ;;
esac
