# Azure Deploy Skill

A Claude/Copilot skill for deploying applications to Azure App Service, Azure Functions, and Static Web Apps.

## Features

- **Smart Detection**: Automatically detects application type and recommends the optimal Azure service
- **Local Preview**: Test applications locally before deploying (no Azure auth required)
- **Guided Deployment**: Step-by-step deployment with Azure CLI
- **Multi-Service Support**: Complex applications handled with azd + Infrastructure as Code
- **Dependency Management**: Auto-detects and installs missing CLI tools

## Quick Start

### Install the Skill

```bash
# Claude Code
/plugin install azure-deploy

# Or add to your Claude configuration
```

### Usage

Simply ask Claude to deploy your application:

```
"Deploy this app to Azure"
"Help me get this running on Azure"
"What Azure service should I use for this project?"
"Preview my app locally"
```

## What It Does

### 1. Detects Your Application Type

The skill analyzes your project to determine:
- Framework (React, Vue, Angular, Next.js, Express, Flask, .NET, etc.)
- Whether it's static, SSR, or serverless
- If it needs multiple services

### 2. Recommends the Right Service

| Application Type | Recommended Service |
|-----------------|---------------------|
| Static frontend (React, Vue, Angular) | Static Web Apps |
| Static + serverless API | Static Web Apps + managed Functions |
| SSR frameworks (Next.js SSR, Nuxt SSR) | App Service |
| Full backend (Express, Flask, .NET) | App Service |
| Event-driven / triggers | Azure Functions |
| Multi-service / complex | azd + Infrastructure as Code |

### 3. Handles Dependencies

Automatically checks for and helps install:
- Azure CLI (`az`)
- Azure Functions Core Tools (`func`)
- Static Web Apps CLI (`swa`)
- Azure Developer CLI (`azd`)
- Project dependencies (npm, pip, dotnet, etc.)

### 4. Deploys Your Application

Provides complete deployment commands and guides you through:
- Resource creation
- Configuration
- Deployment
- Troubleshooting

## Reference Documentation

The skill includes comprehensive guides:

- [App Service Guide](./reference/app-service.md) - Full web app deployment
- [Azure Functions Guide](./reference/functions.md) - Serverless functions
- [Static Web Apps Guide](./reference/static-web-apps.md) - Static sites and JAMstack
- [Local Preview Guide](./reference/local-preview.md) - Local development setup
- [Multi-Service Guide](./reference/multi-service.md) - azd and IaC patterns
- [Azure Verified Modules](./reference/azure-verified-modules.md) - Bicep module catalog
- [Troubleshooting Guide](./reference/troubleshooting.md) - Common issues and fixes

## Requirements

- Azure subscription
- Azure CLI (skill can help install)
- Node.js 18+ (for SWA CLI and Functions Core Tools)

## License

Apache 2.0 - See [LICENSE.txt](./LICENSE.txt)
