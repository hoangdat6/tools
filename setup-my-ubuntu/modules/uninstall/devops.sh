#!/usr/bin/env bash
set -e

echo "🗑️ Uninstalling DevOps Tools..."
echo ""

read -p "⚠️ This will remove Docker, Terraform, AWS CLI, and Portainer. Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# ============================================================
# PORTAINER
# ============================================================
echo ""
echo "== Removing Portainer =="
if sudo docker ps -a | grep -q portainer; then
    sudo docker stop portainer
    sudo docker rm portainer
    sudo docker volume rm portainer_data 2>/dev/null || true
    echo "✅ Portainer removed"
else
    echo "⏭️ Portainer not running, skipping"
fi

# ============================================================
# AWS CLI
# ============================================================
echo ""
echo "== Removing AWS CLI =="
if [ -f /usr/local/bin/aws ]; then
    sudo rm -rf /usr/local/aws-cli
    sudo rm -f /usr/local/bin/aws
    sudo rm -f /usr/local/bin/aws_completer
    echo "✅ AWS CLI removed"
else
    echo "⏭️ AWS CLI not installed, skipping"
fi

# ============================================================
# TERRAFORM
# ============================================================
echo ""
echo "== Removing Terraform =="
if dpkg -l | grep -q terraform; then
    sudo apt remove -y terraform
    sudo rm -f /etc/apt/sources.list.d/hashicorp.list
    sudo rm -f /etc/apt/keyrings/hashicorp.gpg
    echo "✅ Terraform removed"
else
    echo "⏭️ Terraform not installed, skipping"
fi

# ============================================================
# DOCKER
# ============================================================
echo ""
echo "== Removing Docker =="
if dpkg -l | grep -q docker-ce; then
    sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/keyrings/docker.gpg
    echo "✅ Docker removed"
    echo "   Note: Docker data in /var/lib/docker is preserved"
    echo "   To remove all data: sudo rm -rf /var/lib/docker"
else
    echo "⏭️ Docker not installed, skipping"
fi

sudo apt autoremove -y

echo ""
echo "✅ DevOps tools uninstalled!"
