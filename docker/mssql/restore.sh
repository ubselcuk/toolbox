#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"
load_env

info "This script is intended to restore a MSSQL database from a .bak file."
info "Make sure you have placed the .bak file in the /opt/backups/$MSSQL_CONTAINER_NAME directory."
info "You can change these settings in the .env file."

read -rp "Enter the name of the .bak file (including .bak extension): " BAK_FILE
BAK_PATH="/opt/backups/$MSSQL_CONTAINER_NAME/$BAK_FILE"

if [[ ! -f "$BAK_PATH" ]]; then
    error "The specified backup file does not exist: $BAK_PATH"
    exit 1
fi

info "Starting the restore process for database '$MSSQL_DB_NAME' from file '$BAK_PATH'..."

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -qw "$MSSQL_CONTAINER_NAME"; then
    error "Container '$MSSQL_CONTAINER_NAME' is not running."
    exit 1
fi

info "Container '$MSSQL_CONTAINER_NAME' is running."

# Run restore command
info "Executing restore command using mssql-tools container..."
if ! docker run --rm \
  --network container:"$MSSQL_CONTAINER_NAME" \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -b \
  -Q "RESTORE DATABASE [$MSSQL_DB_NAME] 
      FROM DISK = N'/var/opt/mssql/backups/${BAK_FILE}' 
      WITH REPLACE, STATS = 10"; then
  error "ERROR: Failed to perform MSSQL restore."
  exit 1
fi