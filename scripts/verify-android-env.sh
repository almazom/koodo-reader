#!/bin/bash
# verify-android-env.sh

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}┌───────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       Android Development Environment Verification     │${NC}"
echo -e "${BLUE}└───────────────────────────────────────────────────────┘${NC}"

# Create verification results directory
RESULTS_DIR="logs"
mkdir -p "$RESULTS_DIR"
RESULTS_FILE="$RESULTS_DIR/android-env-verification-$(date +%Y%m%d-%H%M%S).log"
touch "$RESULTS_FILE"

# Log function
log() {
  echo -e "$1" | tee -a "$RESULTS_FILE"
}

# Helper function to check if a command exists
check_command() {
  local cmd=$1
  local name=$2
  if command -v $cmd &> /dev/null; then
    log "${GREEN}✓ $name:${NC} Found"
    return 0
  else
    log "${RED}✗ $name:${NC} Not found"
    return 1
  fi
}

log "Verification started at $(date)"
log "----------------------------------------"

# Check Node.js
if check_command node "Node.js"; then
  node_version=$(node -v 2>/dev/null)
  if [[ $node_version == v20* ]]; then
    log "${GREEN}✓ Node.js version:${NC} $node_version (correct version)"
  else
    log "${RED}✗ Node.js version:${NC} $node_version (expected v20.x)"
    log "${YELLOW}ℹ️ Recommendation:${NC} Install Node.js 20.x using nvm or from nodejs.org"
  fi
fi

# Check npm
if check_command npm "npm"; then
  npm_version=$(npm -v 2>/dev/null)
  log "${GREEN}✓ npm version:${NC} $npm_version"
fi

# Check JDK
if check_command java "Java"; then
  java_version=$(java -version 2>&1 | grep version | awk '{print $3}' | tr -d '"')
  if [[ $java_version == 17* || $java_version == 1.17* ]]; then
    log "${GREEN}✓ JDK version:${NC} $java_version (correct version)"
  else
    log "${RED}✗ JDK version:${NC} $java_version (expected 17.x)"
    log "${YELLOW}ℹ️ Recommendation:${NC} Install JDK 17 using: sudo apt install openjdk-17-jdk"
  fi
fi

# Check JAVA_HOME
if [[ -n "$JAVA_HOME" ]]; then
  log "${GREEN}✓ JAVA_HOME:${NC} $JAVA_HOME"
else
  log "${RED}✗ JAVA_HOME:${NC} not set"
  log "${YELLOW}ℹ️ Recommendation:${NC} Set JAVA_HOME in ~/.bashrc or ~/.zshrc"
fi

# Check ANDROID_HOME
if [[ -n "$ANDROID_HOME" ]]; then
  log "${GREEN}✓ ANDROID_HOME:${NC} $ANDROID_HOME"
else
  log "${RED}✗ ANDROID_HOME:${NC} not set"
  log "${YELLOW}ℹ️ Recommendation:${NC} Set ANDROID_HOME to point to your Android SDK location"
  log "${YELLOW}  Example:${NC} export ANDROID_HOME=\$HOME/Android/Sdk"
fi

# Check Android SDK components
if [[ -n "$ANDROID_HOME" ]]; then
  # Check cmdline-tools
  if [[ -d "$ANDROID_HOME/cmdline-tools" ]]; then
    log "${GREEN}✓ Android cmdline-tools:${NC} Found"
  else
    log "${RED}✗ Android cmdline-tools:${NC} Not found"
    log "${YELLOW}ℹ️ Recommendation:${NC} Download cmdline-tools from Android Studio or SDK Manager"
  fi
  
  # Check platform-tools
  if [[ -d "$ANDROID_HOME/platform-tools" ]]; then
    log "${GREEN}✓ Android platform-tools:${NC} Found"
    # Check adb version
    adb_version=$(adb version 2>/dev/null | head -n 1)
    if [[ -n "$adb_version" ]]; then
      log "${GREEN}✓ adb:${NC} $adb_version"
    fi
  else
    log "${RED}✗ Android platform-tools:${NC} Not found"
    log "${YELLOW}ℹ️ Recommendation:${NC} Install platform-tools using sdkmanager"
  fi
  
  # Check build-tools
  if [[ -d "$ANDROID_HOME/build-tools" ]]; then
    build_tools_versions=$(ls "$ANDROID_HOME/build-tools" 2>/dev/null)
    log "${GREEN}✓ Android build-tools:${NC} $build_tools_versions"
    
    # Check if we have build-tools version 31.0.0 or higher
    if [[ -d "$ANDROID_HOME/build-tools/31.0.0" ]] || [[ -d "$ANDROID_HOME/build-tools/32.0.0" ]] || [[ -d "$ANDROID_HOME/build-tools/33.0.0" ]] || [[ -d "$ANDROID_HOME/build-tools/34.0.0" ]]; then
      log "${GREEN}✓ Android build-tools 31.0.0 or higher:${NC} Found"
    else
      log "${RED}✗ Android build-tools 31.0.0 or higher:${NC} Not found"
      log "${YELLOW}ℹ️ Recommendation:${NC} Install build-tools;31.0.0 using sdkmanager"
    fi
  else
    log "${RED}✗ Android build-tools:${NC} Not found"
    log "${YELLOW}ℹ️ Recommendation:${NC} Install build-tools using sdkmanager"
  fi
  
  # Check platforms
  if [[ -d "$ANDROID_HOME/platforms" ]]; then
    platform_versions=$(ls "$ANDROID_HOME/platforms" 2>/dev/null)
    log "${GREEN}✓ Android platforms:${NC} $platform_versions"
    
    # Check if we have platform 31 (Android 12) or higher
    if [[ -d "$ANDROID_HOME/platforms/android-31" ]] || [[ -d "$ANDROID_HOME/platforms/android-32" ]] || [[ -d "$ANDROID_HOME/platforms/android-33" ]] || [[ -d "$ANDROID_HOME/platforms/android-34" ]]; then
      log "${GREEN}✓ Android platform 31 (Android 12) or higher:${NC} Found"
    else
      log "${RED}✗ Android platform 31 (Android 12) or higher:${NC} Not found"
      log "${YELLOW}ℹ️ Recommendation:${NC} Install platforms;android-31 using sdkmanager"
    fi
  else
    log "${RED}✗ Android platforms:${NC} Not found"
    log "${YELLOW}ℹ️ Recommendation:${NC} Install Android platforms using sdkmanager"
  fi
  
  # Check if SDK licenses are accepted
  if [[ -d "$ANDROID_HOME/licenses" ]]; then
    license_count=$(ls "$ANDROID_HOME/licenses" 2>/dev/null | wc -l)
    if [[ $license_count -gt 0 ]]; then
      log "${GREEN}✓ Android SDK licenses:${NC} Found $license_count license files"
    else
      log "${RED}✗ Android SDK licenses:${NC} No licenses accepted"
      log "${YELLOW}ℹ️ Recommendation:${NC} Accept licenses using: sdkmanager --licenses"
    fi
  else
    log "${RED}✗ Android SDK licenses:${NC} Directory not found"
    log "${YELLOW}ℹ️ Recommendation:${NC} Accept licenses using: sdkmanager --licenses"
  fi
fi

# Check Gradle
check_command gradle "Gradle"
if command -v gradle &> /dev/null; then
  gradle_version=$(gradle -v 2>/dev/null | grep Gradle | head -n 1)
  log "${GREEN}✓ Gradle version:${NC} $gradle_version"
fi

# Check capacitor
if npm list -g @capacitor/cli | grep -q "@capacitor/cli"; then
  capacitor_version=$(npx cap --version 2>/dev/null)
  log "${GREEN}✓ Capacitor CLI (global):${NC} $capacitor_version"
else
  log "${YELLOW}ℹ️ Capacitor CLI:${NC} Not installed globally (will be installed during build)"
fi

# Summary
log "\n----------------------------------------"
log "Environment verification completed at $(date)"
log "${BLUE}📝 Verification results saved to:${NC} $RESULTS_FILE"

# Count issues
success_count=$(grep -c "✓" "$RESULTS_FILE")
error_count=$(grep -c "✗" "$RESULTS_FILE")

echo -e "\n${BLUE}┌───────────────────────────────────────────────────────┐${NC}"
if [[ $error_count -eq 0 ]]; then
  echo -e "${BLUE}│${GREEN} ✅ All checks passed! Environment is ready for Android build${BLUE} │${NC}"
else
  echo -e "${BLUE}│${RED} ❌ Found $error_count issue(s). Please fix before proceeding${BLUE}    │${NC}"
fi
echo -e "${BLUE}└───────────────────────────────────────────────────────┘${NC}"

# Make the script executable
chmod +x "$0"

exit $error_count 