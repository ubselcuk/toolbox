#!/bin/bash
set -euo pipefail

if [[ -t 1 ]]; then
  RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'; NC=$'\033[0m'
else
  RED=""; YEL=""; GRN=""; NC=""
fi

ts()    { date -Is; }
info()  { printf "[%s] ${GRN}INFO${NC}  %s\n" "$(ts)" "$*"; }
warn()  { printf "[%s] ${YEL}WARN${NC}  %s\n" "$(ts)" "$*"; }
error() { printf "[%s] ${RED}ERROR${NC} %s\n" "$(ts)" "$*"; }