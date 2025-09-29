#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

ZONE="Europe/Istanbul"

info "Configuring timezone to $ZONE"
timedatectl set-timezone "$ZONE"
info "Current time: $(date)"
info "Timezone configuration completed."

# NTP configuration (optional)
if ! timedatectl show | grep -q 'NTP=yes'; then
  info "Enabling NTP synchronization"
  timedatectl set-ntp true
  info "NTP synchronization enabled"
else
  info "NTP synchronization is already enabled"
fi