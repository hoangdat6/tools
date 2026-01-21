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

echo -e "${BLUE}🗄️  Installing DBeaver Community Edition...${NC}"

# Ensure Java is installed (DBeaver needs it, though checks usually handle it)
# The deb package usually brings its own jre or dep, but let's be safe
echo "Checking dependencies..."
sudo apt update
sudo apt install -y default-jre

# Install DBeaver
echo "Downloading DBeaver DEB..."
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Get latest version URL
LATEST_URL="https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb"
wget -O dbeaver.deb "$LATEST_URL"

echo "Installing DBeaver..."
sudo apt install -y ./dbeaver.deb

cd ~
rm -rf "$TMP_DIR"

echo ""
echo -e "${GREEN}✅ DBeaver CE installed!${NC}"
echo "   Run 'dbeaver' or find it in your application menu."
