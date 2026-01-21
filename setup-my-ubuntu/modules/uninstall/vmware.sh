#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling VMware Workstation..."

if command -v vmware-installer &> /dev/null; then
    echo "Running VMware uninstaller..."
    sudo vmware-installer -u vmware-workstation --console
    echo "✅ VMware Workstation removed"
else
    echo "⏭️ VMware uninstaller not found, checking manual files..."
    if [ -d "/usr/lib/vmware" ]; then
        sudo rm -rf /usr/lib/vmware
        sudo rm -rf /etc/vmware
        echo "✅ VMware directories manually removed"
    else
        echo "⏭️ VMware not detected"
    fi
fi
