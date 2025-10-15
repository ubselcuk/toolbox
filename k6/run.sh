#!/usr/bin/env bash

if [ -z "${1:-}" ]; then
    echo "Usage: $0 [script.js]"
    exit 1
fi

docker run --rm -i --platform linux/amd64 -v "$PWD":/mnt -w /mnt grafana/k6 run "$1"