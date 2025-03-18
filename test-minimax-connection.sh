#!/bin/bash
# Simple shell script to test Minimax API connection

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${MAGENTA}=== MINIMAX API CONNECTION TEST SUITE ===${NC}\n"

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed. Please install it to run these tests.${NC}"
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "node_modules/axios" ] || [ ! -d "node_modules/dotenv" ]; then
    echo -e "${YELLOW}Installing required dependencies...${NC}"
    npm install axios dotenv
fi

# Check if .env file exists and validate API key
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file for API key...${NC}"
    echo "# Add your Minimax API key below" > .env
    echo "MINIMAX_API_KEY=your-api-key-here" >> .env
    echo -e "${BOLD}${RED}Please edit the .env file to add your valid API key before running the tests.${NC}"
    echo -e "${CYAN}Then run this script again.${NC}"
    exit 1
else
    API_KEY=$(grep -oP 'MINIMAX_API_KEY=\K.*' .env)
    if [[ "$API_KEY" == "your-api-key-here" || -z "$API_KEY" ]]; then
        echo -e "${BOLD}${RED}Invalid or missing API key detected in .env file.${NC}"
        echo -e "${YELLOW}Please edit the .env file and add a valid Minimax API key.${NC}"
        echo -e "${CYAN}Format: MINIMAX_API_KEY=your-actual-api-key-here${NC}"
        exit 1
    fi
    echo -e "${GREEN}API key found in .env file.${NC}"
    echo -e "${BLUE}Key begins with:${NC} ${CYAN}${API_KEY:0:10}...${NC}"
fi

# Function to run a test
run_test() {
    echo -e "\n${BOLD}${BLUE}Running test: $1${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
    node $1
    
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}Test $1 completed successfully${NC}"
    else
        echo -e "${RED}Test $1 failed with exit code $exit_code${NC}"
        echo -e "${YELLOW}Check error messages above for details.${NC}"
        echo -e "${CYAN}Possible issues:${NC}"
        echo -e " - ${YELLOW}Invalid or expired API key${NC}"
        echo -e " - ${YELLOW}Network connectivity problems${NC}"
        echo -e " - ${YELLOW}API endpoint URL might be incorrect${NC}"
        echo -e " - ${YELLOW}API response format might have changed${NC}"
        exit 1
    fi
    echo -e "${YELLOW}----------------------------------------${NC}\n"
}

# Run the tests
echo -e "${BOLD}${BLUE}Starting tests...${NC}\n"

# Standard English haiku test
run_test "./minimax-direct-test.js"

# Russian haiku test
run_test "./minimax-russian-haiku-test.js"

echo -e "${BOLD}${GREEN}All tests completed successfully!${NC}"
echo -e "${MAGENTA}Minimax API connection verified.${NC}" 