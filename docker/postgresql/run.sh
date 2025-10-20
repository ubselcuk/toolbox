#!/usr/bin/env bash
set -euo pipefail

docker run \
  -d \
  --rm \
  --name postgres \
  --restart unless-stopped \
  -p 5432:5432 \
  -e POSTGRES_USER="foo" \
  -e POSTGRES_PASSWORD="bar" \
  -e POSTGRES_DB="default" \
  -v pgdata:/var/lib/postgresql/data \
  postgres:latest