#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling VS Code..."

if dpkg -l | grep -q "^ii.*code "; then
    sudo apt remove -y code
    sudo rm -f /etc/apt/sources.list.d/vscode.list
    sudo rm -f /usr/share/keyrings/mscode.gpg
    sudo apt autoremove -y
    echo "✅ VS Code removed"
else
    echo "⏭️ VS Code not installed, skipping"
fi
