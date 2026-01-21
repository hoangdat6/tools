#!/usr/bin/env bash
set -e

echo "🔮 Installing Cursor Editor..."

# Install dependencies
sudo apt update
sudo apt install -y libfuse2 curl

# Use the custom cursor installer script if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$SCRIPT_DIR/assets/cursor/install.sh" ]; then
    echo "Using local Cursor installer..."
    cd "$SCRIPT_DIR/assets/cursor"
    bash install.sh
else
    # Fallback to remote installer
    echo "Using remote Cursor installer..."
    curl -fsSL https://raw.githubusercontent.com/watzon/cursor-linux-installer/main/install.sh | bash
fi

echo "✅ Cursor Editor installed!"
echo "   Run 'cursor' to launch"
