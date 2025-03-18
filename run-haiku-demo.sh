#!/bin/bash

# Color codes for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${YELLOW}                Russian Haiku Generator Demo                ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if ts-node is installed
if ! command -v npx &> /dev/null
then
    echo -e "${YELLOW}npx is not installed. Installing...${NC}"
    npm install -g npx
fi

if ! npm list -g ts-node &> /dev/null
then
    echo -e "${YELLOW}ts-node is not installed. Installing...${NC}"
    npm install -g ts-node
fi

# Run the demo script
echo -e "${CYAN}Starting haiku generation demo...${NC}"
echo -e "${YELLOW}This will connect to the actual Minimax API and generate haikus in Russian.${NC}"
echo ""
echo -e "${YELLOW}Note: Make sure your api-keys.ts file is properly configured with a valid Minimax API key.${NC}"
echo ""

read -p "Press Enter to continue or Ctrl+C to cancel..."

npx ts-node src/services/llm/tests/run-haiku-demo.ts

echo ""
echo -e "${GREEN}Demo completed!${NC}" 