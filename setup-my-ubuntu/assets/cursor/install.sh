#!/usr/bin/env bash

set -e

# Local bin directory
LOCAL_BIN="$HOME/.local/bin"

# Create ~/.local/bin if it doesn't exist
mkdir -p "$LOCAL_BIN"

# Download cursor.sh and save it as 'cursor' in ~/.local/bin
echo "Downloading Cursor installer script..."
cp "./cursor.sh" "$LOCAL_BIN/cursor"

# Make the script executable
chmod +x "$LOCAL_BIN/cursor"

echo "Cursor script has been placed in $LOCAL_BIN/cursor"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo "Warning: $LOCAL_BIN is not in your PATH."
    echo "To add it, run this command or add it to your shell profile:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Run cursor --update to download and install Cursor
echo "Downloading and installing Cursor..."
"$LOCAL_BIN/cursor" --update "$@"

echo "Cursor has been installed. You can now run 'cursor' to start Cursor."
