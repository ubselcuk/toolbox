#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"

load_env
require_root

BACKUP_DIR="/opt/backups/$MSSQL_CONTAINER_NAME"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
BACKUP_FILE="${MSSQL_CONTAINER_NAME}_${TIMESTAMP}.bak"

info "Starting MSSQL single-database backup process..."

# Ensure the backup directory exists (host bind mount)
mkdir -p "$BACKUP_DIR" || { error "Failed to create backup directory at $BACKUP_DIR"; exit 1; }
info "Backup directory is ready: $BACKUP_DIR"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -qw "$MSSQL_CONTAINER_NAME"; then
    error "Container '$MSSQL_CONTAINER_NAME' is not running."
    exit 1
fi
info "Container '$MSSQL_CONTAINER_NAME' is running."

# Run backup for a single DB (from .env: MSSQL_DB_NAME)
info "Executing backup command using mssql-tools container..."

if ! docker run --rm \
  --network container:"$MSSQL_CONTAINER_NAME" \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -b \
  -Q "BACKUP DATABASE [$MSSQL_DB_NAME] 
      TO DISK = N'/var/opt/mssql/backups/${BACKUP_FILE}' 
      WITH INIT, NAME = 'Full Backup', STATS = 10"; then
  error "ERROR: Failed to perform MSSQL backup."
  exit 1
fi
info "Backup command executed successfully."

# Verify backup file on host
HOST_FILE="$BACKUP_DIR/$BACKUP_FILE"
if [[ -f "$HOST_FILE" ]]; then
    info "Backup file available on host: $HOST_FILE"
else
    error "Backup file was not found on host: $HOST_FILE"
    exit 1
fi
