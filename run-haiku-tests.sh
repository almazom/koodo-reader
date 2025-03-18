#!/bin/bash

# Color codes for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${YELLOW}            Russian Haiku Generator Unit Tests             ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Run the tests with verbose output
echo -e "${CYAN}Running Russian haiku generation tests...${NC}"
echo -e "${YELLOW}These are the mocked tests that don't call the actual API.${NC}"
echo ""

yarn test src/services/llm/tests/russian-haiku.test.ts --verbose

echo ""
echo -e "${GREEN}Tests completed!${NC}" 