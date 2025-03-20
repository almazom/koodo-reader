# Koodo Reader Development Scripts

This directory contains a collection of development scripts for Koodo Reader that simplify common development tasks and provide a consistent experience across different environments.

## Available Scripts

### `koodo.sh` - Main Development Interface

The main script that provides an interactive menu and command-line interface for all development operations.

**Usage:**
```bash
# Interactive menu
./scripts/koodo.sh

# Direct commands
./scripts/koodo.sh web     # Start web-only development
./scripts/koodo.sh docker  # Start Docker container
./scripts/koodo.sh rebuild # Rebuild Docker with preserved volumes
./scripts/koodo.sh android # Build Android APK
./scripts/koodo.sh update  # Update dependencies
./scripts/koodo.sh help    # Show help message
```

> For convenience, the `./koodo` symbolic link in the project root points to this script.

### `dev-web.sh` - Web-Only Development

This script starts the React development server without Electron, suitable for headless servers or environments without X11.

**Usage:**
```bash
./scripts/dev-web.sh
```

**Features:**
- Port conflict detection and resolution
- Automatic dependency installation
- IP address detection for remote access
- Avoids X server errors from Electron

### `docker-build.sh` - Docker Container Management

This script rebuilds Docker containers while preserving volumes, ensuring data persistence.

**Usage:**
```bash
./scripts/docker-build.sh
```

**Features:**
- Volume backup before rebuilding
- Clean image rebuilding
- Automatic container restart
- IP detection for remote access

### `build-android.sh` - Android APK Builder

This script builds an Android APK for Koodo Reader using Capacitor.

**Usage:**
```bash
./scripts/build-android.sh
```

**Features:**
- Automatic Capacitor installation
- Environment validation (Java, Android SDK)
- Capacitor configuration generation
- Build summary and confirmation
- APK size calculation
- Next steps guidance

### `docker-maintenance.sh` - Docker System Maintenance

Interactive tool for monitoring and cleaning Docker resources.

**Usage:**
```bash
./scripts/docker-maintenance.sh
```

**Features:**
- System information dashboard
- Orphaned container detection and cleanup
- Dangling image identification and removal
- Volume management
- Docker log size monitoring and truncation
- Log rotation configuration
- Colorful interactive menu interface

### `docker-cron-cleanup.sh` - Automated Docker Cleanup

Script designed for cron-based automated Docker maintenance.

**Usage:**
```bash
# Run manually
./scripts/docker-cron-cleanup.sh

# Or add to crontab (weekly at 2:00 AM on Sunday)
0 2 * * 0 /path/to/koodo-reader/scripts/docker-cron-cleanup.sh > /path/to/docker-cleanup.log 2>&1
```

**Features:**
- Safe automated cleanup (containers, images, networks)
- Detailed before/after statistics
- Large log file detection and truncation
- Timestamp logging for audit trails
- Non-interactive design for cron usage

### `docker-compose-check.sh` - Docker Compose Best Practices Checker

Tool to analyze Docker Compose files for best practices and issues.

**Usage:**
```bash
# Check default docker-compose.yml
./scripts/docker-compose-check.sh

# Check specific file
./scripts/docker-compose-check.sh path/to/compose-file.yml
```

**Features:**
- Compose file validation
- Best practices analysis
- Production readiness checks
- Volume and network configuration analysis
- Resource constraint detection
- Logging configuration verification
- Detailed recommendations for improvements

## Requirements

Different scripts have different requirements:

- **Web Development**: Node.js, npm
- **Docker Development**: Docker, Docker Compose
- **Android Development**: Node.js, JDK, Android SDK

## Common Issues

### X Server Errors

If you see errors like `Missing X server or $DISPLAY`, use the web-only development mode with `dev-web.sh` or `koodo.sh web`.

### Port Conflicts

If port 3000 is already in use, you'll see a message with instructions on how to free up the port.

### Android Build Issues

If Android builds fail, check:
- Java installation: `java -version`
- Android SDK installation
- Environment variables: `ANDROID_HOME` or `ANDROID_SDK_ROOT`

## Organization

These scripts follow these design principles:
- **Single Responsibility**: Each script focuses on a specific task
- **User-Friendly**: Clear, colorful output and helpful error messages
- **Modular**: Scripts can be used independently or together
- **Robust**: Error checking and graceful failure
- **Cross-Platform**: Works on both local development and remote servers 