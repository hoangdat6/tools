#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Go (Golang)..."

GO_DIR="/usr/local/go"

if [ -d "$GO_DIR" ]; then
    sudo rm -rf "$GO_DIR"
    echo "Removed $GO_DIR"
    
    # Remove GOPATH
    if [ -d "$HOME/go" ]; then
        read -p "Remove GOPATH ($HOME/go) with all Go projects? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/go"
            echo "Removed $HOME/go"
        else
            echo "Kept $HOME/go"
        fi
    fi
    
    # Remove from shell configs
    for rc in ~/.bashrc ~/.zshrc ~/.profile; do
        if [ -f "$rc" ]; then
            sed -i '/GO PATH/d' "$rc"
            sed -i '/GOPATH/d' "$rc"
            sed -i '/\/usr\/local\/go\/bin/d' "$rc"
        fi
    done
    echo "Removed Go from shell configs"
    
    echo "✅ Go removed!"
else
    echo "⏭️ Go not installed, skipping"
fi

echo ""
echo "📝 Note: Restart your terminal for changes to take effect"
