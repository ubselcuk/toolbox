#!/usr/bin/env bash
set -euo pipefail

# --- CHECK ROOT ---
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# --- CHECK ARGUMENTS ---
if [[ -z "${1:-}" ]]; then
    echo "No .env file provided!"
    echo "Usage: $0 /path/to/.env"
    exit 1
fi

ENV_FILE="$1"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Config file '$ENV_FILE' does not exist!"
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

# --- CHECK REQUIRED VARIABLES ---
REQUIRED_VARS=(MSSQL_CONTAINER_NAME MSSQL_SA_PASSWORD MSSQL_DATABASE_NAME MSSQL_BACKUP_PATH)
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: Required variable '$var' not set in $ENV_FILE"
        exit 1
    fi
done

# --- CHECK DOCKER ---
if ! command -v docker &> /dev/null; then
    echo "Docker command not found. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Docker is not running. Start Docker first."
    exit 1
fi

# --- CHECK CONTAINER RUNNING ---
if ! docker ps --format '{{.Names}}' | grep -qw "$MSSQL_CONTAINER_NAME"; then
    echo "Error: Container '$MSSQL_CONTAINER_NAME' is not running!"
    exit 1
fi

# --- PREPARE BACKUP FILE NAME ---
TIMESTAMP=$(date +'%Y%m%d_%H%M')
NEW_BACKUP_FILE="${MSSQL_DATABASE_NAME}_backup_${TIMESTAMP}.bak"
HOST_BACKUP_PATH="$MSSQL_BACKUP_PATH/$NEW_BACKUP_FILE"

echo "Starting backup of '$MSSQL_DATABASE_NAME'..."
echo "Backup will be saved to: $HOST_BACKUP_PATH"

# --- RUN BACKUP ---
docker exec -i "$MSSQL_CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
    -C -S localhost -U SA -P "$MSSQL_SA_PASSWORD" \
    -Q "BACKUP DATABASE [$MSSQL_DATABASE_NAME] 
        TO DISK = N'/var/opt/mssql/backups/$NEW_BACKUP_FILE'
        WITH INIT, NAME = 'Full Backup', STATS = 10"

echo "✔ Backup completed successfully!"
echo "File: $HOST_BACKUP_PATH"

 
# --- COMPRESS IF REQUESTED ---
if [[ "${ZIP_BACKUP:-no}" == "yes" ]]; then
    GZ_FILE="${NEW_BACKUP_FILE%.bak}.bak.gz"

    docker run --rm \
        --cpus="4" \
        -v "$MSSQL_BACKUP_PATH":/backup \
        ghcr.io/kasperskytte/docker-pigz:master \
        -6 -k /backup/"$NEW_BACKUP_FILE"

    echo "Backup compressed: $GZ_FILE"

    rm -f "$MSSQL_BACKUP_PATH/$NEW_BACKUP_FILE"

    NEW_BACKUP_FILE="$GZ_FILE"
fi

# --- SFTP upload if active ---
if [[ "${SFTP_ACTIVE:-no}" == "yes" ]]; then
    echo "Starting SFTP upload of $NEW_BACKUP_FILE ..."

    REQUIRED_VARS=(SFTP_PASSWORD SFTP_PORT SFTP_USER SFTP_HOST SFTP_REMOTE_PATH)
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Error: Required variable '$var' not set in $ENV_FILE"
            exit 1
        fi
    done


    docker run --rm -v "$MSSQL_BACKUP_PATH":/backup ubuntu:24.04 bash -c "
        apt-get update -qq && apt-get install -y sshpass openssh-client >/dev/null && \
        sshpass -p '$SFTP_PASSWORD' sftp -o StrictHostKeyChecking=no -P ${SFTP_PORT:-22} $SFTP_USER@$SFTP_HOST <<EOF
put /backup/$NEW_BACKUP_FILE $SFTP_REMOTE_PATH/$NEW_BACKUP_FILE
bye
EOF
    "

    if [[ $? -eq 0 ]]; then
        echo "SFTP upload complete. Removing local file: $NEW_BACKUP_FILE"
        rm -f "$MSSQL_BACKUP_PATH/$NEW_BACKUP_FILE"
    else
        echo "SFTP upload failed! Local file retained: $NEW_BACKUP_FILE"
    fi
fi

if [[ "${SEND_MAIL:-no}" == "yes" ]]; then
    echo "SENDMAIL is active. Checking required SMTP variables..."

    REQUIRED_VARS=(SMTP_SERVER SMTP_PORT SMTP_USER SMTP_PASS SMTP_FROM SMTP_TO)
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Error: Required variable '$var' not set in $ENV_FILE"
            exit 1
        fi
    done

    echo "SMTP configuration OK. Sending simple email..."

    docker run --rm \
      -e SMTP_SERVER="$SMTP_SERVER" \
      -e SMTP_PORT="$SMTP_PORT" \
      -e SMTP_USER="$SMTP_USER" \
      -e SMTP_PASS="$SMTP_PASS" \
      -e SMTP_FROM="$SMTP_FROM" \
      -e SMTP_TO="$SMTP_TO" \
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
body = 'Backup process completed successfully.'
# attachment_path = f\"/backup/{os.environ['ZIP_FILE']}\"

msg = EmailMessage()
msg['From'] = from_addr
msg['To'] = to_addr
msg['Subject'] = subject
msg.set_content(body)

# with open(attachment_path, 'rb') as f:
#     msg.add_attachment(f.read(), maintype='application', subtype='zip', filename=os.path.basename(attachment_path))

context = ssl.create_default_context()
with smtplib.SMTP_SSL(smtp_server, smtp_port, context=context) as server:
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
EOF
"

    if [ $? -eq 0 ]; then
        echo "Backup email sent successfully to: $SMTP_TO"
    else
        echo "ERROR: Failed to send email."
    fi
fi

echo "Backup process completed!"