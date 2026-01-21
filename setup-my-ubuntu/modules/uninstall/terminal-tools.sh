#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Terminal Tools..."

read -p "This will remove ripgrep, jq, yq, htop, flameshot, bat, tree, tldr. Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Remove apt packages
sudo apt remove -y ripgrep jq htop flameshot bat tree tldr 2>/dev/null || true

# Remove yq (manually installed)
sudo rm -f /usr/local/bin/yq

# Remove bat symlink
rm -f ~/.local/bin/bat

sudo apt autoremove -y

echo ""
echo "✅ Terminal Tools removed!"
