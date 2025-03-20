#!/bin/bash

# Rich UI elements
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print section header
print_header() {
  echo -e "\n${MAGENTA}${BOLD}=== $1 ===${NC}\n"
}

# Function to print success message
print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

# Function to print info message
print_info() {
  echo -e "${BLUE}ℹ️ $1${NC}"
}

# Function to print warning message
print_warning() {
  echo -e "${YELLOW}⚠️ $1${NC}"
}

# Function to print error message
print_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Log file setup
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/android-env-setup-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

# Log function
log() {
  echo -e "$1" | tee -a "$LOG_FILE"
}

log "${CYAN}${BOLD}🚀 Android Development Environment Setup${NC}"
log "Started at $(date)"
log "----------------------------------------"

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then
  print_error "Please do not run this script with sudo directly."
  print_info "The script will ask for sudo permissions when needed."
  exit 1
fi

# Install Node.js 18.x if not already installed
print_header "Node.js Installation"
if ! command -v node &> /dev/null || [[ $(node -v) != v18* ]]; then
    log "${YELLOW}Installing Node.js 18.x...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - 2>&1 | tee -a "$LOG_FILE"
    sudo apt-get install -y nodejs 2>&1 | tee -a "$LOG_FILE"
    print_success "Node.js $(node -v) installed successfully"
else
    print_info "Node.js $(node -v) is already installed"
fi

# Install Android SDK dependencies
print_header "Android SDK Dependencies"
log "${YELLOW}Installing Android SDK dependencies...${NC}"
sudo apt-get update 2>&1 | tee -a "$LOG_FILE"
sudo apt-get install -y openjdk-17-jdk unzip gradle 2>&1 | tee -a "$LOG_FILE"
print_success "Android SDK dependencies installed"

# Download and install Android SDK Command Line Tools
print_header "Android SDK Command Line Tools"
ANDROID_HOME="$HOME/Android/Sdk"
log "${YELLOW}Setting up Android SDK at $ANDROID_HOME${NC}"

mkdir -p "$ANDROID_HOME"
mkdir -p "$ANDROID_HOME/cmdline-tools/latest"

log "${YELLOW}Downloading Android SDK Command Line Tools...${NC}"
cd /tmp
if [ -f "cmdline-tools.zip" ]; then
    print_info "Command line tools already downloaded, using existing file"
else
    curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip 2>&1 | tee -a "$LOG_FILE"
fi

print_info "Extracting Android SDK Command Line Tools..."
unzip -q cmdline-tools.zip 2>&1 | tee -a "$LOG_FILE"
cd cmdline-tools

print_info "Installing Android SDK Command Line Tools..."
cp -r ./bin "$ANDROID_HOME/cmdline-tools/latest/" 2>&1 | tee -a "$LOG_FILE"
cp -r ./lib "$ANDROID_HOME/cmdline-tools/latest/" 2>&1 | tee -a "$LOG_FILE"
cp -r ./source.properties "$ANDROID_HOME/cmdline-tools/latest/" 2>&1 | tee -a "$LOG_FILE"
cp -r ./NOTICE.txt "$ANDROID_HOME/cmdline-tools/latest/" 2>&1 | tee -a "$LOG_FILE"
print_success "Android SDK Command Line Tools installed"

# Add Android SDK to PATH
print_header "Environment Configuration"
log "${YELLOW}Setting up environment variables...${NC}"

# Check if ANDROID_HOME is already in .bashrc
if grep -q "export ANDROID_HOME=" ~/.bashrc; then
    print_info "ANDROID_HOME is already configured in .bashrc"
else
    echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
    print_success "Added ANDROID_HOME to .bashrc"
fi

# Check if Android SDK paths are already in PATH
if grep -q "export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin" ~/.bashrc; then
    print_info "Android SDK paths are already in PATH"
else
    echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/31.0.0"' >> ~/.bashrc
    print_success "Added Android SDK paths to PATH"
fi

# Set environment variables for current session
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/31.0.0"

# Accept Android SDK licenses
print_header "Android SDK Licenses"
log "${YELLOW}Accepting Android SDK licenses...${NC}"
print_info "Please accept all license agreements when prompted"
echo "y" | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses 2>&1 | tee -a "$LOG_FILE"
print_success "Android SDK licenses accepted"

# Install required SDK components
print_header "Android SDK Components"
log "${YELLOW}Installing required Android SDK components...${NC}"
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-31" "build-tools;31.0.0" 2>&1 | tee -a "$LOG_FILE"
print_success "Android SDK components installed"

print_header "Summary"
log "${GREEN}${BOLD}✅ Android development environment setup complete!${NC}"
log "${BLUE}📝 Setup logs available at: $LOG_FILE${NC}"
log ""
log "${YELLOW}${BOLD}Next steps:${NC}"
log "1. Close and reopen your terminal or run: source ~/.bashrc"
log "2. Run the native-build-android.sh script to build your APK"
log ""
log "${CYAN}${BOLD}Happy coding! 🚀${NC}" 