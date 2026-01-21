#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Antigravity..."

if dpkg -l | grep -q antigravity; then
    sudo apt remove -y antigravity
    sudo rm -f /etc/apt/sources.list.d/antigravity.list
    sudo rm -f /etc/apt/keyrings/antigravity-repo-key.gpg
    sudo apt autoremove -y
    echo "✅ Antigravity removed"
else
    echo "⏭️ Antigravity not installed, skipping"
fi
