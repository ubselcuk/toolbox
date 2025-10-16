#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"

# MSSQL_SA_PASSWORD=YourStrong!Passw0rd
# MSSQL_CONTAINER_NAME=toolbox-mssql
# MSSQL_DB_NAME=name
# ZIP_PASSWORD=123456
# SMTP_SERVER="smtp.example.com"
# SMTP_PORT=465
# SMTP_USER="example@example.com"
# SMTP_PASS="yourpassword"
# SMTP_FROM="title <example@example.com>" 
# SMTP_TO=example@example.com

load_env
require_root

BACKUP_DIR="/opt/backups/$MSSQL_CONTAINER_NAME"
TIMESTAMP=$(date +'%Y%m%d_%H%M')
BACKUP_FILE="${MSSQL_CONTAINER_NAME}_${MSSQL_DB_NAME}_${TIMESTAMP}.bak"
ZIP_FILE="${BACKUP_FILE%.*}.zip"

info "Starting MSSQL single-database backup process..."

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR" || { error "Failed to create backup directory at $BACKUP_DIR"; exit 1; }
info "Backup directory is ready: $BACKUP_DIR"

# Check if the MSSQL container is running
if ! docker ps --format '{{.Names}}' | grep -qw "$MSSQL_CONTAINER_NAME"; then
    error "Container '$MSSQL_CONTAINER_NAME' is not running."
    exit 1
fi
info "Container '$MSSQL_CONTAINER_NAME' is running."

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

HOST_FILE="$BACKUP_DIR/$BACKUP_FILE"
if [[ -f "$HOST_FILE" ]]; then
    info "Backup file available on host: $HOST_FILE"
else
    error "Backup file was not found on host: $HOST_FILE"
    exit 1
fi

info "Compressing and encrypting backup using 7z..."
if [ -z "$ZIP_PASSWORD" ]; then
    error "ZIP_PASSWORD is not set. Cannot compress and encrypt the backup."
    exit 1
fi

if docker run --rm -v "$BACKUP_DIR":/backup alpine sh -c "
    apk add --no-cache p7zip >/dev/null && \
    7z a -tzip -p'$ZIP_PASSWORD' -mem=AES256 -mx=9 \"/backup/${ZIP_FILE}\" \"/backup/$BACKUP_FILE\"
"; then
    info "Backup compressed successfully."
    rm -f "$HOST_FILE" && info "Removed uncompressed backup file: $HOST_FILE"
else
    error "Backup compression failed. Uncompressed file kept: $HOST_FILE"
    exit 1
fi

info "Looking for zip files older than 7 days..."
find "$BACKUP_DIR" -type f -name '*.zip' -mtime +7 -print0 | xargs -0 rm -f
info "Old backup files (older than 7 days) deleted if found."

info "Preparing to send backup file via email..."

# Check if all SMTP variables are set
if [[ -z "$SMTP_SERVER" || -z "$SMTP_PORT" || -z "$SMTP_USER" || -z "$SMTP_PASS" || -z "$SMTP_FROM" || -z "$SMTP_TO" ]]; then
    warn "SMTP environment variables are missing. Skipping email send step."
else
    info "SMTP configuration found. Sending backup via email..."

    docker run --rm -v "$BACKUP_DIR":/backup \
      -e SMTP_SERVER="$SMTP_SERVER" \
      -e SMTP_PORT="$SMTP_PORT" \
      -e SMTP_USER="$SMTP_USER" \
      -e SMTP_PASS="$SMTP_PASS" \
      -e SMTP_FROM="$SMTP_FROM" \
      -e SMTP_TO="$SMTP_TO" \
      -e ZIP_FILE="$ZIP_FILE" \
      python:3.11-slim bash -c "
set -e
python3 - <<EOF
import os, smtplib, ssl
from email.message import EmailMessage
from datetime import datetime

smtp_server = os.environ['SMTP_SERVER']
smtp_port = int(os.environ['SMTP_PORT'])
smtp_user = os.environ['SMTP_USER']
smtp_password = os.environ['SMTP_PASS']
from_addr = os.environ['SMTP_FROM']
to_addr = os.environ['SMTP_TO']
subject = f'Database Backup - {datetime.now():%Y-%m-%d %H:%M}'
body = 'Compressed and encrypted backup file is attached.'
attachment_path = f\"/backup/{os.environ['ZIP_FILE']}\"

msg = EmailMessage()
msg['From'] = from_addr
msg['To'] = to_addr
msg['Subject'] = subject
msg.set_content(body)

with open(attachment_path, 'rb') as f:
    msg.add_attachment(f.read(), maintype='application', subtype='zip', filename=os.path.basename(attachment_path))

context = ssl.create_default_context()
with smtplib.SMTP_SSL(smtp_server, smtp_port, context=context) as server:
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
EOF
"

    if [ $? -eq 0 ]; then
        info "Backup email sent successfully to: $SMTP_TO"
    else
        error "ERROR: Failed to send email."
    fi
fi

info "=== MSSQL backup process completed successfully ==="