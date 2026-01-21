#!/usr/bin/env bash
set -e

echo "☁️ Installing Azure CLI..."

# Check if already installed
if command -v az &> /dev/null; then
    echo "Azure CLI is already installed: $(az --version | head -1)"
    echo ""
    read -p "Update to latest version? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Install dependencies
sudo apt update
sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Add Microsoft GPG key
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

# Add Azure CLI repository
AZ_DIST=$(lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list

# Install
sudo apt update
sudo apt install -y azure-cli

echo ""
echo "✅ Azure CLI installed!"
az --version | head -3
echo ""
echo "📝 To login, run: az login"
echo "   To set subscription: az account set --subscription <name-or-id>"
