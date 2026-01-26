# Azure Deploy Skill

A Claude/Copilot skill for deploying applications to Azure. Automatically detects your application type, recommends the optimal Azure service, and guides you through deployment.

## Supported Azure Services

| Service | Best For |
|---------|----------|
| **Static Web Apps** | React, Vue, Angular, static sites, JAMstack |
| **App Service** | Full-stack apps, APIs, SSR frameworks (Next.js, Nuxt) |
| **Azure Functions** | Serverless, event-driven, scheduled tasks |

## Installation

### Option 1: Claude Code Plugin

```bash
# Add this repository as a plugin
/plugin install azure-deploy
```

### Option 2: Manual Installation

Clone and add the skill folder to your Claude/Copilot configuration.

## Usage

### Basic Usage

Simply describe what you want to deploy:

```
"Deploy this app to Azure"
"Help me get this running on Azure"  
"What Azure service should I use?"
```

### Explicit Skill Invocation

> **Note**: If you have the Azure MCP tools enabled, phrases like "deploy to Azure" may trigger the MCP instead of this skill. Use explicit invocation if needed:

```
"Use the azure-deploy skill to deploy my app"
"@azure-deploy help me deploy this"
```

Or reference the skill directly in your prompt:
```
"Using the azure-deploy skill, analyze my project and recommend an Azure service"
```

## What the Skill Does

### 1. Detects Your Application

The skill scans your project for:
- **Package files**: `package.json`, `requirements.txt`, `*.csproj`, `pom.xml`
- **Framework configs**: `next.config.js`, `vite.config.ts`, `angular.json`
- **Azure configs**: `azure.yaml`, `host.json`, `staticwebapp.config.json`

### 2. Recommends a Service

| Detection | Recommendation |
|-----------|----------------|
| `host.json` or `function.json` | Azure Functions |
| `staticwebapp.config.json` | Static Web Apps |
| React/Vue/Angular + Vite | Static Web Apps |
| Next.js with `output: 'export'` | Static Web Apps |
| Next.js with SSR | App Service |
| Express/Flask/FastAPI | App Service |
| Monorepo / multiple services | azd + Infrastructure as Code |

### 3. Handles Prerequisites

- Checks for Azure CLI, installs if missing
- **Auto-login**: Runs `az login` if not authenticated
- Installs project dependencies (`npm install`, etc.)

### 4. Deploys Your App

Provides step-by-step commands for:
- Resource group creation
- Service provisioning
- Code deployment
- Configuration

## Local Preview

Test your app locally before deploying (no Azure login required):

```bash
# Static Web Apps
swa start ./dist

# Azure Functions  
func start

# App Service apps
npm run dev  # or flask run, dotnet run, etc.
```

## Multi-Service Applications

For complex applications with multiple components, the skill recommends **Azure Developer CLI (azd)** with Infrastructure as Code:

```bash
azd init      # Initialize project
azd up        # Provision + deploy
```

## Test Scripts

The skill includes test scripts to validate functionality:

```bash
# Test app type detection logic
./test-detection.sh

# Test local preview/dev servers (no Azure required)
./test-local.sh

# Test actual Azure deployments (requires Azure subscription)
./test-deploy.sh
```

### Test Coverage

| Script | What It Tests | Azure Required |
|--------|---------------|----------------|
| `test-detection.sh` | App type detection, service recommendations | No |
| `test-local.sh` | Local dev servers (`npm run dev`, `flask run`, `func start`) | No |
| `test-deploy.sh` | End-to-end Azure deployment with curl validation | Yes |

### Test Scenarios

The `test-scenarios/` folder contains sample projects:

| Scenario | Type | Local Test | Deploy Target |
|----------|------|------------|---------------|
| `static-html/` | Static site | Python HTTP server | Static Web Apps |
| `react-app/` | Vite + React | `npm run dev` | Static Web Apps |
| `python-flask/` | Flask API | `flask run` | App Service |
| `azure-functions/` | Node.js v4 Functions | `func start` | Azure Functions |
| `nextjs-ssr/` | Next.js SSR | `npm run dev` | App Service |
| `monorepo/` | Multi-service | N/A | azd + IaC |

### Running Tests

```bash
# Quick validation (no Azure)
./test-detection.sh && ./test-local.sh

# Full validation (requires Azure subscription + login)
az login
./test-deploy.sh
```

## Reference Documentation

Detailed guides are available in the `reference/` folder:

- [App Service Guide](./reference/app-service.md)
- [Azure Functions Guide](./reference/functions.md)
- [Static Web Apps Guide](./reference/static-web-apps.md)
- [Local Preview Guide](./reference/local-preview.md)
- [Multi-Service Guide](./reference/multi-service.md)
- [Azure Verified Modules](./reference/azure-verified-modules.md)
- [Troubleshooting](./reference/troubleshooting.md)

## Requirements

- **Azure subscription** (for deployment only)
- **Azure CLI** (skill can install)
- **Node.js 22 LTS** (recommended for SWA CLI, Functions Core Tools)
- **Python 3.10+** (for Flask/Django apps)
- **Azure Functions Core Tools** (for Functions development)

## Known Limitations

### Azure MCP Collision

If you have Azure MCP tools enabled in your environment, generic phrases like "deploy to Azure" may invoke the MCP instead of this skill. Solutions:

1. Use explicit skill invocation (see Usage above)
2. Reference specific skill features: "detect my app type and recommend an Azure service"
3. Disable Azure MCP deploy tools if you prefer this skill

### Region Availability

Static Web Apps are only available in certain regions:
- `centralus`, `eastus2`, `westus2`, `westeurope`, `eastasia`

The skill automatically uses compatible regions.

## License

Apache 2.0 - See [LICENSE.txt](./LICENSE.txt)
