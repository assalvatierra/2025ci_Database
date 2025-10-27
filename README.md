# 2025ci_Database

![Docker Build & Push](https://github.com/assalvatierra/2025ci_Database/actions/workflows/docker-build-push.yml/badge.svg)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-postgresql--schema--runner-blue)](https://github.com/assalvatierra/2025ci_Database/pkgs/container/2025ci_database%2Fpostgresql-schema-runner)

| Folder          | Purpose                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| **Diagrams/**   | Holds all Model Diagrams                                                                                     |
| **schema/**     | Holds all Data Definition Language (DDL) files — tables, views, stored procedures, etc.                      |
| **migrations/** | Contains versioned scripts that track incremental schema changes (used with tools like Flyway or Liquibase). |
| **scripts/**    | General-purpose SQL files for admin, analysis, or maintenance.                                               |
| **seeds/**      | Inserts sample or initial data for testing or bootstrapping environments.                                    |
| **tests/**      | Optional SQL scripts to verify schema integrity or stored procedure logic.                                   |
| **config/**     | Configuration files for connecting to databases or defining environment variables.                           |
| **SchemaRunner**| Console App SQL Script runner                                                                                |



**SchemaRunner Usage**

# Just list files and see which ones have run
dotnet run

# Execute all pending scripts against a database
dotnet run -- --execute --server localhost --database YourDB

# Use SQL Server authentication
dotnet run -- -e -s myserver -d mydb -u myuser -p mypass

---

## Docker Setup - PostgreSQL with Schema Runner

This Docker setup builds and runs a PostgreSQL instance with automatic schema deployment using the SchemaRunner .NET application.

### Features

- **Multi-stage build**: Builds SchemaRunner in first stage, runs PostgreSQL in second stage
- **Automatic schema deployment**: Runs all SQL scripts from the Schema folder on startup
- **Script tracking**: Uses sysdbscriptlog table to track executed scripts
- **Retry logic**: Attempts schema deployment multiple times if needed
- **Health checks**: Monitors PostgreSQL readiness

### Quick Start

**Option 1: Docker Compose (Recommended)**
```bash
# Build and start the container
docker-compose up --build

# Run in background
docker-compose up --build -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

**Option 2: Use Pre-built Image from GitHub Container Registry**
```bash
# Pull and run the latest image (recommended)
docker run -p 5432:5432 \
  -e POSTGRES_DB=schemadb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=YourStrong@Passw0rd \
  ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner-simple:latest

# Alternative: Full multi-stage image (if available)
docker run -p 5432:5432 \
  -e POSTGRES_DB=schemadb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=YourStrong@Passw0rd \
  ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:latest
```

**Option 3: Docker Build & Run (Local Development)**
```bash
# Build the image locally
docker build -t postgresql-schema .

# Run the container
docker run -p 5432:5432 \
  -e POSTGRES_DB=schemadb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=YourStrong@Passw0rd \
  postgresql-schema
```
docker run -p 5432:5432 -e POSTGRES_DB=schemadb -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=YourStrong@Passw0rd postgresql-schema

### Connection Details

Once running, connect to PostgreSQL using:
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `schemadb`
- **Username**: `postgres`
- **Password**: `YourStrong@Passw0rd`
- **Connection String**: `Host=localhost;Port=5432;Database=schemadb;Username=postgres;Password=YourStrong@Passw0rd;`

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PASSWORD` | `YourStrong@Passw0rd` | PostgreSQL user password |
| `POSTGRES_DB` | `schemadb` | Target database name |
| `POSTGRES_USER` | `postgres` | PostgreSQL username |