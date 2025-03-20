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

# Default to analyzing the most recent log
LOG_DIR="logs"
LATEST_LOG=$(ls -t "$LOG_DIR"/android-build-*.log 2>/dev/null | head -1)

# If no logs found or a specific log is provided
if [ -z "$LATEST_LOG" ]; then
    print_error "No build logs found in $LOG_DIR"
    exit 1
fi

if [ -n "$1" ]; then
    if [ -f "$1" ]; then
        LATEST_LOG="$1"
    else
        print_error "Log file not found: $1"
        exit 1
    fi
fi

print_header "Android Build Log Analysis"
print_info "Analyzing log file: $LATEST_LOG"
print_info "Log date: $(stat -c %y "$LATEST_LOG")"
echo

# Extract line count for sizing
LOG_SIZE=$(wc -l < "$LATEST_LOG")
print_info "Log contains $LOG_SIZE lines"

# Count error patterns
ERROR_COUNT=$(grep -i "error" "$LATEST_LOG" | wc -l)
WARN_COUNT=$(grep -i "warning" "$LATEST_LOG" | wc -l)
FAIL_COUNT=$(grep -i "fail" "$LATEST_LOG" | wc -l)
EXCEPTION_COUNT=$(grep -i "exception" "$LATEST_LOG" | wc -l)

print_info "Found $ERROR_COUNT error mentions, $WARN_COUNT warnings, $FAIL_COUNT failures, and $EXCEPTION_COUNT exceptions"

# Check for common error patterns
print_header "Common Error Patterns"

# Check for npm dependency issues
if grep -q "ERESOLVE" "$LATEST_LOG"; then
    print_error "NPM dependency resolution errors detected"
    grep -A 10 "ERESOLVE" "$LATEST_LOG" | grep -v "^npm " | head -n 15
    echo
    print_warning "Recommended fix: Use --legacy-peer-deps or --force flag with npm install"
fi

# Check for license acceptance issues
if grep -q "license is not accepted" "$LATEST_LOG"; then
    print_error "Android SDK license acceptance issues detected"
    grep -A 5 "license is not accepted" "$LATEST_LOG"
    echo
    print_warning "Recommended fix: Run sdkmanager --licenses and accept all licenses"
fi

# Check for Docker-related issues
if grep -q "docker: Error" "$LATEST_LOG"; then
    print_error "Docker errors detected"
    grep -A 3 "docker: Error" "$LATEST_LOG"
    echo
    print_warning "Recommended fix: Ensure Docker is running and image is built correctly"
fi

# Check for Gradle build failures
if grep -q "Execution failed for task" "$LATEST_LOG"; then
    print_error "Gradle build failures detected"
    grep -A 5 "Execution failed for task" "$LATEST_LOG"
    echo
    print_warning "Recommended fix: Check Android project configuration and dependencies"
fi

# Check for Java/JDK issues
if grep -q "Java" "$LATEST_LOG" | grep -q "error"; then
    print_error "Java/JDK issues detected"
    grep "Java" "$LATEST_LOG" | grep "error" | head -n 5
    echo
    print_warning "Recommended fix: Ensure correct JDK version is installed (recommended: JDK 17)"
fi

# Check for file not found errors
if grep -q "No such file or directory" "$LATEST_LOG"; then
    print_error "File not found errors detected"
    grep -A 2 "No such file or directory" "$LATEST_LOG" | head -n 10
    echo
    print_warning "Recommended fix: Check file paths and ensure all required files exist"
fi

# Check if the build was successful
if grep -q "APK build completed successfully" "$LATEST_LOG"; then
    print_success "Build completed successfully!"
    grep -A 3 "APK Details" "$LATEST_LOG"
else
    print_error "Build did not complete successfully"
    # Show the last few error lines
    print_header "Last Error Messages"
    grep -i "error" "$LATEST_LOG" | tail -n 10
fi

print_header "Recommended Next Steps"

# Provide recommendations based on findings
if grep -q "ERESOLVE" "$LATEST_LOG"; then
    echo "1. Try using native-build-android.sh script which uses --legacy-peer-deps flag"
    echo "2. Update package versions in package.json to resolve conflicts"
fi

if grep -q "license is not accepted" "$LATEST_LOG"; then
    echo "1. Run setup-android-env.sh to properly set up Android SDK and accept licenses"
    echo "2. Manually run: sdkmanager --licenses and accept all licenses"
fi

if grep -q "docker: Error" "$LATEST_LOG"; then
    echo "1. Switch to native build approach instead of Docker"
    echo "2. Check Docker installation and configuration"
fi

if grep -q "Execution failed for task" "$LATEST_LOG"; then
    echo "1. Check Android project configuration"
    echo "2. Ensure all Android dependencies are correctly specified"
fi

echo
print_info "For detailed error information, view the full log file:"
echo "less $LATEST_LOG"
echo
print_info "To try the native build approach:"
echo "./scripts/setup-android-env.sh"
echo "./scripts/native-build-android.sh" 