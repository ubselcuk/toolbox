#!/usr/bin/env bash
set -euo pipefail


docker run \
    -d \
    --rm \
    --name pgadmin \
    -p 54321:80 \
    -e PGADMIN_DEFAULT_EMAIL="foo@bar.com" \
    -e PGADMIN_DEFAULT_PASSWORD="foobar" \
    dpage/pgadmin4