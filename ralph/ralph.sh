#!/usr/bin/env bash
set -euo pipefail

# Ralph runner wrapper for Azure Deploy skill testing
# Usage: ./ralph/ralph.sh <iterations>
#        ./ralph/ralph.sh --detection <iterations>
#        ./ralph/ralph.sh --deploy <iterations>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE
Usage:
  $0 [--detection|--deploy] <iterations>

Modes:
  (default)     Run full test suite (detection + deployment)
  --detection   Run detection tests only (no Azure resources)
  --deploy      Run deployment tests only (requires Azure auth)

Examples:
  $0 5                    # Run 5 iterations of full tests
  $0 --detection 10       # Run 10 iterations of detection tests
  $0 --deploy 3           # Run 3 iterations of deployment tests
  
Environment:
  MODEL         Copilot model to use (default: gpt-5.2)
USAGE
}

mode="full"
iterations=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --detection)
      mode="detection"
      shift
      ;;
    --deploy)
      mode="deploy"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$iterations" ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
        iterations="$1"
        shift
      else
        echo "Error: unknown argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$iterations" ]]; then
  echo "Error: missing <iterations>" >&2
  usage
  exit 1
fi

cd "$PROJECT_ROOT"

# Check for Ralph scripts in parent or sibling
RALPH_SCRIPT=""
for path in "../ralph/ralph.sh" "../../ralph/ralph.sh" "$HOME/ralph/ralph.sh"; do
  if [[ -x "$path" ]]; then
    RALPH_SCRIPT="$path"
    break
  fi
done

if [[ -z "$RALPH_SCRIPT" ]]; then
  echo "Error: ralph.sh not found. Please clone https://github.com/soderlind/ralph"
  echo "Expected locations: ../ralph/, ../../ralph/, or ~/ralph/"
  exit 1
fi

# Select prompt and PRD based on mode
case "$mode" in
  detection)
    prompt="ralph/prompts/azure-deploy-detection.txt"
    prd="ralph/plans/prd-azure-deploy-detection.json"
    profile="locked"  # Detection only needs file access
    ;;
  deploy)
    prompt="ralph/prompts/azure-deploy-deploy.txt"
    prd="ralph/plans/prd-azure-deploy-deploy.json"
    profile="dev"  # Deployment needs shell access for az/swa/func
    ;;
  *)
    prompt="ralph/prompts/azure-deploy.txt"
    prd="ralph/plans/prd.json"
    profile="dev"
    ;;
esac

echo "======================================="
echo "Azure Deploy Skill - Ralph Testing"
echo "======================================="
echo "Mode: $mode"
echo "Iterations: $iterations"
echo "Prompt: $prompt"
echo "PRD: $prd"
echo "Profile: $profile"
echo ""

# Copy progress file to project root if it doesn't exist
if [[ ! -f "progress.txt" ]]; then
  cp "$SCRIPT_DIR/progress.txt" "progress.txt"
fi

# Run Ralph
exec "$RALPH_SCRIPT" \
  --prompt "$prompt" \
  --prd "$prd" \
  --skill azure-deploy \
  --allow-profile "$profile" \
  "$iterations"
