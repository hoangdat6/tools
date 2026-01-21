#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Browsers..."

# Microsoft Edge
if dpkg -l | grep -q microsoft-edge-stable; then
    echo "➡ Removing Microsoft Edge..."
    sudo apt remove -y microsoft-edge-stable
    sudo rm -f /etc/apt/sources.list.d/microsoft-edge.list
    sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg
    echo "✅ Microsoft Edge removed"
else
    echo "⏭️ Microsoft Edge not installed, skipping"
fi

# Google Chrome
if dpkg -l | grep -q google-chrome-stable; then
    echo "➡ Removing Google Chrome..."
    sudo apt remove -y google-chrome-stable
    echo "✅ Google Chrome removed"
else
    echo "⏭️ Google Chrome not installed, skipping"
fi

sudo apt autoremove -y
echo "✅ Browsers uninstalled!"
