# Multi-stage Dockerfile for PostgreSQL with Schema Runner
# Stage 1: Build SchemaRunner
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build-env
WORKDIR /app

# Copy SchemaRunner project files
COPY SchemaRunner/*.csproj ./SchemaRunner/
WORKDIR /app/SchemaRunner
RUN dotnet restore

# Copy source code and build
COPY SchemaRunner/ ./
RUN dotnet publish -c Release -o /app/out

# Stage 2: PostgreSQL with SchemaRunner
FROM postgres:16

# Install .NET Runtime for SchemaRunner
RUN apt-get update && \
    apt-get install -y wget curl && \
    wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-runtime-9.0 && \
    rm -rf /var/lib/apt/lists/* && \
    rm packages-microsoft-prod.deb

# Create app directory and set proper ownership
RUN mkdir -p /app/schemarunner /app/schema && \
    chown -R postgres:postgres /app

# Copy SchemaRunner executable and schema files
COPY --from=build-env /app/out/ /app/schemarunner/
COPY Schema/ /app/schema/

# Set ownership for copied files
RUN chown -R postgres:postgres /app

# Copy startup script for schema deployment
COPY docker-entrypoint.sh /usr/local/bin/schema-runner.sh
RUN chmod +x /usr/local/bin/schema-runner.sh

# Create a custom entrypoint that runs schema deployment after PostgreSQL starts
COPY postgres-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/postgres-entrypoint.sh

# Set environment variables for PostgreSQL
ENV POSTGRES_DB=schemadb
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=YourStrong@Passw0rd

# Expose PostgreSQL port
EXPOSE 5432

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/postgres-entrypoint.sh"]
CMD ["postgres"]