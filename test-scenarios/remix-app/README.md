# Remix App Test Scenario

A Remix v2 application using Vite. Remix apps require server-side rendering
and should be deployed to **App Service** (not Static Web Apps).

## Detection Signals
- `package.json` with `@remix-run/*` dependencies
- `vite.config.ts` with remix plugin
- Has `remix-serve` for production server

## Expected Detection
- Service: App Service
- Confidence: MEDIUM (framework detection from dependencies)
