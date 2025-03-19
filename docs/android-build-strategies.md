# Android Build Strategies for Koodo Reader

## Strategy 1: Using Capacitor with existing SDK tools
- **Goal**: Build Android APK using Capacitor and the script `scripts/build-android.sh`
- **Approach**:
  1. Fixed Java version issues in Gradle files:
     - Changed `VERSION_21` to `VERSION_17` in `android/app/capacitor.build.gradle`
     - Changed `VERSION_21` to `VERSION_17` in `android/capacitor-cordova-android-plugins/build.gradle`
  2. Updated SDK versions in `android/variables.gradle` to match installed versions (31)
  3. Updated `android/local.properties` to point to the correct SDK path: `/home/almaz/android-sdk`
  4. Attempted to build with `./gradlew assembleDebug` from the android directory
- **Result**: Build failed with license acceptance issues for build-tools 30.0.3

## Strategy 2: Alternative Approach - Using cordova-android
- **Goal**: Build Android APK using Cordova instead of Capacitor
- **Approach**:
  1. Install Cordova globally
  2. Create a Cordova project and copy the web app
  3. Configure Cordova project for Android
  4. Build with Cordova
- **Pending Implementation**

## Strategy 3: Using Android Studio
- **Goal**: Build Android APK using Android Studio IDE
- **Approach**: 
  1. Open the project in Android Studio
  2. Let Android Studio handle SDK installations and license agreements
  3. Build through the IDE
- **Pending Implementation**

## Strategy 4: Docker-based build
- **Goal**: Use a Docker container with all Android SDK components pre-installed
- **Approach**:
  1. Created a Dockerfile (Dockerfile.android) with:
     - Debian Bullseye Slim base image (for apt-get support)
     - Java 17 JDK installation via apt
     - Android SDK and build tools installation
     - License acceptance
     - Automated build process
  2. Created a build script (scripts/docker-build-android.sh) to:
     - Check for Docker installation and running service
     - Build the Docker image
     - Run a container that builds the APK
     - Output the APK to ./android-build directory
  3. Made the script executable with `chmod +x scripts/docker-build-android.sh`
- **Implementation**:
  - The Dockerfile handles all SDK installations and license acceptance
  - The container builds the web app and then the Android APK
  - A volume mount is used to extract the built APK back to the host
  - This approach avoids SDK installation and license issues on the host machine
- **Advantages**:
  - Consistent build environment across different systems
  - No need to install Android SDK on the host
  - Automated license acceptance
  - Can be integrated into CI/CD pipelines
- **Status**: Fixed base image issue, ready to retry build 