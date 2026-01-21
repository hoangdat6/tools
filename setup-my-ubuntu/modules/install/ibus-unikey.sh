#!/usr/bin/env bash
set -e

echo "🇻🇳 Installing IBus Unikey (Vietnamese Input)..."

# Detect distro
if [ -f /etc/debian_version ]; then
    echo "Detected Debian/Ubuntu"
    sudo apt update
    sudo apt install -y ibus ibus-unikey
elif [ -f /etc/arch-release ]; then
    echo "Detected Arch Linux"
    sudo pacman -S --noconfirm ibus ibus-unikey
elif [ -f /etc/fedora-release ]; then
    echo "Detected Fedora"
    sudo dnf install -y ibus ibus-unikey
else
    echo "❌ Unsupported distribution"
    exit 1
fi

echo "== Configuring IBUS environment =="

# Set IBUS environment variables
ENV_FILE="$HOME/.xprofile"

if ! grep -q "IBUS" "$ENV_FILE" 2>/dev/null; then
    cat >> "$ENV_FILE" <<'EOF'
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
EOF
    echo "Added IBUS environment variables to $ENV_FILE"
else
    echo "IBUS environment variables already configured"
fi

echo "== Restarting ibus =="
ibus-daemon -drx || true

echo "== Opening IBus Preferences =="
ibus-setup &

echo ""
echo "✅ IBus Unikey installed!"
echo ""
echo "📝 Quick Setup Guide:"
echo "   1. Log out and log back in for full effect"
echo "   2. In IBus Preferences → Input Method → Add → Vietnamese → Unikey"
echo "   3. Default toggle key: Ctrl+Shift or Super+Space"
