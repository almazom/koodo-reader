#!/bin/bash

set -e

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
  exit 1
}

# Log file setup
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/android-build-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

# Log function
log() {
  echo -e "$1" | tee -a "$LOG_FILE"
}

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

log "${CYAN}${BOLD}🚀 Koodo Reader Android APK Builder (Native)${NC}"
log "Started at $(date)"
log "----------------------------------------"

# Check environment
print_header "Environment Check"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please run setup-android-env.sh first."
fi
print_info "Node.js $(node -v) detected"

# Check if ANDROID_HOME is set
if [ -z "$ANDROID_HOME" ]; then
    if [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
        print_warning "ANDROID_HOME was not set, defaulting to $ANDROID_HOME"
    else
        print_error "ANDROID_HOME is not set and default location not found. Please run setup-android-env.sh first."
    fi
fi
print_info "Android SDK found at $ANDROID_HOME"

# Check for sdkmanager
if ! command -v "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" &> /dev/null; then
    print_error "Android SDK tools not properly installed. Please run setup-android-env.sh first."
fi
print_info "Android SDK tools detected"

# Install dependencies with legacy peer deps flag
print_header "NPM Dependencies"
log "${YELLOW}Installing npm dependencies...${NC}"

# Save current package-lock.json as backup
if [ -f "package-lock.json" ]; then
    cp package-lock.json package-lock.json.bak
    print_info "Backed up package-lock.json"
fi

npm install --legacy-peer-deps 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    print_warning "npm install encountered issues, trying with --force flag"
    npm install --legacy-peer-deps --force 2>&1 | tee -a "$LOG_FILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Failed to install npm dependencies even with --force flag. See logs for details."
    fi
fi
print_success "Dependencies installed"

# Build the web app
print_header "Web App Build"
log "${YELLOW}Building the web application...${NC}"
npm run build 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    print_error "Failed to build the web application. See logs for details."
fi
print_success "Web app built successfully"

# Install Capacitor if needed
print_header "Capacitor Setup"
if ! npm list @capacitor/cli | grep -q "@capacitor/cli"; then
    log "${YELLOW}Installing Capacitor dependencies...${NC}"
    npm install @capacitor/cli @capacitor/core @capacitor/android --legacy-peer-deps 2>&1 | tee -a "$LOG_FILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Failed to install Capacitor dependencies. See logs for details."
    fi
    print_success "Capacitor installed"
else
    print_info "Capacitor already installed"
fi

# Check if capacitor.config.ts exists, create if not
if [ ! -f "capacitor.config.ts" ]; then
    log "${YELLOW}Creating Capacitor configuration...${NC}"
    cat > capacitor.config.ts << 'EOF'
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.koodo.reader',
  appName: 'Koodo Reader',
  webDir: 'build',
  bundledWebRuntime: false
};

export default config;
EOF
    print_success "Capacitor config created"
else
    print_info "Capacitor config already exists"
fi

# Add or sync Android platform
print_header "Android Platform"
if [ ! -d "android" ]; then
    log "${YELLOW}Adding Android platform...${NC}"
    npx cap add android 2>&1 | tee -a "$LOG_FILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Failed to add Android platform. See logs for details."
    fi
    print_success "Android platform added"
else
    log "${YELLOW}Syncing Android platform...${NC}"
    npx cap sync android 2>&1 | tee -a "$LOG_FILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Failed to sync Android platform. See logs for details."
    fi
    print_success "Android platform synced"
fi

# Build the APK
print_header "APK Build"
log "${YELLOW}Building Android APK...${NC}"
cd android
chmod +x gradlew
./gradlew assembleDebug 2>&1 | tee -a "../$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    print_error "Failed to build the APK. See logs for details."
fi
cd ..
print_success "APK built successfully"

# Create output directory and copy APK
print_header "APK Output"
mkdir -p android-build
if [ -f "android/app/build/outputs/apk/debug/app-debug.apk" ]; then
    cp android/app/build/outputs/apk/debug/app-debug.apk android-build/koodo-reader.apk
    print_success "APK copied to android-build/koodo-reader.apk"
else
    print_error "APK file not found at expected location. Build may have failed."
fi

# Create a summary report
print_header "Build Summary"
APK_SIZE=$(du -h android-build/koodo-reader.apk | cut -f1)
APK_PATH="$(pwd)/android-build/koodo-reader.apk"

log "${GREEN}${BOLD}✅ Android APK build completed successfully!${NC}"
log ""
log "${YELLOW}APK Details:${NC}"
log "📱 Location: ${CYAN}$APK_PATH${NC}"
log "📊 Size: ${CYAN}$APK_SIZE${NC}"
log "📝 Build logs: ${CYAN}$LOG_FILE${NC}"
log ""
log "${YELLOW}Next Steps:${NC}"
log "1. Install the APK on your Android device"
log "   adb install $APK_PATH"
log "2. Or share the APK file directly"
log ""
log "${CYAN}${BOLD}Happy reading with Koodo Reader! 📚${NC}" 