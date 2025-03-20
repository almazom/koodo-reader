# Fresh Approach to Android APK Building

## Current Issues Summary
1. **npm Dependency Conflicts**
   - `@testing-library/react@16.2.0` requires `@types/react@^18.0.0 || ^19.0.0`
   - Project has `@types/react@17.0.2`

2. **Android SDK License Acceptance**
   - Automated license acceptance isn't working properly

3. **Docker Build Process**
   - Image fails to build due to npm install errors
   - Container can't run because image doesn't exist

## New Strategy: Direct Native Build

Instead of focusing on fixing the Docker build, let's create a direct native build process that will work reliably.

### Step 1: Prepare the Environment
1. Install Node.js LTS (v18.x) directly on the host
2. Install Android SDK tools directly
3. Accept Android licenses interactively

### Step 2: Modify the Build Scripts
1. Create a new `native-build-android.sh` script
2. Use `npm install --legacy-peer-deps` to bypass dependency conflicts
3. Implement better error handling and logging

### Step 3: Build Process
1. Build the web app first
2. Add Android platform using Capacitor
3. Generate the APK using Gradle directly

## Implementation Plan

### 1. Environment Setup Script
```bash
#!/bin/bash
# setup-android-env.sh

# Install Node.js 18.x if not already installed
if ! command -v node &> /dev/null || [[ $(node -v) != v18* ]]; then
    echo "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install Android SDK dependencies
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk unzip gradle

# Download and install Android SDK Command Line Tools
ANDROID_HOME="$HOME/Android/Sdk"
mkdir -p "$ANDROID_HOME"
mkdir -p "$ANDROID_HOME/cmdline-tools/latest"

echo "Downloading Android SDK Command Line Tools..."
cd /tmp
curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip -q cmdline-tools.zip
cd cmdline-tools
cp -r ./bin "$ANDROID_HOME/cmdline-tools/latest/"
cp -r ./lib "$ANDROID_HOME/cmdline-tools/latest/"
cp -r ./source.properties "$ANDROID_HOME/cmdline-tools/latest/"
cp -r ./NOTICE.txt "$ANDROID_HOME/cmdline-tools/latest/"

# Add Android SDK to PATH
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/31.0.0"' >> ~/.bashrc
source ~/.bashrc

# Accept Android SDK licenses interactively
echo "Please accept the Android SDK licenses when prompted:"
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Install required SDK components
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-31" "build-tools;31.0.0"

echo "Android development environment setup complete!"
```

### 2. Native Build Script
```bash
#!/bin/bash
# native-build-android.sh

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

log "${YELLOW}🚀 Starting Android APK build process...${NC}"
log "Build started at $(date)"
log "----------------------------------------"

# Check environment
if ! command -v node &> /dev/null; then
    log "${RED}❌ Node.js is not installed. Please run setup-android-env.sh first.${NC}"
    exit 1
fi

if [ -z "$ANDROID_HOME" ]; then
    log "${RED}❌ ANDROID_HOME is not set. Please run setup-android-env.sh first.${NC}"
    exit 1
fi

# Install dependencies with legacy peer deps flag
log "${YELLOW}📦 Installing npm dependencies...${NC}"
npm install --legacy-peer-deps 2>&1 | tee -a "$LOG_FILE"

# Build the web app
log "${YELLOW}🔨 Building the web application...${NC}"
npm run build 2>&1 | tee -a "$LOG_FILE"

# Install Capacitor if needed
if ! npm list @capacitor/cli | grep -q "@capacitor/cli"; then
    log "${YELLOW}📦 Installing Capacitor dependencies...${NC}"
    npm install -g @capacitor/cli
    npm install @capacitor/core @capacitor/android
fi

# Add Android platform if not already added
if [ ! -d "android" ]; then
    log "${YELLOW}📱 Adding Android platform...${NC}"
    npx cap add android 2>&1 | tee -a "$LOG_FILE"
else
    log "${YELLOW}📱 Syncing Android platform...${NC}"
    npx cap sync android 2>&1 | tee -a "$LOG_FILE"
fi

# Build the APK
log "${YELLOW}🔨 Building Android APK...${NC}"
cd android
./gradlew assembleDebug 2>&1 | tee -a "$LOG_FILE"
cd ..

# Create output directory and copy APK
mkdir -p android-build
cp android/app/build/outputs/apk/debug/app-debug.apk android-build/koodo-reader.apk

# Check if APK was generated
if [ -f "android-build/koodo-reader.apk" ]; then
    log "${GREEN}✅ Android APK build completed!${NC}"
    log "${GREEN}📱 APK location: $(pwd)/android-build/koodo-reader.apk${NC}"
    log "${BLUE}📝 Build logs available at: $LOG_FILE${NC}"
else
    log "${RED}❌ APK was not generated. Check the build logs for errors.${NC}"
    log "${BLUE}📝 Build logs available at: $LOG_FILE${NC}"
    exit 1
fi
```

## Advantages of This Approach

1. **Simplicity**
   - Eliminates Docker-related complexities
   - Direct access to the build process

2. **Better Debugging**
   - Interactive environment for troubleshooting
   - No container abstraction layer

3. **Reliable License Acceptance**
   - Interactive license acceptance ensures proper setup
   - One-time setup, persistent configuration

4. **Flexible Dependency Resolution**
   - Uses `--legacy-peer-deps` to handle conflicting dependencies
   - Can be easily modified for other resolution strategies

## Next Steps

1. Run the environment setup script once
2. Use the native build script for all future builds
3. If Docker is still preferred, fix the Dockerfile based on learnings from the native build

## FAQ

**Q: Why not use Docker?**
A: Docker adds an extra layer of complexity. For a successful first build, we're eliminating variables.

**Q: Will this work on CI/CD systems?**
A: Yes, with slight modifications to handle non-interactive license acceptance.

**Q: What about dependency conflicts?**
A: The `--legacy-peer-deps` flag allows npm to install despite peer dependency conflicts. 