#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"

require_root

info "Installing Caddy web server..."
# Already installed?
if command -v caddy >/dev/null 2>&1; then
  info "Caddy is already installed. Skipping installation."
  exit 0
fi

info "Installing Caddy..."
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install caddy -y
info "Caddy installed."
