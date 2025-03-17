# Docker Setup for Koodo Reader

This document describes how to use Docker to run Koodo Reader for development purposes.

## Prerequisites

- Docker installed on your system
- Basic understanding of Docker commands

## Quick Start

```bash
./start.sh
```

The script will automatically:
1. Stop any existing Koodo Reader containers
2. Clean up unused Docker resources
3. Start a new container on port 7070 (with fallback ports if needed)
4. Verify the container is responding correctly
5. Display access URLs for both local and remote access

## Port Configuration

The application uses the following port strategy:
1. Default port: 7070
2. Fallback ports (in order): 8080, 8081, 9090

## Container Management

- **Start**: `./start.sh`
- **Stop**: `docker stop koodo-reader`
- **View Logs**: `docker logs koodo-reader`
- **Restart**: `docker restart koodo-reader`

## Troubleshooting

1. **Container not starting**
   - Check if ports are available
   - View logs using `docker logs koodo-reader`
   - Ensure Docker daemon is running

2. **Cannot access application**
   - Verify the container is running: `docker ps | grep koodo-reader`
   - Check the port mapping: `docker port koodo-reader`
   - Test using curl: `curl -I http://localhost:7070`

3. **Performance issues**
   - Check container resources: `docker stats koodo-reader`
   - Verify host system resources: `htop` or `top`

## Best Practices

1. The container is configured to restart automatically on system reboot
2. Regular Docker cleanup is performed automatically
3. Health checks ensure the application is responding correctly
4. Multiple access URLs are provided for flexibility

## Security Notes

1. The container runs on standard HTTP port 80 internally
2. External access is mapped to a different port for security
3. Container has automatic restart policy enabled

## Remote Access

The application will be accessible at:
- Local: `http://localhost:7070`
- Remote: `http://<server-ip>:7070`

Remember to configure your firewall rules if accessing remotely.

## Development Workflow

When working on Koodo Reader with Docker:

1. Use the container for testing your changes
2. For active development, you'll still want to use the local development environment with `yarn start` or `yarn dev`
3. The Docker setup is primarily useful for verifying your changes in a production-like environment

## Additional Resources

- [Koodo Reader GitHub Repository](https://github.com/koodo-reader/koodo-reader)
- [Docker Documentation](https://docs.docker.com/) 