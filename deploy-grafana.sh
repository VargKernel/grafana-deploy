#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[*] Updating system packages..."
apt-get update

echo "[*] Installing required dependencies..."
# docker.io provides the daemon (dockerd)
apt-get install -y docker.io docker-compose

sudo systemctl start docker
sudo systemctl enable docker

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

[[ -f .env ]] || { echo "[!] Create .env from .env.example first" >&2; exit 1; }
[[ -f secrets/grafana_admin_password.txt ]] || { echo "[!] Missing secrets/grafana_admin_password.txt" >&2; exit 1; }

docker compose down --remove-orphans || true

mkdir -p grafana/data prometheus/data
rm -f ./prometheus/data/queries.active 

# Grafana permissions (UID 472)
chown -R 472:472 ./grafana/data
chmod -R 755 ./grafana/data

# Prometheus permissions (UID 65534)
chown -R 65534:65534 ./prometheus/data
chmod -R 777 ./prometheus/data

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || { echo "[!] Missing: $1" >&2; exit 1; }
}

need_cmd docker

if ! docker compose version >/dev/null 2>&1; then
    echo "[!] Docker Compose plugin is missing" >&2
    exit 1
fi

[[ -f .env ]] || { echo "[!] Create .env from .env.example first" >&2; exit 1; }
[[ -f secrets/grafana_admin_password.txt ]] || { echo "[!] Missing secrets/grafana_admin_password.txt" >&2; exit 1; }

mkdir -p grafana/data prometheus/data

echo "[*] Pulling images..."
docker compose pull

echo "[*] Starting stack..."
docker compose up -d --remove-orphans

# echo "[*] Waiting for Grafana..."
# for _ in $(seq 1 60); do
#     if docker compose exec -T grafana sh -lc 'wget -qO- http://localhost:3000/api/health | grep -q "\"database\":\"ok\""'; then
#         echo "[+] Grafana is healthy"
#         break
#     fi
#     sleep 2
# done
# 
# echo "[*] Waiting for Prometheus..."
# for _ in $(seq 1 60); do
#     if docker compose exec -T prometheus sh -lc 'wget -qO- http://localhost:9090/-/ready | grep -q "Ready"'; then
#         echo "[+] Prometheus is ready"
#         break
#     fi
#     sleep 2
# done

echo ""
docker compose ps
echo ""
echo "[+] Grafana is on localhost:3000 inside the host and should be proxied by nginx at /grafana/"
