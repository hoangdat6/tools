#!/usr/bin/env bash
set -e

echo "🔧 Installing Terminal Tools..."
echo "   - ripgrep (rg)"
echo "   - jq"
echo "   - yq"
echo "   - htop"
echo "   - flameshot"
echo "   - bat"
echo "   - tree"
echo "   - tldr"
echo ""

sudo apt update

# ripgrep - fast grep alternative
echo "Installing ripgrep..."
sudo apt install -y ripgrep

# jq - JSON processor
echo "Installing jq..."
sudo apt install -y jq

# yq - YAML processor
echo "Installing yq..."
YQ_VERSION="v4.44.1"
sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
sudo chmod +x /usr/local/bin/yq

# htop - interactive process viewer
echo "Installing htop..."
sudo apt install -y htop

# flameshot - screenshot tool
echo "Installing flameshot..."
sudo apt install -y flameshot

# bat - cat with syntax highlighting
echo "Installing bat..."
sudo apt install -y bat
# Create symlink for 'bat' command (Ubuntu uses 'batcat')
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat 2>/dev/null || true

# tree - directory structure viewer
echo "Installing tree..."
sudo apt install -y tree

# tldr - simplified man pages
echo "Installing tldr..."
sudo apt install -y tldr

echo ""
echo "✅ Terminal Tools installed!"
echo ""
echo "Installed tools:"
echo "   rg $(rg --version | head -1)"
echo "   jq $(jq --version)"
echo "   yq $(yq --version)"
echo "   htop $(htop --version | head -1)"
echo "   flameshot $(flameshot --version 2>&1 | head -1)"
echo "   bat (use 'batcat' or '~/.local/bin/bat')"
echo "   tree $(tree --version)"
echo ""
echo "📝 Tips:"
echo "   - Use 'rg pattern' instead of 'grep -r pattern'"
echo "   - Use 'cat file.json | jq .' to format JSON"
echo "   - Use 'flameshot gui' to take screenshots"
