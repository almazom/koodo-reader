# Android Build Strategies for Koodo Reader

## Overview
This document outlines different approaches we've attempted for building an Android APK version of Koodo Reader. We've documented each strategy along with the challenges faced and lessons learned.

## Strategy 1: Capacitor Framework (Current Approach)

### Description
We're using Capacitor, which is designed to build native iOS and Android apps with web technologies. The workflow involves:
1. Building the web app
2. Adding the Android platform
3. Syncing web assets to the Android project
4. Building the APK with Gradle

### Implementation Steps

1. **Environment Setup**
   - Installed JDK 17 for Android Gradle plugin compatibility
   - Set up Android SDK (API level 31)
   - Created build scripts in `scripts/build-android.sh`

2. **Project Configuration**
   - Created `capacitor.config.ts` with Android-specific settings
   - Added Java version configuration: `sourceCompatibility: '17', targetCompatibility: '17'`
   - Updated Gradle configurations for SDK compatibility

3. **Build Process Modifications**
   - Fixed Java version references in Gradle files:
     - `android/app/capacitor.build.gradle`
     - `android/capacitor-cordova-android-plugins/build.gradle`
   - Updated SDK paths in `local.properties`
   - Modified SDK version targets to match available components

### Challenges

1. **Java Version Conflicts**
   - Original project was configured for Java 21, but environment had Java 17
   - Required updating multiple Gradle files manually
   - Needed to handle auto-generated Gradle files that get overwritten

2. **SDK Licensing Issues**
   - Android SDK licensing acceptance is required
   - Build tools version conflicts between what's required and what's installed
   - Difficulty in finding correct command-line tools for license acceptance

3. **Build Process Failures**
   - Memory issues during web app building phase
   - Inconsistent error messages from Gradle
   - Multiple conflicting environment variables

### Current Status
- Successfully configured Java version across all required files
- Successfully pointed Gradle to the correct SDK path
- Still encountering SDK licensing and build tools version issues
- The build process runs properly but fails at final APK compilation

### Lessons Learned
- Capacitor configuration is sensitive to Java versions
- Local environment needs to match exactly with project requirements
- Auto-generated files present a challenge for maintaining configurations

## Strategy 2: Android Studio Project (Planned)

### Description
This approach would involve creating a native Android application using Android Studio and integrating the web app as a WebView component.

### Planned Implementation
1. Create a new Android Studio project
2. Set up a WebView to load the built web app assets
3. Configure proper permissions and settings
4. Build directly through Android Studio

### Potential Benefits
- More direct control over Android configuration
- Native debugging tools available
- Easier to manage SDK versions and licensing

### Preparation Steps
- Build the web app with production settings
- Research WebView best practices for offline reading apps
- Understand how to bundle web assets in an Android project

## Strategy 3: React Native Migration (Alternative)

### Description
Instead of webview-based approach, migrate the core functionality to React Native for a fully native mobile experience.

### Considerations
- Significant refactoring would be required
- May provide better performance and user experience
- Would require maintaining two separate codebases (web/desktop and mobile)

### Research Needed
- Evaluate React Native libraries for ePub handling
- Assess feasibility of reusing existing business logic
- Determine timeline and resource requirements

## Alternative Approaches

### Pre-configured Docker Container
Using a Docker container with all required Android SDK components pre-installed could bypass environment setup issues.

### Commercial Build Services
Services like PhoneGap Build, Ionic Appflow, or Visual Studio App Center could handle the build process while we focus on the app logic.

### Progressive Web App (PWA)
Focusing on PWA capabilities rather than native packaging could be a faster approach to mobile support.

## Recommended Path Forward

Based on current progress and challenges, we recommend:

1. Complete one more focused attempt with Capacitor by:
   - Using a Docker container with Android SDK pre-configured
   - Simplifying the web build to avoid memory issues
   - Isolating the build environment from other system components

2. If Capacitor approach continues to present challenges:
   - Pivot to the Android Studio approach
   - Focus on a minimal viable product (MVP) with core reading features

3. Document all attempts thoroughly to avoid repeating unsuccessful approaches

## References
- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Android WebView Guide](https://developer.android.com/guide/webapps/webview)
- [React Native Documentation](https://reactnative.dev/docs/getting-started) 