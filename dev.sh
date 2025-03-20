#!/bin/bash

# Terminal colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Koodo Reader LLM Development Environment${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Function to run the Docker container for main application
start_docker_app() {
  echo -e "${YELLOW}🛑 Stopping any existing Koodo Reader container...${NC}"
  docker stop koodo-reader &>/dev/null
  docker rm koodo-reader &>/dev/null
  
  echo -e "${YELLOW}🧹 Cleaning up Docker resources...${NC}"
  docker system prune -f &>/dev/null
  
  echo -e "${BLUE}📚 Starting Koodo Reader container on port 7070...${NC}"
  docker run -d --name koodo-reader -p 7070:80 --restart always ghcr.io/koodo-reader/koodo-reader:master
  
  echo -e "${GREEN}✅ Koodo Reader is running at: ${CYAN}http://localhost:7070/#/manager/home${NC}"
}

# Function to monitor source code changes
watch_source_code() {
  echo -e "${YELLOW}👀 Watching source code for changes...${NC}"
  echo -e "${YELLOW}📝 Changes will be automatically applied${NC}"
  
  # Add your watch command here, e.g., using nodemon or similar
  # nodemon --watch src --ext js,jsx,ts,tsx --exec "yarn build"
}

# Function to start the LLM sandbox environment
start_llm_sandbox() {
  echo -e "${PURPLE}🧠 Starting LLM Sandbox environment...${NC}"
  
  # Check if Python is available
  if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 is not installed. Please install it first.${NC}"
    return 1
  fi
  
  # Navigate to sandbox directory
  cd ai-button-sandbox || mkdir -p ai-button-sandbox
  
  # Start a simple HTTP server for the sandbox
  echo -e "${GREEN}🌐 LLM Sandbox running at: ${CYAN}http://localhost:8000${NC}"
  python3 -m http.server 8000 &
  SANDBOX_PID=$!
  echo $SANDBOX_PID > .sandbox_pid
  cd ..
}

# Function to test Minimax LLM connection
test_minimax_connection() {
  echo -e "${PURPLE}🔄 Testing Minimax LLM connection...${NC}"
  
  # Create a simple test script
  cat > minimax_test.js << EOF
const axios = require('axios');

async function testMinimaxConnection() {
  const MINIMAX_API_KEY = process.env.MINIMAX_API_KEY || 'your_api_key';
  
  try {
    const response = await axios.post(
      'https://api.minimax.chat/v1/text/generation',
      {
        model: 'abab5.5-chat',
        messages: [
          { role: 'user', content: 'Create a haiku about reading books' }
        ],
        temperature: 0.7,
        max_tokens: 100
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': \`Bearer \${MINIMAX_API_KEY}\`
        }
      }
    );
    
    console.log('✅ Minimax connection successful!');
    console.log('📝 Generated haiku:');
    console.log(response.data.choices[0].message.content);
  } catch (error) {
    console.error('❌ Minimax connection failed:', error.message);
    if (error.response) {
      console.error('Error details:', error.response.data);
    }
  }
}

testMinimaxConnection();
EOF

  # Test if Node.js is available
  if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install it first.${NC}"
    return 1
  fi
  
  # Install axios if not present
  if ! grep -q "axios" package.json; then
    echo -e "${YELLOW}📦 Installing axios for API testing...${NC}"
    yarn add axios --dev
  fi
  
  # Run the test script
  echo -e "${YELLOW}⏳ Sending test request to Minimax API...${NC}"
  node minimax_test.js
}

# Function to clean up resources
cleanup() {
  echo -e "${YELLOW}🧹 Cleaning up resources...${NC}"
  
  # Kill sandbox server if running
  if [ -f "ai-button-sandbox/.sandbox_pid" ]; then
    SANDBOX_PID=$(cat ai-button-sandbox/.sandbox_pid)
    kill $SANDBOX_PID &>/dev/null
    rm ai-button-sandbox/.sandbox_pid
  fi
  
  echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Function to display help
show_help() {
  echo -e "${CYAN}Available commands:${NC}"
  echo -e "  ${GREEN}app${NC}      - Start Koodo Reader in Docker"
  echo -e "  ${GREEN}sandbox${NC}  - Start LLM sandbox environment"
  echo -e "  ${GREEN}watch${NC}    - Watch source code for changes"
  echo -e "  ${GREEN}test-llm${NC} - Test Minimax LLM connection"
  echo -e "  ${GREEN}clean${NC}    - Clean up resources"
  echo -e "  ${GREEN}help${NC}     - Show this help message"
}

# Set up trap for cleanup on exit
trap cleanup EXIT

# Check command line arguments
if [ "$#" -eq 0 ]; then
  # Default behavior: start everything
  start_docker_app
  start_llm_sandbox
  show_help
else
  case $1 in
    app)
      start_docker_app
      ;;
    sandbox)
      start_llm_sandbox
      ;;
    watch)
      watch_source_code
      ;;
    test-llm)
      test_minimax_connection
      ;;
    clean)
      cleanup
      ;;
    help)
      show_help
      ;;
    *)
      echo -e "${RED}Unknown command: $1${NC}"
      show_help
      exit 1
      ;;
  esac
fi

echo -e "\n${YELLOW}📘 Development environment ready!${NC}"
echo -e "${YELLOW}Press Ctrl+C to exit${NC}"

# Keep script running unless it's a one-off command
case $1 in
  test-llm|clean|help)
    # These are one-off commands, exit after completion
    ;;
  *)
    # For other commands, keep the script running
    while true; do
      sleep 1
    done
    ;;
esac 