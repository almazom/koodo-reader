#!/bin/bash

# Terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

echo -e "${BLUE}${BOLD}🚀 Koodo Reader PWA Tester${NC}"
echo -e "${YELLOW}===================================================${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed. Please install Node.js and npm first.${NC}"
    exit 1
fi

# Check if build directory exists
if [ ! -d "build" ]; then
    echo -e "${YELLOW}📦 Build directory not found. Building the app first...${NC}"
    npm run build
else
    echo -e "${GREEN}✅ Build directory found.${NC}"
fi

# Check if serve is installed
if ! command -v serve &> /dev/null; then
    echo -e "${YELLOW}📦 Installing serve...${NC}"
    npm install -g serve
fi

# Get local IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo -e "${YELLOW}🔎 Testing PWA functionality...${NC}"
echo -e "${CYAN}💡 To test the PWA on your devices:${NC}"
echo -e "${CYAN}   1. Open Chrome or Edge on your mobile device${NC}"
echo -e "${CYAN}   2. Navigate to http://${IP_ADDRESS}:5000${NC}"
echo -e "${CYAN}   3. You should see the PWA installation prompt${NC}"
echo -e "${CYAN}   4. Use Chrome DevTools Lighthouse to audit PWA capabilities${NC}"
echo -e "${YELLOW}===================================================${NC}"

# Start the server
echo -e "${GREEN}🚀 Starting server on http://${IP_ADDRESS}:5000${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
serve -s build -l 5000 