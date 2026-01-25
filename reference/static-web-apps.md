# Static Web Apps Deployment Guide

Deploy static frontends and JAMstack applications with optional serverless APIs.

---

## Overview

Azure Static Web Apps provides:
- Global CDN distribution
- Free SSL certificates
- Integrated serverless APIs (managed Functions)
- GitHub/Azure DevOps CI/CD integration
- Preview environments for pull requests

**Best for:** React, Vue, Angular, Svelte, Gatsby, Hugo, plain HTML/CSS/JS sites

---

## Quick Start

```bash
# 1. Create resource group
az group create --name myswa-rg --location eastus

# 2. Create Static Web App
az staticwebapp create \
  --name myswa \
  --resource-group myswa-rg \
  --location eastus \
  --sku Free

# 3. Get deployment token
TOKEN=$(az staticwebapp secrets list \
  --name myswa \
  --resource-group myswa-rg \
  --query "properties.apiKey" -o tsv)

# 4. Build and deploy
npm run build
swa deploy ./dist --deployment-token $TOKEN
```

---

## SKU Options

| SKU | Price | Features |
|-----|-------|----------|
| **Free** | $0 | 2 custom domains, 100GB bandwidth, community support |
| **Standard** | ~$9/mo | 5 custom domains, password protection, custom auth |

```bash
# Create with Standard SKU
az staticwebapp create \
  --name <app> \
  --resource-group <rg> \
  --sku Standard
```

---

## SWA CLI Usage

### Installation

```bash
npm install -g @azure/static-web-apps-cli
```

### Initialize Configuration

```bash
# Auto-detect framework and create swa-cli.config.json
swa init
```

### Local Development

```bash
# Start with auto-detection
swa start

# Specify build output and API
swa start ./dist --api-location ./api

# Proxy to dev server
swa start http://localhost:3000 --api-location ./api

# With custom port
swa start --port 4280
```

### Deploy

```bash
# Deploy with token
swa deploy ./dist --deployment-token <token>

# Deploy with API
swa deploy ./dist --api-location ./api --deployment-token <token>

# Print token for CI/CD
swa deploy --print-token
```

---

## Configuration: staticwebapp.config.json

Place in your output directory or repository root:

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/images/*", "/api/*", "*.{css,js,png,jpg,svg}"]
  },
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["authenticated"]
    },
    {
      "route": "/admin/*",
      "allowedRoles": ["admin"]
    }
  ],
  "responseOverrides": {
    "401": {
      "statusCode": 302,
      "redirect": "/.auth/login/aad"
    },
    "404": {
      "rewrite": "/404.html"
    }
  },
  "globalHeaders": {
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff"
  },
  "platform": {
    "apiRuntime": "node:20"
  }
}
```

---

## Framework-Specific Setup

### React (Vite/CRA)

```bash
# Build
npm run build

# Deploy (Vite outputs to dist/, CRA to build/)
swa deploy ./dist --deployment-token $TOKEN
```

### Vue (Vite)

```bash
npm run build
swa deploy ./dist --deployment-token $TOKEN
```

### Angular

```bash
npm run build
# Output is in dist/<project-name>/browser
swa deploy ./dist/<project-name>/browser --deployment-token $TOKEN
```

### Next.js (Static Export)

Add to `next.config.js`:
```javascript
module.exports = {
  output: 'export',
  trailingSlash: true,
}
```

```bash
npm run build
swa deploy ./out --deployment-token $TOKEN
```

### Astro

```bash
npm run build
swa deploy ./dist --deployment-token $TOKEN
```

### Gatsby

```bash
npm run build
swa deploy ./public --deployment-token $TOKEN
```

---

## API Integration

### Managed Functions (Built-in)

Create `api/` folder in project root:

```
project/
├── src/
├── api/
│   ├── host.json
│   ├── package.json
│   └── hello/
│       ├── function.json
│       └── index.js
└── staticwebapp.config.json
```

**api/hello/index.js:**
```javascript
module.exports = async function (context, req) {
  context.res = {
    body: { message: "Hello from API!" }
  };
};
```

**api/hello/function.json:**
```json
{
  "bindings": [{
    "authLevel": "anonymous",
    "type": "httpTrigger",
    "direction": "in",
    "methods": ["get", "post"]
  }, {
    "type": "http",
    "direction": "out"
  }]
}
```

Deploy with API:
```bash
swa deploy ./dist --api-location ./api --deployment-token $TOKEN
```

### Linked Backend (Bring Your Own)

Link existing Function App, App Service, or Container App:

```bash
az staticwebapp backends link \
  --name <swa-name> \
  --resource-group <rg> \
  --backend-resource-id <resource-id> \
  --backend-region <region>
```

---

## Authentication

### Built-in Providers

```json
{
  "routes": [
    { "route": "/login", "redirect": "/.auth/login/github" },
    { "route": "/login/aad", "redirect": "/.auth/login/aad" },
    { "route": "/.auth/login/twitter", "statusCode": 404 }
  ]
}
```

Available providers: `github`, `aad` (Microsoft Entra ID), `twitter`

### Custom Authentication

Configure in Azure Portal or via ARM/Bicep for custom OpenID Connect providers.

### Access User Info

In your frontend:
```javascript
const response = await fetch('/.auth/me');
const { clientPrincipal } = await response.json();
// clientPrincipal.userId, .userRoles, .identityProvider
```

In API (Node.js):
```javascript
module.exports = async function (context, req) {
  const header = req.headers['x-ms-client-principal'];
  const user = header ? JSON.parse(Buffer.from(header, 'base64').toString()) : null;
};
```

---

## Custom Domains

```bash
# Add custom domain
az staticwebapp hostname set \
  --name <app> \
  --resource-group <rg> \
  --hostname www.example.com

# List domains
az staticwebapp hostname list \
  --name <app> \
  --resource-group <rg>
```

**DNS Configuration:**
- CNAME: Point `www` to `<app>.azurestaticapps.net`
- Root domain: Use Azure DNS or provider's ALIAS/ANAME record

---

## Environment Variables

```bash
# Set for production
az staticwebapp appsettings set \
  --name <app> \
  --resource-group <rg> \
  --setting-names \
    API_URL=https://api.example.com \
    FEATURE_FLAG=true

# List
az staticwebapp appsettings list \
  --name <app> \
  --resource-group <rg>
```

---

## Preview Environments

Automatically created for pull requests when using GitHub Actions.

```bash
# List environments
az staticwebapp environment list \
  --name <app> \
  --resource-group <rg>

# Delete preview environment
az staticwebapp environment delete \
  --name <app> \
  --resource-group <rg> \
  --environment-name <env-name>
```

---

## GitHub Actions Workflow

Auto-generated when linking GitHub repo, or create manually:

```yaml
name: Deploy to SWA
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build
        run: |
          npm install
          npm run build
          
      - name: Deploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.SWA_TOKEN }}
          action: upload
          app_location: /
          output_location: dist
          api_location: api
```

---

## Cleanup

```bash
# Delete Static Web App
az staticwebapp delete \
  --name <app> \
  --resource-group <rg> \
  --yes

# Delete resource group
az group delete --name <rg> --yes
```
