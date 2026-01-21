#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Python (Pyenv)..."

PYENV_ROOT="$HOME/.pyenv"

if [ -d "$PYENV_ROOT" ]; then
    rm -rf "$PYENV_ROOT"
    echo "Removed $PYENV_ROOT"
    
    # Remove from shell configs
    for rc in ~/.bashrc ~/.zshrc ~/.profile; do
        if [ -f "$rc" ]; then
            sed -i '/PYENV_ROOT/d' "$rc"
            sed -i '/pyenv init/d' "$rc"
        fi
    done
    echo "Removed Pyenv from shell configs"
    
    echo "✅ Pyenv removed!"
else
    echo "⏭️ Pyenv not installed, skipping"
fi

echo ""
echo "📝 Note: Restart your terminal for changes to take effect"
echo "   System Python is still available"
