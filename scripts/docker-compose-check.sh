#!/bin/bash

# Docker Compose Check Script
# This script checks Docker Compose files for common issues and provides best practices

# Terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

echo -e "${BLUE}🔍 Docker Compose File Checker${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed.${NC}"
    exit 1
fi

# Default file to check
COMPOSE_FILE="docker-compose.yml"

# Allow specifying a different file
if [ -n "$1" ]; then
    COMPOSE_FILE="$1"
fi

# Check if the compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Docker Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

echo -e "${CYAN}Analyzing Docker Compose file: ${YELLOW}$COMPOSE_FILE${NC}\n"

# Perform basic validation
echo -e "${PURPLE}${BOLD}Basic Validation${NC}"
docker-compose -f "$COMPOSE_FILE" config > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Compose file is valid${NC}"
else
    echo -e "${RED}❌ Compose file validation failed${NC}"
    echo -e "${YELLOW}Detailed validation:${NC}"
    docker-compose -f "$COMPOSE_FILE" config
    exit 1
fi

# Check for common issues
echo -e "\n${PURPLE}${BOLD}Common Issues Check${NC}"

# 1. Check for container names
echo -e "\n${CYAN}Container Names:${NC}"
if grep -q "container_name:" "$COMPOSE_FILE"; then
    echo -e "${YELLOW}⚠️  Found explicit container_name directives${NC}"
    echo -e "   ${CYAN}Consider using default compose naming for better scalability${NC}"
    grep -n "container_name:" "$COMPOSE_FILE" | sed "s/^/   Line /"
else
    echo -e "${GREEN}✅ No explicit container names found (good for scaling)${NC}"
fi

# 2. Check for restart policies
echo -e "\n${CYAN}Restart Policies:${NC}"
if grep -q "restart:" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Restart policies defined${NC}"
    grep -n "restart:" "$COMPOSE_FILE" | sed "s/^/   Line /"
else
    echo -e "${YELLOW}⚠️  No restart policies found${NC}"
    echo -e "   ${CYAN}Consider adding 'restart: unless-stopped' for production services${NC}"
fi

# 3. Check for volumes
echo -e "\n${CYAN}Volume Configuration:${NC}"
if grep -q "volumes:" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Volumes are configured${NC}"
    
    # Check if named volumes are used
    if grep -A10 "^volumes:" "$COMPOSE_FILE" | grep -q ":"; then
        echo -e "${GREEN}✅ Named volumes are used (good for data persistence)${NC}"
    else
        echo -e "${YELLOW}⚠️  Consider using named volumes for better data management${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No volumes found${NC}"
    echo -e "   ${CYAN}Consider using volumes for data persistence${NC}"
fi

# 4. Check for environment variables
echo -e "\n${CYAN}Environment Variables:${NC}"
if grep -q "environment:" "$COMPOSE_FILE" || grep -q "env_file:" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Environment configuration found${NC}"
    
    # Check for env_file usage
    if grep -q "env_file:" "$COMPOSE_FILE"; then
        echo -e "${GREEN}✅ Using env_file for environment variables (recommended)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No environment configuration found${NC}"
    echo -e "   ${CYAN}Consider using env_file for centralizing environment variables${NC}"
fi

# 5. Check for resource constraints
echo -e "\n${CYAN}Resource Constraints:${NC}"
if grep -q "mem_limit:" "$COMPOSE_FILE" || grep -q "cpus:" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Resource constraints defined${NC}"
else
    echo -e "${YELLOW}⚠️  No resource constraints found${NC}"
    echo -e "   ${CYAN}Consider adding memory and CPU limits for production services${NC}"
    echo -e "   ${CYAN}Example:${NC}"
    echo -e "     ${CYAN}mem_limit: 512m${NC}"
    echo -e "     ${CYAN}cpus: 0.5${NC}"
fi

# 6. Check for health checks
echo -e "\n${CYAN}Health Checks:${NC}"
if grep -q "healthcheck:" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Health checks configured${NC}"
else
    echo -e "${YELLOW}⚠️  No health checks found${NC}"
    echo -e "   ${CYAN}Consider adding health checks for critical services${NC}"
    echo -e "   ${CYAN}Example:${NC}"
    echo -e "     ${CYAN}healthcheck:${NC}"
    echo -e "       ${CYAN}test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8080/health\"]${NC}"
    echo -e "       ${CYAN}interval: 30s${NC}"
    echo -e "       ${CYAN}timeout: 10s${NC}"
    echo -e "       ${CYAN}retries: 3${NC}"
fi

# 7. Check for networks
echo -e "\n${CYAN}Network Configuration:${NC}"
if grep -q "networks:" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Custom networks defined${NC}"
else
    echo -e "${YELLOW}⚠️  No custom networks found${NC}"
    echo -e "   ${CYAN}Consider using custom networks for better isolation${NC}"
fi

# 8. Check for version
echo -e "\n${CYAN}Compose Version:${NC}"
VERSION=$(grep "^version:" "$COMPOSE_FILE" | awk '{print $2}' | tr -d "'\"")
if [ -n "$VERSION" ]; then
    if [[ "$VERSION" == "3"* ]]; then
        echo -e "${GREEN}✅ Using version $VERSION (good)${NC}"
    else
        echo -e "${YELLOW}⚠️  Using older version: $VERSION${NC}"
        echo -e "   ${CYAN}Consider upgrading to version 3.x for newer features${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No version specified${NC}"
    echo -e "   ${CYAN}Consider adding version: '3' or higher${NC}"
fi

# 9. Check for logging configuration
echo -e "\n${CYAN}Logging Configuration:${NC}"
if grep -q "logging:" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Logging configuration found${NC}"
else
    echo -e "${YELLOW}⚠️  No logging configuration found${NC}"
    echo -e "   ${CYAN}Consider adding logging limits to prevent disk space issues${NC}"
    echo -e "   ${CYAN}Example:${NC}"
    echo -e "     ${CYAN}logging:${NC}"
    echo -e "       ${CYAN}driver: \"json-file\"${NC}"
    echo -e "       ${CYAN}options:${NC}"
    echo -e "         ${CYAN}max-size: \"10m\"${NC}"
    echo -e "         ${CYAN}max-file: \"3\"${NC}"
fi

# Summary
echo -e "\n${PURPLE}${BOLD}Summary and Recommendations${NC}"
echo -e "${CYAN}Your Docker Compose file has been analyzed. Please review the suggestions above.${NC}"
echo -e "${CYAN}For production environments, consider:${NC}"
echo -e "  ${CYAN}• Adding restart policies (restart: unless-stopped)${NC}"
echo -e "  ${CYAN}• Using named volumes for data persistence${NC}"
echo -e "  ${CYAN}• Adding resource constraints (memory and CPU limits)${NC}"
echo -e "  ${CYAN}• Configuring logging limits to prevent disk space issues${NC}"
echo -e "  ${CYAN}• Implementing health checks for critical services${NC}"
echo -e "  ${CYAN}• Using environment files for configuration${NC}"

echo -e "\n${GREEN}Analysis complete!${NC}"
exit 0 