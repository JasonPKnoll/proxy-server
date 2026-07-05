#!/usr/bin/env bash
#
# First-time setup for the Iori Pi. Safe to run more than once.
# Requires sudo for individual privileged steps; do not run this script
# itself as root.

set -euo pipefail

if [[ "$EUID" -eq 0 ]]; then
    echo "Do not run this script as root. Run as 'jason'; it will use sudo where needed." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing nginx"
if ! command -v nginx >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y nginx
else
    echo "nginx already installed, skipping"
fi

echo "==> Creating web root directories"
for app in dashboard jp-drill song-drill; do
    sudo mkdir -p "/var/www/$app"
    sudo chown jason:www-data "/var/www/$app"
done

echo "==> Installing Nginx site config"
sudo cp "$REPO_DIR/nginx/iori.conf" /etc/nginx/sites-available/iori
sudo ln -sf /etc/nginx/sites-available/iori /etc/nginx/sites-enabled/iori

if [[ -e /etc/nginx/sites-enabled/default ]]; then
    echo "==> Removing default Nginx site"
    sudo rm -f /etc/nginx/sites-enabled/default
fi

echo "==> Validating Nginx config"
if ! sudo nginx -t; then
    echo "nginx config test failed — aborting before reload" >&2
    exit 1
fi

echo "==> Installing systemd service files"
sudo cp "$REPO_DIR/systemd/iori-jp-drill-api.service" /etc/systemd/system/
sudo cp "$REPO_DIR/systemd/iori-song-drill-api.service" /etc/systemd/system/

sudo systemctl daemon-reload

echo "==> Enabling and starting services"
for svc in iori-jp-drill-api iori-song-drill-api; do
    sudo systemctl enable "$svc"
    sudo systemctl restart "$svc"
done

echo "==> Reloading Nginx"
sudo systemctl reload nginx

echo
echo "Setup complete."
echo "Open http://iori on any Tailscale device (e.g. your iPhone)."
