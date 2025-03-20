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

echo -e "${BLUE}${BOLD}🚀 Koodo Reader Development Environment${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Make sure the scripts are executable
chmod +x scripts/build-android.sh 2>/dev/null
chmod +x scripts/dev-web.sh 2>/dev/null
chmod +x scripts/docker-build.sh 2>/dev/null
chmod +x scripts/docker-maintenance.sh 2>/dev/null
chmod +x scripts/docker-cron-cleanup.sh 2>/dev/null
chmod +x scripts/docker-compose-check.sh 2>/dev/null

# Check Docker and Docker Compose
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed. Docker options will not be available.${NC}"
        return 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not installed. Docker options will not be available.${NC}"
        return 1
    fi
    
    return 0
}

# Check if node and npm are installed
check_node() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed. Web development options will not be available.${NC}"
        return 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm is not installed. Web development options will not be available.${NC}"
        return 1
    fi
    
    return 0
}

# Function to start Docker containers
start_docker() {
    echo -e "${YELLOW}🐳 Starting existing Docker containers...${NC}"
    docker-compose up -d
    
    # Get IP address for remote access
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    PORT=$(grep -oP '(?<=- ").*?(?=:)' docker-compose.yml)
    
    echo -e "${GREEN}✅ Koodo Reader is running in Docker!${NC}"
    echo -e "${CYAN}   - Local access: http://localhost:${PORT}${NC}"
    echo -e "${CYAN}   - Remote access: http://${IP_ADDRESS}:${PORT}${NC}"
}

# Function to stop Docker containers
stop_docker() {
    echo -e "${YELLOW}🛑 Stopping Docker containers...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ Docker containers stopped${NC}"
}

# Function to run web development mode
run_web_dev() {
    echo -e "${YELLOW}🌐 Starting web development mode...${NC}"
    ./scripts/dev-web.sh
}

# Function to update dependencies
update_dependencies() {
    echo -e "${YELLOW}📦 Updating dependencies...${NC}"
    npm install -g npm-check-updates
    ncu -u
    yarn install
    echo -e "${GREEN}✅ Dependencies updated${NC}"
}

# Function to build Android APK
build_android_apk() {
    echo -e "${YELLOW}📱 Running Android APK builder...${NC}"
    ./scripts/build-android.sh
}

# Function to run Docker maintenance tools
run_docker_maintenance() {
  echo -e "\n${CYAN}${BOLD}Docker Maintenance${NC}"
  echo -e "${YELLOW}------------------${NC}"
  echo -e "${CYAN}1. ${NC}Run interactive Docker maintenance tool"
  echo -e "${CYAN}2. ${NC}Run Docker cleanup script"
  echo -e "${CYAN}3. ${NC}Check Docker Compose file"
  echo -e "${CYAN}4. ${NC}Back to main menu"
  
  read -p "$(echo -e ${YELLOW}"Select an option [1-4]: "${NC})" docker_maint_option
  
  case $docker_maint_option in
    1)
      echo -e "\n${CYAN}Starting Docker maintenance tool...${NC}"
      ./scripts/docker-maintenance.sh
      ;;
    2)
      echo -e "\n${CYAN}Running Docker cleanup script...${NC}"
      ./scripts/docker-cron-cleanup.sh
      read -p "Press Enter to continue..."
      ;;
    3)
      echo -e "\n${CYAN}Checking Docker Compose file...${NC}"
      # Check if docker-compose.improved.yml exists
      if [ -f "docker-compose.improved.yml" ]; then
        echo -e "${YELLOW}Multiple Docker Compose files found.${NC}"
        echo -e "${CYAN}1. ${NC}Check docker-compose.yml (current)"
        echo -e "${CYAN}2. ${NC}Check docker-compose.improved.yml (recommended)"
        
        read -p "$(echo -e ${YELLOW}"Select a file to check [1-2]: "${NC})" compose_file_option
        
        case $compose_file_option in
          1)
            ./scripts/docker-compose-check.sh docker-compose.yml
            ;;
          2)
            ./scripts/docker-compose-check.sh docker-compose.improved.yml
            ;;
          *)
            echo -e "${RED}Invalid option. Checking docker-compose.yml${NC}"
            ./scripts/docker-compose-check.sh docker-compose.yml
            ;;
        esac
      else
        ./scripts/docker-compose-check.sh
      fi
      read -p "Press Enter to continue..."
      ;;
    4)
      show_menu
      ;;
    *)
      echo -e "${RED}Invalid option${NC}"
      run_docker_maintenance
      ;;
  esac
}

# Show menu
show_menu() {
    echo -e "\n${CYAN}${BOLD}Choose an option:${NC}"
    echo -e "${GREEN}1)${NC} Start web development server (no Electron)"
    
    if check_docker; then
        echo -e "${GREEN}2)${NC} Start Docker container"
        echo -e "${GREEN}3)${NC} Rebuild Docker with preserved volumes"
        echo -e "${GREEN}4)${NC} Stop Docker containers"
    else
        echo -e "${RED}2)${NC} Start Docker container ${RED}[Docker not available]${NC}"
        echo -e "${RED}3)${NC} Rebuild Docker with preserved volumes ${RED}[Docker not available]${NC}"
        echo -e "${RED}4)${NC} Stop Docker containers ${RED}[Docker not available]${NC}"
    fi
    
    echo -e "${GREEN}5)${NC} Update dependencies"
    echo -e "${GREEN}6)${NC} Docker maintenance tools"
    echo -e "${GREEN}7)${NC} Exit"
    
    echo -ne "\n${YELLOW}Enter your choice [1-7]:${NC} "
    read choice
    
    case $choice in
        1)
            if check_node; then
                run_web_dev
            else
                echo -e "${RED}❌ Cannot run web development mode. Node.js or npm is missing.${NC}"
                show_menu
            fi
            ;;
        2)
            if check_docker; then
                start_docker
            else
                echo -e "${RED}❌ Cannot start Docker. Docker or Docker Compose is missing.${NC}"
                show_menu
            fi
            ;;
        3)
            if check_docker; then
                ./scripts/docker-build.sh
            else
                echo -e "${RED}❌ Cannot rebuild Docker. Docker or Docker Compose is missing.${NC}"
                show_menu
            fi
            ;;
        4)
            if check_docker; then
                stop_docker
                show_menu
            else
                echo -e "${RED}❌ Cannot stop Docker. Docker or Docker Compose is missing.${NC}"
                show_menu
            fi
            ;;
        5)
            if check_node; then
                update_dependencies
                show_menu
            else
                echo -e "${RED}❌ Cannot update dependencies. Node.js or npm is missing.${NC}"
                show_menu
            fi
            ;;
        6)
            run_docker_maintenance
            ;;
        7)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please try again.${NC}"
            show_menu
            ;;
    esac
}

# Process command line arguments
if [ $# -eq 0 ]; then
    # No arguments, show menu
    show_menu
else
    # Process arguments
    case $1 in
        web)
            if check_node; then
                run_web_dev
            else
                echo -e "${RED}❌ Cannot run web development mode. Node.js or npm is missing.${NC}"
                exit 1
            fi
            ;;
        docker)
            if check_docker; then
                start_docker
            else
                echo -e "${RED}❌ Cannot start Docker. Docker or Docker Compose is missing.${NC}"
                exit 1
            fi
            ;;
        rebuild)
            if check_docker; then
                ./scripts/docker-build.sh
            else
                echo -e "${RED}❌ Cannot rebuild Docker. Docker or Docker Compose is missing.${NC}"
                exit 1
            fi
            ;;
        stop)
            if check_docker; then
                stop_docker
            else
                echo -e "${RED}❌ Cannot stop Docker. Docker or Docker Compose is missing.${NC}"
                exit 1
            fi
            ;;
        update)
            if check_node; then
                update_dependencies
            else
                echo -e "${RED}❌ Cannot update dependencies. Node.js or npm is missing.${NC}"
                exit 1
            fi
            ;;
        android)
            build_android_apk
            ;;
        maintenance)
            run_docker_maintenance
            ;;
        help)
            echo -e "${CYAN}${BOLD}Available commands:${NC}"
            echo -e "${GREEN}web${NC}      - Start web development server"
            echo -e "${GREEN}docker${NC}   - Start Docker container"
            echo -e "${GREEN}rebuild${NC}  - Rebuild Docker with preserved volumes"
            echo -e "${GREEN}stop${NC}     - Stop Docker containers"
            echo -e "${GREEN}update${NC}   - Update dependencies"
            echo -e "${GREEN}android${NC}  - Build Android APK"
            echo -e "${GREEN}maintenance${NC} - Run Docker maintenance tools"
            echo -e "${GREEN}help${NC}     - Show this help message"
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo -e "${YELLOW}Run 'koodo help' for available commands${NC}"
            exit 1
            ;;
    esac
fi 