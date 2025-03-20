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

echo -e "${BLUE}${BOLD}📱 Koodo Reader Android APK Builder${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Function to display Android SDK installation instructions
show_android_sdk_instructions() {
    echo -e "\n${PURPLE}${BOLD}Android SDK Installation Instructions:${NC}"
    echo -e "${YELLOW}To build Android APKs, you need to install the Android SDK.${NC}"
    echo -e "\n${CYAN}Option 1: Install via Android Studio (Recommended)${NC}"
    echo -e "${YELLOW}1. Download Android Studio from https://developer.android.com/studio${NC}"
    echo -e "${YELLOW}2. Install Android Studio and follow the setup wizard${NC}"
    echo -e "${YELLOW}3. Open Android Studio > Tools > SDK Manager${NC}"
    echo -e "${YELLOW}4. Install the latest Android SDK${NC}"
    
    echo -e "\n${CYAN}Option 2: Command-line installation${NC}"
    echo -e "${YELLOW}Use the following commands:${NC}"
    echo -e "${CYAN}   sudo apt-get install -y android-sdk${NC}"
    echo -e "${CYAN}   echo 'export ANDROID_SDK_ROOT=/usr/lib/android-sdk' >> ~/.bashrc${NC}"
    echo -e "${CYAN}   echo 'export PATH=\$PATH:\$ANDROID_SDK_ROOT/tools/bin:\$ANDROID_SDK_ROOT/platform-tools' >> ~/.bashrc${NC}"
    echo -e "${CYAN}   source ~/.bashrc${NC}"
    
    echo -e "\n${CYAN}Option 3: Manual download${NC}"
    echo -e "${YELLOW}1. Download Command line tools from https://developer.android.com/studio#command-tools${NC}"
    echo -e "${YELLOW}2. Extract to a folder (e.g., ~/android-sdk)${NC}"
    echo -e "${YELLOW}3. Set up environment variables:${NC}"
    echo -e "${CYAN}   echo 'export ANDROID_SDK_ROOT=~/android-sdk' >> ~/.bashrc${NC}"
    echo -e "${CYAN}   echo 'export PATH=\$PATH:\$ANDROID_SDK_ROOT/tools/bin:\$ANDROID_SDK_ROOT/platform-tools' >> ~/.bashrc${NC}"
    echo -e "${CYAN}   source ~/.bashrc${NC}"
    
    echo -e "\n${PURPLE}${BOLD}After installation:${NC}"
    echo -e "${YELLOW}1. Run 'sdkmanager --update' to update packages${NC}"
    echo -e "${YELLOW}2. Run 'sdkmanager \"platform-tools\" \"platforms;android-31\"' to install platform tools${NC}"
    echo -e "${YELLOW}3. Run this script again${NC}"
}

# Check if Java is installed (required for Android builds)
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java is not installed. Android builds require JDK 17.${NC}"
    echo -e "${YELLOW}Please install JDK 17. Example for Ubuntu:${NC}"
    echo -e "${CYAN}   sudo apt install openjdk-17-jdk${NC}"
    exit 1
fi

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed 's/^1\.//' | cut -d'.' -f1)
if [ -z "$JAVA_VERSION" ] || [ "$JAVA_VERSION" -lt 17 ]; then
    echo -e "${RED}❌ Java version is less than 17 (found: $JAVA_VERSION).${NC}"
    echo -e "${YELLOW}Android Gradle plugin requires Java 17. Example for Ubuntu:${NC}"
    echo -e "${CYAN}   sudo apt install openjdk-17-jdk${NC}"
    echo -e "${CYAN}   sudo update-alternatives --config java${NC}"
    exit 1
fi

# Accept Android SDK licenses automatically
echo -e "${YELLOW}📋 Accepting Android SDK licenses...${NC}"
if [ -n "$ANDROID_SDK_ROOT" ] || [ -n "$ANDROID_HOME" ]; then
    # Determine the SDK root
    SDK_ROOT=${ANDROID_SDK_ROOT:-$ANDROID_HOME}
    
    # Create licenses directory if it doesn't exist
    sudo mkdir -p "$SDK_ROOT/licenses" 2>/dev/null || mkdir -p "$SDK_ROOT/licenses" 2>/dev/null
    
    # Add common license texts
    echo "8933bad161af4178b1185d1a37fbf41ea5269c55" | sudo tee "$SDK_ROOT/licenses/android-sdk-license" >/dev/null 2>&1 || echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > "$SDK_ROOT/licenses/android-sdk-license" 2>/dev/null
    echo "d56f5187479451eabf01fb78af6dfcb131a6481e" | sudo tee "$SDK_ROOT/licenses/android-sdk-platform-tools-preview-license" >/dev/null 2>&1 || echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > "$SDK_ROOT/licenses/android-sdk-platform-tools-preview-license" 2>/dev/null
    echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" | sudo tee "$SDK_ROOT/licenses/android-sdk-preview-license" >/dev/null 2>&1 || echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$SDK_ROOT/licenses/android-sdk-preview-license" 2>/dev/null
    
    echo -e "${GREEN}✅ Android SDK licenses accepted.${NC}"
else
    echo -e "${YELLOW}⚠️ Could not determine Android SDK root to accept licenses.${NC}"
    echo -e "${YELLOW}Building might fail due to license issues.${NC}"
fi

# Check for Android command line tools
if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
    echo -e "${YELLOW}⚠️ ANDROID_SDK_ROOT or ANDROID_HOME is not set.${NC}"
    
    # Attempt to find Android SDK in common locations
    for dir in "$HOME/Android/Sdk" "$HOME/Library/Android/sdk" "$HOME/AppData/Local/Android/Sdk" "/usr/local/lib/android/sdk" "/usr/lib/android-sdk"; do
        if [ -d "$dir" ]; then
            echo -e "${GREEN}✅ Found potential Android SDK at: $dir${NC}"
            echo -e "${YELLOW}Setting ANDROID_SDK_ROOT temporarily for this session...${NC}"
            export ANDROID_SDK_ROOT="$dir"
            export PATH="$PATH:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools"
            break
        fi
    done
    
    # Still not set?
    if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
        echo -e "${RED}❌ Could not find Android SDK.${NC}"
        echo -e "${YELLOW}Would you like to see installation instructions? (y/n):${NC} "
        read -r show_instructions
        
        if [[ $show_instructions == "y" || $show_instructions == "Y" ]]; then
            show_android_sdk_instructions
        fi
        
        echo -e "${YELLOW}Continuing with the build, but APK creation will fail without Android SDK.${NC}"
    fi
fi

# Install Capacitor dependencies if needed
if ! grep -q "@capacitor/android" package.json; then
    echo -e "${YELLOW}📦 Installing Capacitor Android dependencies...${NC}"
    yarn add @capacitor/core @capacitor/android --ignore-engines
    npm install -g @capacitor/cli
else
    echo -e "${GREEN}✅ Capacitor Android dependencies are already installed.${NC}"
fi

# Build the web app first
echo -e "${BLUE}🔨 Building web app...${NC}"
export NODE_OPTIONS="--max-old-space-size=3072"
npm run build
# If build fails, try a more memory-efficient approach
if [ ! -d "build" ] || [ ! -f "build/index.html" ]; then
    echo -e "${YELLOW}⚠️ Standard build failed, trying with optimization flags...${NC}"
    NODE_ENV=production CI=false npm run build
fi

# Update capacitor config if needed
if [ ! -f "capacitor.config.ts" ]; then
    echo -e "${YELLOW}📝 Creating Capacitor config...${NC}"
    cat > capacitor.config.ts << EOF
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.koodoreader.app',
  appName: 'Koodo Reader',
  webDir: 'build',
  bundledWebRuntime: false,
  server: {
    androidScheme: 'https'
  }
};

export default config;
EOF
    echo -e "${GREEN}✅ Created capacitor.config.ts${NC}"
else
    echo -e "${GREEN}✅ Capacitor config already exists.${NC}"
fi

# Add Android platform if needed
if [ ! -d "android" ]; then
    echo -e "${YELLOW}📱 Adding Android platform...${NC}"
    cap add android || {
        echo -e "${RED}❌ Failed to add Android platform. Check errors above.${NC}"
        exit 1
    }
else
    echo -e "${GREEN}✅ Android platform already exists.${NC}"
fi

# Copy web assets to Android
echo -e "${BLUE}📂 Copying web assets to Android project...${NC}"
cap sync android || {
    echo -e "${RED}❌ Failed to sync web assets. Check errors above.${NC}"
    exit 1
}

# Show summary before building
echo -e "\n${PURPLE}${BOLD}Build Summary:${NC}"
echo -e "${CYAN}• Web app built to:${NC} $(pwd)/build"
echo -e "${CYAN}• Android project:${NC} $(pwd)/android"
echo -e "${CYAN}• Target APK:${NC} $(pwd)/koodo-reader.apk\n"

# Ask user to confirm before proceeding with Android build
echo -ne "${YELLOW}Proceed with Android build? (y/n):${NC} "
read -r confirmation

if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
    echo -e "${YELLOW}⚠️ Build canceled by user.${NC}"
    exit 0
fi

# Check if Android directory exists before trying to build
if [ ! -d "android" ]; then
    echo -e "${RED}❌ Android directory not found. Cannot build APK.${NC}"
    exit 1
fi

# Build Android APK
echo -e "${BLUE}🔨 Building Android APK...${NC}"
echo -e "${YELLOW}This may take several minutes. Please be patient...${NC}"

cd android || {
    echo -e "${RED}❌ Failed to navigate to android directory.${NC}"
    exit 1
}

# Check for gradle wrapper
if [ ! -f "./gradlew" ]; then
    echo -e "${RED}❌ Gradle wrapper not found in android directory.${NC}"
    exit 1
fi

# Make gradlew executable
chmod +x ./gradlew

# Run gradle build
./gradlew assembleDebug -Pandroid.overrideVersionCheck=true || {
    echo -e "${RED}❌ APK build failed. Check errors above.${NC}"
    cd ..
    
    echo -e "\n${PURPLE}${BOLD}Troubleshooting:${NC}"
    echo -e "${YELLOW}• Check that Android SDK is properly installed${NC}"
    echo -e "${YELLOW}• Verify ANDROID_HOME or ANDROID_SDK_ROOT environment variables${NC}"
    echo -e "${YELLOW}• Ensure Gradle can access JDK (java -version should work)${NC}"
    echo -e "${YELLOW}• Look for specific error messages above${NC}"
    
    exit 1
}

# Check if build succeeded
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo -e "${GREEN}${BOLD}✅ Android APK built successfully!${NC}"
    echo -e "${CYAN}   APK location: ${PWD}/app/build/outputs/apk/debug/app-debug.apk${NC}"
    
    # Copy APK to project root for easier access
    cp app/build/outputs/apk/debug/app-debug.apk ../koodo-reader.apk
    cd ..
    echo -e "${GREEN}✅ APK copied to: ${CYAN}${PWD}/koodo-reader.apk${NC}"
    
    # Calculate file size
    APK_SIZE=$(du -h koodo-reader.apk | cut -f1)
    echo -e "${GREEN}📦 APK size: ${CYAN}${APK_SIZE}${NC}"
    
    echo -e "\n${PURPLE}${BOLD}Next Steps:${NC}"
    echo -e "${YELLOW}• Install on Android device:${NC} adb install koodo-reader.apk"
    echo -e "${YELLOW}• Run on connected device:${NC} adb shell am start -n com.koodoreader.app/com.koodoreader.app.MainActivity"
    echo -e "${YELLOW}• Transfer to device:${NC} Use USB cable or ${CYAN}python -m http.server${NC} to host it locally"
else
    echo -e "${RED}❌ APK build failed. Check for errors above.${NC}"
    cd ..
    
    echo -e "\n${PURPLE}${BOLD}Troubleshooting:${NC}"
    echo -e "${YELLOW}• Check that Android SDK is properly installed${NC}"
    echo -e "${YELLOW}• Verify ANDROID_HOME or ANDROID_SDK_ROOT environment variables${NC}"
    echo -e "${YELLOW}• Ensure Gradle can access JDK (java -version should work)${NC}"
    echo -e "${YELLOW}• Look for specific error messages above${NC}"
fi

echo -e "\n${GREEN}${BOLD}Build process completed!${NC}" 