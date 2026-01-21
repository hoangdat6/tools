#!/usr/bin/env bash
set -e

echo "🖥️ Configuring GNOME Dock..."

# Auto-hide dock
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true

# Disable extend height (panel mode)
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false

# Position at bottom
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'

# Icon size
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 28

# Multi-monitor support
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true

echo "✅ GNOME Dock configured!"
echo "   - Position: Bottom"
echo "   - Auto-hide: Enabled"
echo "   - Icon size: 28px"
echo "   - Multi-monitor: Enabled"
