#!/usr/bin/env bash
set -e

echo "🛠️ Installing JetBrains Toolbox..."

# Installation directories
INSTALL_DIR="$HOME/.local/share/JetBrains/Toolbox"
BIN_DIR="$INSTALL_DIR/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

# Check if already installed
if [ -f "$BIN_DIR/jetbrains-toolbox" ]; then
    echo "JetBrains Toolbox is already installed!"
    echo "Location: $BIN_DIR/jetbrains-toolbox"
    exit 0
fi

# Create directories
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"

# Download
echo "Downloading JetBrains Toolbox..."
TEMP_DIR=$(mktemp -d)

wget --show-progress -qO "$TEMP_DIR/toolbox.tar.gz" "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"

# Extract
tar -C "$TEMP_DIR" -xf "$TEMP_DIR/toolbox.tar.gz"

# Find the toolbox executable
TOOLBOX_EXTRACTED=$(find "$TEMP_DIR" -maxdepth 2 -type d -name "jetbrains-toolbox-*" | head -1)

if [ -z "$TOOLBOX_EXTRACTED" ]; then
    echo "❌ Error: Could not find extracted JetBrains Toolbox"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Copy to permanent location
echo "Installing to $BIN_DIR..."
cp -r "$TOOLBOX_EXTRACTED"/* "$BIN_DIR/"
chmod +x "$BIN_DIR/bin/jetbrains-toolbox" 2>/dev/null || chmod +x "$BIN_DIR/jetbrains-toolbox" 2>/dev/null

# Find the actual binary
TOOLBOX_BIN=$(find "$BIN_DIR" -name "jetbrains-toolbox" -type f | head -1)

# Create desktop entry
cat > "$DESKTOP_DIR/jetbrains-toolbox.desktop" << EOF
[Desktop Entry]
Type=Application
Name=JetBrains Toolbox
Icon=$BIN_DIR/toolbox.svg
Exec=$TOOLBOX_BIN
Categories=Development;IDE;
Terminal=false
StartupNotify=true
EOF

# Cleanup temp files
rm -rf "$TEMP_DIR"

# Run Toolbox
echo "Launching JetBrains Toolbox..."
"$TOOLBOX_BIN" &

echo ""
echo "✅ JetBrains Toolbox installed!"
echo "   Location: $TOOLBOX_BIN"
echo "   Use Toolbox to install IntelliJ IDEA, PyCharm, WebStorm, etc."
echo "   Toolbox should appear in your system tray."
