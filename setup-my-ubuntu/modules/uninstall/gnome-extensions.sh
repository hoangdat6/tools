#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling GNOME Extensions..."

# List installed extensions
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"

if [ -d "$EXTENSIONS_DIR" ]; then
    echo "Found extensions in $EXTENSIONS_DIR:"
    ls -1 "$EXTENSIONS_DIR" 2>/dev/null || true
    echo ""
    
    read -p "Remove all user-installed GNOME extensions? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Disable extensions first
        for ext in "$EXTENSIONS_DIR"/*/; do
            ext_name=$(basename "$ext")
            gnome-extensions disable "$ext_name" 2>/dev/null || true
        done
        
        rm -rf "$EXTENSIONS_DIR"
        echo "Removed all extensions"
    fi
fi

# Ask about removing packages
read -p "Remove GNOME extension packages (extension-manager, tweaks, etc.)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt remove -y \
        gnome-shell-extension-manager \
        gnome-tweaks \
        2>/dev/null || true
    sudo apt autoremove -y
    echo "Removed packages"
fi

echo ""
echo "✅ GNOME Extensions removed!"
echo "📝 Note: Restart GNOME Shell (Alt+F2, type 'r') or log out/in"
