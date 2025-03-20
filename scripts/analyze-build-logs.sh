#!/bin/bash
# analyze-build-logs.sh - Android Build Log Analyzer

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log directory
LOG_DIR="logs"

print_header() {
  echo -e "${BLUE}┌───────────────────────────────────────────────────────┐${NC}"
  echo -e "${BLUE}│         Koodo Reader Android Build Log Analyzer       │${NC}"
  echo -e "${BLUE}└───────────────────────────────────────────────────────┘${NC}"
}

show_usage() {
  echo -e "\n${YELLOW}Usage:${NC}"
  echo -e "  ${GREEN}./scripts/analyze-build-logs.sh${NC} [log_file]"
  echo
  echo -e "${YELLOW}Options:${NC}"
  echo -e "  ${GREEN}log_file${NC}    Path to specific log file (optional)"
  echo
  echo -e "${YELLOW}If no log file is specified, the most recent log file will be used.${NC}"
  echo
}

# Function to print section headers
print_section() {
  echo -e "\n${CYAN}➤ $1${NC}"
  echo -e "${CYAN}$(printf '─%.0s' {1..50})${NC}"
}

# Common Android build errors and solutions
analyze_error() {
  local log_content="$1"
  local found_error=false
  
  print_section "Error Analysis"
  
  # Check for common errors and provide solutions
  if grep -q "Minimum supported Gradle version is" <<< "$log_content"; then
    echo -e "${RED}✗ Gradle Version Error${NC}"
    echo -e "   The Gradle version is too old for this project."
    echo -e "   ${YELLOW}Solution:${NC} Update Gradle to the required version."
    echo -e "   Run: gradle wrapper --gradle-version=8.0.2 (or later version)"
    found_error=true
  fi
  
  if grep -q "Failed to install the following Android SDK packages" <<< "$log_content"; then
    echo -e "${RED}✗ Android SDK Package Installation Error${NC}"
    echo -e "   Missing required Android SDK packages."
    echo -e "   ${YELLOW}Solution:${NC} Install the required packages using sdkmanager:"
    echo -e "   Run: \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --install \"platforms;android-31\" \"build-tools;31.0.0\""
    found_error=true
  fi
  
  if grep -q "You have not accepted the license agreements" <<< "$log_content"; then
    echo -e "${RED}✗ License Agreement Error${NC}"
    echo -e "   Android SDK license agreements not accepted."
    echo -e "   ${YELLOW}Solution:${NC} Accept the licenses using sdkmanager:"
    echo -e "   Run: \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses"
    found_error=true
  fi
  
  if grep -q "Deprecated Gradle features were used" <<< "$log_content"; then
    echo -e "${YELLOW}⚠ Gradle Deprecation Warnings${NC}"
    echo -e "   Using deprecated Gradle features that will be removed in future versions."
    echo -e "   ${YELLOW}Info:${NC} These are warnings only and don't affect the build."
    found_error=true
  fi
  
  if grep -q "Unable to resolve dependency for" <<< "$log_content"; then
    echo -e "${RED}✗ Dependency Resolution Error${NC}"
    echo -e "   Failed to resolve one or more dependencies."
    echo -e "   ${YELLOW}Solution:${NC} Check your internet connection and try again."
    echo -e "   If using a proxy, ensure it's properly configured."
    found_error=true
  fi
  
  if grep -q "Execution failed for task ':app:processDebugResources'" <<< "$log_content"; then
    echo -e "${RED}✗ Resource Processing Error${NC}"
    echo -e "   Failed to process Android resources."
    echo -e "   ${YELLOW}Solution:${NC} Check for errors in resource files (XML files in res/ directory)."
    found_error=true
  fi
  
  if grep -q "Execution failed for task ':app:compileDebugJavaWithJavac'" <<< "$log_content"; then
    echo -e "${RED}✗ Java Compilation Error${NC}"
    echo -e "   Failed to compile Java source files."
    echo -e "   ${YELLOW}Solution:${NC} Check for Java syntax errors in the generated Android project."
    found_error=true
  fi
  
  if grep -q "conflict with the internal version" <<< "$log_content"; then
    echo -e "${RED}✗ Dependency Conflict Error${NC}"
    echo -e "   There's a conflict between dependencies."
    echo -e "   ${YELLOW}Solution:${NC} Update the capacitor.config.ts to specify compatible dependencies."
    found_error=true
  fi
  
  if grep -q "Could not find tools.jar" <<< "$log_content"; then
    echo -e "${RED}✗ JDK Configuration Error${NC}"
    echo -e "   The build cannot find the Java Development Kit tools."
    echo -e "   ${YELLOW}Solution:${NC} Ensure JAVA_HOME is properly set to a JDK (not JRE) location."
    found_error=true
  fi
  
  if grep -q "npm ERR!" <<< "$log_content"; then
    echo -e "${RED}✗ NPM Error${NC}"
    echo -e "   There was an error during npm dependency installation."
    echo -e "   ${YELLOW}Solution:${NC} Try running 'npm install --legacy-peer-deps' manually."
    found_error=true
  fi
  
  if grep -q "FAILURE: Build failed with an exception" <<< "$log_content"; then
    # Extract the actual exception
    exception=$(grep -A 5 "FAILURE: Build failed with an exception" <<< "$log_content" | grep -v "FAILURE:")
    echo -e "${RED}✗ Gradle Build Exception${NC}"
    echo -e "   Build failed with exception:"
    echo -e "   ${YELLOW}$exception${NC}"
    found_error=true
  fi
  
  # If no specific error was identified
  if [ "$found_error" = false ]; then
    echo -e "${YELLOW}⚠ No specific error pattern recognized.${NC}"
    echo -e "   Please review the full log file for details."
    
    # Extract just error lines for a summary
    echo -e "\n${YELLOW}Error Summary:${NC}"
    grep -i "error:" <<< "$log_content" | head -10
  fi
}

# Function to print build statistics
print_stats() {
  local log_content="$1"
  
  print_section "Build Statistics"
  
  # Extract build duration if available
  if grep -q "Total time:" <<< "$log_content"; then
    build_time=$(grep "Total time:" <<< "$log_content" | head -1)
    echo -e "${GREEN}➤ $build_time${NC}"
  fi
  
  # Count warnings and errors
  warning_count=$(grep -i "warning:" <<< "$log_content" | wc -l)
  error_count=$(grep -i "error:" <<< "$log_content" | wc -l)
  
  echo -e "${YELLOW}➤ Warnings:${NC} $warning_count"
  echo -e "${RED}➤ Errors:${NC} $error_count"
  
  # Build status
  if grep -q "BUILD SUCCESSFUL" <<< "$log_content"; then
    echo -e "${GREEN}➤ Build Status: SUCCESSFUL${NC}"
  elif grep -q "BUILD FAILED" <<< "$log_content"; then
    echo -e "${RED}➤ Build Status: FAILED${NC}"
  else
    echo -e "${YELLOW}➤ Build Status: UNKNOWN${NC}"
  fi
}

# Function to suggest next steps
suggest_next_steps() {
  local log_content="$1"
  
  print_section "Suggested Next Steps"
  
  if grep -q "BUILD SUCCESSFUL" <<< "$log_content"; then
    echo -e "${GREEN}✓ The build was successful!${NC}"
    
    # Check if APK was produced
    if grep -q "APK location:" <<< "$log_content"; then
      apk_location=$(grep "APK location:" <<< "$log_content" | sed 's/.*APK location: //')
      echo -e "${GREEN}✓ APK was generated at:${NC} $apk_location"
      echo -e "${YELLOW}➤ Next steps:${NC}"
      echo -e "   1. Install on device: adb install -r $apk_location"
      echo -e "   2. Test the application functionality"
      echo -e "   3. Consider creating a signed release build for distribution"
    fi
  else
    echo -e "${RED}✗ The build failed. Recommended actions:${NC}"
    
    # Generic recommendations
    echo -e "   1. Address the specific errors highlighted in the Error Analysis section"
    echo -e "   2. Check Android SDK and JDK installations"
    echo -e "   3. Verify that all required Android SDK components are installed"
    echo -e "   4. Ensure licenses are accepted using: \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses"
    echo -e "   5. Run the build with verbose logging: ./scripts/enhanced-build-android.sh"
  fi
}

# Main function
main() {
  print_header
  
  # Determine which log file to analyze
  log_file=""
  
  if [ -n "$1" ]; then
    # Use specified log file
    log_file="$1"
    if [ ! -f "$log_file" ]; then
      echo -e "${RED}Error: Specified log file '$log_file' not found.${NC}"
      show_usage
      exit 1
    fi
  else
    # Find the most recent log file in the logs directory
    if [ -d "$LOG_DIR" ]; then
      log_file=$(find "$LOG_DIR" -name "android-build-*.log" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")
      
      if [ -z "$log_file" ]; then
        echo -e "${RED}Error: No Android build log files found in $LOG_DIR directory.${NC}"
        show_usage
        exit 1
      fi
    else
      echo -e "${RED}Error: Logs directory '$LOG_DIR' not found.${NC}"
      show_usage
      exit 1
    fi
  fi
  
  echo -e "${GREEN}Analyzing log file:${NC} $log_file"
  echo -e "${CYAN}$(printf '─%.0s' {1..50})${NC}"
  
  # Read log file content
  log_content=$(cat "$log_file")
  
  # Perform analysis
  print_stats "$log_content"
  analyze_error "$log_content"
  suggest_next_steps "$log_content"
  
  echo -e "\n${GREEN}Analysis complete.${NC}"
  echo -e "${YELLOW}For detailed examination, view the full log file:${NC} $log_file"
}

# Run the main function with parameters
main "$@"

# Make the script executable
chmod +x "$0" 