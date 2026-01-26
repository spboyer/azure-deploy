#!/usr/bin/env bash
set -euo pipefail

# Single-run Ralph wrapper for Azure Deploy skill testing
# Usage: ./ralph/ralph-once.sh [--detection|--deploy]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE
Usage:
  $0 [--detection|--deploy]

Modes:
  (default)     Run one iteration of full test suite
  --detection   Run one detection test (no Azure resources)
  --deploy      Run one deployment test (requires Azure auth)

Examples:
  $0                      # Run one full test
  $0 --detection          # Run one detection test
  $0 --deploy             # Run one deployment test

Environment:
  MODEL         Copilot model to use (default: gpt-5.2)
USAGE
}

mode="full"

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
      echo "Error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Check for Ralph scripts
RALPH_SCRIPT=""
for path in "../ralph/ralph-once.sh" "../../ralph/ralph-once.sh" "$HOME/ralph/ralph-once.sh"; do
  if [[ -x "$path" ]]; then
    RALPH_SCRIPT="$path"
    break
  fi
done

if [[ -z "$RALPH_SCRIPT" ]]; then
  echo "Error: ralph-once.sh not found. Please clone https://github.com/soderlind/ralph"
  echo "Expected locations: ../ralph/, ../../ralph/, or ~/ralph/"
  exit 1
fi

# Select prompt and PRD based on mode
case "$mode" in
  detection)
    prompt="ralph/prompts/azure-deploy-detection.txt"
    prd="ralph/plans/prd-azure-deploy-detection.json"
    profile="locked"
    ;;
  deploy)
    prompt="ralph/prompts/azure-deploy-deploy.txt"
    prd="ralph/plans/prd-azure-deploy-deploy.json"
    profile="dev"
    ;;
  *)
    prompt="ralph/prompts/azure-deploy.txt"
    prd="ralph/plans/prd.json"
    profile="dev"
    ;;
esac

echo "======================================="
echo "Azure Deploy Skill - Ralph Single Test"
echo "======================================="
echo "Mode: $mode"
echo "Prompt: $prompt"
echo "PRD: $prd"
echo "Profile: $profile"
echo ""

# Copy progress file to project root if it doesn't exist
if [[ ! -f "progress.txt" ]]; then
  cp "$SCRIPT_DIR/progress.txt" "progress.txt"
fi

# Run Ralph once
exec "$RALPH_SCRIPT" \
  --prompt "$prompt" \
  --prd "$prd" \
  --skill azure-deploy \
  --allow-profile "$profile"
