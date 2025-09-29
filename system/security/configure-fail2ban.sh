#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

info "Installing fail2ban..."
apt-get update -y
apt-get install -y fail2ban

if command -v ufw >/dev/null 2>&1; then
  BANACTION="ufw"
  info "UFW detected, will use banaction=ufw."
  if ! ufw status >/dev/null 2>&1; then
    warn "UFW is not enabled; bans may not apply until UFW is enabled."
  fi
elif command -v nft >/dev/null 2>&1; then
  BANACTION="nftables-multiport"
else
  BANACTION="iptables-multiport"
fi

# Determine SSH port from sshd_config, default to 22 if not found
SSH_PORT="$(grep -E '^[[:space:]]*Port[[:space:]]+[0-9]+' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -n1 || true)"
: "${SSH_PORT:=22}"
info "Detected SSH port: $SSH_PORT"

mkdir -p /etc/fail2ban/jail.d
JAIL_FILE="/etc/fail2ban/jail.d/10-ssh-hardening.local"

info "Writing Fail2ban configuration to ${JAIL_FILE} ..."
cat > "${JAIL_FILE}" <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 1h
findtime = 10m
maxretry = 5
banaction = ${BANACTION}
backend = auto

[sshd]
enabled = true
port    = ${SSH_PORT}
logpath = %(sshd_log)s
EOF

if systemctl is-active --quiet fail2ban; then
  info "Reloading fail2ban to apply changes..."
  systemctl restart fail2ban
else
  info "Enabling and starting fail2ban..."
  systemctl enable --now fail2ban
fi

info "Waiting for fail2ban to become ready..."
ready=0
for i in {1..10}; do
  if fail2ban-client ping >/dev/null 2>&1; then
    info "fail2ban is ready (pong)."
    ready=1
    break
  fi
  sleep 1
done

if [[ $ready -ne 1 ]]; then
  error "fail2ban not ready after 10s. Recent logs:"
  journalctl -xeu fail2ban --no-pager -n 50 || true
  exit 1
fi

info "Fail2ban service state: $(systemctl is-active fail2ban || true)"
info "Jails overview:"
fail2ban-client status || true
info "sshd jail status:"
fail2ban-client status sshd || true

info "Fail2ban setup completed."
