#!/bin/bash

# Docker Cron Cleanup Script
# This script is designed to be run from cron for automatic Docker maintenance
# Recommended cron schedule: 0 2 * * 0 (weekly at 2:00 AM on Sunday)
# To add to crontab: crontab -e
# Then add: 0 2 * * 0 /path/to/koodo-reader/scripts/docker-cron-cleanup.sh > /path/to/docker-cleanup.log 2>&1

# Terminal colors for log output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Timestamp for logs
timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

log() {
  echo -e "$(timestamp) $1"
}

# Change to project root directory
cd "$(dirname "$0")/.." || {
  log "${RED}Error: Could not change to project root directory${NC}"
  exit 1
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  log "${RED}Error: Docker is not installed${NC}"
  exit 1
fi

# Log start of maintenance
log "${BLUE}Starting automated Docker maintenance${NC}"
log "${YELLOW}===========================================${NC}"

# Check disk usage before cleanup
log "${CYAN}Disk usage before cleanup:${NC}"
docker system df | sed "s/^/  /"

# Count resources before cleanup
CONTAINERS_BEFORE=$(docker ps -qa | wc -l)
IMAGES_BEFORE=$(docker images -qa | wc -l)
VOLUMES_BEFORE=$(docker volume ls -q | wc -l)

log "${YELLOW}Resources before cleanup:${NC}"
log "  Containers: $CONTAINERS_BEFORE"
log "  Images: $IMAGES_BEFORE"
log "  Volumes: $VOLUMES_BEFORE"

# Perform cleanup
log "${BLUE}Performing Docker cleanup...${NC}"

# Remove stopped containers
log "${CYAN}Removing stopped containers...${NC}"
docker container prune -f
CONTAINERS_REMOVED=$?

# Remove dangling images
log "${CYAN}Removing dangling images...${NC}"
docker image prune -f
IMAGES_REMOVED=$?

# Clean build cache
log "${CYAN}Cleaning build cache...${NC}"
docker builder prune -f
CACHE_CLEANED=$?

# Remove unused networks
log "${CYAN}Removing unused networks...${NC}"
docker network prune -f
NETWORKS_REMOVED=$?

# Check for old volumes (dangling)
OLD_VOLUMES=$(docker volume ls -qf dangling=true | wc -l)
if [ "$OLD_VOLUMES" -gt 0 ]; then
  log "${YELLOW}Found $OLD_VOLUMES dangling volumes${NC}"
  log "${YELLOW}Dangling volumes are not automatically removed for safety${NC}"
  log "${YELLOW}Run 'docker volume prune' manually if needed${NC}"
fi

# Truncate large container logs (only for logs over 100MB)
log "${CYAN}Checking for large container logs...${NC}"
for container_id in $(docker ps -qa); do
  container_name=$(docker inspect --format '{{.Name}}' "$container_id" | sed 's/\///')
  log_path=$(docker inspect --format '{{.LogPath}}' "$container_id")
  
  if [ -f "$log_path" ]; then
    # Get log size in bytes
    log_size=$(stat -c%s "$log_path" 2>/dev/null)
    
    # 100MB = 104857600 bytes
    if [ -n "$log_size" ] && [ "$log_size" -gt 104857600 ]; then
      log_size_mb=$((log_size / 1048576))
      log "${YELLOW}Large log detected: $container_name ($log_size_mb MB)${NC}"
      log "  Truncating log file..."
      
      # Truncate the log file
      sudo truncate -s 0 "$log_path"
      if [ $? -eq 0 ]; then
        log "  ${GREEN}Successfully truncated log file${NC}"
      else
        log "  ${RED}Failed to truncate log file (permission issue)${NC}"
      fi
    fi
  fi
done

# Check disk usage after cleanup
log "${CYAN}Disk usage after cleanup:${NC}"
docker system df | sed "s/^/  /"

# Count resources after cleanup
CONTAINERS_AFTER=$(docker ps -qa | wc -l)
IMAGES_AFTER=$(docker images -qa | wc -l)
VOLUMES_AFTER=$(docker volume ls -q | wc -l)

log "${YELLOW}Resources after cleanup:${NC}"
log "  Containers: $CONTAINERS_AFTER (removed: $((CONTAINERS_BEFORE - CONTAINERS_AFTER)))"
log "  Images: $IMAGES_AFTER (removed: $((IMAGES_BEFORE - IMAGES_AFTER)))"
log "  Volumes: $VOLUMES_AFTER (unchanged for safety)"

# Check if any cleanup operations failed
if [ $CONTAINERS_REMOVED -ne 0 ] || [ $IMAGES_REMOVED -ne 0 ] || [ $CACHE_CLEANED -ne 0 ] || [ $NETWORKS_REMOVED -ne 0 ]; then
  log "${RED}One or more cleanup operations failed${NC}"
  exit 1
fi

# Log completion
log "${GREEN}Docker maintenance completed successfully${NC}"
log "${YELLOW}===========================================${NC}"

exit 0 