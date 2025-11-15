#!/usr/bin/env bash
set -euo pipefail

docker run \
  -d \
  --name postgres \
  --restart unless-stopped \
  --network custom-app-network \
  --cpus="1.0" \
  --memory="4g" \
  -p 127.0.0.1:5432:5432 \
  -e TZ=Europe/Istanbul \
  -e POSTGRES_USER="postgres" \
  -e POSTGRES_PASSWORD="foobar" \
  -v pgdb:/var/lib/postgresql \
  --health-cmd "pg_isready -U postgres" \
  --health-interval 5s \
  --health-timeout 5s \
  --health-retries 5 \
  --log-driver=json-file \
  --log-opt max-size=50m \
  --log-opt max-file=3 \
  postgres:18