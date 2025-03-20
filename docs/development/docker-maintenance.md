# Docker Maintenance Guide

This document provides guidance on monitoring and maintaining your Docker environment to keep it clean, efficient, and prevent disk space issues.

## Docker Maintenance Tool

We've created a comprehensive Docker maintenance tool that helps you:

- Monitor Docker system resources
- Identify and clean orphaned containers
- Remove dangling images and unused volumes
- Manage Docker log files (view sizes and truncate)
- Configure log rotation to prevent disk space issues

### Running the Tool

```bash
# From the project root
./scripts/docker-maintenance.sh
```

## Common Docker Maintenance Tasks

### 1. Viewing System Information

The tool provides a dashboard showing:
- Docker version
- Container counts (running/stopped/total)
- Image count
- Volume information

### 2. Managing Orphaned Resources

Docker can accumulate "orphaned" resources over time:

- **Stopped containers**: Containers that exited but weren't removed
- **Dangling images**: Images without tags, often left after builds
- **Unused volumes**: Volumes not attached to any container

Our tool helps you identify and clean these resources safely.

### 3. Managing Docker Logs

Docker container logs can consume significant disk space, especially in production environments. Our tool allows you to:

- View log file sizes for all containers
- Truncate log files to reclaim disk space
- Configure log rotation limits to prevent future issues

## Best Practices

1. **Regular Maintenance**: Schedule regular maintenance (weekly/monthly) to prevent resource buildup
2. **Log Rotation**: Always configure log rotation for production environments
3. **Prune Carefully**: Be cautious when pruning volumes as they may contain important data
4. **Automate**: Consider automating maintenance tasks for production systems

## Commands for Manual Maintenance

If you prefer to run commands manually rather than using our tool, here are some helpful Docker commands:

```bash
# Remove all stopped containers
docker container prune

# Remove dangling images
docker image prune

# Remove all unused images (not just dangling)
docker image prune -a

# Remove unused volumes
docker volume prune

# Clean everything at once (containers, networks, images)
docker system prune

# Include volumes in system prune (BE CAREFUL!)
docker system prune --volumes

# View disk usage
docker system df
```

## Log Management

### Viewing Log Sizes

To check the size of Docker logs manually:

```bash
sudo find /var/lib/docker/containers -name "*.log" -exec ls -sh {} \;
```

### Setting Up Log Rotation

Create or edit `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker after making changes:

```bash
sudo systemctl restart docker
```

## Automated Maintenance

For production environments, we've created an automated maintenance script that can be scheduled with cron:

```bash
# From the project root
./scripts/docker-cron-cleanup.sh
```

This script performs safe automated cleanup:
- Removes stopped containers
- Cleans dangling images
- Prunes build cache
- Removes unused networks
- Identifies but doesn't remove dangling volumes (for safety)
- Truncates large container logs (>100MB)
- Provides detailed before/after statistics

### Setting Up Scheduled Maintenance

To set up weekly automated maintenance:

1. Edit your crontab:
   ```bash
   crontab -e
   ```

2. Add the following line to run weekly at 2:00 AM on Sunday:
   ```
   0 2 * * 0 /path/to/koodo-reader/scripts/docker-cron-cleanup.sh > /path/to/docker-cleanup.log 2>&1
   ```

3. Check that your cron job has been added:
   ```bash
   crontab -l
   ```

The script will generate a detailed log file with timestamps, making it easy to review what was cleaned up during each automated run.

## Docker Compose Best Practices

We've created a Docker Compose checker tool to help ensure your compose files follow best practices:

```bash
# Check the default docker-compose.yml
./scripts/docker-compose-check.sh

# Or specify a different compose file
./scripts/docker-compose-check.sh path/to/other-compose.yml
```

The checker analyzes your Docker Compose files for common issues and provides recommendations for:

- Container naming and scaling
- Restart policies
- Volume configuration
- Environment variable management  
- Resource constraints
- Health checks
- Network configuration
- Logging limits
- Compose file version

This tool is particularly helpful when preparing a Docker Compose file for production use.

### Common Best Practices

When creating or updating Docker Compose files:

1. **Use restart policies** - Add `restart: unless-stopped` for production services
2. **Configure resource limits** - Prevent container resource abuse with memory and CPU limits
3. **Implement health checks** - Detect and recover from service failures
4. **Set logging limits** - Prevent log files from consuming all disk space
5. **Use named volumes** - Better for data persistence and backup
6. **Centralize environment variables** - Use `.env` files or environment variable files
7. **Define custom networks** - Better security through isolation

## Improved Docker Compose Template

Based on the best practices, we've created an improved Docker Compose template you can use as a starting point for production deployments:

```yaml
version: '3.8'

services:
  koodo:
    build: .
    # Container name removed to support scaling
    ports:
      - "${KOODO_PORT:-7070}:80"
    restart: unless-stopped
    # Added resource constraints
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    # Added health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
    # Added logging configuration
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    # Added volumes for data persistence
    volumes:
      - koodo_data:/app/data
    # Using env file for environment variables
    env_file:
      - .env.docker
    # Added networks
    networks:
      - koodo_network

# Define named volumes
volumes:
  koodo_data:
    driver: local

# Define custom networks
networks:
  koodo_network:
    driver: bridge
```

This template includes:
- Environment variable management with `.env.docker`
- Memory and CPU limits to prevent resource abuse
- Health checks for improved stability
- Log rotation to prevent disk space issues
- Named volumes for data persistence
- Custom network for better isolation

You can find this template in the project root as `docker-compose.improved.yml`.

## Troubleshooting

### Common Issues

1. **Disk Space Warnings**: If you receive disk space warnings, check container logs first as they are often the culprit
2. **Permission Denied**: Log management often requires sudo privileges
3. **Cannot Remove Running Container**: Stop the container first before removal

### Emergency Cleanup

If you need to quickly reclaim disk space:

```bash
# One-line command to truncate all container logs (use with caution)
sudo find /var/lib/docker/containers -name "*.log" -exec truncate -s 0 {} \;
```

## Further Resources

- [Docker Documentation - Prune unused objects](https://docs.docker.com/config/pruning/)
- [Docker Documentation - Configure logging drivers](https://docs.docker.com/config/containers/logging/configure/)

## TODO

- Implement automated scheduled maintenance
- Add monitoring integration
- Consider advanced log aggregation solutions for production 