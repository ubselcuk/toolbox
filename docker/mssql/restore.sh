#!/usr/bin/env bash
set -euo pipefail

# --- CHECK ROOT ---
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# --- CHECK ARGUMENTS ---
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 /path/to/.env <DatabaseName> <BackupFilePath>"
    echo "Example: $0 toolbox/docker/mssql/use.env MyAppDb /opt/volumes/my_mssql/backups/MyAppDb_Full_20251016_1030.bak"
    exit 1
fi

ENV_FILE="$1"
DB_NAME="$2"
BACKUP_FILE="$3"

# --- CHECK ENV FILE ---
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Config file '$ENV_FILE' not found!"
    exit 1
fi

# --- LOAD ENV VARIABLES ---
set -a
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^\s*# ]] && continue
    [[ -z "$line" ]] && continue
    eval "$line"
done < "$ENV_FILE"
set +a

echo "Loaded configuration from $ENV_FILE"

# --- REQUIRED VARIABLES ---
REQUIRED_VARS=(
  MSSQL_CONTAINER_NAME
  MSSQL_SA_PASSWORD
  MSSQL_BACKUP_PATH
)
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: Required variable '$var' not set in $ENV_FILE"
        exit 1
    fi
done

# --- CHECK DOCKER ---
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Docker daemon not running."
    exit 1
fi

# --- CHECK CONTAINER RUNNING ---
if ! docker ps --format '{{.Names}}' | grep -qw "$MSSQL_CONTAINER_NAME"; then
    echo "Error: Container '$MSSQL_CONTAINER_NAME' is not running!"
    exit 1
fi

# --- CHECK BACKUP FILE EXISTS ---
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: Backup file '$BACKUP_FILE' not found on host!"
    exit 1
fi

# --- COPY BACKUP FILE TO CONTAINER ---
mv $BACKUP_FILE "$MSSQL_BACKUP_PATH/"

# --- MAP HOST BACKUP PATH TO CONTAINER ---
CONTAINER_BACKUP_PATH="/var/opt/mssql/backups/$(basename "$BACKUP_FILE")"

echo "Restoring database '$DB_NAME' from backup file:"
echo "  Host path: $BACKUP_FILE"
echo "  Container path: $CONTAINER_BACKUP_PATH"

# --- GET LOGICAL FILE NAMES ---
echo "Fetching logical file names from backup..."
FILELIST=$(docker exec "$MSSQL_CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
    -C -l 0 -S localhost -U SA -P "$MSSQL_SA_PASSWORD" \
    -Q "RESTORE FILELISTONLY FROM DISK = N'$CONTAINER_BACKUP_PATH'" -W -w 2048 -s"|" | grep -v '^-' | grep -v '^$' | awk -F'|' 'NR==2{print $1,$2;next} NR==3{print $1,$2}')

LOGICAL_DATA_NAME=$(echo "$FILELIST" | head -n 1 | awk '{print $1}')
LOGICAL_LOG_NAME=$(echo "$FILELIST" | tail -n 1 | awk '{print $1}')

if [[ -z "$LOGICAL_DATA_NAME" || -z "$LOGICAL_LOG_NAME" ]]; then
    echo "Error: Could not determine logical file names from backup."
    exit 1
fi

echo "Logical names detected:"
echo "  Data file: $LOGICAL_DATA_NAME"
echo "  Log file : $LOGICAL_LOG_NAME"

docker exec -i "$MSSQL_CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
  -C -S localhost -U SA -P "$MSSQL_SA_PASSWORD" \
  -Q "RESTORE DATABASE [$DB_NAME] 
          FROM DISK = N'$CONTAINER_BACKUP_PATH'
          WITH MOVE N'$LOGICAL_DATA_NAME' TO N'/var/opt/mssql/data/$DB_NAME.mdf',
               MOVE N'$LOGICAL_LOG_NAME' TO N'/var/opt/mssql/data/${DB_NAME}_log.ldf',
               REPLACE, RECOVERY, STATS = 10"

echo "✔ Database '$DB_NAME' restored successfully!"