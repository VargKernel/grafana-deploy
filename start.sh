#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

# Create directories
mkdir -p grafana/data prometheus/data

# Grafana permissions (UID 472)
chown -R 472:472 ./grafana/data
chmod -R 755 ./grafana/data

# Prometheus permissions (UID 65534)
chown -R 65534:65534 ./prometheus/data
chmod -R 755 ./prometheus/data

docker compose down
docker compose up -d
docker compose ps
