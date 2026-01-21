#!/usr/bin/env bash
set -e

echo "🌐 Installing Browsers..."

# ====== Microsoft Edge ======
echo "➡ Installing Microsoft Edge..."
sudo apt update && sudo apt install curl -y

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
rm microsoft.gpg

sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
sudo apt update
sudo apt install microsoft-edge-stable -y

echo "✅ Microsoft Edge installed!"

# ====== Google Chrome ======
echo "➡ Installing Google Chrome..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt install -f -y

cd ~
rm -rf "$TEMP_DIR"

echo "✅ Google Chrome installed!"
echo "🌐 All browsers installed successfully!"
