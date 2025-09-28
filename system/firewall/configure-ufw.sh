#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"

info "Configuring UFW firewall..."

if ! command -v ufw &> /dev/null; then
    warn "UFW not found. Installing..."
    if command -v apt-get &> /dev/null; then
        apt-get update -y
        apt-get install -y ufw
    else
        error "Unsupported package manager. Please install UFW manually."
        exit 1
    fi
fi

# --- Force IPv4 only ---
info "Disabling IPv6 support in UFW..."
if grep -q "^IPV6=" /etc/default/ufw; then
    sed -i 's/^IPV6=.*/IPV6=no/' /etc/default/ufw
else
    echo "IPV6=no" | tee -a /etc/default/ufw >/dev/null
fi

info "Reloading UFW to apply IPv4-only mode..."
ufw disable >/dev/null 2>&1 || true
ufw --force enable

info "Setting default policies (IPv4 only)..."
ufw default deny incoming
ufw default allow outgoing

# --- Detect current SSH port ---
SSH_PORT=$(grep -E '^[[:space:]]*Port[[:space:]]+[0-9]+' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -n1 || true)
: "${SSH_PORT:=22}"  # fallback to 22 if not set
info "Detected SSH port: $SSH_PORT"

# Ports to allow (IPv4 only)
ALLOW_PORTS=("${SSH_PORT}" 80 443)
for PORT in "${ALLOW_PORTS[@]}"; do
    if ufw status 2>/dev/null | grep -q "${PORT}/tcp"; then
        info "[skip] ${PORT}/tcp already allowed"
    else
        ufw allow from 0.0.0.0/0 to any port "$PORT" proto tcp
        info "[add]  Allowed ${PORT}/tcp (IPv4 only)"
    fi
done

info "Enabling UFW..."
ufw --force enable

info "Current UFW status:"
ufw status verbose

info "UFW configuration completed (IPv4 only)."
