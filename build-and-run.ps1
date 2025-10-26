# Build and test script for SQL Server with Schema Runner
Write-Host "=== Building PostgreSQL with Schema Runner ===" -ForegroundColor Green

# Clean up any existing containers
Write-Host "Cleaning up existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null
docker rmi postgresql-schema 2>$null

# Build the image
Write-Host "Building Docker image..." -ForegroundColor Yellow
if (docker-compose build) {
    Write-Host "✓ Docker image built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Docker build failed" -ForegroundColor Red
    exit 1
}

# Start the container
Write-Host "Starting container..." -ForegroundColor Yellow
if (docker-compose up -d) {
    Write-Host "✓ Container started successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Container failed to start" -ForegroundColor Red
    exit 1
}

# Wait and check health
Write-Host "Waiting for SQL Server to be ready..." -ForegroundColor Yellow
Start-Sleep 30

# Check if container is running
$containerStatus = docker-compose ps
if ($containerStatus -match "Up") {
    Write-Host "✓ Container is running" -ForegroundColor Green
    
    # Show logs
    Write-Host ""
    Write-Host "=== Container Logs ===" -ForegroundColor Cyan
    docker-compose logs --tail=20
    
    Write-Host ""
    Write-Host "=== Connection Information ===" -ForegroundColor Cyan
    Write-Host "Host: localhost" -ForegroundColor White
    Write-Host "Port: 5432" -ForegroundColor White
    Write-Host "Database: schemadb" -ForegroundColor White
    Write-Host "Username: postgres" -ForegroundColor White
    Write-Host "Password: YourStrong@Passw0rd" -ForegroundColor White
    Write-Host "Connection String: Host=localhost;Port=5432;Database=schemadb;Username=postgres;Password=YourStrong@Passw0rd;" -ForegroundColor White
    
    Write-Host ""
    Write-Host "=== Management Commands ===" -ForegroundColor Cyan
    Write-Host "View logs: docker-compose logs -f" -ForegroundColor Gray
    Write-Host "Stop container: docker-compose down" -ForegroundColor Gray
    Write-Host "Restart: docker-compose restart" -ForegroundColor Gray
    
} else {
    Write-Host "✗ Container is not running properly" -ForegroundColor Red
    Write-Host "Showing logs:" -ForegroundColor Yellow
    docker-compose logs
    exit 1
}