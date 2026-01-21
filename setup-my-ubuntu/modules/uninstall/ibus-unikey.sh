#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling IBus Unikey..."

if dpkg -l | grep -q ibus-unikey; then
    sudo apt remove -y ibus-unikey
    sudo apt autoremove -y
    echo "✅ IBus Unikey removed"
else
    echo "⏭️ IBus Unikey not installed, skipping"
fi

echo ""
echo "📝 Note: IBus environment variables in ~/.xprofile are preserved"
echo "   You may want to remove these lines manually if not using IBus:"
echo "   export GTK_IM_MODULE=ibus"
echo "   export QT_IM_MODULE=ibus"
echo "   export XMODIFIERS=@im=ibus"
