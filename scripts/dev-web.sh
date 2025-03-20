#!/bin/bash

# Terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

echo -e "${BLUE}🌐 Koodo Reader Web Development Mode${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Check if port 3000 is already in use
check_port() {
    if lsof -i :3000 &> /dev/null; then
        echo -e "${RED}❌ Port 3000 is already in use. Please free the port and try again.${NC}"
        echo -e "${YELLOW}You can use this command to see what's using the port:${NC}"
        echo -e "${CYAN}   lsof -i :3000${NC}"
        echo -e "${YELLOW}To kill the process:${NC}"
        echo -e "${CYAN}   kill \$(lsof -t -i:3000)${NC}"
        exit 1
    fi
}

# Install dependencies if needed
install_dependencies() {
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}📦 Installing dependencies with Yarn...${NC}"
        yarn install
    fi
}

# Start web development server
start_web_dev() {
    echo -e "${BLUE}🔧 Starting web-only development server...${NC}"
    echo -e "${GREEN}✅ The app will be available at: ${CYAN}http://localhost:3000${NC}"
    echo -e "${YELLOW}💡 Hot reloading is enabled - your changes will be reflected automatically${NC}"
    
    # Get the IP address for remote access
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}✅ Remote access: ${CYAN}http://${IP_ADDRESS}:3000${NC}"
    
    # Use BROWSER=none to prevent browser opening
    BROWSER=none npm start
}

# Main execution
check_port
install_dependencies
start_web_dev 