#!/bin/bash
set -e

DOMAIN=${1:-"localhost"}
DATA_PATH="/media"

echo "[*] Configuring service connections..."
sleep 5

get_api_key() {
    grep -oP "(?<=ApiKey>)[^<]+" "$1" 2>/dev/null || echo ""
}

RADARR_KEY=${get_api_key "$DATA_PATH/configs/radarr/config.xml")
SONARR_KEY=$(get_api_key "$DATA_PATH/configs/sonarr/config.xml")
PROWLARR_KEY=${get_api_key "$DATA_PATH/configs/prowlarr/config.xml")

echo "[*] API Keys found"

if [ -n "$PROWLARR_KEY" ]; then
    echo "[*] Configuring Prowlarr..."
    curl -s -X POST "http://localhost:9696/api/v1/indexerProxy" -H "Content-Type: application/json" -H "X-Api-Key: $PROWLARR_KEY" -d '{"name":"FlareSolverr","fields":[{"name":"host","value":"http://flaresolverr:8191"},{"name":"requestTimeout","value":60}],"implementationName":"FlareSolverr","implementation":"FlareSolverr","configContract":"FlareSolverrSettings","tags":[1]}' >/dev/null 2>&1 || true
fi

if [ -n "$RADARR_KEY" ]; then
    echo "[*] Configuring Radarr..."
    curl -s -X POST "http://localhost:7878/api/v3/downloadclient" -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" -d '{"name":"qBittorrent","fields":[{"name":"host","value":"qbittorrent"},{"name":"port","value":8080},{"name":"movieCategory","value":"radarr"}],"implementationName":"qBittorrent","implementation":"QBittorrent","configContract":"QBittorrentSettings","enable":true}' >/dev/null 2>&1 || true
    curl -s -X POST "http://localhost:7878/api/v3/rootfolder" -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" -d '{"path":"/movies"}' >/dev/null 2>&1 || true
fi

if [ -n "$SONARR_KEY" ]; then
    echo "[*] Configuring Sonarr..."
    curl -s -X POST "http://localhost:8989/api/v3/downloadclient" -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" -d '{"name":"qBittorrent","fields":[{"name":"host","value":"qbittorrent"},{"name":"port","value":8080},{"name":"tvCategory","value":"sonarr"}],"implementationName":"qBittorrent","implementation":"QBittorrent","configContract":"QBittorrentSettings","enable":true}' >/dev/null 2>&1 || true
    curl -s -X POST "http://localhost:8989/api/v3/rootfolder" -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" -d '{"path":"/tv"}' >/dev/null 2>&1 || true
fi

echo "[*] Configuring Bazarr..."
mkdir -p "$DATA_PATH/configs/bazarr/config"
cat > "$DATA_PATH/configs/bazarr/config/config.yaml" << EOF
general:
  use_radarr: true
  use_sonarr: true
  enabled_providers:
    - yifysubtitles
    - supersubtitles
  minimum_score_movie: 50
  minimum_score: 50
radarr:
  ip: radarr
  port: 7878
  apikey: $RADARR_KEY
sonarr:
  ip: sonarr
  port: 8989
  apikey: $SONARR_KEY
EOF
docker restart bazarr 2>/dev/null || true

echo "[*] Configuration complete!"
