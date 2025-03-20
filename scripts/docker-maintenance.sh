#!/bin/bash

# Docker Maintenance Script
# This script helps monitor and clean Docker orphans and log files

# Terminal colors for rich UI
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

echo -e "${BLUE}🧹 Docker Maintenance Tool${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Function to display dashboard header
display_header() {
    echo -e "\n${PURPLE}${BOLD}$1${NC}\n"
}

# Function to check Docker system info
check_docker_system() {
    display_header "Docker System Information"
    
    # Get Docker info
    echo -e "${CYAN}Docker Version:${NC}"
    docker version --format '{{.Server.Version}}' | sed "s/^/   /"
    
    echo -e "\n${CYAN}Docker System Info:${NC}"
    docker info --format '{{.Driver}}: {{.DriverStatus}}' | sed "s/^/   /"
    docker info --format 'Containers: {{.Containers}} (Running: {{.ContainersRunning}}, Paused: {{.ContainersPaused}}, Stopped: {{.ContainersStopped}})' | sed "s/^/   /"
    docker info --format 'Images: {{.Images}}' | sed "s/^/   /"
}

# Function to list orphaned containers
list_orphaned_containers() {
    display_header "Orphaned Containers"
    
    # List all containers that are not running
    echo -e "${CYAN}Stopped/Exited Containers:${NC}"
    if [ "$(docker ps -a -q -f status=exited -f status=created -f status=dead)" ]; then
        docker ps -a -f status=exited -f status=created -f status=dead --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" | sed "s/^/   /"
    else
        echo -e "   ${GRAY}No orphaned containers found${NC}"
    fi
}

# Function to list dangling images
list_dangling_images() {
    display_header "Dangling Images"
    
    # List all dangling images
    echo -e "${CYAN}Dangling Images (untagged):${NC}"
    if [ "$(docker images -f "dangling=true" -q)" ]; then
        docker images -f "dangling=true" --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" | sed "s/^/   /"
    else
        echo -e "   ${GRAY}No dangling images found${NC}"
    fi
}

# Function to list unused volumes
list_unused_volumes() {
    display_header "Unused Volumes"
    
    # List all volumes
    echo -e "${CYAN}Volumes:${NC}"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}" | sed "s/^/   /"
    
    # Show which volumes might be orphaned (this is harder to determine)
    echo -e "\n${CYAN}Potentially Unused Volumes:${NC}"
    echo -e "   ${GRAY}This is a best guess - manual verification recommended${NC}"
    docker volume ls -qf dangling=true | sed "s/^/   /"
}

# Function to check Docker logs size
check_log_sizes() {
    display_header "Docker Log Usage"
    
    # Check container log sizes
    echo -e "${CYAN}Container Log Sizes:${NC}"
    for container_id in $(docker ps -qa); do
        container_name=$(docker inspect --format '{{.Name}}' "$container_id" | sed 's/\///')
        log_path=$(docker inspect --format '{{.LogPath}}' "$container_id")
        
        if [ -f "$log_path" ]; then
            size=$(du -h "$log_path" 2>/dev/null | awk '{print $1}')
            echo -e "   ${YELLOW}$container_name${NC}: ${size}"
        else
            echo -e "   ${YELLOW}$container_name${NC}: ${GRAY}Log file not found${NC}"
        fi
    done
}

# Function to clean Docker system
clean_docker_system() {
    display_header "Cleaning Docker System"

    # Security warning
    echo -e "${RED}⚠️  SECURITY WARNING: ${NC}"
    echo -e "${YELLOW}This operation will permanently remove resources from your system:${NC}"
    echo -e "  ${YELLOW}• Stopped containers will be removed${NC}"
    echo -e "  ${YELLOW}• Dangling images will be deleted${NC}"
    echo -e "  ${YELLOW}• Unused networks will be removed${NC}"
    echo -e "  ${YELLOW}• Build cache will be cleared${NC}"
    echo -e "${YELLOW}This operation cannot be undone.${NC}\n"

    # Prompt for confirmation with typed response
    echo -e "${RED}To proceed, type 'confirm' (or 'c' to cancel): ${NC}"
    read confirmation

    if [[ "$confirmation" == "confirm" ]]; then
        echo -e "\n${CYAN}Removing stopped containers, dangling images, unused networks and build cache...${NC}"
        docker system prune -f
        echo -e "${GREEN}✅ Basic system cleanup completed${NC}"
        
        echo -e "\n${YELLOW}========== VOLUME CLEANUP (EXTRA CAUTION) ==========${NC}"
        echo -e "${RED}⚠️  WARNING: Volumes often contain important data!${NC}"
        echo -e "${YELLOW}This includes databases, configuration, and user data.${NC}"
        echo -e "${YELLOW}Lost volume data CANNOT be recovered!${NC}\n"
        
        echo -e "${RED}To proceed with volume cleanup, type 'delete-volumes': ${NC}"
        read volume_confirmation
        
        if [[ "$volume_confirmation" == "delete-volumes" ]]; then
            echo -e "\n${CYAN}Removing unused volumes...${NC}"
            docker volume prune -f
            echo -e "${GREEN}✅ Volume cleanup completed${NC}"
        else
            echo -e "${GREEN}✅ Volume cleanup skipped (good choice for data safety)${NC}"
        fi
        
        echo -e "\n${YELLOW}========== UNUSED IMAGES CLEANUP ==========${NC}"
        echo -e "${YELLOW}This will remove ALL unused images, not just dangling ones.${NC}"
        echo -e "${YELLOW}This includes cached base images needed for future builds.${NC}\n"
        
        echo -e "${RED}To remove ALL unused images, type 'delete-images': ${NC}"
        read images_confirmation
        
        if [[ "$images_confirmation" == "delete-images" ]]; then
            echo -e "\n${CYAN}Removing all unused images...${NC}"
            docker image prune -a -f
            echo -e "${GREEN}✅ Unused images cleanup completed${NC}"
        else
            echo -e "${GREEN}✅ Unused images cleanup skipped${NC}"
        fi
    else
        echo -e "${YELLOW}Cleanup cancelled - No changes were made${NC}"
    fi
}

# Function to truncate container logs
truncate_container_logs() {
    display_header "Truncating Container Logs"
    
    # Security warning
    echo -e "${RED}⚠️  SECURITY WARNING: ${NC}"
    echo -e "${YELLOW}This operation requires sudo privileges and will erase log data:${NC}"
    echo -e "  ${YELLOW}• Container logs will be permanently erased${NC}"
    echo -e "  ${YELLOW}• This may affect your ability to troubleshoot issues${NC}"
    echo -e "  ${YELLOW}• Consider setting up log rotation instead for future logs${NC}"
    echo -e "${YELLOW}Only proceed if you're sure you need to reclaim disk space immediately.${NC}\n"
    
    # Prompt to continue
    read -p "$(echo -e ${RED}"Do you want to continue with log truncation? (yes/no): "${NC})" trunc_confirm
    
    if [[ ! "$trunc_confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${GREEN}Log truncation cancelled - No changes were made${NC}"
        return
    fi
    
    echo -e "${CYAN}Available Containers:${NC}"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | sed "s/^/   /"
    
    read -p "$(echo -e ${YELLOW}"Enter container ID or name to truncate logs (or 'all' for all containers): "${NC})" container_id
    
    if [ "$container_id" = "all" ]; then
        echo -e "\n${RED}⚠️  You are about to truncate ALL container logs. This cannot be undone.${NC}"
        read -p "$(echo -e ${RED}"Type 'truncate-all-logs' to confirm: "${NC})" final_confirm
        
        if [ "$final_confirm" = "truncate-all-logs" ]; then
            echo -e "\n${CYAN}Truncating logs for all containers...${NC}"
            for cid in $(docker ps -qa); do
                container_name=$(docker inspect --format '{{.Name}}' "$cid" | sed 's/\///')
                log_path=$(docker inspect --format '{{.LogPath}}' "$cid")
                
                if [ -f "$log_path" ]; then
                    sudo truncate -s 0 "$log_path"
                    echo -e "   ${GREEN}✅ Truncated logs for container: $container_name${NC}"
                else
                    echo -e "   ${GRAY}Log file not found for container: $container_name${NC}"
                fi
            done
        else
            echo -e "${GREEN}Log truncation cancelled - No changes were made${NC}"
            return
        fi
    elif [ -n "$container_id" ]; then
        log_path=$(docker inspect --format '{{.LogPath}}' "$container_id" 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -f "$log_path" ]; then
            container_name=$(docker inspect --format '{{.Name}}' "$container_id" | sed 's/\///')
            echo -e "${YELLOW}You are about to truncate logs for: $container_name${NC}"
            read -p "$(echo -e ${RED}"Type 'truncate' to confirm: "${NC})" single_confirm
            
            if [ "$single_confirm" = "truncate" ]; then
                sudo truncate -s 0 "$log_path"
                echo -e "${GREEN}✅ Truncated logs for container: $container_name${NC}"
            else
                echo -e "${GREEN}Log truncation cancelled - No changes were made${NC}"
            fi
        else
            echo -e "${RED}❌ Container not found or log file not accessible${NC}"
        fi
    else
        echo -e "${YELLOW}No container specified, skipping log truncation${NC}"
    fi
}

# Function to show Docker disk usage
show_disk_usage() {
    display_header "Docker Disk Usage"
    echo -e "${CYAN}Current Docker Disk Usage:${NC}"
    docker system df | sed "s/^/   /"
}

# Function to limit container logs
limit_container_logs() {
    display_header "Set Log Size Limits"
    
    # Security warning
    echo -e "${RED}⚠️  SECURITY WARNING: ${NC}"
    echo -e "${YELLOW}This operation requires root privileges:${NC}"
    echo -e "  ${YELLOW}• Will modify system-wide Docker configuration${NC}"
    echo -e "  ${YELLOW}• Requires a Docker daemon restart to take effect${NC}"
    echo -e "  ${YELLOW}• May temporarily stop running containers during restart${NC}"
    echo -e "${YELLOW}This is a system configuration change that affects all containers.${NC}\n"
    
    echo -e "${CYAN}This will create/update the daemon.json file to set log rotation limits.${NC}"
    
    # Prompt for confirmation with typed response
    echo -e "${RED}To proceed with log configuration, type 'configure-logs': ${NC}"
    read config_confirm
    
    if [[ "$config_confirm" == "configure-logs" ]]; then
        DAEMON_FILE="/etc/docker/daemon.json"
        
        if [ ! -f "$DAEMON_FILE" ]; then
            echo -e "${CYAN}Creating new daemon.json file...${NC}"
            sudo mkdir -p /etc/docker
            sudo bash -c "cat > $DAEMON_FILE" << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
        else
            echo -e "${CYAN}Updating existing daemon.json file...${NC}"
            # This is a simple approach - in a real environment, you might want to use jq to properly update JSON
            if grep -q "log-driver" "$DAEMON_FILE"; then
                echo -e "${YELLOW}Log settings already exist in daemon.json. Manual edit recommended.${NC}"
                echo -e "${GRAY}Edit the file at: $DAEMON_FILE${NC}"
            else
                # Backup the original file
                sudo cp "$DAEMON_FILE" "${DAEMON_FILE}.bak"
                echo -e "${GREEN}✅ Created backup at ${DAEMON_FILE}.bak${NC}"
                
                # Remove the closing brace, add our settings, and add closing brace back
                sudo sed -i '$ d' "$DAEMON_FILE"
                sudo bash -c "cat >> $DAEMON_FILE" << 'EOF'
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
            fi
        fi
        
        echo -e "${GREEN}✅ Log rotation limits set${NC}"
        echo -e "${YELLOW}⚠️  Docker daemon restart required for changes to take effect:${NC}"
        echo -e "${GRAY}   sudo systemctl restart docker${NC}"
        
        # Offer to restart Docker
        echo -e "\n${YELLOW}Would you like to restart Docker now to apply changes?${NC}"
        echo -e "${RED}WARNING: This will stop all running containers!${NC}"
        echo -e "${RED}To restart Docker, type 'restart-docker': ${NC}"
        read restart_confirm
        
        if [[ "$restart_confirm" == "restart-docker" ]]; then
            echo -e "${CYAN}Restarting Docker daemon...${NC}"
            sudo systemctl restart docker
            echo -e "${GREEN}✅ Docker restarted with new log configuration${NC}"
        else
            echo -e "${YELLOW}Docker not restarted. Remember to restart later for changes to take effect.${NC}"
        fi
    else
        echo -e "${YELLOW}Log limit setup cancelled - No changes were made${NC}"
    fi
}

# Function to calculate container space
calculate_container_space() {
    CONTAINER_SPACE=$(docker ps -a -f "status=exited" -f "status=created" -f "status=dead" --format "{{.Size}}" | grep -oP '\d+(\.\d+)?[KMGT]B' | awk '{
        size = $1;
        if (size ~ /KB/) size = size * 1024;
        else if (size ~ /MB/) size = size * 1024 * 1024;
        else if (size ~ /GB/) size = size * 1024 * 1024 * 1024;
        else if (size ~ /TB/) size = size * 1024 * 1024 * 1024 * 1024;
        total += size;
    } END {
        if (total < 1024) printf "%.2f B", total;
        else if (total < 1024 * 1024) printf "%.2f KB", total/1024;
        else if (total < 1024 * 1024 * 1024) printf "%.2f MB", total/(1024*1024);
        else printf "%.2f GB", total/(1024*1024*1024);
    }')
    
    CONTAINER_COUNT=$(docker ps -a -f "status=exited" -f "status=created" -f "status=dead" -q | wc -l)
    
    if [ -z "$CONTAINER_SPACE" ]; then
        CONTAINER_SPACE="0 B"
    fi
    
    export CONTAINER_SPACE
    export CONTAINER_COUNT
}

# Function to calculate dangling image space
calculate_image_space() {
    IMAGE_SPACE=$(docker images -f "dangling=true" --format "{{.Size}}" | awk '{
        size = $1;
        if (size ~ /KB/) size = size * 1024;
        else if (size ~ /MB/) size = size * 1024 * 1024;
        else if (size ~ /GB/) size = size * 1024 * 1024 * 1024;
        else if (size ~ /TB/) size = size * 1024 * 1024 * 1024 * 1024;
        total += size;
    } END {
        if (total < 1024) printf "%.2f B", total;
        else if (total < 1024 * 1024) printf "%.2f KB", total/1024;
        else if (total < 1024 * 1024 * 1024) printf "%.2f MB", total/(1024*1024);
        else printf "%.2f GB", total/(1024*1024*1024);
    }')
    
    IMAGE_COUNT=$(docker images -f "dangling=true" -q | wc -l)
    
    if [ -z "$IMAGE_SPACE" ]; then
        IMAGE_SPACE="0 B"
    fi
    
    export IMAGE_SPACE
    export IMAGE_COUNT
}

# Function to calculate unused volume count
calculate_volume_space() {
    VOLUME_COUNT=$(docker volume ls -f "dangling=true" -q | wc -l)
    export VOLUME_COUNT
}

# Function to calculate log space
calculate_log_space() {
    TOTAL_LOG_SIZE=0
    
    for container_id in $(docker ps -qa); do
        log_path=$(docker inspect --format '{{.LogPath}}' "$container_id")
        
        if [ -f "$log_path" ]; then
            # Get log size
            log_size=$(sudo du -b "$log_path" 2>/dev/null | awk '{print $1}')
            
            # If we got a size back
            if [ -n "$log_size" ]; then
                # Add to total
                TOTAL_LOG_SIZE=$((TOTAL_LOG_SIZE + log_size))
            fi
        fi
    done
    
    # Calculate total log size in human-readable format
    if [ "$TOTAL_LOG_SIZE" -lt 1024 ]; then
        LOG_SPACE="${TOTAL_LOG_SIZE} B"
    elif [ "$TOTAL_LOG_SIZE" -lt 1048576 ]; then
        LOG_SPACE="$(echo "scale=2; ${TOTAL_LOG_SIZE}/1024" | bc) KB"
    elif [ "$TOTAL_LOG_SIZE" -lt 1073741824 ]; then
        LOG_SPACE="$(echo "scale=2; ${TOTAL_LOG_SIZE}/1048576" | bc) MB"
    else
        LOG_SPACE="$(echo "scale=2; ${TOTAL_LOG_SIZE}/1073741824" | bc) GB"
    fi
    
    if [ -z "$LOG_SPACE" ]; then
        LOG_SPACE="0 B"
    fi
    
    export LOG_SPACE
}

# Function to calculate build cache size
calculate_build_cache() {
    # Get build cache size
    CACHE_SIZE=$(docker system df --format "{{.BuildCacheSize}}" | sed 's/\.[0-9]*//g')
    
    if [ -z "$CACHE_SIZE" ]; then
        # Alternate method if the above doesn't work
        CACHE_SIZE=$(docker system df | grep "Build Cache" | awk '{print $3}')
    fi
    
    if [ -z "$CACHE_SIZE" ]; then
        CACHE_SIZE="Unknown"
    fi
    
    export CACHE_SIZE
}

# Function to calculate all space
calculate_all_space() {
    calculate_container_space
    calculate_image_space
    calculate_volume_space
    calculate_log_space
    calculate_build_cache
    
    # Total reclamable space (rough estimate)
    # Convert all to bytes for addition
    CONTAINER_BYTES=$(echo "$CONTAINER_SPACE" | awk '{
        size = $1;
        if ($2 == "B") multiplier = 1;
        else if ($2 == "KB") multiplier = 1024;
        else if ($2 == "MB") multiplier = 1024 * 1024;
        else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
        else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
        printf "%.0f", size * multiplier;
    }')
    
    IMAGE_BYTES=$(echo "$IMAGE_SPACE" | awk '{
        size = $1;
        if ($2 == "B") multiplier = 1;
        else if ($2 == "KB") multiplier = 1024;
        else if ($2 == "MB") multiplier = 1024 * 1024;
        else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
        else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
        printf "%.0f", size * multiplier;
    }')
    
    LOG_BYTES=$(echo "$LOG_SPACE" | awk '{
        size = $1;
        if ($2 == "B") multiplier = 1;
        else if ($2 == "KB") multiplier = 1024;
        else if ($2 == "MB") multiplier = 1024 * 1024;
        else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
        else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
        printf "%.0f", size * multiplier;
    }')
    
    # Handle the case where CACHE_SIZE might be "Unknown"
    if [[ "$CACHE_SIZE" == "Unknown" ]]; then
        CACHE_BYTES=0
    else
        CACHE_BYTES=$(echo "$CACHE_SIZE" | awk '{
            size = $1;
            if ($2 == "B") multiplier = 1;
            else if ($2 == "KB") multiplier = 1024;
            else if ($2 == "MB") multiplier = 1024 * 1024;
            else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
            else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
            printf "%.0f", size * multiplier;
        }')
    fi
    
    # Add up all bytes
    TOTAL_BYTES=$((CONTAINER_BYTES + IMAGE_BYTES + LOG_BYTES + CACHE_BYTES))
    
    # Convert back to human-readable
    if [ "$TOTAL_BYTES" -lt 1024 ]; then
        TOTAL_SPACE="${TOTAL_BYTES} B"
    elif [ "$TOTAL_BYTES" -lt 1048576 ]; then
        TOTAL_SPACE="$(echo "scale=2; ${TOTAL_BYTES}/1024" | bc) KB"
    elif [ "$TOTAL_BYTES" -lt 1073741824 ]; then
        TOTAL_SPACE="$(echo "scale=2; ${TOTAL_BYTES}/1048576" | bc) MB"
    else
        TOTAL_SPACE="$(echo "scale=2; ${TOTAL_BYTES}/1073741824" | bc) GB"
    fi
    
    export TOTAL_SPACE
}

# Function to show space savings dashboard
show_space_dashboard() {
    display_header "Docker Space Savings Dashboard"
    
    # Calculate all space metrics
    calculate_all_space
    
    # Get current disk usage
    DISK_USAGE=$(df -h / | tail -n 1 | awk '{print $5}')
    DISK_AVAIL=$(df -h / | tail -n 1 | awk '{print $4}')
    
    # Show disk usage info
    echo -e "${CYAN}Current System Disk Usage:${NC}"
    echo -e "   Disk usage: ${YELLOW}${DISK_USAGE}${NC}"
    echo -e "   Available space: ${GREEN}${DISK_AVAIL}${NC}"
    
    # Show Docker usage summary
    echo -e "\n${CYAN}Docker Resource Usage:${NC}"
    docker system df | sed "s/^/   /"
    
    # Show detailed space usage breakdown
    echo -e "\n${PURPLE}${BOLD}Potential Space Savings:${NC}"
    
    # Create a visual representation of space usage
    total_width=50
    
    # Orphaned Containers
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        container_icon="🔷"
        container_label="${CYAN}Orphaned Containers (${CONTAINER_COUNT}):${NC}"
        printf "%-40s " "$container_label"
        echo -e "${YELLOW}${CONTAINER_SPACE}${NC}"
        printf "   "
        # Calculate width based on percentage of total space
        container_bytes=$(echo "$CONTAINER_SPACE" | awk '{
            size = $1;
            if ($2 == "B") multiplier = 1;
            else if ($2 == "KB") multiplier = 1024;
            else if ($2 == "MB") multiplier = 1024 * 1024;
            else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
            else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
            printf "%.0f", size * multiplier;
        }')
        
        total_bytes=$(echo "$TOTAL_SPACE" | awk '{
            size = $1;
            if ($2 == "B") multiplier = 1;
            else if ($2 == "KB") multiplier = 1024;
            else if ($2 == "MB") multiplier = 1024 * 1024;
            else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
            else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
            printf "%.0f", size * multiplier;
        }')
        
        if [ "$total_bytes" -gt 0 ]; then
            container_width=$(( container_bytes * total_width / total_bytes ))
            # Ensure at least 1 character if non-zero
            if [ "$container_bytes" -gt 0 ] && [ "$container_width" -eq 0 ]; then
                container_width=1
            fi
            # Print the bar
            for (( i=0; i<container_width; i++ )); do
                printf "${CYAN}${container_icon}${NC}"
            done
        fi
        echo ""
    fi
    
    # Dangling Images
    if [ "$IMAGE_COUNT" -gt 0 ]; then
        image_icon="🔶"
        image_label="${PURPLE}Dangling Images (${IMAGE_COUNT}):${NC}"
        printf "%-40s " "$image_label"
        echo -e "${YELLOW}${IMAGE_SPACE}${NC}"
        printf "   "
        # Calculate width based on percentage of total space
        image_bytes=$(echo "$IMAGE_SPACE" | awk '{
            size = $1;
            if ($2 == "B") multiplier = 1;
            else if ($2 == "KB") multiplier = 1024;
            else if ($2 == "MB") multiplier = 1024 * 1024;
            else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
            else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
            printf "%.0f", size * multiplier;
        }')
        
        if [ "$total_bytes" -gt 0 ]; then
            image_width=$(( image_bytes * total_width / total_bytes ))
            # Ensure at least 1 character if non-zero
            if [ "$image_bytes" -gt 0 ] && [ "$image_width" -eq 0 ]; then
                image_width=1
            fi
            # Print the bar
            for (( i=0; i<image_width; i++ )); do
                printf "${PURPLE}${image_icon}${NC}"
            done
        fi
        echo ""
    fi
    
    # Volumes
    if [ "$VOLUME_COUNT" -gt 0 ]; then
        volume_icon="📦"
        echo -e "${BLUE}Unused Volumes (${VOLUME_COUNT}):${NC} ${YELLOW}Size unknown${NC}"
        printf "   "
        # Print a small fixed bar since we don't know volume sizes
        for (( i=0; i<3; i++ )); do
            printf "${BLUE}${volume_icon}${NC}"
        done
        echo ""
    fi
    
    # Log space
    if [ "$LOG_SPACE" != "0 B" ]; then
        log_icon="📃"
        log_label="${GREEN}Container Logs:${NC}"
        printf "%-40s " "$log_label"
        echo -e "${YELLOW}${LOG_SPACE}${NC}"
        printf "   "
        # Calculate width based on percentage of total space
        log_bytes=$(echo "$LOG_SPACE" | awk '{
            size = $1;
            if ($2 == "B") multiplier = 1;
            else if ($2 == "KB") multiplier = 1024;
            else if ($2 == "MB") multiplier = 1024 * 1024;
            else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
            else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
            printf "%.0f", size * multiplier;
        }')
        
        if [ "$total_bytes" -gt 0 ]; then
            log_width=$(( log_bytes * total_width / total_bytes ))
            # Ensure at least 1 character if non-zero
            if [ "$log_bytes" -gt 0 ] && [ "$log_width" -eq 0 ]; then
                log_width=1
            fi
            # Print the bar
            for (( i=0; i<log_width; i++ )); do
                printf "${GREEN}${log_icon}${NC}"
            done
        fi
        echo ""
    fi
    
    # Build cache
    if [ "$CACHE_SIZE" != "0" ] && [ "$CACHE_SIZE" != "Unknown" ]; then
        cache_icon="🔧"
        cache_label="${YELLOW}Build Cache:${NC}"
        printf "%-40s " "$cache_label"
        echo -e "${YELLOW}${CACHE_SIZE}${NC}"
        printf "   "
        # Calculate width based on percentage of total space
        if [[ "$CACHE_SIZE" == "Unknown" ]]; then
            cache_bytes=0
        else
            cache_bytes=$(echo "$CACHE_SIZE" | awk '{
                size = $1;
                if ($2 == "B") multiplier = 1;
                else if ($2 == "KB") multiplier = 1024;
                else if ($2 == "MB") multiplier = 1024 * 1024;
                else if ($2 == "GB") multiplier = 1024 * 1024 * 1024;
                else if ($2 == "TB") multiplier = 1024 * 1024 * 1024 * 1024;
                printf "%.0f", size * multiplier;
            }')
        fi
        
        if [ "$total_bytes" -gt 0 ]; then
            cache_width=$(( cache_bytes * total_width / total_bytes ))
            # Ensure at least 1 character if non-zero
            if [ "$cache_bytes" -gt 0 ] && [ "$cache_width" -eq 0 ]; then
                cache_width=1
            fi
            # Print the bar
            for (( i=0; i<cache_width; i++ )); do
                printf "${YELLOW}${cache_icon}${NC}"
            done
        fi
        echo ""
    fi
    
    # Total space
    echo -e "\n${RED}${BOLD}Total Reclaimable Space:${NC} ${YELLOW}${BOLD}${TOTAL_SPACE}${NC}"
    
    # Recommended actions
    echo -e "\n${CYAN}Recommended Actions:${NC}"
    if [ "$CONTAINER_COUNT" -gt 5 ]; then
        echo -e "   ${YELLOW}• Run container cleanup (many orphaned containers)${NC}"
    fi
    if [ "$IMAGE_COUNT" -gt 5 ]; then
        echo -e "   ${YELLOW}• Remove dangling images (many unused images)${NC}"
    fi
    if [ "$VOLUME_COUNT" -gt 5 ]; then
        echo -e "   ${YELLOW}• Check unused volumes (many dangling volumes)${NC}"
    fi
    if [[ "$LOG_SPACE" == *"GB"* ]] || [[ "$LOG_SPACE" == *"MB"* && "${LOG_SPACE%.*}" -gt 100 ]]; then
        echo -e "   ${RED}• Truncate container logs (large log files detected)${NC}"
    fi
    
    # Add option to auto clean
    echo -e "\n${GREEN}To reclaim this space, use option 7 from the main menu.${NC}"
}

# Main menu
show_menu() {
    clear
    
    # Calculate space before showing menu
    echo -e "${BLUE}${BOLD}Calculating potential disk savings...${NC}"
    calculate_all_space
    
    clear
    echo -e "${BLUE}🧹 Docker Maintenance Tool${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${GREEN}🔒 SECURITY LEVEL:${NC} ✅ High (Safe)  ⚠️ Medium (Caution)  ❌ High Risk"
    echo -e "${YELLOW}===============================================${NC}"
    
    # Show total reclaimable space
    echo -e "${PURPLE}${BOLD}Total Reclaimable Space: ${YELLOW}${TOTAL_SPACE}${NC}${PURPLE}${BOLD} 🗑️${NC}\n"
    
    echo -e "${CYAN}1. ${NC}Show Space Savings Dashboard"
    echo -e "${CYAN}2. ${NC}Show Docker System Information ${GREEN}[✅ Safe - Read Only]${NC}"
    echo -e "${CYAN}3. ${NC}List Orphaned Containers      ${GREEN}[✅ Safe - Read Only]${NC} ${YELLOW}(${CONTAINER_COUNT} containers, ${CONTAINER_SPACE})${NC}"
    echo -e "${CYAN}4. ${NC}List Dangling Images          ${GREEN}[✅ Safe - Read Only]${NC} ${YELLOW}(${IMAGE_COUNT} images, ${IMAGE_SPACE})${NC}"
    echo -e "${CYAN}5. ${NC}List Unused Volumes           ${GREEN}[✅ Safe - Read Only]${NC} ${YELLOW}(${VOLUME_COUNT} volumes)${NC}"
    echo -e "${CYAN}6. ${NC}Check Container Log Sizes     ${GREEN}[✅ Safe - Read Only]${NC} ${YELLOW}(${LOG_SPACE})${NC}"
    echo -e "${CYAN}7. ${NC}Show Docker Disk Usage        ${GREEN}[✅ Safe - Read Only]${NC}"
    echo -e "${CYAN}8. ${NC}Clean Docker System (prune)   ${YELLOW}[⚠️ Caution - Deletes Resources]${NC} ${GREEN}(Saves ${TOTAL_SPACE})${NC}"
    echo -e "${CYAN}9. ${NC}Truncate Container Logs       ${YELLOW}[⚠️ Caution - Requires Sudo]${NC} ${GREEN}(Saves ${LOG_SPACE})${NC}"
    echo -e "${CYAN}10. ${NC}Set Container Log Size Limits ${YELLOW}[⚠️ Caution - Requires Sudo]${NC}"
    echo -e "${CYAN}0. ${NC}Exit"
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "Enter your choice: \c"
}

# Main program
while true; do
    show_menu
    read choice
    
    case $choice in
        1) show_space_dashboard; read -p "Press Enter to continue..." ;;
        2) check_docker_system; read -p "Press Enter to continue..." ;;
        3) list_orphaned_containers; read -p "Press Enter to continue..." ;;
        4) list_dangling_images; read -p "Press Enter to continue..." ;;
        5) list_unused_volumes; read -p "Press Enter to continue..." ;;
        6) check_log_sizes; read -p "Press Enter to continue..." ;;
        7) show_disk_usage; read -p "Press Enter to continue..." ;;
        8) clean_docker_system; read -p "Press Enter to continue..." ;;
        9) truncate_container_logs; read -p "Press Enter to continue..." ;;
        10) limit_container_logs; read -p "Press Enter to continue..." ;;
        0) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; read -p "Press Enter to continue..." ;;
    esac
done 