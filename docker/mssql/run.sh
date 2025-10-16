#!/usr/bin/env bash
set -euo pipefail

# CHECK ROOT
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# IS ARGUMENT PROVIDED
if [[ -z "${1:-}" ]]; then
    echo "No .env file provided!"
    echo "Usage: $0 /path/to/.env"
    exit 1
fi

# IS FILE EXISTS
if [[ ! -f "$1" ]]; then
    echo "Config file '$1' does not exist!"
    exit 1
fi

# LOAD ENV VARIABLES
set -a
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^\s*# ]] && continue
    [[ -z "$line" ]] && continue
    eval "$line"
done < "$1"
set +a

echo "Loaded configuration from $1"

# REQUIRED VARIABLES
REQUIRED_VARS=(
  MSSQL_CONTAINER_NAME
  MSSQL_SA_PASSWORD
  MSSQL_MEMORY_LIMIT_MB
  MSSQL_CPU_LIMIT
  MSSQL_PORT
  MSSQL_PID
  MSSQL_COLLATION
  MSSQL_TIMEZONE
  MSSQL_AGENT_ENABLED
  MSSQL_VOLUME_PATH
  MSSQL_BACKUP_PATH
  MSSQL_NETWORK_NAME
)
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: Required variable '$var' not set in $1"
        exit 1
    fi
done

echo "All required variables are set!"

# IS DOCKER INSTALLED
if ! command -v docker &> /dev/null; then
    echo "Docker command not found. Please install Docker first."
    exit 1
fi

# IS DOCKER RUNNING
if ! docker info &> /dev/null; then
    echo "Docker does not seem to be running. Please start Docker service."
    exit 1
fi

# IS CONTAINER EXISTS
if docker ps -a --format '{{.Names}}' | grep -qw "$MSSQL_CONTAINER_NAME"; then
    echo "Container '$MSSQL_CONTAINER_NAME' already exists."
    exit 1
fi

# CREATE VOLUME DIRECTORY
if [[ ! -d "$MSSQL_VOLUME_PATH" ]]; then
    echo "Creating volume directory at $MSSQL_VOLUME_PATH..."
    mkdir -p "$MSSQL_VOLUME_PATH"
    chown -R 10001:10001 "$MSSQL_VOLUME_PATH"
fi

# CREATE BACKUP DIRECTORY
if [[ ! -d "$MSSQL_BACKUP_PATH" ]]; then
    echo "Creating backup directory at $MSSQL_BACKUP_PATH..."
    mkdir -p "$MSSQL_BACKUP_PATH"
    chown -R 10001:10001 "$MSSQL_BACKUP_PATH"
fi

# CREATE DOCKER NETWORK
if ! docker network inspect "$MSSQL_NETWORK_NAME" >/dev/null 2>&1; then
    echo "Docker network '$MSSQL_NETWORK_NAME' not found. Creating..."
    docker network create "$MSSQL_NETWORK_NAME"
fi

# CHECK IF PORT IS FREE
if ss -tuln | grep -q ":$MSSQL_PORT\b"; then
    echo "Error: Port $MSSQL_PORT is already in use. Please choose another port."
    exit 1
fi

# RUN MSSQL CONTAINER
docker run -d \
  --name "$MSSQL_CONTAINER_NAME" \
  --network "$MSSQL_NETWORK_NAME" \
  --restart unless-stopped \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD" \
  -e "MSSQL_PID=$MSSQL_PID" \
  -e "MSSQL_AGENT_ENABLED=$MSSQL_AGENT_ENABLED" \
  -e "MSSQL_COLLATION=$MSSQL_COLLATION" \
  -e "TZ=$MSSQL_TIMEZONE" \
  -e "MSSQL_TCP_PORT=1433" \
  -p "$MSSQL_PORT":1433 \
  -v "$MSSQL_VOLUME_PATH":/var/opt/mssql \
  -v "$MSSQL_BACKUP_PATH":/var/opt/mssql/backups \
  --health-cmd="/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P \"$MSSQL_SA_PASSWORD\" -Q \"SELECT 1\" -l 5 >/dev/null 2>&1 || exit 1" \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=20 \
  --health-start-period=60s \
  --memory="${MSSQL_MEMORY_LIMIT_MB}m" \
  --cpus="$MSSQL_CPU_LIMIT" \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  mcr.microsoft.com/mssql/server:2022-latest

echo "MSSQL container '$MSSQL_CONTAINER_NAME' started successfully!"

echo "Disable enforce password policy"
docker exec -it "$MSSQL_CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -Q "ALTER LOGIN SA WITH CHECK_POLICY=OFF"