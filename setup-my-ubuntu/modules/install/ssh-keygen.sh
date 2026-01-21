#!/usr/bin/env bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔑 SSH Key Setup${NC}"
echo ""

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_ed25519"

# Check if key already exists
if [ -f "$KEY_FILE" ]; then
    echo -e "${YELLOW}SSH key already exists at $KEY_FILE${NC}"
    echo ""
    echo "Public key:"
    cat "${KEY_FILE}.pub"
    echo ""
    read -p "Generate a new key? (will backup existing) [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    # Backup existing
    mv "$KEY_FILE" "${KEY_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    mv "${KEY_FILE}.pub" "${KEY_FILE}.pub.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backed up existing keys"
fi

# Create .ssh directory if not exists
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Get email for key
echo ""
read -p "Enter your email (for SSH key comment): " email
if [ -z "$email" ]; then
    email="$USER@$(hostname)"
fi

# Generate key
echo ""
echo "Generating SSH key (Ed25519)..."
ssh-keygen -t ed25519 -C "$email" -f "$KEY_FILE"

# Set permissions
chmod 600 "$KEY_FILE"
chmod 644 "${KEY_FILE}.pub"

# Start ssh-agent and add key
eval "$(ssh-agent -s)"
ssh-add "$KEY_FILE"

echo ""
echo -e "${GREEN}✅ SSH key generated successfully!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}Your public key (copy this):${NC}"
echo ""
cat "${KEY_FILE}.pub"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📝 Next steps:${NC}"
echo ""
echo "1. Add to GitHub:"
echo "   https://github.com/settings/ssh/new"
echo ""
echo "2. Add to GitLab:"
echo "   https://gitlab.com/-/user_settings/ssh_keys"
echo ""
echo "3. Add to Azure DevOps:"
echo "   https://dev.azure.com/<org>/_usersSettings/keys"
echo ""
echo "4. Test connection:"
echo "   ssh -T git@github.com"
echo ""

# Offer to copy to clipboard
if command -v xclip &> /dev/null; then
    read -p "Copy public key to clipboard? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cat "${KEY_FILE}.pub" | xclip -selection clipboard
        echo -e "${GREEN}✅ Copied to clipboard!${NC}"
    fi
elif command -v xsel &> /dev/null; then
    read -p "Copy public key to clipboard? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cat "${KEY_FILE}.pub" | xsel --clipboard
        echo -e "${GREEN}✅ Copied to clipboard!${NC}"
    fi
fi
