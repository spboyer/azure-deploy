#!/bin/bash
# Azure Deploy Skill - Detection Test Script
# Tests the app detection logic from SKILL.md against sample projects

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

detect_app_type() {
    local dir=$1
    local result=""
    local confidence="LOW"
    
    echo -e "${BOLD}Scanning: $dir${NC}"
    
    # HIGH confidence: Azure config files
    if [[ -f "$dir/azure.yaml" ]]; then
        result="azd project (already configured)"
        confidence="HIGH"
    elif [[ -f "$dir/host.json" ]]; then
        result="Azure Functions"
        confidence="HIGH"
    elif [[ -f "$dir/staticwebapp.config.json" ]]; then
        result="Static Web Apps"
        confidence="HIGH"
    # MEDIUM confidence: Framework detection
    elif [[ -f "$dir/package.json" ]]; then
        # Check for specific frameworks
        if [[ -f "$dir/next.config.js" ]] || [[ -f "$dir/next.config.mjs" ]] || [[ -f "$dir/next.config.ts" ]]; then
            # Check for static export - if NOT present, it's SSR
            if grep -q "output.*export" "$dir/next.config.js" 2>/dev/null || \
               grep -q "output.*export" "$dir/next.config.mjs" 2>/dev/null || \
               grep -q "output.*export" "$dir/next.config.ts" 2>/dev/null; then
                result="Static Web Apps (Next.js SSG)"
            else
                result="App Service (Next.js SSR)"
            fi
            confidence="MEDIUM"
        elif [[ -f "$dir/nuxt.config.ts" ]] || [[ -f "$dir/nuxt.config.js" ]]; then
            result="App Service (Nuxt SSR) or Static Web Apps (if static)"
            confidence="MEDIUM"
        elif [[ -f "$dir/angular.json" ]]; then
            result="Static Web Apps (Angular)"
            confidence="MEDIUM"
        elif [[ -f "$dir/vite.config.js" ]] || [[ -f "$dir/vite.config.ts" ]]; then
            result="Static Web Apps (Vite-based)"
            confidence="MEDIUM"
        elif [[ -f "$dir/gatsby-config.js" ]]; then
            result="Static Web Apps (Gatsby)"
            confidence="MEDIUM"
        elif [[ -f "$dir/astro.config.mjs" ]]; then
            result="Static Web Apps (Astro)"
            confidence="MEDIUM"
        elif grep -q "express\|fastify\|koa\|hapi" "$dir/package.json" 2>/dev/null; then
            result="App Service (Node.js backend)"
            confidence="MEDIUM"
        elif grep -q "@azure/functions" "$dir/package.json" 2>/dev/null; then
            result="Azure Functions (Node.js)"
            confidence="MEDIUM"
        else
            result="Static Web Apps (generic Node.js)"
            confidence="LOW"
        fi
    elif [[ -f "$dir/requirements.txt" ]]; then
        if [[ -f "$dir/function_app.py" ]]; then
            result="Azure Functions (Python v2)"
            confidence="HIGH"
        elif grep -q "flask" "$dir/requirements.txt" 2>/dev/null; then
            result="App Service (Flask)"
            confidence="MEDIUM"
        elif grep -q "django" "$dir/requirements.txt" 2>/dev/null; then
            result="App Service (Django)"
            confidence="MEDIUM"
        elif grep -q "fastapi" "$dir/requirements.txt" 2>/dev/null; then
            result="App Service (FastAPI)"
            confidence="MEDIUM"
        elif grep -q "azure-functions" "$dir/requirements.txt" 2>/dev/null; then
            result="Azure Functions (Python)"
            confidence="MEDIUM"
        else
            result="App Service (Python)"
            confidence="LOW"
        fi
    elif [[ -f "$dir/index.html" ]] && [[ ! -f "$dir/package.json" ]]; then
        result="Static Web Apps (pure static)"
        confidence="HIGH"
    else
        result="Unknown - needs clarification"
        confidence="LOW"
    fi
    
    # Check for multi-service indicators
    local is_multiservice=false
    if [[ -d "$dir/frontend" ]] || [[ -d "$dir/backend" ]] || [[ -d "$dir/api" ]] || [[ -d "$dir/packages" ]]; then
        is_multiservice=true
    fi
    if [[ -f "$dir/docker-compose.yml" ]] || [[ -f "$dir/docker-compose.yaml" ]]; then
        is_multiservice=true
    fi
    # Check for multiple package.json files
    local pkg_count=$(find "$dir" -maxdepth 3 -name "package.json" 2>/dev/null | wc -l)
    if [[ $pkg_count -gt 1 ]]; then
        is_multiservice=true
    fi
    
    # Output results
    echo -e "  ${BLUE}Detected:${NC} $result"
    if [[ "$confidence" == "HIGH" ]]; then
        echo -e "  ${GREEN}Confidence:${NC} $confidence"
    elif [[ "$confidence" == "MEDIUM" ]]; then
        echo -e "  ${YELLOW}Confidence:${NC} $confidence"
    else
        echo -e "  ${YELLOW}Confidence:${NC} $confidence (would ask clarifying questions)"
    fi
    
    if [[ "$is_multiservice" == true ]]; then
        echo -e "  ${YELLOW}⚠ Multi-service detected:${NC} Recommend azd + IaC"
    fi
    echo ""
}

echo -e "${BOLD}=======================================${NC}"
echo -e "${BOLD}Azure Deploy Skill - Detection Tests${NC}"
echo -e "${BOLD}=======================================${NC}"
echo ""

# Run detection on each test scenario
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$SCRIPT_DIR/test-scenarios"

for scenario in "$TEST_DIR"/*; do
    if [[ -d "$scenario" ]]; then
        detect_app_type "$scenario"
    fi
done

echo -e "${BOLD}=======================================${NC}"
echo -e "${GREEN}Detection tests complete!${NC}"
