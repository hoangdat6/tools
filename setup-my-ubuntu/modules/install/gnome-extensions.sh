#!/usr/bin/env bash
set -e

echo "🧩 Installing GNOME Extensions & Tools..."
echo ""

# Install GNOME Extension Manager and dependencies
echo "Installing GNOME Shell Extensions support..."
sudo apt update
sudo apt install -y \
    gnome-shell-extension-manager \
    gnome-shell-extensions \
    gnome-tweaks \
    gir1.2-gtop-2.0 \
    lm-sensors \
    nvme-cli

# Initialize sensors
echo "Detecting hardware sensors..."
sudo sensors-detect --auto || true

# Install gnome-extensions CLI tool if not available
if ! command -v gnome-extensions &> /dev/null; then
    sudo apt install -y gnome-shell-extension-prefs
fi

echo ""
echo "Installing popular GNOME Extensions..."

# Function to install extension from extensions.gnome.org
install_extension() {
    local extension_id="$1"
    local extension_name="$2"
    
    echo "  → $extension_name"
    
    # Get GNOME Shell version
    GNOME_VERSION=$(gnome-shell --version | grep -oP '\d+' | head -1)
    
    # Download extension info
    EXTENSION_INFO=$(curl -s "https://extensions.gnome.org/extension-info/?pk=${extension_id}&shell_version=${GNOME_VERSION}" 2>/dev/null)
    
    if [ -z "$EXTENSION_INFO" ]; then
        echo "    ⚠️ Could not fetch extension info"
        return 1
    fi
    
    # Get download URL
    DOWNLOAD_URL=$(echo "$EXTENSION_INFO" | jq -r '.download_url' 2>/dev/null)
    UUID=$(echo "$EXTENSION_INFO" | jq -r '.uuid' 2>/dev/null)
    
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
        echo "    ⚠️ Extension not available for GNOME $GNOME_VERSION"
        return 1
    fi
    
    # Download and install
    TEMP_ZIP=$(mktemp)
    curl -sL "https://extensions.gnome.org${DOWNLOAD_URL}" -o "$TEMP_ZIP"
    
    EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"
    mkdir -p "$EXTENSIONS_DIR"
    unzip -q -o "$TEMP_ZIP" -d "$EXTENSIONS_DIR"
    rm -f "$TEMP_ZIP"
    
    # Enable extension
    gnome-extensions enable "$UUID" 2>/dev/null || true
    
    echo "    ✅ Installed"
}

# Popular extensions
echo ""

# System Monitor (by paradoxxx.zero)
install_extension "120" "System Monitor"

# Vitals (CPU, Memory, Temperature)
install_extension "1460" "Vitals"

# Clipboard Indicator
install_extension "779" "Clipboard Indicator"

# Blur my Shell
install_extension "3193" "Blur my Shell"

# AppIndicator Support (for tray icons)
install_extension "615" "AppIndicator Support"

echo ""
echo "✅ GNOME Extensions installed!"
echo ""
echo "Installed extensions:"
echo "   - System Monitor (system stats in top bar)"
echo "   - Vitals (CPU, RAM, Temperature, Fan speed)"
echo "   - Clipboard Indicator (clipboard history)"
echo "   - Blur my Shell (blur effects)"
echo "   - AppIndicator (system tray support)"
echo ""
echo "📝 Notes:"
echo "   - Run 'gnome-tweaks' to configure extensions"
echo "   - Run 'extension-manager' for GUI management"
echo "   - Run 'sensors' to see temperature readings"
echo "   - Some extensions require a GNOME Shell restart (Alt+F2, type 'r')"
echo "   - Or log out and log back in"
