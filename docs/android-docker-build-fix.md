# Android Docker Build Fix Plan

## Problem Analysis

The Docker build for Android is failing with the following error:
```
mv: cannot move 'cmdline-tools/latest' to a subdirectory of itself, '/opt/android-sdk/cmdline-tools/latest/latest'
```

This suggests that the Android SDK commandline tools extraction is encountering issues with directory structure. The current implementation is trying to move files into a directory structure that already contains similar paths.

## Root Cause

The Google Android SDK commandline tools zip file has a specific directory structure that needs careful handling:
- The zip contains a top-level `cmdline-tools` directory
- When we extract it to `$ANDROID_HOME`, we get `$ANDROID_HOME/cmdline-tools/`
- When we try to move contents to `$ANDROID_HOME/cmdline-tools/latest/`, we may end up with recursive paths

Additionally:
- The Node.js version in the Dockerfile is outdated (v12) and causes compatibility issues with modern packages

## Action Plan

- [x] Examine the error logs to understand the exact file structure issue
- [x] Modify the Dockerfile.android to properly handle the commandline tools extraction
- [x] Use a temporary directory for extraction and selectively copy only needed files
- [x] Update Node.js version to a more compatible version (16.x)
- [ ] Test the Docker build process
- [ ] Verify APK generation

## Implementation Details

1. Changed the Android SDK installation approach:
   - Use `/tmp/android` for temporary extraction
   - Selectively copy needed files to the correct target directory
   - Properly clean up temporary files

2. Updated Node.js installation:
   - Removed outdated Node.js/NPM packages
   - Added installation from NodeSource repository for Node.js 16.x
   - Updated NPM to latest version

## Next Steps

1. Test the modified Dockerfile with the docker-build-android.sh script
2. If successful, verify the APK is generated correctly
3. If issues persist, analyze error logs and make further adjustments

## Success Criteria

- Docker build completes successfully
- Android APK is generated
- Build artifact is available at the expected location 