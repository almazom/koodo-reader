#!/bin/bash
# enhanced-build-android.sh - Koodo Reader Android APK Builder

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file setup
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/android-build-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

# Log function
log() {
  echo -e "$1" | tee -a "$LOG_FILE"
}

show_progress() {
  local title="$1"
  local status="$2" # "pending", "running", "success", "error"
  local icon="⏳"
  local color="${BLUE}"
  
  case "$status" in
    "pending") icon="⏳"; color="${YELLOW}" ;;
    "running") icon="⚙️"; color="${BLUE}" ;;
    "success") icon="✅"; color="${GREEN}" ;;
    "error") icon="❌"; color="${RED}" ;;
  esac
  
  log "${color}${icon} ${title}${NC}"
}

print_header() {
  log "\n${BLUE}┌───────────────────────────────────────────────────────┐${NC}"
  log "${BLUE}│       Koodo Reader Android APK Build Process           │${NC}"
  log "${BLUE}└───────────────────────────────────────────────────────┘${NC}"
  log "Build started at $(date)"
  log "----------------------------------------"
}

print_summary() {
  local success=$1
  local apk_path=$2
  
  log "\n${BLUE}┌───────────────────────────────────────────────────────┐${NC}"
  log "${BLUE}│                   Build Summary                        │${NC}"
  log "${BLUE}└───────────────────────────────────────────────────────┘${NC}"
  
  if [ "$success" = true ]; then
    log "${GREEN}✅ Build completed successfully!${NC}"
    log "${GREEN}📱 APK location: $apk_path${NC}"
  else
    log "${RED}❌ Build failed.${NC}"
  fi
  
  log "${BLUE}📝 Build logs available at: $LOG_FILE${NC}"
  log "Build finished at $(date)"
}

retry_command() {
  local cmd="$1"
  local max_attempts=${2:-3}
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    log "${YELLOW}Attempt $attempt of $max_attempts: $cmd${NC}"
    if eval "$cmd"; then
      return 0
    else
      log "${RED}Command failed on attempt $attempt${NC}"
      attempt=$((attempt+1))
      [ $attempt -le $max_attempts ] && log "${YELLOW}Retrying...${NC}" && sleep 3
    fi
  done
  
  log "${RED}Command failed after $max_attempts attempts${NC}"
  return 1
}

# Main build process
print_header

# Step 1: Environment check using verify-android-env.sh if available
show_progress "Verifying build environment" "running"

if [ -f "scripts/verify-android-env.sh" ]; then
  log "${YELLOW}Running environment verification script...${NC}"
  bash scripts/verify-android-env.sh
  ENV_CHECK_RESULT=$?
  
  if [ $ENV_CHECK_RESULT -ne 0 ]; then
    log "${RED}❌ Environment verification found issues. Please fix them before proceeding.${NC}"
    log "${YELLOW}Run scripts/verify-android-env.sh manually to see the detailed report.${NC}"
    print_summary false ""
    exit 1
  fi
else
  # Fallback to basic checks if verification script not found
  if ! command -v node &> /dev/null; then
    log "${RED}❌ Node.js is not installed.${NC}"
    print_summary false ""
    exit 1
  fi

  if [ -z "$ANDROID_HOME" ]; then
    log "${RED}❌ ANDROID_HOME is not set.${NC}"
    print_summary false ""
    exit 1
  fi
fi
show_progress "Environment verification passed" "success"

# Step 2: Install dependencies
show_progress "Installing npm dependencies" "running"
retry_command "npm install --legacy-peer-deps" 3
show_progress "Dependencies installed successfully" "success"

# Step 3: Build the web app
show_progress "Building the web application" "running"
npm run build 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    show_progress "Web application build failed" "error"
    log "${RED}❌ Failed to build the web application. Please check the logs for details.${NC}"
    print_summary false ""
    exit 1
fi
show_progress "Web application built successfully" "success"

# Step 4: Install and configure Capacitor
show_progress "Configuring Capacitor" "running"
if ! npm list @capacitor/cli | grep -q "@capacitor/cli"; then
    log "${YELLOW}Installing Capacitor CLI and core packages...${NC}"
    npm install -g @capacitor/cli
    npm install @capacitor/core @capacitor/android
fi

# Verify capacitor.config.ts exists
if [ ! -f "capacitor.config.ts" ]; then
    log "${YELLOW}Creating default capacitor.config.ts...${NC}"
    cat > capacitor.config.ts << 'EOF'
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.koodoreader.app',
  appName: 'Koodo Reader',
  webDir: 'build',
  bundledWebRuntime: false,
  server: {
    androidScheme: 'https'
  },
  android: {
    buildOptions: {
      sourceCompatibility: '17',
      targetCompatibility: '17'
    }
  }
};

export default config;
EOF
    log "${GREEN}Created default capacitor.config.ts${NC}"
fi
show_progress "Capacitor configured successfully" "success"

# Step 5: Add or sync Android platform
show_progress "Preparing Android platform" "running"
if [ ! -d "android" ]; then
    log "${YELLOW}📱 Adding Android platform...${NC}"
    npx cap add android 2>&1 | tee -a "$LOG_FILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        show_progress "Failed to add Android platform" "error"
        log "${RED}❌ Error adding Android platform. Trying with --verbose flag...${NC}"
        npx cap add android --verbose 2>&1 | tee -a "$LOG_FILE"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            log "${RED}❌ Failed to add Android platform even with --verbose flag.${NC}"
            print_summary false ""
            exit 1
        fi
    fi
else
    log "${YELLOW}📱 Syncing Android platform...${NC}"
    npx cap sync android 2>&1 | tee -a "$LOG_FILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        show_progress "Failed to sync Android platform" "error"
        log "${RED}❌ Error syncing Android platform. Trying with --verbose flag...${NC}"
        npx cap sync android --verbose 2>&1 | tee -a "$LOG_FILE"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            log "${RED}❌ Failed to sync Android platform.${NC}"
            print_summary false ""
            exit 1
        fi
    fi
fi
show_progress "Android platform prepared successfully" "success"

# Step 6: Ensure Java version compatibility in Gradle files
show_progress "Verifying Gradle configuration" "running"
if [ -f "android/app/capacitor.build.gradle" ]; then
    log "${YELLOW}Checking Java version in capacitor.build.gradle...${NC}"
    if grep -q "VERSION_21" "android/app/capacitor.build.gradle"; then
        log "${YELLOW}Updating Java version from VERSION_21 to VERSION_17 in capacitor.build.gradle${NC}"
        sed -i 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle
    fi
fi

if [ -f "android/capacitor-cordova-android-plugins/build.gradle" ]; then
    log "${YELLOW}Checking Java version in capacitor-cordova-android-plugins/build.gradle...${NC}"
    if grep -q "VERSION_21" "android/capacitor-cordova-android-plugins/build.gradle"; then
        log "${YELLOW}Updating Java version from VERSION_21 to VERSION_17 in capacitor-cordova-android-plugins/build.gradle${NC}"
        sed -i 's/VERSION_21/VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle
    fi
fi

# Update local.properties with correct SDK path
if [ -n "$ANDROID_HOME" ]; then
    log "${YELLOW}Creating/updating local.properties with SDK path...${NC}"
    echo "sdk.dir=$ANDROID_HOME" > android/local.properties
fi
show_progress "Gradle configuration verified" "success"

# Step 7: Build the APK
show_progress "Building Android APK" "running"
cd android
if [ -f "./gradlew" ]; then
    chmod +x ./gradlew
    ./gradlew assembleDebug --stacktrace 2>&1 | tee -a "../$LOG_FILE"
    BUILD_RESULT=${PIPESTATUS[0]}
    if [ $BUILD_RESULT -ne 0 ]; then
        show_progress "Initial APK build failed, trying with --info flag" "error"
        log "${YELLOW}Retrying build with --info flag for more details...${NC}"
        ./gradlew assembleDebug --info --stacktrace 2>&1 | tee -a "../$LOG_FILE"
        BUILD_RESULT=${PIPESTATUS[0]}
    fi
else
    log "${RED}❌ Gradle wrapper (gradlew) not found in android directory.${NC}"
    BUILD_RESULT=1
fi

cd ..

if [ $BUILD_RESULT -ne 0 ]; then
    show_progress "APK build failed" "error"
    log "${RED}❌ Failed to build APK. Please check the logs for details.${NC}"
    print_summary false ""
    exit 1
fi
show_progress "APK built successfully" "success"

# Step 8: Copy and verify APK
show_progress "Finalizing APK" "running"
mkdir -p android-build
APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    cp "$APK_PATH" android-build/koodo-reader.apk
    
    # Get APK size
    APK_SIZE=$(du -h android-build/koodo-reader.apk | cut -f1)
    
    show_progress "APK finalized successfully" "success"
    log "${GREEN}📊 APK Size: $APK_SIZE${NC}"
    FULL_APK_PATH="$(pwd)/android-build/koodo-reader.apk"
    print_summary true "$FULL_APK_PATH"
    
    log "${YELLOW}ℹ️ To install on a connected device, run:${NC}"
    log "  adb install -r android-build/koodo-reader.apk"
    
    log "${YELLOW}ℹ️ To create a release build later, run:${NC}"
    log "  cd android && ./gradlew assembleRelease"
else
    show_progress "APK finalization failed" "error"
    log "${RED}❌ APK file not found at expected location: $APK_PATH${NC}"
    print_summary false ""
    exit 1
fi

# Make the script executable
chmod +x "$0" 