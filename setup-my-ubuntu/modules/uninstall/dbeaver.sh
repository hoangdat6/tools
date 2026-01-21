#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling DBeaver CE..."

if dpkg -l | grep -q "dbeaver-ce"; then
    sudo apt remove -y dbeaver-ce
    echo "✅ DBeaver CE removed"
else
    echo "⏭️ DBeaver CE not installed"
fi
