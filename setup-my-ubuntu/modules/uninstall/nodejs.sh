#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Node.js (NVM)..."

NVM_DIR="$HOME/.nvm"

if [ -d "$NVM_DIR" ]; then
    rm -rf "$NVM_DIR"
    echo "Removed $NVM_DIR"
    
    # Remove from shell configs
    for rc in ~/.bashrc ~/.zshrc ~/.profile; do
        if [ -f "$rc" ]; then
            sed -i '/NVM_DIR/d' "$rc"
            sed -i '/nvm.sh/d' "$rc"
            sed -i '/bash_completion/d' "$rc"
        fi
    done
    echo "Removed NVM from shell configs"
    
    echo "✅ NVM removed!"
else
    echo "⏭️ NVM not installed, skipping"
fi

echo ""
echo "📝 Note: Restart your terminal for changes to take effect"
