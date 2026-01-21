#!/usr/bin/env bash
set -e

# Import common functions if not already imported
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Simple Colors fallback
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'
fi

echo -e "${BLUE}🖥️  Installing VMware Workstation 17 Pro...${NC}"

# Check dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y build-essential gcc make linux-headers-$(uname -r) libgl1 libglib2.0-0 libx11-6 libx11-xcb1 libxau6 libxcb1 libxdmcp6 libxext6 libxi6 libxinerama1 libxrender1 libxtst6

# Define asset path
ASSETS_DIR="$SCRIPT_DIR/assets"
VMWARE_DIR="$ASSETS_DIR/vmware17"

# Find the bundle file
VMWARE_BUNDLE=$(find "$VMWARE_DIR" -name "VMware-Workstation-*.bundle" | head -1)

if [ -z "$VMWARE_BUNDLE" ]; then
    echo -e "${RED}❌ VMware bundle not found in $VMWARE_DIR${NC}"
    echo "Please place the .bundle file in 'assets/vmware17/'"
    exit 1
fi

echo -e "${GREEN}Found installer: $(basename "$VMWARE_BUNDLE")${NC}"

# Make executable
chmod +x "$VMWARE_BUNDLE"

# Install
echo "Starting installation (requires sudo)..."
echo "Note: This may verify kernel modules."
sudo "$VMWARE_BUNDLE" --console --eulas-agreed --required

# Init modules (specifically for vmmon/vmnet)
echo "Initializing VMware kernel modules..."
sudo vmware-modconfig --console --install-all

echo ""
echo -e "${GREEN}✅ VMware Workstation 17 Pro installed successfully!${NC}"
echo "   Run 'vmware' to launch."
echo -e "${YELLOW}📝 Note: You may need to enter a license key on first run.${NC}"
