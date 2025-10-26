#!/bin/bash
set -e

# Start the schema runner in the background after PostgreSQL is ready
run_schema_deployment() {
    echo "Waiting for PostgreSQL to be ready for schema deployment..."
    
    # Wait for PostgreSQL to accept connections
    until pg_isready -h localhost -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB" &>/dev/null; do
        echo "PostgreSQL is not ready yet, waiting..."
        sleep 2
    done
    
    echo "PostgreSQL is ready, starting schema deployment..."
    sleep 5  # Give it a bit more time to be fully ready
    
    # Run the schema deployment
    /usr/local/bin/schema-runner.sh
}

# Start schema deployment in background
run_schema_deployment &

# Call the original PostgreSQL entrypoint
exec docker-entrypoint.sh "$@"