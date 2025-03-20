#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Build the Docker image with logs
log "${YELLOW}📦 Building Docker image...${NC}"
docker build -t koodo-reader-android-builder:latest -f Dockerfile.android . 2>&1 | tee -a "$LOG_FILE"

# Check if build was successful
if [ $? -ne 0 ]; then
    log "${RED}❌ Docker image build failed. See logs for details.${NC}"
    log "Full logs available at: $LOG_FILE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p android-build

# Run the container with logs
log "${YELLOW}🚀 Running Docker container to build Android APK...${NC}"
docker run --rm \
    -v "$(pwd)/android-build:/output" \
    koodo-reader-android-builder:latest 2>&1 | tee -a "$LOG_FILE"

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