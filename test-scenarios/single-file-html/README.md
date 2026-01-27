# Single File HTML Test Scenario

This test scenario validates deployment of a single HTML file to Azure Static Web Apps.

## Purpose

Tests the edge case where a user has only a single `index.html` file with no build process, no package.json, and no other configuration files.

## Expected Behavior

The deployment should:
1. Detect it's a plain HTML site
2. Create a temporary `dist` folder
3. Copy the HTML file to `dist/`
4. Deploy from the `dist/` folder
5. Clean up the temporary folder

## Testing

```bash
# From repository root
./test-deploy.sh
```
