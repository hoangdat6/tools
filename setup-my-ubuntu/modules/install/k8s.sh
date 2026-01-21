#!/usr/bin/env bash
set -e

# Import common functions if not already imported
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Simple Colors fallback
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
fi

echo -e "${BLUE}☸️  Installing Kubernetes Pack...${NC}"

# ============================================================
# KUBECTL
# ============================================================
echo ""
echo "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl

    # Download public key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # Add repo
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubectl
else
    echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# ============================================================
# HELM
# ============================================================
echo ""
echo "Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    sudo apt-get install apt-transport-https --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
else
    echo "Helm already installed: $(helm version --short)"
fi

# ============================================================
# K9S
# ============================================================
echo ""
echo "Installing k9s..."
if ! command -v k9s &> /dev/null; then
    # Fetch latest version
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep "tag_name" | awk '{print $2}' | sed 's/[",]//g')
    echo "Latest k9s version: $K9S_VERSION"
    
    # Download
    wget -qO k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
    tar -xzf k9s.tar.gz
    chmod +x k9s
    sudo mv k9s /usr/local/bin/
    rm k9s.tar.gz LICENSE README.md 2>/dev/null || true
else
    echo "k9s already installed: $(k9s version --short | head -1)"
fi

echo ""
echo -e "${GREEN}✅ Kubernetes Pack installed!${NC}"
echo "   kubectl: $(kubectl version --client --short 2>/dev/null | head -1)"
echo "   helm:    $(helm version --short)"
echo "   k9s:     $(k9s version --short | head -1 2>/dev/null || echo 'installed')"
