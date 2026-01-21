# 🚀 Ubuntu Setup Tool

A modular, full-featured setup tool for quickly installing all your favorite tools when setting up a new Ubuntu installation. Designed for DevOps Engineers and Full Stack Developers.

## ✨ Features

- **Interactive Menu**: Easy-to-use menu system.
- **Wizard Mode**: Profile-based setup (DevOps, Backend, Frontend, Full Stack).
- **Health Check**: Verify installation status of all tools.
- **Export/Import Config**: Backup your toolset configuration and restore it on another machine.
- **Uninstall Mode**: Cleanly remove installed tools.
- **Modular Architecture**: Easy to extend with new scripts.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <your-repo-url>
cd setup-my-ubuntu

# Make scripts executable (if needed)
chmod +x setup.sh modules/install/*.sh modules/utils/*.sh

# Run the setup
./setup.sh
```

## 📖 Usage

### Interactive Mode
```bash
./setup.sh
```
This opens the main menu where you can:
- Install individual tools (Browsers, VSCode, Docker, K8s, etc.).
- Run **Wizard Mode** for profile setups.
- Run **Health Check**.
- **Export/Import** tool configurations.
- Access the **Uninstall Menu**.

### Command Line Options
```bash
./setup.sh --wizard      # Start Wizard Mode (Profiles)
./setup.sh --health      # Run System Health Check
./setup.sh --export      # Export/Import Configuration
./setup.sh --all         # Install ALL tools
./setup.sh --uninstall <module>  # Uninstall specific module
./setup.sh <module>      # Install specific module (e.g., ./setup.sh k8s)
```

## 📦 Available Modules

| Category | Modules | Description |
|----------|---------|-------------|
| **Core** | `browsers` | Microsoft Edge + Google Chrome |
| | `vscode`, `cursor` | Visual Studio Code, Cursor AI Editor |
| | `jetbrains` | JetBrains Toolbox |
| | `antigravity` | Antigravity AI Assistant |
| **DevOps** | `devops` | Git, Docker, Docker Compose, Terraform, AWS CLI, Portainer |
| | `azure-cli` | Azure CLI |
| | `k8s` | **Kubernetes Pack**: kubectl, helm, k9s |
| | `vmware` | **VMware Workstation 17 Pro** (requires local bundle) |
| **backend** | `nodejs` | Node.js (via NVM) |
| | `python` | Python (via Pyenv) |
| | `golang` | Go (Golang) |
| | `dbeaver` | **DBeaver Community** (Database Client) |
| **System** | `zsh` | Zsh + Oh My Zsh (with plugins & themes) |
| | `dock` | GNOME Dock configuration |
| | `gnome-extensions` | Useful GNOME extensions |
| | `ibus-unikey` | Vietnamese Input Method |
| | `ssh-keygen` | SSH Key Generator (Ed25519) |
| **Utils** | `terminal-tools` | ripgrep, jq, yq, htop, flameshot, bat, tree |
| | `apps` | **Telegram**, **Postman** |

## 📂 Project Structure

```
setup-my-ubuntu/
├── setup.sh                 # Main entry point
├── lib/
│   └── common.sh            # Shared functions and colors
├── modules/
│   ├── install/             # Installation scripts
│   │   ├── apps.sh          # Telegram, Postman
│   │   ├── k8s.sh           # Kubernetes tools
│   │   ├── vmware.sh        # VMware Workstation
│   │   └── ...
│   ├── uninstall/           # Uninstallation scripts
│   └── utils/               # Utility scripts
│       ├── health-check.sh  # System health check
│       ├── wizard.sh        # Setup Wizard
│       └── export-config.sh # Config Export/Import
└── assets/                  # Local installers (cursor, vmware, etc.)
```

## 📝 Notes

- **VMware Workstation**: Requires the `.bundle` installer placed in `assets/vmware17/`.
- **Docker**: You must **logout and login** after installation for group changes to take effect.
- **Zsh**: Set as default shell; restart session to apply.
- **Health Check**: Run `./setup.sh --health` anytime to verify your environment.

## 📄 License

MIT
