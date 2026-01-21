#!/usr/bin/env bash
set -e

echo "🐚 Installing Zsh + Oh My Zsh..."

# Install Zsh
if ! command -v zsh &> /dev/null; then
    echo "Installing Zsh..."
    sudo apt update
    sudo apt install -y zsh
else
    echo "Zsh already installed: $(zsh --version)"
fi

# Check if Oh My Zsh is already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is already installed!"
    
    # Still check if zsh is default
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Setting Zsh as default shell..."
        sudo chsh -s $(which zsh) $USER
    fi
    exit 0
fi

# Install Oh My Zsh (unattended)
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install popular plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true

echo "Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true

# Update .zshrc plugins and theme
if [ -f "$HOME/.zshrc" ]; then
    # Set theme to xiong-chiamiov
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="xiong-chiamiov"/' "$HOME/.zshrc"
    echo "Set theme to xiong-chiamiov"
    
    # Update plugins
    sed -i 's/plugins=(git)/plugins=(git docker kubectl terraform aws zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    echo "Updated plugins in .zshrc"
    
    # Also add NVM to .zshrc if it exists
    if [ -d "$HOME/.nvm" ] && ! grep -q "NVM_DIR" "$HOME/.zshrc" 2>/dev/null; then
        cat >> "$HOME/.zshrc" << 'EOF'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
        echo "Added NVM to .zshrc"
    fi
fi

# Set Zsh as default shell using sudo
echo "Setting Zsh as default shell..."
if sudo chsh -s $(which zsh) $USER; then
    echo "✅ Zsh is now the default shell"
else
    echo "⚠️ Could not change default shell automatically."
    echo "   Run manually: sudo chsh -s \$(which zsh) \$USER"
fi

echo ""
echo "✅ Zsh + Oh My Zsh installed!"
echo "   Zsh: $(zsh --version)"
echo "   Oh My Zsh: ~/.oh-my-zsh"
echo ""
echo "Installed plugins:"
echo "   - zsh-autosuggestions"
echo "   - zsh-syntax-highlighting"
echo "   - git, docker, kubectl, terraform, aws"
echo ""
echo "📝 IMPORTANT: Log out and log back in for Zsh to become your default shell"
echo "   Or start Zsh now by running: zsh"
