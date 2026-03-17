#!/bin/bash
# ============================================================
# Setup WSL2 Ubuntu 24.04 for Claude Code
# + MCP SQL Server + Azure DevOps CLI + Tavily Search
#
# Run inside WSL2. No credentials are stored in this file.
# ============================================================

set -e

echo "=========================================="
echo " WSL2 Setup for Claude Code"
echo "=========================================="

# ------------------------------------------
# 1. Fix DNS in WSL2
# ------------------------------------------
echo ""
echo "[1/7] Configuring DNS..."

sudo rm -f /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8
nameserver 8.8.4.4" > /etc/resolv.conf'

if ! grep -q "generateResolvConf = false" /etc/wsl.conf 2>/dev/null; then
  sudo bash -c 'cat >> /etc/wsl.conf << EOF

[network]
generateResolvConf = false
EOF'
fi

if ! grep -q "appendWindowsPath = false" /etc/wsl.conf 2>/dev/null; then
  sudo bash -c 'cat >> /etc/wsl.conf << EOF

[interop]
appendWindowsPath = false
EOF'
fi

echo "Verifying DNS..."
if ping -c 1 registry.npmjs.org &>/dev/null; then
  echo "DNS working"
else
  echo "ERROR: DNS not working. Restart WSL from PowerShell with 'wsl --shutdown' and run this script again."
  exit 1
fi

# ------------------------------------------
# 2. Install Node.js via nvm
# ------------------------------------------
echo ""
echo "[2/7] Installing Node.js via nvm..."

if command -v node &>/dev/null; then
  echo "Node.js already installed: $(node --version)"
else
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  nvm install --lts
  echo "Node.js installed: $(node --version)"
fi

# ------------------------------------------
# 3. Configure npm for corporate networks
# ------------------------------------------
echo ""
echo "[3/7] Configuring npm (disable strict SSL for corporate proxies)..."

npm config set strict-ssl false
echo "npm strict-ssl disabled"

# ------------------------------------------
# 4. Download MCP SQL Server package
# ------------------------------------------
echo ""
echo "[4/7] Downloading MCP SQL Server package..."

npx -y mcp-mssql-server --help 2>/dev/null || true
echo "MCP SQL Server package ready"

# ------------------------------------------
# 5. Download Tavily MCP package
# ------------------------------------------
echo ""
echo "[5/7] Downloading Tavily MCP package..."

npx -y tavily-mcp@latest --help 2>/dev/null || true
echo "Tavily MCP package ready"

# ------------------------------------------
# 6. Install Azure CLI + DevOps extension
# ------------------------------------------
echo ""
echo "[6/7] Installing Azure CLI..."

# Siempre priorizar ~/.local/bin antes de cualquier chequeo
export PATH="$HOME/.local/bin:$PATH"
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Ignorar el az de Windows (ruta /mnt/c/...) — no puede ejecutarse en Linux
if command -v az &>/dev/null && [[ "$(which az)" != /mnt/c/* ]]; then
  echo "Azure CLI already installed: $(az --version | head -1)"
else
  sudo apt update && sudo apt install -y python3-pip
  pip install azure-cli --break-system-packages
  echo "Azure CLI installed: $(az --version | head -1)"
fi

echo "Installing Azure DevOps extension..."
az extension add --name azure-devops 2>/dev/null \
  || az extension update --name azure-devops 2>/dev/null \
  || true
echo "Azure DevOps extension ready"

# ------------------------------------------
# 7. Configure Azure DevOps (interactive)
# ------------------------------------------
echo ""
echo "[7/7] Configuring Azure DevOps..."
echo ""

read -p "Do you want to configure Azure DevOps? (y/n): " CONFIGURE_AZDO

if [[ "$CONFIGURE_AZDO" == "y" || "$CONFIGURE_AZDO" == "Y" ]]; then
  read -p "Azure DevOps URL (e.g., http://192.168.2.238/DefaultCollection or https://dev.azure.com/org): " AZDO_ORG
  read -p "Default project name: " AZDO_PROJECT

  az devops configure --defaults \
    organization="$AZDO_ORG" \
    project="$AZDO_PROJECT"

  echo ""
  echo "Generate a Personal Access Token (PAT) from:"
  echo "  ${AZDO_ORG}/_usersSettings/tokens"
  echo ""
  echo "Recommended permissions: Read on Code and Release"
  echo ""
  read -sp "Paste your PAT here (input hidden): " AZDO_PAT
  echo ""

  if grep -q "AZURE_DEVOPS_EXT_PAT" ~/.bashrc 2>/dev/null; then
    sed -i "s|export AZURE_DEVOPS_EXT_PAT=.*|export AZURE_DEVOPS_EXT_PAT=\"$AZDO_PAT\"|" ~/.bashrc
  else
    echo "export AZURE_DEVOPS_EXT_PAT=\"$AZDO_PAT\"" >> ~/.bashrc
  fi
  export AZURE_DEVOPS_EXT_PAT="$AZDO_PAT"

  echo "Verifying Azure DevOps connection..."
  if az repos list --output table 2>/dev/null; then
    echo "Azure DevOps connection successful"
  else
    echo "WARNING: Could not connect to Azure DevOps. Check PAT and URL."
  fi
else
  echo "Skipping Azure DevOps configuration."
fi

# ------------------------------------------
# Summary
# ------------------------------------------
echo ""
echo "=========================================="
echo " WSL Setup complete"
echo "=========================================="
echo ""
echo " IMPORTANT: Restart WSL from PowerShell:"
echo "   wsl --shutdown"
echo ""
echo " Then reopen WSL and run setup-project.sh"
echo " to configure a specific project."
echo ""