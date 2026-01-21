#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling Kubernetes Pack..."

# Kubectl
if command -v kubectl &> /dev/null; then
    sudo apt remove -y kubectl
    sudo rm -f /etc/apt/sources.list.d/kubernetes.list
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "✅ kubectl removed"
else
    echo "⏭️ kubectl not installed"
fi

# Helm
if command -v helm &> /dev/null; then
    sudo apt remove -y helm
    sudo rm -f /etc/apt/sources.list.d/helm-stable-debian.list
    sudo rm -f /usr/share/keyrings/helm.gpg
    echo "✅ helm removed"
else
    echo "⏭️ helm not installed"
fi

# k9s
if command -v k9s &> /dev/null; then
    sudo rm -f /usr/local/bin/k9s
    echo "✅ k9s removed"
else
    echo "⏭️ k9s not installed"
fi
