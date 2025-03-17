# Docker Setup for Koodo Reader Development

This document describes how to use Docker to run Koodo Reader for development purposes.

## Prerequisites

- Docker installed on your system
- Basic understanding of Docker commands

## Quick Start

We've created a convenience script that handles the entire Docker setup process for you. To use it:

```bash
# From the project root directory
./start.sh
```

This script will:
1. Stop any existing Koodo Reader container
2. Clean up unused Docker resources
3. Start a new Koodo Reader container with host networking
4. Provide you with the URL to access the application

## Manual Setup

If you prefer to run the commands manually:

```bash
# Stop and remove any existing container
docker stop koodo-reader
docker rm koodo-reader

# Optionally clean up Docker resources
docker system prune -f

# Start a new container
docker run -d --name koodo-reader --network host ghcr.io/koodo-reader/koodo-reader:master
```

## Access the Application

Once the container is running, you can access Koodo Reader in your browser at:

```
http://localhost
```

The actual port may vary based on your system configuration. If port 80 is unavailable, Caddy (the web server used by the Docker image) will automatically choose an available port.

## Troubleshooting

### Port Conflicts

If you see errors related to port binding, it could mean port 80 is already in use on your system. The `--network host` flag allows the container to use the host's network stack, which helps resolve many port-related issues.

### Container Not Starting

If the container doesn't start, check the logs:

```bash
docker logs koodo-reader
```

### Application Not Accessible

If you can't access the application in your browser, try:

1. Verifying the container is running with `docker ps | grep koodo`
2. Checking which port is being used with `docker logs koodo-reader`
3. Testing connectivity with `curl -I http://localhost`

## Development Workflow

When working on Koodo Reader with Docker:

1. Use the container for testing your changes
2. For active development, you'll still want to use the local development environment with `yarn start` or `yarn dev`
3. The Docker setup is primarily useful for verifying your changes in a production-like environment

## Additional Resources

- [Koodo Reader GitHub Repository](https://github.com/koodo-reader/koodo-reader)
- [Docker Documentation](https://docs.docker.com/) 