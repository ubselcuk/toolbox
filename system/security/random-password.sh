#!/usr/bin/env bash
set -euo pipefail

openssl rand -base64 48 | tr -dc 'a-zA-Z1-9' | head -c 16