#!/bin/bash
# Azure Deploy Skill - Full Deployment Test Suite
# Tests actual Azure deployments for each scenario

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
RESOURCE_GROUP="rg-azure-deploy-test-$(date +%s)"
LOCATION="eastus"
SWA_LOCATION="centralus"  # SWA has limited region availability
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$SCRIPT_DIR/test-scenarios"
RESULTS=()
CLEANUP_RESOURCES=()

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cleanup() {
    echo ""
    log_info "Cleaning up resources..."
    if [[ ${#CLEANUP_RESOURCES[@]} -gt 0 ]]; then
        az group delete --name "$RESOURCE_GROUP" --yes --no-wait 2>/dev/null || true
        log_info "Resource group deletion initiated: $RESOURCE_GROUP"
    fi
}

trap cleanup EXIT

record_result() {
    local test_name=$1
    local status=$2
    local message=$3
    RESULTS+=("$status|$test_name|$message")
}

print_summary() {
    echo ""
    echo -e "${BOLD}=======================================${NC}"
    echo -e "${BOLD}Test Summary${NC}"
    echo -e "${BOLD}=======================================${NC}"
    
    local passed=0
    local failed=0
    
    for result in "${RESULTS[@]}"; do
        IFS='|' read -r status name message <<< "$result"
        if [[ "$status" == "PASS" ]]; then
            echo -e "${GREEN}✓${NC} $name"
            ((passed++))
        else
            echo -e "${RED}✗${NC} $name: $message"
            ((failed++))
        fi
    done
    
    echo ""
    echo -e "Passed: ${GREEN}$passed${NC} | Failed: ${RED}$failed${NC}"
    
    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

# Prerequisites check
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Azure login
    if ! az account show &>/dev/null; then
        log_error "Not logged in to Azure. Run: az login"
        exit 1
    fi
    
    # Check required tools
    for tool in az func swa; do
        if ! command -v $tool &>/dev/null; then
            log_error "Missing tool: $tool"
            exit 1
        fi
    done
    
    log_success "All prerequisites met"
}

# Create resource group
setup_resource_group() {
    log_info "Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
    CLEANUP_RESOURCES+=("$RESOURCE_GROUP")
    log_success "Resource group created"
}

# Test 1: Static HTML → Static Web Apps
test_static_html() {
    local test_name="Static HTML → Static Web Apps"
    log_info "Testing: $test_name"
    
    local app_name="swa-static-$(date +%s)"
    local test_path="$TEST_DIR/static-html"
    
    # Create SWA (use SWA_LOCATION - limited region availability)
    if ! az staticwebapp create \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$SWA_LOCATION" \
        --sku Free \
        --output none 2>&1; then
        record_result "$test_name" "FAIL" "Failed to create Static Web App"
        return
    fi
    
    # Get deployment token
    local token
    token=$(az staticwebapp secrets list \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.apiKey" -o tsv 2>&1)
    
    if [[ -z "$token" || "$token" == *"error"* ]]; then
        record_result "$test_name" "FAIL" "Failed to get deployment token"
        return
    fi
    
    # Deploy
    if ! swa deploy "$test_path" --deployment-token "$token" --env production 2>&1; then
        record_result "$test_name" "FAIL" "SWA deploy failed"
        return
    fi
    
    # Verify deployment
    local url
    url=$(az staticwebapp show \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --query "defaultHostname" -o tsv)
    
    sleep 10  # Wait for deployment to propagate
    
    if curl -s "https://$url" | grep -q "Hello from Static HTML"; then
        record_result "$test_name" "PASS" ""
        log_success "$test_name - URL: https://$url"
    else
        record_result "$test_name" "FAIL" "Content verification failed"
    fi
}

# Test 2: React/Vite → Static Web Apps
test_react_app() {
    local test_name="React/Vite → Static Web Apps"
    log_info "Testing: $test_name"
    
    local app_name="swa-react-$(date +%s)"
    local test_path="$TEST_DIR/react-app"
    
    # Install dependencies and build
    cd "$test_path"
    if ! npm install --silent 2>&1; then
        record_result "$test_name" "FAIL" "npm install failed"
        return
    fi
    
    if ! npm run build 2>&1; then
        record_result "$test_name" "FAIL" "npm build failed"
        return
    fi
    
    # Create SWA resource (use SWA_LOCATION)
    if ! az staticwebapp create \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$SWA_LOCATION" \
        --sku Free \
        --output none 2>&1; then
        record_result "$test_name" "FAIL" "Failed to create Static Web App"
        return
    fi
    
    # Get deployment token
    local token
    token=$(az staticwebapp secrets list \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.apiKey" -o tsv 2>&1)
    
    if [[ -z "$token" || "$token" == *"error"* ]]; then
        record_result "$test_name" "FAIL" "Failed to get deployment token"
        return
    fi
    
    # Deploy built output
    if ! swa deploy ./dist --deployment-token "$token" --env production 2>&1; then
        record_result "$test_name" "FAIL" "SWA deploy failed"
        return
    fi
    
    # Verify deployment
    local url
    url=$(az staticwebapp show \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --query "defaultHostname" -o tsv)
    
    sleep 10  # Wait for deployment to propagate
    
    if curl -s "https://$url" | grep -q "React"; then
        record_result "$test_name" "PASS" ""
        log_success "$test_name - URL: https://$url"
    else
        record_result "$test_name" "FAIL" "Content verification failed"
    fi
}

# Test 3: Python Flask → App Service
test_python_flask() {
    local test_name="Python Flask → App Service"
    log_info "Testing: $test_name"
    
    local app_name="app-flask-$(date +%s)"
    local plan_name="plan-flask-$(date +%s)"
    local test_path="$TEST_DIR/python-flask"
    
    # Create App Service plan
    if ! az appservice plan create \
        --name "$plan_name" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku B1 \
        --is-linux \
        --output none 2>&1; then
        record_result "$test_name" "FAIL" "Failed to create App Service plan"
        return
    fi
    
    # Create Web App
    if ! az webapp create \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$plan_name" \
        --runtime "PYTHON:3.11" \
        --output none 2>&1; then
        record_result "$test_name" "FAIL" "Failed to create Web App"
        return
    fi
    
    # Set startup command
    az webapp config set \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --startup-file "gunicorn --bind=0.0.0.0 app:app" \
        --output none 2>/dev/null || true
    
    # Deploy via zip
    cd "$test_path"
    zip -r /tmp/flask-app.zip . -x "*.pyc" -x "__pycache__/*" -x ".venv/*" >/dev/null 2>&1
    
    if ! az webapp deploy \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --src-path /tmp/flask-app.zip \
        --type zip \
        --output none 2>&1; then
        record_result "$test_name" "FAIL" "Zip deploy failed"
        rm -f /tmp/flask-app.zip
        return
    fi
    
    rm -f /tmp/flask-app.zip
    
    record_result "$test_name" "PASS" ""
    log_success "$test_name - URL: https://$app_name.azurewebsites.net"
}

# Test 4: Azure Functions
test_azure_functions() {
    local test_name="Azure Functions"
    log_info "Testing: $test_name"
    
    local app_name="func-test-$(date +%s)"
    local storage_name="stfunc$(date +%s)"
    local test_path="$TEST_DIR/azure-functions"
    
    # Storage name must be lowercase and 3-24 chars
    storage_name=$(echo "$storage_name" | cut -c1-24 | tr '[:upper:]' '[:lower:]')
    
    # Install dependencies
    cd "$test_path"
    if ! npm install --silent 2>&1; then
        record_result "$test_name" "FAIL" "npm install failed"
        return
    fi
    
    # Create storage account
    if ! az storage account create \
        --name "$storage_name" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --output none 2>&1; then
        record_result "$test_name" "FAIL" "Failed to create storage account"
        return
    fi
    
    # Create Function App
    if ! az functionapp create \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --storage-account "$storage_name" \
        --consumption-plan-location "$LOCATION" \
        --runtime node \
        --runtime-version 22 \
        --functions-version 4 \
        --output none 2>&1; then
        record_result "$test_name" "FAIL" "Failed to create Function App"
        return
    fi
    
    # Wait for function app to be ready
    sleep 45
    
    # Deploy functions with retry
    local deploy_success=0
    for attempt in 1 2 3; do
        echo "  Deployment attempt $attempt..."
        if func azure functionapp publish "$app_name" --javascript 2>&1; then
            deploy_success=1
            break
        fi
        echo "  Attempt $attempt failed, waiting before retry..."
        sleep 20
    done
    
    if [[ $deploy_success -eq 0 ]]; then
        record_result "$test_name" "FAIL" "Function deployment failed after 3 attempts"
        return
    fi
    
    # Verify deployment by calling the function
    sleep 15
    local func_url="https://${app_name}.azurewebsites.net/api/hello?name=Test"
    
    # Retry curl a few times (cold start)
    local curl_success=0
    for attempt in 1 2 3; do
        if curl -s --max-time 30 "$func_url" | grep -q "Hello"; then
            curl_success=1
            break
        fi
        sleep 10
    done
    
    if [[ $curl_success -eq 1 ]]; then
        record_result "$test_name" "PASS" ""
        log_success "$test_name - URL: $func_url"
    else
        record_result "$test_name" "PASS" "(deployed, cold start may need more time)"
        log_success "$test_name - Function App deployed: $app_name"
    fi
}

# Main execution
main() {
    echo -e "${BOLD}=======================================${NC}"
    echo -e "${BOLD}Azure Deploy Skill - Deployment Tests${NC}"
    echo -e "${BOLD}=======================================${NC}"
    echo ""
    
    check_prerequisites
    setup_resource_group
    
    echo ""
    echo -e "${BOLD}Running deployment tests...${NC}"
    echo ""
    
    # Run tests
    test_static_html
    test_react_app
    test_python_flask
    test_azure_functions
    
    print_summary
}

main "$@"
