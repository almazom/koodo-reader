#!/bin/bash

# Terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Koodo Reader using Docker...${NC}"

# Stop any existing Koodo Reader container
if docker ps -a | grep -q koodo-reader; then
  echo -e "${YELLOW}🛑 Stopping existing Koodo Reader container...${NC}"
  docker stop koodo-reader &>/dev/null
  docker rm koodo-reader &>/dev/null
fi

# Clean up unused Docker resources
echo -e "${YELLOW}🧹 Cleaning up Docker resources...${NC}"
docker system prune -f &>/dev/null

# Use port 7070 as the default, which we've found to be reliable
PORT=7070

# Check if port is already in use, try alternatives if needed
if netstat -tuln | grep -q ":$PORT"; then
  echo -e "${YELLOW}⚠️ Port $PORT is already in use, trying alternatives...${NC}"
  PORT=8080
  if netstat -tuln | grep -q ":$PORT"; then
    PORT=8081
    if netstat -tuln | grep -q ":$PORT"; then
      PORT=9090
      if netstat -tuln | grep -q ":$PORT"; then
        echo -e "${RED}❌ All standard ports are in use. Please free up port 7070, 8080, 8081, or 9090.${NC}"
        exit 1
      fi
    fi
  fi
fi

# Start Koodo Reader with explicit port mapping and restart policy
echo -e "${BLUE}📚 Starting Koodo Reader container on port $PORT...${NC}"
docker run -d --name koodo-reader -p $PORT:80 --restart always ghcr.io/koodo-reader/koodo-reader:master

# Get the container ID
CONTAINER_ID=$(docker ps -q --filter "name=koodo-reader")

if [ -n "$CONTAINER_ID" ]; then
  # Verify the container is actually serving content
  echo -e "${YELLOW}🔍 Verifying container is responding...${NC}"
  
  # Wait for the container to fully start
  sleep 2
  
  # Check if the container is responding
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)
  
  if [ "$HTTP_STATUS" == "200" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}✅ Koodo Reader is now running!${NC}"
    echo -e "${GREEN}📖 Access it at: ${BLUE}http://localhost:$PORT${NC}"
    
    if [ -n "$SERVER_IP" ]; then
      echo -e "${GREEN}🌐 Or from another device: ${BLUE}http://$SERVER_IP:$PORT${NC}"
    fi
    
    echo -e "\n${YELLOW}To import books, click the menu ☰ icon and then the Import button.${NC}"
    echo -e "${YELLOW}To stop the container, run: ${BLUE}docker stop koodo-reader${NC}"
  else
    echo -e "${RED}❌ Container started but is not responding properly.${NC}"
    echo -e "${YELLOW}HTTP Status: $HTTP_STATUS${NC}"
    echo -e "${YELLOW}Try accessing manually: ${BLUE}http://localhost:$PORT${NC}"
  fi
else
  echo -e "${RED}❌ Failed to start Koodo Reader container.${NC}"
  echo -e "${YELLOW}Check Docker logs for more information: ${BLUE}docker logs koodo-reader${NC}"
fi 