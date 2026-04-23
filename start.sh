#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

chown -R 472:472 ./grafana/data
chmod -R 750 ./grafana/data

docker compose down
docker compose up -d
docker compose ps
