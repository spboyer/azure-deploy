# Local Preview Guide

Test your application locally before deploying to Azure. No Azure authentication required.

---

## Quick Test

Run the included test script to verify all local dev servers work:

```bash
./test-local.sh
```

This tests:
- Static HTML with Python HTTP server
- React/Vite with `npm run dev`
- Python Flask with `flask run`
- Azure Functions with `func start`

---

## Quick Reference

| Service Target | Local Tool | Command | Default Port |
|----------------|------------|---------|--------------|
| Static Web Apps | SWA CLI | `swa start` | 4280 |
| Azure Functions | Functions Core Tools | `func start` | 7071 |
| App Service (Node) | npm | `npm run dev` | varies |
| App Service (Python) | Flask | `flask run` | 5000 |
| App Service (.NET) | dotnet | `dotnet run` | 5000 |

---

## Install Local Development Tools

```bash
# Install all tools at once (npm-based)
npm install -g @azure/static-web-apps-cli azure-functions-core-tools@4

# Verify installations
swa --version
func --version
```

---

## Static Web Apps Local Development

### Basic Usage

```bash
# Auto-detect and start
swa start

# Specify output directory
swa start ./dist

# With API folder
swa start ./dist --api-location ./api
```

### With Framework Dev Server

For hot-reload during development:

```bash
# Start your dev server first (in another terminal)
npm run dev  # Runs on http://localhost:3000

# Then proxy through SWA CLI
swa start http://localhost:3000 --api-location ./api
```

### Configuration File

Create `swa-cli.config.json` for persistent settings:

```json
{
  "configurations": {
    "app": {
      "outputLocation": "./dist",
      "apiLocation": "./api",
      "devServerCommand": "npm run dev",
      "devServerUrl": "http://localhost:3000"
    }
  }
}
```

Then just run:
```bash
swa start
```

### Mock Authentication

SWA CLI provides mock auth for testing:

```bash
# Access mock login
http://localhost:4280/.auth/login/github

# Mock user appears as authenticated
# Customize via /.auth/login/<provider>?post_login_redirect_uri=/
```

---

## Azure Functions Local Development

### Basic Usage

```bash
# Start Functions runtime
func start

# Custom port
func start --port 7072

# Enable CORS
func start --cors "*"

# Verbose output
func start --verbose
```

### Local Settings

Create `local.settings.json` (gitignored by default):

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "node"
  },
  "Host": {
    "CORS": "*",
    "CORSCredentials": false
  }
}
```

### With Azurite (Local Storage Emulator)

```bash
# Install Azurite
npm install -g azurite

# Start storage emulator
azurite --silent --location ./azurite --debug ./azurite/debug.log

# In another terminal, start Functions
func start
```

### Debugging

**VS Code:** Use built-in debugging with F5 (launch.json auto-generated).

**Node.js manual:**
```bash
func start --language-worker -- --inspect=9229
```

---

## App Service Local Development

Use your framework's native development server.

### Node.js

```bash
# Express/Fastify/etc.
npm run dev
# or
npm start
# or
node server.js
```

### Python

```bash
# Flask
flask run --debug

# FastAPI
uvicorn main:app --reload --port 8000

# Django
python manage.py runserver
```

### .NET

```bash
# Watch mode (auto-reload)
dotnet watch run

# Standard run
dotnet run
```

### Java Spring Boot

```bash
./mvnw spring-boot:run
# or
./gradlew bootRun
```

---

## Full-Stack Local Development

### SWA + Managed Functions

```bash
# Project structure
project/
├── src/           # Frontend source
├── dist/          # Frontend build output
├── api/           # Functions API
│   ├── host.json
│   └── function1/

# Terminal 1: Build and watch frontend
npm run dev

# Terminal 2: Start SWA with API
swa start http://localhost:3000 --api-location ./api
```

### Separate Frontend + Backend

```bash
# Terminal 1: Backend API (e.g., Express on :3001)
cd backend && npm run dev

# Terminal 2: Frontend (e.g., React on :3000)
cd frontend && npm run dev

# Configure frontend to proxy API calls
# vite.config.js or setupProxy.js
```

**Vite proxy example:**
```javascript
// vite.config.js
export default {
  server: {
    proxy: {
      '/api': 'http://localhost:3001'
    }
  }
}
```

---

## Environment Variables

### Local .env Files

```bash
# .env.local (gitignored)
API_URL=http://localhost:7071/api
DATABASE_URL=mongodb://localhost:27017/dev
```

### Framework Support

| Framework | File | Access |
|-----------|------|--------|
| Vite | `.env.local` | `import.meta.env.VITE_*` |
| Create React App | `.env.local` | `process.env.REACT_APP_*` |
| Next.js | `.env.local` | `process.env.NEXT_PUBLIC_*` |
| Vue CLI | `.env.local` | `process.env.VUE_APP_*` |
| Angular | `environment.ts` | Import directly |

---

## Docker-Based Local Development

### With Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    
  api:
    build: ./api
    ports:
      - "7071:7071"
    environment:
      - AzureWebJobsStorage=UseDevelopmentStorage=true
    
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    ports:
      - "10000:10000"
      - "10001:10001"
      - "10002:10002"
```

```bash
docker-compose up
```

---

## Database Emulators

### Cosmos DB Emulator

```bash
# Docker
docker run -p 8081:8081 -p 10251-10254:10251-10254 \
  mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:latest

# Connection string
AccountEndpoint=https://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
```

### SQL Server

```bash
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong!Passw0rd" \
  -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
```

### Redis

```bash
docker run -p 6379:6379 redis:alpine
```

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

### SWA CLI Issues

```bash
# Clear SWA CLI cache
rm -rf ~/.swa

# Run with debug output
SWA_CLI_DEBUG=* swa start
```

### Functions Core Tools Issues

```bash
# Clear Functions cache
rm -rf ~/.azure-functions-core-tools

# Check Node version (Functions v4 requires Node 18+)
node --version
```

### CORS Errors

Local development often requires CORS configuration:

```bash
# Functions: local.settings.json
{
  "Host": { "CORS": "*" }
}

# Or start with flag
func start --cors "*"
```
