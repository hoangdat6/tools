#!/usr/bin/env bash
set -e

echo "📝 Installing Visual Studio Code..."

# Check if already installed
if command -v code &> /dev/null; then
    echo "VS Code is already installed: $(code --version | head -1)"
    exit 0
fi

# Clean up any conflicting source configurations
echo "Cleaning up old VS Code sources..."
sudo rm -f /etc/apt/sources.list.d/vscode.list
sudo rm -f /etc/apt/sources.list.d/vscode.sources
sudo rm -f /usr/share/keyrings/mscode.gpg

# Check if microsoft.gpg already exists (from Edge or other MS products)
if [ -f /usr/share/keyrings/microsoft.gpg ]; then
    echo "Using existing Microsoft GPG key..."
    GPG_KEY="/usr/share/keyrings/microsoft.gpg"
else
    # Add Microsoft GPG key
    echo "Adding Microsoft GPG key..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
    GPG_KEY="/usr/share/keyrings/microsoft.gpg"
fi

# Add VS Code repository using the existing/new key
echo "deb [arch=amd64 signed-by=$GPG_KEY] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list

# Install
sudo apt update
sudo apt install -y code

echo "✅ Visual Studio Code installed!"
echo "   Run 'code' to launch VS Code"
