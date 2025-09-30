#!/usr/bin/env bash

# Enable strict error handling
# -e : exit immediately if a command exits with a non-zero status
# -u : treat unset variables as an error and exit immediately
# -o pipefail : if any command in a pipeline fails, the whole pipeline fails
set -euo pipefail

# Check if stdout (file descriptor 1) is a terminal
if [[ -t 1 ]]; then
  # Define color codes for terminal output
  RED=$'\033[31m'   # red
  YEL=$'\033[33m'   # yellow
  GRN=$'\033[32m'   # green
  NC=$'\033[0m'     # no color (reset)
else
  # If not a terminal, disable colors (plain text)
  RED=""; YEL=""; GRN=""; NC=""
fi

# Print an info message in green with a timestamp
info()  { printf "[%s] ${GRN}INFO${NC}  %s\n"  "$(date +"%Y-%m-%d %H:%M:%S")" "$@"; }

# Print a warning message in yellow with a timestamp
warn()  { printf "[%s] ${YEL}WARN${NC}  %s\n"  "$(date +"%Y-%m-%d %H:%M:%S")" "$@"; }

# Print an error message in red with a timestamp
error() { printf "[%s] ${RED}ERROR${NC} %s\n"  "$(date +"%Y-%m-%d %H:%M:%S")" "$@"; }

# Ensure the script is run as root
require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    error "This script must be run as root."
    exit 1
  else
    info "Running with root privileges..."
  fi
}

# Get the directory of the top-level script that sourced this file
caller_script_dir() {
  local top=""
  # If there are entries in BASH_SOURCE, get the last one
  if (( ${#BASH_SOURCE[@]} )); then
    top="${BASH_SOURCE[$((${#BASH_SOURCE[@]}-1))]}"
  fi
  # If called from interactive shell, return current working directory
  if [[ -z "${top:-}" || "$top" == "bash" || "$top" == "-bash" ]]; then
    printf '%s\n' "$PWD"
  else
    # Otherwise, return the absolute path of the script's directory
    cd "$(dirname "$top")" || exit 1
    pwd -P
  fi
}

# Load environment variables from a .env file
load_env() {
  info "Loading environment variables..."
  local ENV_FILE="${1:-"$(caller_script_dir)/.env"}"
  
  # Check if the .env file exists
  if [[ ! -f "$ENV_FILE" ]]; then
    error "Environment file '.env' not found at: $ENV_FILE"
    error "Create it from your template (e.g., .env.example)."
    exit 1
  fi
  
  # Fix Windows CRLF line endings if needed
  if file "$ENV_FILE" | grep -q 'CRLF'; then
    warn "CRLF line endings detected in $ENV_FILE, converting to LF"
    sed -i 's/\r$//' "$ENV_FILE"
  fi
  
  # Load environment variables from the .env file
  set -a
  source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
  set +a
  
  info "Environment variables loaded from: $ENV_FILE"
  return 0
}
