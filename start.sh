#!/bin/bash

echo "🚀 Starting Koodo Reader using Docker..."

# Stop any existing Koodo Reader container
if docker ps -a | grep -q koodo-reader; then
  echo "🛑 Stopping existing Koodo Reader container..."
  docker stop koodo-reader &>/dev/null
  docker rm koodo-reader &>/dev/null
fi

# Clean up unused Docker resources
echo "🧹 Cleaning up Docker resources..."
docker system prune -f &>/dev/null

# Try to use port 8080, fallback to other ports if unavailable
PORT=8080
if netstat -tuln | grep -q ":$PORT"; then
  PORT=8081
  if netstat -tuln | grep -q ":$PORT"; then
    PORT=8082
  fi
fi

# Start Koodo Reader with explicit port mapping
echo "📚 Starting Koodo Reader container on port $PORT..."
docker run -d --name koodo-reader -p $PORT:80 ghcr.io/koodo-reader/koodo-reader:master

# Get the container ID
CONTAINER_ID=$(docker ps -q --filter "name=koodo-reader")

if [ -n "$CONTAINER_ID" ]; then
  echo "✅ Koodo Reader is now running!"
  echo "📖 Access it at: http://localhost:$PORT"
  echo ""
  echo "To stop the container, run: docker stop koodo-reader"
else
  echo "❌ Failed to start Koodo Reader container."
fi 