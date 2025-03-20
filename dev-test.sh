#!/bin/bash

# Terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Koodo Reader in Development Mode${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Make sure Docker container is stopped
echo -e "${YELLOW}🛑 Stopping any existing Koodo Reader container...${NC}"
docker stop koodo-reader &>/dev/null

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo -e "${YELLOW}📦 Installing dependencies with Yarn...${NC}"
  yarn install
fi

# Start development server
echo -e "${BLUE}🔧 Starting development server...${NC}"
echo -e "${GREEN}✅ The app will be available at: ${CYAN}http://localhost:3000${NC}"
echo -e "${YELLOW}💡 Hot reloading is enabled - your changes will be reflected automatically${NC}"

# Run the development server
yarn start 