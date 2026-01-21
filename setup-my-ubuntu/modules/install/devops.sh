#!/usr/bin/env bash
set -e

echo "🐳 Installing DevOps Tools..."
echo "   - Git"
echo "   - Docker + Docker Compose"
echo "   - Terraform"
echo "   - AWS CLI v2"
echo "   - Portainer"
echo ""

# Ensure running on Ubuntu/Debian
if ! [ -f /etc/debian_version ]; then
    echo "❌ This script currently supports Debian/Ubuntu only"
    exit 1
fi

# Install dependencies
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    software-properties-common

# ============================================================
# GIT
# ============================================================
echo ""
echo "== Installing Git =="
sudo apt install -y git
git --version

# ============================================================
# DOCKER
# ============================================================
echo ""
echo "== Installing Docker =="

# Remove old versions
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker repo
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
if ! groups $USER | grep -q docker; then
    sudo usermod -aG docker $USER
    echo "👉 Added $USER to docker group (logout required)"
fi

docker --version
docker compose version

# ============================================================
# TERRAFORM
# ============================================================
echo ""
echo "== Installing Terraform =="

curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg

echo \
    "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] \
    https://apt.releases.hashicorp.com \
    $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform
terraform version | head -n 1

# ============================================================
# AWS CLI v2
# ============================================================
echo ""
echo "== Installing AWS CLI v2 =="

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
sudo ./aws/install --update

cd ~
rm -rf "$TMP_DIR"
aws --version

# ============================================================
# PORTAINER
# ============================================================
echo ""
echo "== Installing Portainer =="

sudo docker volume create portainer_data

if ! sudo docker ps -a | grep -q portainer; then
    sudo docker run -d \
        --name portainer \
        --restart=always \
        -p 8000:8000 \
        -p 9443:9443 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    echo "Portainer container started"
else
    echo "Portainer already exists, skipping"
fi

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ DevOps Tools Installed                       ║"
echo "╠════════════════════════════════════════════════════════════════════╣"
echo "║  Git:        $(git --version | head -c 30)"
echo "║  Docker:     $(docker --version | head -c 30)"
echo "║  Compose:    $(docker compose version | head -c 30)"
echo "║  Terraform:  $(terraform version | head -n 1 | head -c 30)"
echo "║  AWS CLI:    $(aws --version 2>&1 | head -c 30)"
echo "║  Portainer:  https://localhost:9443"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "👉 Note: Logout & login again for Docker group changes to take effect"
