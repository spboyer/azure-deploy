# Azure Container Apps Deployment Guide

Comprehensive guide for deploying containerized applications to Azure Container Apps.

---

## Overview

Azure Container Apps is a serverless container platform for running microservices and containerized applications. Use Container Apps for:

- Applications with Dockerfiles
- Microservices architectures
- Apps requiring custom runtimes or dependencies
- Event-driven processing with scale-to-zero
- Background jobs and workers
- Apps needing Dapr integration

### Container Apps vs App Service

| Factor | Container Apps | App Service |
|--------|---------------|-------------|
| **Best for** | Containers, microservices | Traditional web apps |
| **Requires Docker knowledge** | Yes (or use auto-build) | No |
| **Scale to zero** | ✅ Yes | ❌ No (minimum 1 instance) |
| **Custom runtimes** | ✅ Any container | Limited to supported runtimes |
| **Pricing** | Pay per vCPU-second | Pay per plan (always on) |
| **Dapr support** | ✅ Built-in | ❌ No |

**Choose Container Apps when:**
- You have a Dockerfile
- You need custom system dependencies
- You want scale-to-zero for cost savings
- Building microservices with service discovery
- Need Dapr for distributed app features

**Choose App Service when:**
- No Docker experience needed
- Using standard runtime (Node, Python, .NET, Java)
- Simpler deployment workflow preferred
- Need deployment slots for staging

---

## Quick Start

### Deploy from Source Code (Recommended)

The simplest path - no local Docker required:

```bash
# 1. Create resource group
az group create --name myapp-rg --location eastus

# 2. Deploy directly from source (builds in cloud)
az containerapp up \
  --name myapp \
  --resource-group myapp-rg \
  --source . \
  --ingress external \
  --target-port 8080
```

This command:
- Creates a Container Apps environment (if none exists)
- Creates an Azure Container Registry (if none exists)
- Builds your Dockerfile in the cloud
- Deploys the container

### Deploy from Existing Image

```bash
# Create environment first
az containerapp env create \
  --name myapp-env \
  --resource-group myapp-rg \
  --location eastus

# Deploy from Docker Hub or ACR
az containerapp create \
  --name myapp \
  --resource-group myapp-rg \
  --environment myapp-env \
  --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
  --target-port 80 \
  --ingress external
```

---

## Hosting Plans

### Consumption (Default - Recommended)

Serverless, pay-per-use, scales to zero:

```bash
# Consumption is the default - no extra flags needed
az containerapp env create \
  --name <env-name> \
  --resource-group <rg> \
  --location <location>
```

**Features:**
- Scale to zero when idle
- Auto-scale based on HTTP traffic, events, or custom rules
- Pay only for active compute time
- Up to 4 vCPU, 8 GB memory per container

### Dedicated (Workload Profiles)

For GPU workloads, larger containers, or reserved capacity:

```bash
# Create environment with workload profiles
az containerapp env create \
  --name <env-name> \
  --resource-group <rg> \
  --location <location> \
  --enable-workload-profiles

# Add a dedicated workload profile
az containerapp env workload-profile add \
  --name <env-name> \
  --resource-group <rg> \
  --workload-profile-type D4 \
  --workload-profile-name "dedicated" \
  --min-nodes 1 \
  --max-nodes 3
```

**Workload Profile Types:**
- `D4` - 4 vCPU, 16 GB (general purpose)
- `D8` - 8 vCPU, 32 GB
- `D16` - 16 vCPU, 64 GB
- `E4` - 4 vCPU, 32 GB (memory optimized)
- `NC24` - GPU enabled (check regional availability)

---

## Dockerfile Generation

If your project doesn't have a Dockerfile, create one based on your framework:

### Node.js

```dockerfile
# Node.js Dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:22-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
```

**For Next.js:**
```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
ENV PORT=3000
CMD ["node", "server.js"]
```

### Python (Flask/FastAPI)

```dockerfile
# Python Dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

# Flask
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]

# FastAPI (uncomment below, comment above)
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### .NET

```dockerfile
# .NET Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

### Java (Spring Boot)

```dockerfile
# Spring Boot Dockerfile
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY . .
RUN ./mvnw package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Go

```dockerfile
# Go Dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

### .dockerignore

Always include a `.dockerignore`:

```
node_modules
.git
.gitignore
*.md
.env*
.vscode
__pycache__
*.pyc
.pytest_cache
venv
.venv
bin
obj
target
.idea
```

---

## Local Preview with Docker Compose

Test your containerized app locally before deploying:

### Basic docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=mongodb://db:27017/myapp
    depends_on:
      - db

  db:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
```

### Run Locally

```bash
# Build and start
docker-compose up --build

# Run in background
docker-compose up -d --build

# View logs
docker-compose logs -f app

# Stop
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Multi-Service Example

```yaml
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - API_URL=http://api:8080
    depends_on:
      - api

  api:
    build: ./api
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgres://postgres:password@db:5432/myapp
      - REDIS_URL=redis://cache:6379
    depends_on:
      - db
      - cache

  db:
    image: postgres:16
    environment:
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=myapp
    volumes:
      - postgres-data:/var/lib/postgresql/data

  cache:
    image: redis:alpine

volumes:
  postgres-data:
```

---

## ACR Integration

### Create Azure Container Registry

```bash
# Create ACR (Basic tier for dev, Standard/Premium for production)
az acr create \
  --name <acr-name> \
  --resource-group <rg> \
  --sku Basic \
  --admin-enabled true
```

### Build in Cloud (Recommended)

No local Docker required:

```bash
# Build image in ACR
az acr build \
  --registry <acr-name> \
  --image myapp:latest \
  .
```

### Push from Local

```bash
# Login to ACR
az acr login --name <acr-name>

# Build locally
docker build -t <acr-name>.azurecr.io/myapp:latest .

# Push
docker push <acr-name>.azurecr.io/myapp:latest
```

### Deploy from ACR

```bash
# With managed identity (recommended)
az containerapp create \
  --name <app-name> \
  --resource-group <rg> \
  --environment <env-name> \
  --image <acr-name>.azurecr.io/myapp:latest \
  --registry-server <acr-name>.azurecr.io \
  --target-port 8080 \
  --ingress external

# With admin credentials (simpler but less secure)
az containerapp create \
  --name <app-name> \
  --resource-group <rg> \
  --environment <env-name> \
  --image <acr-name>.azurecr.io/myapp:latest \
  --registry-server <acr-name>.azurecr.io \
  --registry-username <username> \
  --registry-password <password> \
  --target-port 8080 \
  --ingress external
```

---

## Environment Variables & Secrets

### Set Environment Variables

```bash
# During creation
az containerapp create \
  --name <app-name> \
  --resource-group <rg> \
  --environment <env-name> \
  --image <image> \
  --env-vars \
    NODE_ENV=production \
    API_URL=https://api.example.com

# Update existing app
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --set-env-vars \
    NEW_VAR=value \
    ANOTHER_VAR=value2
```

### Manage Secrets

```bash
# Add secrets
az containerapp secret set \
  --name <app-name> \
  --resource-group <rg> \
  --secrets \
    db-password=supersecret \
    api-key=myapikey

# Use secret as env var
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --set-env-vars \
    DATABASE_PASSWORD=secretref:db-password

# List secrets
az containerapp secret list \
  --name <app-name> \
  --resource-group <rg>
```

### Reference Key Vault Secrets

```bash
# Enable managed identity
az containerapp identity assign \
  --name <app-name> \
  --resource-group <rg> \
  --system-assigned

# Grant Key Vault access (get identity principal ID first)
PRINCIPAL_ID=$(az containerapp identity show \
  --name <app-name> \
  --resource-group <rg> \
  --query principalId -o tsv)

az keyvault set-policy \
  --name <keyvault-name> \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get

# Add Key Vault reference
az containerapp secret set \
  --name <app-name> \
  --resource-group <rg> \
  --secrets "db-conn=keyvaultref:<keyvault-uri>/secrets/db-connection,identityref:system"
```

---

## Scaling Configuration

### HTTP Scaling (Default)

```bash
# Set min/max replicas
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --min-replicas 0 \
  --max-replicas 10

# Configure HTTP scaling rule
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 100
```

### Event-Driven Scaling (KEDA)

```bash
# Scale on Azure Queue messages
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --scale-rule-name queue-rule \
  --scale-rule-type azure-queue \
  --scale-rule-metadata \
    queueName=myqueue \
    queueLength=10 \
  --scale-rule-auth \
    connection=queue-connection-string
```

### CPU/Memory Scaling

```bash
# Scale based on CPU utilization
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --scale-rule-name cpu-rule \
  --scale-rule-type cpu \
  --scale-rule-metadata \
    type=utilization \
    value=70
```

---

## Ingress & Networking

### External Ingress (Public)

```bash
az containerapp ingress enable \
  --name <app-name> \
  --resource-group <rg> \
  --type external \
  --target-port 8080 \
  --transport auto
```

### Internal Ingress (Private)

For service-to-service communication:

```bash
az containerapp ingress enable \
  --name <app-name> \
  --resource-group <rg> \
  --type internal \
  --target-port 8080
```

### Custom Domain & SSL

```bash
# Add custom domain
az containerapp hostname add \
  --name <app-name> \
  --resource-group <rg> \
  --hostname www.example.com

# Bind managed certificate
az containerapp hostname bind \
  --name <app-name> \
  --resource-group <rg> \
  --hostname www.example.com \
  --environment <env-name> \
  --validation-method CNAME
```

---

## Health Probes

### Configure Probes

```bash
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --container-name <container-name> \
  --set-probes '[
    {
      "type": "liveness",
      "httpGet": {
        "path": "/health",
        "port": 8080
      },
      "initialDelaySeconds": 10,
      "periodSeconds": 30
    },
    {
      "type": "readiness",
      "httpGet": {
        "path": "/ready",
        "port": 8080
      },
      "initialDelaySeconds": 5,
      "periodSeconds": 10
    }
  ]'
```

### Probe Types

| Probe | Purpose | Action on Failure |
|-------|---------|-------------------|
| **Startup** | Wait for app to start | Delay other probes |
| **Liveness** | Check if app is alive | Restart container |
| **Readiness** | Check if app can serve traffic | Remove from load balancer |

---

## Logging & Monitoring

### View Logs

```bash
# Stream live logs
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg> \
  --follow

# System logs
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg> \
  --type system

# Console logs
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg> \
  --type console
```

### Log Analytics

```bash
# Query logs via Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'myapp' | take 100"
```

### Application Insights

```bash
# Enable Application Insights on environment
az containerapp env update \
  --name <env-name> \
  --resource-group <rg> \
  --dapr-instrumentation-key <app-insights-key>
```

---

## Revisions & Traffic Splitting

### Deploy New Revision

```bash
# Update triggers new revision automatically
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --image <new-image>:v2

# Set revision mode to multiple
az containerapp revision set-mode \
  --name <app-name> \
  --resource-group <rg> \
  --mode multiple
```

### Traffic Splitting

```bash
# Split traffic between revisions
az containerapp ingress traffic set \
  --name <app-name> \
  --resource-group <rg> \
  --revision-weight \
    myapp--rev1=80 \
    myapp--rev2=20

# Route 100% to latest
az containerapp ingress traffic set \
  --name <app-name> \
  --resource-group <rg> \
  --revision-weight latest=100
```

---

## Common Configurations by Framework

### Node.js / Express

```bash
# Deploy
az containerapp up \
  --name myapp \
  --resource-group myapp-rg \
  --source . \
  --target-port 8080 \
  --ingress external \
  --env-vars NODE_ENV=production
```

### Python / FastAPI

```bash
# Deploy
az containerapp up \
  --name myapi \
  --resource-group myapp-rg \
  --source . \
  --target-port 8080 \
  --ingress external
```

### .NET

```bash
# Deploy
az containerapp up \
  --name mydotnetapp \
  --resource-group myapp-rg \
  --source . \
  --target-port 8080 \
  --ingress external
```

### Next.js (Standalone)

Ensure `next.config.js` has:
```javascript
module.exports = {
  output: 'standalone',
}
```

```bash
az containerapp up \
  --name mynextapp \
  --resource-group myapp-rg \
  --source . \
  --target-port 3000 \
  --ingress external \
  --env-vars NODE_ENV=production
```

---

## Troubleshooting

### Build Fails

```bash
# Check build logs
az acr task logs --registry <acr-name>

# Build locally to debug
docker build -t test .

# Common issues:
# - Missing files in build context (check .dockerignore)
# - Wrong base image platform (use --platform linux/amd64)
# - Missing dependencies in Dockerfile
```

### App Won't Start

```bash
# Check container logs
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg> \
  --type console

# Common issues:
# - Wrong target port (must match EXPOSE in Dockerfile)
# - App binding to localhost instead of 0.0.0.0
# - Missing environment variables
# - Health probe failing
```

### Connection Refused

```bash
# Verify ingress is enabled
az containerapp ingress show \
  --name <app-name> \
  --resource-group <rg>

# Check app is listening on correct port
# In your app, bind to 0.0.0.0:$PORT, not localhost
```

### ACR Authentication Failed

```bash
# Enable admin credentials (simplest)
az acr update --name <acr-name> --admin-enabled true

# Or use managed identity (more secure)
az containerapp registry set \
  --name <app-name> \
  --resource-group <rg> \
  --server <acr-name>.azurecr.io \
  --identity system
```

### Out of Memory

```bash
# Increase container resources
az containerapp update \
  --name <app-name> \
  --resource-group <rg> \
  --cpu 1.0 \
  --memory 2.0Gi
```

**Resource Limits (Consumption plan):**
- CPU: 0.25 - 4 cores
- Memory: 0.5 - 8 GB
- Memory must be 2x CPU (e.g., 0.5 CPU = 1GB memory minimum)

---

## Cleanup

```bash
# Delete Container App
az containerapp delete \
  --name <app-name> \
  --resource-group <rg> \
  --yes

# Delete environment (removes all apps in environment)
az containerapp env delete \
  --name <env-name> \
  --resource-group <rg> \
  --yes

# Delete resource group (removes everything)
az group delete --name <rg> --yes
```

---

## CLI Reference

```bash
# List apps
az containerapp list --resource-group <rg> --output table

# Show app details
az containerapp show --name <app> --resource-group <rg>

# List revisions
az containerapp revision list --name <app> --resource-group <rg>

# Restart app
az containerapp revision restart \
  --name <app> \
  --resource-group <rg> \
  --revision <revision-name>

# Get app URL
az containerapp show \
  --name <app> \
  --resource-group <rg> \
  --query properties.configuration.ingress.fqdn -o tsv
```
