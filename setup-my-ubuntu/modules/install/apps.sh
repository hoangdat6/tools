#!/usr/bin/env bash
set -e

# Import common functions if not already imported
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

echo -e "${BLUE}💬 Installing Communication & Productivity Tools...${NC}"

# Check for Snap
if ! command -v snap &> /dev/null; then
    echo "Installing Snapd..."
    sudo apt update
    sudo apt install -y snapd
fi

# ============================================================
# TELEGRAM
# ============================================================
echo ""
echo "Installing Telegram Desktop..."
if ! snap list | grep -q telegram-desktop; then
    sudo snap install telegram-desktop
    echo -e "${GREEN}✅ Telegram installed${NC}"
else
    echo "Telegram already installed"
fi

# ============================================================
# POSTMAN
# ============================================================
echo ""
echo "Installing Postman..."
if ! snap list | grep -q postman; then
    sudo snap install postman
    echo -e "${GREEN}✅ Postman installed${NC}"
else
    echo "Postman already installed"
fi

echo ""
echo -e "${GREEN}✅ Apps installation complete!${NC}"
echo "   - Telegram Desktop"
echo "   - Postman"
