#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Communication & Productivity Tools..."

# Telegram
if snap list | grep -q telegram-desktop; then
    sudo snap remove telegram-desktop
    echo "✅ Telegram removed"
else
    echo "⏭️ Telegram not installed via snap"
fi

# Postman
if snap list | grep -q postman; then
    sudo snap remove postman
    echo "✅ Postman removed"
else
    echo "⏭️ Postman not installed via snap"
fi
