#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Zsh + Oh My Zsh..."

# Remove Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    echo "Removed Oh My Zsh"
fi

# Change default shell back to bash
if [ "$SHELL" = "$(which zsh)" ]; then
    echo "Changing default shell back to bash..."
    chsh -s $(which bash) || echo "⚠️ Could not change shell. Run: chsh -s \$(which bash)"
fi

# Ask about removing zsh package
read -p "Remove Zsh package? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt remove -y zsh
    sudo apt autoremove -y
    echo "Removed Zsh package"
fi

# Remove .zshrc backup
rm -f ~/.zshrc.pre-oh-my-zsh 2>/dev/null || true

echo ""
echo "✅ Zsh + Oh My Zsh removed!"
echo "📝 Note: Log out and log back in to use bash as default shell"
