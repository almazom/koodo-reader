#!/bin/bash

# Docker Monitoring Script (READ-ONLY)
# This script provides a safe, read-only way to monitor Docker resources
# No modifications are made to your system

# Terminal colors
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

echo -e "${BLUE}📊 Docker Monitor (READ-ONLY)${NC}"
echo -e "${GREEN}${BOLD}✅ SAFETY: 100% - This script only reads information, makes NO changes${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed.${NC}"
    exit 1
fi

# Function to display header
display_header() {
    echo -e "\n${PURPLE}${BOLD}$1${NC}\n"
}

# Function to check system status with space calculations
check_system_status() {
    display_header "System Overview"
    
    # Calculate potential space savings
    calculate_all_space
    
    # Get Docker version
    echo -e "${CYAN}Docker Version:${NC}"
    docker version --format '{{.Server.Version}}' 2>/dev/null || echo "   Unable to retrieve version"
    
    # Get system information
    echo -e "\n${CYAN}System Information:${NC}"
    echo -e "   Host Kernel: $(uname -r)"
    echo -e "   OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d \")"
    
    # Show Docker disk usage summary
    echo -e "\n${CYAN}Docker Disk Usage:${NC}"
    docker system df | sed "s/^/   /"
    
    # Calculate total docker usage
    echo -e "\n${CYAN}Estimated Total Docker Usage:${NC}"
    if command -v du &> /dev/null && [ -d "/var/lib/docker" ]; then
        DOCKER_SIZE=$(sudo du -sh /var/lib/docker 2>/dev/null | cut -f1)
        if [ -n "$DOCKER_SIZE" ]; then
            echo -e "   /var/lib/docker: ${DOCKER_SIZE}"
        else
            echo -e "   ${GRAY}Unable to check size (requires sudo)${NC}"
        fi
    else
        echo -e "   ${GRAY}Unable to check size${NC}"
    fi
    
    # Show potential disk savings
    echo -e "\n${CYAN}Potential Disk Space Savings:${NC}"
    echo -e "${GREEN}   Total reclaimable space: ${YELLOW}${TOTAL_SPACE}${NC}"
    echo -e "${GREEN}   Stopped containers: ${YELLOW}${CONTAINER_COUNT} containers (${CONTAINER_SPACE})${NC}"
    echo -e "${GREEN}   Dangling images: ${YELLOW}${IMAGE_COUNT} images (${IMAGE_SPACE})${NC}"
    echo -e "${GREEN}   Unused volumes: ${YELLOW}${VOLUME_COUNT} volumes${NC}"
    echo -e "${GREEN}   Container logs: ${YELLOW}${LOG_SPACE}${NC}"
    echo -e "${GREEN}   Build cache: ${YELLOW}${CACHE_SIZE}${NC}"
}

# Function to check running containers
check_running_containers() {
    display_header "Running Containers"
    
    # Count running containers
    RUNNING_COUNT=$(docker ps -q | wc -l)
    
    if [ "$RUNNING_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}No containers currently running${NC}"
    else
        echo -e "${CYAN}Currently Running Containers: ${RUNNING_COUNT}${NC}"
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}" | sed "s/^/   /"
        
        # Show container resource usage (CPU, memory)
        echo -e "\n${CYAN}Container Resource Usage:${NC}"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" | sed "s/^/   /"
    fi
}

# Function to check stopped containers
check_stopped_containers() {
    display_header "Stopped Containers (Orphans)"
    
    # Count stopped containers
    STOPPED_COUNT=$(docker ps -f "status=exited" -f "status=created" -f "status=dead" -q | wc -l)
    
    if [ "$STOPPED_COUNT" -eq 0 ]; then
        echo -e "${GREEN}No stopped containers found${NC}"
    else
        echo -e "${YELLOW}Stopped Containers: ${STOPPED_COUNT}${NC}"
        docker ps -a -f "status=exited" -f "status=created" -f "status=dead" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Size}}" | sed "s/^/   /"
        
        # Calculate total space used by stopped containers
        TOTAL_SIZE=$(docker ps -a -f "status=exited" -f "status=created" -f "status=dead" --format "{{.Size}}" | grep -oP '\d+(\.\d+)?[KMGT]B' | awk '{
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
        
        if [ -n "$TOTAL_SIZE" ]; then
            echo -e "\n${YELLOW}Total space used by stopped containers: ${TOTAL_SIZE}${NC}"
            echo -e "${GRAY}Run 'docker container prune' to reclaim this space${NC}"
        fi
    fi
}

# Function to check dangling images
check_dangling_images() {
    display_header "Dangling Images (Untagged)"
    
    # Count dangling images
    DANGLING_COUNT=$(docker images -f "dangling=true" -q | wc -l)
    
    if [ "$DANGLING_COUNT" -eq 0 ]; then
        echo -e "${GREEN}No dangling images found${NC}"
    else
        echo -e "${YELLOW}Dangling Images: ${DANGLING_COUNT}${NC}"
        docker images -f "dangling=true" --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" | sed "s/^/   /"
        
        # Calculate total space used by dangling images
        TOTAL_SIZE=$(docker images -f "dangling=true" --format "{{.Size}}" | awk '{
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
        
        if [ -n "$TOTAL_SIZE" ]; then
            echo -e "\n${YELLOW}Total space used by dangling images: ${TOTAL_SIZE}${NC}"
            echo -e "${GRAY}Run 'docker image prune' to reclaim this space${NC}"
        fi
    fi
}

# Function to check unused volumes
check_unused_volumes() {
    display_header "Potentially Unused Volumes"
    
    # List all volumes
    echo -e "${CYAN}All Volumes:${NC}"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}" | sed "s/^/   /"
    
    # Count dangling volumes
    DANGLING_COUNT=$(docker volume ls -f "dangling=true" -q | wc -l)
    
    if [ "$DANGLING_COUNT" -eq 0 ]; then
        echo -e "\n${GREEN}No dangling volumes found${NC}"
    else
        echo -e "\n${YELLOW}Potentially Unused Volumes: ${DANGLING_COUNT}${NC}"
        docker volume ls -f "dangling=true" --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}" | sed "s/^/   /"
        echo -e "${GRAY}WARNING: This is a best guess. Manual verification recommended before removal!${NC}"
    fi
}

# Function to check log sizes
check_log_sizes() {
    display_header "Container Log Files"
    
    # Count containers
    CONTAINER_COUNT=$(docker ps -qa | wc -l)
    
    if [ "$CONTAINER_COUNT" -eq 0 ]; then
        echo -e "${GREEN}No containers found${NC}"
    else
        echo -e "${CYAN}Checking log sizes for ${CONTAINER_COUNT} containers...${NC}"
        
        # Variable to track total log size
        TOTAL_LOG_SIZE=0
        TOTAL_PRETTY="0 B"
        
        for container_id in $(docker ps -qa); do
            container_name=$(docker inspect --format '{{.Name}}' "$container_id" | sed 's/\///')
            log_path=$(docker inspect --format '{{.LogPath}}' "$container_id")
            
            if [ -f "$log_path" ]; then
                # Get log size
                log_size=$(sudo du -b "$log_path" 2>/dev/null | awk '{print $1}')
                
                # If we got a size back
                if [ -n "$log_size" ]; then
                    # Convert to human-readable
                    if [ "$log_size" -lt 1024 ]; then
                        size_hr="${log_size} B"
                    elif [ "$log_size" -lt 1048576 ]; then
                        size_hr="$(echo "scale=2; ${log_size}/1024" | bc) KB"
                    elif [ "$log_size" -lt 1073741824 ]; then
                        size_hr="$(echo "scale=2; ${log_size}/1048576" | bc) MB"
                    else
                        size_hr="$(echo "scale=2; ${log_size}/1073741824" | bc) GB"
                    fi
                    
                    # Print log size
                    echo -e "   ${YELLOW}$container_name${NC}: ${size_hr}"
                    
                    # Track total size
                    TOTAL_LOG_SIZE=$((TOTAL_LOG_SIZE + log_size))
                else
                    echo -e "   ${YELLOW}$container_name${NC}: ${GRAY}Size check failed (permissions)${NC}"
                fi
            else
                echo -e "   ${YELLOW}$container_name${NC}: ${GRAY}Log file not found${NC}"
            fi
        done
        
        # Calculate total log size in human-readable format
        if [ "$TOTAL_LOG_SIZE" -lt 1024 ]; then
            TOTAL_PRETTY="${TOTAL_LOG_SIZE} B"
        elif [ "$TOTAL_LOG_SIZE" -lt 1048576 ]; then
            TOTAL_PRETTY="$(echo "scale=2; ${TOTAL_LOG_SIZE}/1024" | bc) KB"
        elif [ "$TOTAL_LOG_SIZE" -lt 1073741824 ]; then
            TOTAL_PRETTY="$(echo "scale=2; ${TOTAL_LOG_SIZE}/1048576" | bc) MB"
        else
            TOTAL_PRETTY="$(echo "scale=2; ${TOTAL_LOG_SIZE}/1073741824" | bc) GB"
        fi
        
        # Show total log size
        echo -e "\n${CYAN}Total Log Size: ${YELLOW}${TOTAL_PRETTY}${NC}"
        
        # Recommendations based on log size
        if [ "$TOTAL_LOG_SIZE" -gt 1073741824 ]; then # 1GB
            echo -e "${YELLOW}⚠️  Large log files detected${NC}"
            echo -e "${GRAY}Consider setting up log rotation or truncating logs${NC}"
        fi
    fi
}

# Function to check network usage
check_network_usage() {
    display_header "Docker Networks"
    
    # List all networks
    echo -e "${CYAN}All Networks:${NC}"
    docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" | sed "s/^/   /"
    
    # Check for unused networks
    echo -e "\n${CYAN}Network Details:${NC}"
    for network in $(docker network ls -q); do
        network_name=$(docker network inspect --format '{{.Name}}' "$network")
        container_count=$(docker network inspect --format '{{len .Containers}}' "$network")
        
        if [ "$container_count" -eq 0 ]; then
            echo -e "   ${YELLOW}$network_name${NC}: ${YELLOW}No containers attached${NC}"
        else
            echo -e "   ${GREEN}$network_name${NC}: ${container_count} containers attached"
        fi
    done
    
    # Count unused networks
    UNUSED_COUNT=$(docker network ls -q | xargs -n 1 docker network inspect --format '{{if eq (len .Containers) 0}}{{.Name}}{{end}}' | wc -l)
    
    if [ "$UNUSED_COUNT" -gt 0 ]; then
        echo -e "\n${YELLOW}You have ${UNUSED_COUNT} unused networks${NC}"
        echo -e "${GRAY}Run 'docker network prune' to remove unused networks${NC}"
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
    display_header "Docker Space Savings Dashboard (READ-ONLY)"
    
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
        echo -e "   ${YELLOW}• Consider cleaning orphaned containers${NC}"
    fi
    if [ "$IMAGE_COUNT" -gt 5 ]; then
        echo -e "   ${YELLOW}• Consider removing dangling images${NC}"
    fi
    if [ "$VOLUME_COUNT" -gt 5 ]; then
        echo -e "   ${YELLOW}• Consider checking unused volumes${NC}"
    fi
    if [[ "$LOG_SPACE" == *"GB"* ]] || [[ "$LOG_SPACE" == *"MB"* && "${LOG_SPACE%.*}" -gt 100 ]]; then
        echo -e "   ${RED}• Consider truncating container logs (large files detected)${NC}"
    fi
    
    # Note about how to clean
    echo -e "\n${GREEN}Note: To clean up these resources, use the docker-maintenance.sh script.${NC}"
    
    # Show real-time resource usage
    echo -e "\n${CYAN}Real-time Container Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" | sed "s/^/   /"
}

# Main menu
show_menu() {
    clear
    
    # Calculate space before showing menu
    echo -e "${BLUE}${BOLD}Calculating potential disk savings...${NC}"
    calculate_all_space
    
    clear
    echo -e "${BLUE}📊 Docker Monitor (READ-ONLY)${NC}"
    echo -e "${GREEN}${BOLD}✅ SAFETY: 100% - This script only reads information, makes NO changes${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    
    # Show total reclaimable space
    echo -e "${PURPLE}${BOLD}Potential Space Savings: ${YELLOW}${TOTAL_SPACE}${NC}${PURPLE}${BOLD} 🗑️${NC}\n"
    
    echo -e "${CYAN}1. ${NC}Space Savings Dashboard (visual overview)"
    echo -e "${CYAN}2. ${NC}System Overview"
    echo -e "${CYAN}3. ${NC}Running Containers Status"
    echo -e "${CYAN}4. ${NC}Stopped Containers (Orphans)       ${YELLOW}(${CONTAINER_COUNT} containers, ${CONTAINER_SPACE})${NC}"
    echo -e "${CYAN}5. ${NC}Dangling Images                    ${YELLOW}(${IMAGE_COUNT} images, ${IMAGE_SPACE})${NC}"
    echo -e "${CYAN}6. ${NC}Volume Usage                       ${YELLOW}(${VOLUME_COUNT} unused volumes)${NC}"
    echo -e "${CYAN}7. ${NC}Log File Sizes                     ${YELLOW}(${LOG_SPACE})${NC}"
    echo -e "${CYAN}8. ${NC}Network Usage"
    echo -e "${CYAN}9. ${NC}Full System Report (all of the above)"
    echo -e "${CYAN}0. ${NC}Exit"
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${GRAY}📝 Note: To clean up space, use docker-maintenance.sh${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "Enter your choice: \c"
}

# Run full system check
run_full_check() {
    check_system_status
    check_running_containers
    check_stopped_containers
    check_dangling_images
    check_unused_volumes
    check_log_sizes
    check_network_usage
}

# Main program
if [ "$1" = "full" ]; then
    # If "full" argument is provided, run full check
    run_full_check
    exit 0
fi

# Interactive menu
while true; do
    show_menu
    read choice
    
    case $choice in
        1) show_space_dashboard; read -p "Press Enter to continue..." ;;
        2) check_system_status; read -p "Press Enter to continue..." ;;
        3) check_running_containers; read -p "Press Enter to continue..." ;;
        4) check_stopped_containers; read -p "Press Enter to continue..." ;;
        5) check_dangling_images; read -p "Press Enter to continue..." ;;
        6) check_unused_volumes; read -p "Press Enter to continue..." ;;
        7) check_log_sizes; read -p "Press Enter to continue..." ;;
        8) check_network_usage; read -p "Press Enter to continue..." ;;
        9) run_full_check; read -p "Press Enter to continue..." ;;
        0) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; read -p "Press Enter to continue..." ;;
    esac
done 