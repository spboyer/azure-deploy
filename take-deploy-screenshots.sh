#!/bin/bash
# Take screenshots of deployed Azure apps
# Reads URLs from .deployed-urls.txt and captures screenshots

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
URLS_FILE="$SCRIPT_DIR/.deployed-urls.txt"
SCREENSHOT_DIR="$SCRIPT_DIR/screenshots"

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ ! -f "$URLS_FILE" ]]; then
    echo "No deployed URLs file found: $URLS_FILE"
    echo "Run ./test-deploy.sh first to deploy apps"
    exit 1
fi

mkdir -p "$SCREENSHOT_DIR"

echo -e "${BOLD}=======================================${NC}"
echo -e "${BOLD}Taking Screenshots of Deployed Apps${NC}"
echo -e "${BOLD}=======================================${NC}"
echo ""

# Read URLs and generate screenshot commands
while IFS='|' read -r name url; do
    if [[ -n "$name" && -n "$url" ]]; then
        echo -e "${BLUE}[INFO]${NC} $name: $url"
        echo "  Screenshot: $SCREENSHOT_DIR/deploy-$name.png"
        
        # Output instructions for Copilot CLI chrome-devtools
        echo ""
        echo "# Copilot CLI commands for $name:"
        echo "chrome-devtools-navigate_page type:url url:$url"
        echo "chrome-devtools-take_screenshot filePath:$SCREENSHOT_DIR/deploy-$name.png"
        echo ""
    fi
done < "$URLS_FILE"

echo -e "${GREEN}[INFO]${NC} Use Copilot CLI with chrome-devtools to capture screenshots"
echo "Or manually visit the URLs above and take screenshots"
