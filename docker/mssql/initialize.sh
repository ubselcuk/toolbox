#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"
. "$(dirname "$0")/../utility.sh"

load_env
require_root

cat <<EOF

    Hello, this script will create a SQL Server container.
    It will take a few minutes for the database to be ready.
    Environment variables are loaded from the .env file.
    Container name: $MSSQL_CONTAINER_NAME
    SA password: $MSSQL_SA_PASSWORD
    The data will be stored in /opt/volumes/$MSSQL_CONTAINER_NAME
    You can change these settings in the .env file.
    Press Ctrl+C to cancel or wait 10 seconds to continue...

EOF

sleep 10
check_docker
remove_container "$MSSQL_CONTAINER_NAME"

info "Creating volume directory for '$MSSQL_CONTAINER_NAME'..."
mkdir -p "/opt/volumes/$MSSQL_CONTAINER_NAME"
info "Volume directory created at /opt/volumes/$MSSQL_CONTAINER_NAME"
info "Setting permissions on /opt/volumes/$MSSQL_CONTAINER_NAME ..."
chown -R 10001:10001 /opt/volumes/$MSSQL_CONTAINER_NAME
info "Permissions set."

info "Creating backup directory for '$MSSQL_CONTAINER_NAME'..."
mkdir -p "/opt/backups/$MSSQL_CONTAINER_NAME"
info "Backup directory created at /opt/backups/$MSSQL_CONTAINER_NAME"
info "Setting permissions on /opt/backups/$MSSQL_CONTAINER_NAME ..."
chown -R 10001:10001 /opt/backups/$MSSQL_CONTAINER_NAME
info "Permissions set."

docker run -d \
  --name "$MSSQL_CONTAINER_NAME" \
  --restart unless-stopped \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD" \
  -e "MSSQL_PID=Express" \
  -e "MSSQL_COLLATION=Turkish_CI_AS" \
  -e "TZ=Europe/Istanbul" \
  -p 1433:1433 \
  -v /opt/volumes/$MSSQL_CONTAINER_NAME:/var/opt/mssql \
  -v /opt/backups/$MSSQL_CONTAINER_NAME:/var/opt/mssql/backups \
  --health-cmd="/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P \"$MSSQL_SA_PASSWORD\" -Q \"SELECT 1\" -l 5 >/dev/null 2>&1 || exit 1" \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=20 \
  --health-start-period=60s \
  --memory=2g \
  --cpus="1.5" \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  mcr.microsoft.com/mssql/server:2022-latest