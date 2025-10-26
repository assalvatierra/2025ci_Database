#!/bin/bash
set -e

echo "Starting schema deployment..."

# Run SchemaRunner to execute SQL scripts
echo "Running schema scripts using SchemaRunner..."
cd /app

# Run SchemaRunner with retry logic
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $(($RETRY_COUNT + 1)) of $MAX_RETRIES"
    
    if dotnet schemarunner/SchemaRunner.dll --execute --server localhost --database "$POSTGRES_DB" --username "$POSTGRES_USER" --password "$POSTGRES_PASSWORD"; then
        echo "Schema scripts executed successfully!"
        break
    else
        echo "Schema execution failed. Retrying in 10 seconds..."
        RETRY_COUNT=$(($RETRY_COUNT + 1))
        sleep 10
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Failed to execute schema scripts after $MAX_RETRIES attempts"
    exit 1
fi

echo "Schema deployment completed. PostgreSQL is ready for connections."
echo "Database: $POSTGRES_DB"
echo "Connection: Host=localhost;Database=$POSTGRES_DB;Username=$POSTGRES_USER;Password=$POSTGRES_PASSWORD;"