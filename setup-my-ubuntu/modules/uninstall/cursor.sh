#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Cursor..."

LOCAL_BIN="$HOME/.local/bin"
APPIMAGE_DIRS=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")

# Remove cursor script
if [ -f "$LOCAL_BIN/cursor" ]; then
    rm -f "$LOCAL_BIN/cursor"
    echo "Removed cursor script"
fi

# Remove AppImage
for dir in "${APPIMAGE_DIRS[@]}"; do
    if [ -f "$dir/cursor.appimage" ]; then
        rm -f "$dir/cursor.appimage"
        rm -f "$dir/.cursor_version"
        echo "Removed cursor.appimage from $dir"
    fi
done

# Remove desktop entry and icons
rm -f "$HOME/.local/share/applications/cursor.desktop"
rm -rf "$HOME/.local/share/icons/hicolor/"*/apps/cursor*

# Refresh desktop database
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "✅ Cursor removed!"
echo "   Note: User config in ~/.config/Cursor is preserved"
echo "   To remove config: rm -rf ~/.config/Cursor"
