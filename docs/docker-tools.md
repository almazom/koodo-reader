# Docker Monitoring and Maintenance Tools

This document provides an overview of the Docker monitoring and maintenance tools included in the Koodo Reader project.

## 📊 Tools Overview

The project includes two primary Docker management tools:

1. `docker-monitor.sh` - A read-only monitoring tool for safely analyzing Docker resource usage
2. `docker-maintenance.sh` - A tool for both monitoring and cleaning Docker resources

## 🔍 Docker Monitor Script (`docker-monitor.sh`)

### Purpose
The Docker Monitor script provides a safe, read-only way to analyze Docker resource usage without making any changes to your system. This tool is ideal for regular monitoring and identifying potential space issues.

### Features
- **100% Safe Operation** - Makes no changes to your system or Docker resources
- **Space Savings Dashboard** - Visual overview of potential disk space that could be reclaimed
- **Resource Usage Visualization** - Visual representations of space usage with interactive bar charts
- **Detailed Analysis** - Comprehensive breakdown of Docker resources:
  - System overview with Docker version and configuration
  - Running container status with resource usage
  - Orphaned/stopped container analysis
  - Dangling image identification
  - Unused volume detection
  - Container log file size analysis
  - Network usage statistics
- **Intelligent Recommendations** - Suggests actions based on detected issues

### Usage
```bash
./scripts/docker-monitor.sh
```

## 🧹 Docker Maintenance Script (`docker-maintenance.sh`)

### Purpose
The Docker Maintenance script provides tools for both monitoring and cleaning Docker resources. It includes all the monitoring capabilities of `docker-monitor.sh` plus functionality to reclaim disk space by cleaning up unused Docker resources.

### Features
- **Space Savings Dashboard** - Visual overview of potential disk space savings
- **Smart Cleanup Menu** - Shows potential space savings for each cleanup operation
- **Security-Focused Design** - Includes security level indicators for each operation
- **Confirmation Prompts** - Requires explicit confirmation for potentially destructive operations
- **Cleanup Operations**:
  - Clean Docker system (prune containers, images, networks, volumes)
  - Truncate container logs
  - Set container log size limits
  - Remove specific resources (containers, images, volumes)

### Security Levels
Operations in the maintenance script are categorized by security level:
- ✅ **Safe** - Read-only operations with no risk
- ⚠️ **Caution** - Operations that modify resources but with confirmation
- ❌ **High Risk** - Operations that require careful consideration

### Usage
```bash
./scripts/docker-maintenance.sh
```

## 🔄 When to Use Each Tool

- **Use `docker-monitor.sh` when**:
  - You want to safely analyze Docker resource usage
  - You need to identify potential space issues
  - You're doing routine monitoring
  - You want to avoid any risk of accidental changes

- **Use `docker-maintenance.sh` when**:
  - You need to reclaim disk space
  - You want to clean up orphaned Docker resources
  - You need to manage container logs
  - You're experiencing Docker-related performance issues

## 📋 Best Practices

1. **Regular Monitoring**: Run the monitor script weekly to track resource usage
2. **Scheduled Maintenance**: Perform cleanup operations monthly or when space is needed
3. **Before Cleanup**: Always run the monitor script first to understand what will be removed
4. **Volume Caution**: Be especially careful with volume cleanup as it may contain important data
5. **Custom Logging**: Consider setting log limits rather than truncating logs 