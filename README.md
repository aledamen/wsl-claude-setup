# WSL2 Setup for Claude Code

One-time setup script for WSL2 Ubuntu 24.04. Configures DNS, Node.js, npm, Azure CLI, and downloads MCP packages.

## Usage
```bash
git clone https://github.com/aledamen/wsl-claude-setup.git
cd wsl-claude-setup
bash setup-wsl.sh
```

## What it does

1. Fixes DNS resolution in WSL2 (common issue with corporate networks)
2. Installs Node.js via nvm (LTS version)
3. Configures npm for corporate networks (disables strict SSL)
4. Downloads MCP SQL Server package (mcp-mssql-server)
5. Downloads Tavily web search package
6. Installs Azure CLI + DevOps extension
7. Configures Azure DevOps connection (interactive, prompts for PAT)

## Requirements

- WSL2 with Ubuntu 24.04
- Internet access

## Security

No credentials are stored in this repository. The script prompts for sensitive data interactively and stores it only in your local `~/.bashrc`.
