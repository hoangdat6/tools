#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling JetBrains Toolbox..."

# Kill running Toolbox
pkill -f jetbrains-toolbox 2>/dev/null || true

# Remove Toolbox directories
if [ -d ~/.local/share/JetBrains/Toolbox ]; then
    rm -rf ~/.local/share/JetBrains/Toolbox
    echo "Removed Toolbox data"
fi

# Remove desktop entries
rm -f ~/.local/share/applications/jetbrains-toolbox.desktop

# Remove from autostart
rm -f ~/.config/autostart/jetbrains-toolbox.desktop

echo "✅ JetBrains Toolbox removed!"
echo ""
echo "⚠️ Note: This only removes Toolbox itself."
echo "   IDEs installed via Toolbox are in: ~/.local/share/JetBrains/"
echo "   To remove all IDEs: rm -rf ~/.local/share/JetBrains"
