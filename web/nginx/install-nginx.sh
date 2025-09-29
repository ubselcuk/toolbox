#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"

info "Installing Nginx web server..."

# Already installed?
if command -v nginx >/dev/null 2>&1; then
  info "Nginx is already installed. Skipping installation."
else
  info "Updating apt and installing Nginx..."
  apt-get update -y
  apt-get install -y nginx
  info "Nginx installed."
fi

# Enable and start service
info "Enabling and starting Nginx service..."
systemctl enable --now nginx

# Quick verification
if systemctl is-active --quiet nginx; then
  info "Nginx is running: $(nginx -v 2>&1)"
else
  warn "Nginx did not start properly. Check logs with: journalctl -xeu nginx"
fi