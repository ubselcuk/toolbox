#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

info "Checking rsyslog installation..."

if command -v rsyslogd >/dev/null 2>&1; then
  info "rsyslog is already installed."
else
  info "rsyslog not found. Installing..."
  apt-get update -y
  apt-get install -y rsyslog
  info "rsyslog installed."
fi

info "Enabling and starting rsyslog service..."
systemctl enable --now rsyslog

active_state=$(systemctl is-active rsyslog || true)
enabled_state=$(systemctl is-enabled rsyslog || true)
info "rsyslog state: active=${active_state}, enabled=${enabled_state}"
info "rsyslog setup completed."