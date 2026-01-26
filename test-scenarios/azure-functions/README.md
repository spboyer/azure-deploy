# Azure Functions Test Project

Node.js v4 programming model Azure Functions project for testing deployment.

## Local Development

```bash
npm install
func start
```

## Test the Function

```bash
curl http://localhost:7071/api/hello
curl "http://localhost:7071/api/hello?name=Azure"
```

## Deploy to Azure

```bash
func azure functionapp publish <function-app-name>
```
