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

# Start Koodo Reader with host networking
echo "📚 Starting Koodo Reader container..."
docker run -d --name koodo-reader --network host ghcr.io/koodo-reader/koodo-reader:master

# Get the container ID
CONTAINER_ID=$(docker ps -q --filter "name=koodo-reader")

if [ -n "$CONTAINER_ID" ]; then
  # Find the port Koodo is running on
  PORT=$(docker logs $CONTAINER_ID 2>&1 | grep -o "listening on :.*" | sed 's/listening on ://')
  
  if [ -z "$PORT" ]; then
    # If port not found in logs, use default port 80
    PORT=80
  fi
  
  echo "✅ Koodo Reader is now running!"
  echo "📖 Access it at: http://localhost:$PORT"
  echo ""
  echo "To stop the container, run: docker stop koodo-reader"
else
  echo "❌ Failed to start Koodo Reader container."
fi 