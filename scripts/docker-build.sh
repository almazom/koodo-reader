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

echo -e "${BLUE}🐳 Koodo Reader Docker Builder${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Function to backup existing volumes
backup_volumes() {
    echo -e "${YELLOW}📦 Backing up Docker volumes...${NC}"
    if docker volume ls -q | grep -q "koodo"; then
        # Create backup directory if it doesn't exist
        mkdir -p ./docker-backups
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        
        # List all koodo volumes and backup them
        for volume in $(docker volume ls -q | grep koodo); do
            echo -e "${BLUE}   - Backing up volume: ${volume}${NC}"
            docker run --rm -v ${volume}:/source -v $(pwd)/docker-backups:/backup alpine \
                tar -czf /backup/${volume}_${timestamp}.tar.gz -C /source .
        done
        echo -e "${GREEN}✅ Volumes backed up to ./docker-backups/${NC}"
    else
        echo -e "${YELLOW}ℹ️ No Koodo volumes found to backup${NC}"
    fi
}

# Function to rebuild the Docker container
rebuild_container() {
    echo -e "${YELLOW}🔨 Rebuilding Docker container...${NC}"
    
    # Stop and remove existing container
    echo -e "${BLUE}   - Stopping any existing containers${NC}"
    docker-compose down
    
    # Remove the old image to ensure a fresh build
    echo -e "${BLUE}   - Removing old Docker images${NC}"
    docker rmi $(docker images -q koodo-reader:latest) 2>/dev/null || true
    
    # Build new image
    echo -e "${BLUE}   - Building fresh Docker image${NC}"
    docker-compose build --no-cache
    
    echo -e "${GREEN}✅ Docker rebuild completed${NC}"
}

# Function to start the container
start_container() {
    echo -e "${YELLOW}🚀 Starting Docker container...${NC}"
    docker-compose up -d
    
    # Get the IP address
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    PORT=$(grep -oP '(?<=- ").*?(?=:)' docker-compose.yml)
    
    echo -e "${GREEN}✅ Koodo Reader is running!${NC}"
    echo -e "${CYAN}   - Local access: http://localhost:${PORT}${NC}"
    echo -e "${CYAN}   - Remote access: http://${IP_ADDRESS}:${PORT}${NC}"
}

# Main execution
echo -e "${PURPLE}Starting Docker rebuild process with volume preservation${NC}"

# 1. Backup existing volumes
backup_volumes

# 2. Rebuild the container
rebuild_container

# 3. Start the container
start_container

echo -e "\n${GREEN}🎉 Docker rebuild completed successfully!${NC}" 