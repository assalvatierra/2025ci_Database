#!/bin/bash
# Build and test script for SQL Server with Schema Runner

echo "=== Building PostgreSQL with Schema Runner ==="

# Clean up any existing containers
echo "Cleaning up existing containers..."
docker-compose down 2>/dev/null || true
docker rmi postgresql-schema 2>/dev/null || true

# Build the image
echo "Building Docker image..."
if docker-compose build; then
    echo "✓ Docker image built successfully"
else
    echo "✗ Docker build failed"
    exit 1
fi

# Start the container
echo "Starting container..."
if docker-compose up -d; then
    echo "✓ Container started successfully"
else
    echo "✗ Container failed to start"
    exit 1
fi

# Wait and check health
echo "Waiting for SQL Server to be ready..."
sleep 30

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    echo "✓ Container is running"
    
    # Show logs
    echo ""
    echo "=== Container Logs ==="
    docker-compose logs --tail=20
    
    echo ""
    echo "=== Connection Information ==="
    echo "Host: localhost"
    echo "Port: 5432"
    echo "Database: schemadb"
    echo "Username: postgres"
    echo "Password: YourStrong@Passw0rd"
    echo "Connection String: Host=localhost;Port=5432;Database=schemadb;Username=postgres;Password=YourStrong@Passw0rd;"
    
    echo ""
    echo "=== Management Commands ==="
    echo "View logs: docker-compose logs -f"
    echo "Stop container: docker-compose down"
    echo "Restart: docker-compose restart"
    
else
    echo "✗ Container is not running properly"
    echo "Showing logs:"
    docker-compose logs
    exit 1
fi