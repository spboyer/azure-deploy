#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Azure Deploy Skill - Local Preview Tests
# Tests that applications can run locally before deployment
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/test-scenarios"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Results tracking
declare -a RESULTS
RESULTS=()

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

record_result() {
    local name="$1"
    local status="$2"
    local note="${3:-}"
    if [[ "$status" == "PASS" ]]; then
        RESULTS+=("✓ $name")
    else
        RESULTS+=("✗ $name: $note")
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}=======================================${NC}"
    echo -e "${BOLD}Test Summary${NC}"
    echo -e "${BOLD}=======================================${NC}"
    
    local passed=0
    local failed=0
    
    for result in "${RESULTS[@]}"; do
        echo "$result"
        if [[ "$result" == ✓* ]]; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    echo -e "Passed: ${GREEN}$passed${NC} | Failed: ${RED}$failed${NC}"
    
    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=()
    
    command -v node >/dev/null 2>&1 || missing+=("node")
    command -v npm >/dev/null 2>&1 || missing+=("npm")
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    command -v func >/dev/null 2>&1 || missing+=("func (Azure Functions Core Tools)")
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_fail "Missing prerequisites: ${missing[*]}"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Wait for server to be ready
wait_for_server() {
    local url="$1"
    local max_attempts="${2:-30}"
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s --max-time 2 "$url" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    return 1
}

# Kill process on port
kill_port() {
    local port="$1"
    lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
}

# =============================================================================
# Test 1: Static HTML with Python HTTP Server
# =============================================================================
test_static_html() {
    local test_name="Static HTML (Python HTTP Server)"
    log_info "Testing: $test_name"
    
    local test_path="$TEST_DIR/static-html"
    local port=8080
    
    # Kill any existing process on port
    kill_port $port
    
    cd "$test_path"
    
    # Start Python HTTP server in background
    python3 -m http.server $port >/dev/null 2>&1 &
    local pid=$!
    
    # Wait for server
    if ! wait_for_server "http://localhost:$port" 10; then
        kill $pid 2>/dev/null || true
        record_result "$test_name" "FAIL" "Server failed to start"
        return
    fi
    
    # Test the endpoint
    if curl -s "http://localhost:$port" | grep -q "Hello from Static HTML"; then
        record_result "$test_name" "PASS"
        log_success "$test_name - http://localhost:$port"
    else
        record_result "$test_name" "FAIL" "Content verification failed"
    fi
    
    # Cleanup
    kill $pid 2>/dev/null || true
}

# =============================================================================
# Test 2: React/Vite Dev Server
# =============================================================================
test_react_vite() {
    local test_name="React/Vite (npm run dev)"
    log_info "Testing: $test_name"
    
    local test_path="$TEST_DIR/react-app"
    local port=5173
    
    # Kill any existing process on port
    kill_port $port
    
    cd "$test_path"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        npm install --silent 2>/dev/null || true
    fi
    
    # Start Vite dev server in background
    npm run dev >/dev/null 2>&1 &
    local pid=$!
    
    # Wait for server (Vite can take a moment)
    if ! wait_for_server "http://localhost:$port" 30; then
        kill $pid 2>/dev/null || true
        kill_port $port
        record_result "$test_name" "FAIL" "Server failed to start"
        return
    fi
    
    # Test the endpoint
    if curl -s "http://localhost:$port" | grep -q -E "(React|Vite|root)"; then
        record_result "$test_name" "PASS"
        log_success "$test_name - http://localhost:$port"
    else
        record_result "$test_name" "FAIL" "Content verification failed"
    fi
    
    # Cleanup
    kill $pid 2>/dev/null || true
    kill_port $port
}

# =============================================================================
# Test 3: Python Flask Dev Server
# =============================================================================
test_python_flask() {
    local test_name="Python Flask (flask run)"
    log_info "Testing: $test_name"
    
    local test_path="$TEST_DIR/python-flask"
    local port=5000
    
    # Kill any existing process on port
    kill_port $port
    
    cd "$test_path"
    
    # Create/activate venv and install deps
    if [[ ! -d ".venv" ]]; then
        python3 -m venv .venv
    fi
    source .venv/bin/activate
    pip install -q flask gunicorn 2>/dev/null
    
    # Start Flask dev server in background
    FLASK_APP=app.py flask run --port $port >/dev/null 2>&1 &
    local pid=$!
    
    # Wait for server
    if ! wait_for_server "http://localhost:$port" 15; then
        kill $pid 2>/dev/null || true
        deactivate 2>/dev/null || true
        record_result "$test_name" "FAIL" "Server failed to start"
        return
    fi
    
    # Test the health endpoint
    if curl -s "http://localhost:$port/health" | grep -q "OK"; then
        record_result "$test_name" "PASS"
        log_success "$test_name - http://localhost:$port"
    else
        record_result "$test_name" "FAIL" "Health check failed"
    fi
    
    # Cleanup
    kill $pid 2>/dev/null || true
    deactivate 2>/dev/null || true
}

# =============================================================================
# Test 4: Azure Functions (func start)
# =============================================================================
test_azure_functions() {
    local test_name="Azure Functions (func start)"
    log_info "Testing: $test_name"
    
    local test_path="$TEST_DIR/azure-functions"
    local port=7071
    
    # Kill any existing process on port
    kill_port $port
    
    cd "$test_path"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        npm install --silent 2>/dev/null || true
    fi
    
    # Start Functions runtime in background
    func start --port $port >/dev/null 2>&1 &
    local pid=$!
    
    # Wait for server (Functions runtime can take longer)
    if ! wait_for_server "http://localhost:$port/api/hello" 45; then
        kill $pid 2>/dev/null || true
        kill_port $port
        record_result "$test_name" "FAIL" "Server failed to start"
        return
    fi
    
    # Test the function endpoint
    if curl -s "http://localhost:$port/api/hello?name=LocalTest" | grep -q "Hello"; then
        record_result "$test_name" "PASS"
        log_success "$test_name - http://localhost:$port/api/hello"
    else
        record_result "$test_name" "FAIL" "Function response verification failed"
    fi
    
    # Cleanup
    kill $pid 2>/dev/null || true
    kill_port $port
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo -e "${BOLD}=======================================${NC}"
    echo -e "${BOLD}Azure Deploy Skill - Local Preview Tests${NC}"
    echo -e "${BOLD}=======================================${NC}"
    echo ""
    
    check_prerequisites
    
    echo ""
    echo -e "${BOLD}Running local preview tests...${NC}"
    echo ""
    
    # Run tests
    test_static_html
    test_react_vite
    test_python_flask
    test_azure_functions
    
    print_summary
}

main "$@"
