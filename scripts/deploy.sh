#!/usr/bin/env bash
#
# Deploy config changes to the Iori Pi. Safe to run more than once.
# Requires sudo for individual privileged steps; do not run this script
# itself as root.

set -euo pipefail

if [[ "$EUID" -eq 0 ]]; then
    echo "Do not run this script as root. Run as 'jason'; it will use sudo where needed." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Pulling latest changes"
git -C "$REPO_DIR" pull

echo "==> Installing updated Nginx config"
sudo cp "$REPO_DIR/nginx/iori.conf" /etc/nginx/sites-available/iori

echo "==> Validating Nginx config"
if ! sudo nginx -t; then
    echo "nginx config test failed — aborting before reload" >&2
    exit 1
fi

echo "==> Reloading Nginx"
sudo systemctl reload nginx

echo "==> Service status"
for svc in iori-jp-drill-api iori-song-drill-api; do
    sudo systemctl status "$svc" --no-pager -l | head -n 5
    echo
done

echo "Deploy complete — http://iori"
