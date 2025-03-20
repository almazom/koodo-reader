# Koodo Reader Android APK Quick Guide

This guide provides quick instructions for generating an Android APK for Koodo Reader using our enhanced build tools.

## 📋 Prerequisites

Before starting, ensure you have:

- Node.js 20.x installed
- JDK 17 installed and properly configured
- Android SDK with Android 31 platform and build-tools 31.0.0 or higher
- ANDROID_HOME environment variable set
- Gradle installed (8.x or higher recommended)

## 🚀 Quick Start

### Step 1: Verify your environment

```bash
./scripts/verify-android-env.sh
```

This will check your development environment and provide recommendations for any missing components.

### Step 2: Build the APK

```bash
./scripts/enhanced-build-android.sh
```

This script will:
1. Verify the environment
2. Install dependencies
3. Build the web app
4. Configure Capacitor
5. Add/sync Android platform
6. Build the APK
7. Copy the APK to the android-build directory

### Step 3: If you encounter any errors

```bash
./scripts/analyze-build-logs.sh
```

This will analyze the build logs and provide specific recommendations for fixing any issues that occurred during the build process.

## 📱 Testing the APK

After a successful build, you can find the APK at:

```
android-build/koodo-reader.apk
```

To install on a connected Android device:

```bash
adb install -r android-build/koodo-reader.apk
```

## 🛠️ Troubleshooting

Common issues and solutions:

1. **License Acceptance Error**  
   Run: `$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses`

2. **Missing Android SDK Components**  
   Run: `$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --install "platforms;android-31" "build-tools;31.0.0"`

3. **JDK Version Issues**  
   Ensure you're using JDK 17 and JAVA_HOME is set correctly

4. **Dependency Conflicts**  
   The build script uses `--legacy-peer-deps` to handle this automatically

5. **Gradle Version Incompatibility**  
   Update Gradle to latest version: `gradle wrapper --gradle-version=8.0.2`

## 📊 Build Dashboard

For a comprehensive view of our Android build strategies and progress, see:

```
docs/android-build-dashboard.md
```

## 📚 Additional Resources

- [Detailed Android APK Generation Strategy](docs/android-apk-generation-plan.md)
- [Android Developer Documentation](https://developer.android.com/docs)
- [Capacitor Documentation](https://capacitorjs.com/docs) 