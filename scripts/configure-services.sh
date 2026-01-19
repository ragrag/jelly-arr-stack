#!/bin/bash
set -e

DOMAIN=${1:-"localhost"}
DATA_PATH="/media"

echo "[*] Configuring service connections..."
sleep 5

get_api_key() {
    grep -oP "(?<=ApiKey>)[^<]+" "$1" 2>/dev/null || echo ""
}

RADARR_KEY=$(get_api_key "$DATA_PATH/configs/radarr/config.xml")
SONARR_KEY=$(get_api_key "$DATA_PATH/configs/sonarr/config.xml")
PROWLARR_KEY=$(get_api_key "$DATA_PATH/configs/prowlarr/config.xml")

echo "[*] API Keys found"

# Configure qBittorrent
echo "[*] Configuring qBittorrent..."
docker compose stop qbittorrent 2>/dev/null || docker stop qbittorrent 2>/dev/null || true
sleep 2

mkdir -p "$DATA_PATH/configs/qbittorrent/qBittorrent"
cat > "$DATA_PATH/configs/qbittorrent/qBittorrent/qBittorrent.conf" << 'QBCONF'
[AutoRun]
enabled=false

[BitTorrent]
Session\AddTorrentStopped=false
Session\DefaultSavePath=/downloads/
Session\Port=6881

[LegalNotice]
Accepted=true

[Preferences]
WebUI\Address=*
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\AuthSubnetWhitelist=0.0.0.0/0
WebUI\LocalHostAuth=false
WebUI\Port=8080
WebUI\ServerDomains=*
WebUI\CSRFProtection=false
WebUI\ClickjackingProtection=false
WebUI\HostHeaderValidation=false
QBCONF

docker compose start qbittorrent 2>/dev/null || docker start qbittorrent 2>/dev/null || true
sleep 5

# Configure Radarr
if [ -n "$RADARR_KEY" ]; then
    echo "[*] Configuring Radarr..."
    curl -s -X POST "http://localhost:7878/api/v3/rootfolder" -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" -d '{"path":"/movies"}' > /dev/null 2>&1 || true
    curl -s -X POST "http://localhost:7878/api/v3/downloadclient" -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" -d '{"name":"qBittorrent","enable":true,"protocol":"torrent","priority":1,"implementation":"QBittorrent","configContract":"QBittorrentSettings","fields":[{"name":"host","value":"qbittorrent"},{"name":"port","value":8080},{"name":"useSsl","value":false},{"name":"urlBase","value":""},{"name":"username","value":""},{"name":"password","value":""},{"name":"movieCategory","value":"radarr"},{"name":"movieImportedCategory","value":""},{"name":"recentMoviePriority","value":0},{"name":"olderMoviePriority","value":0},{"name":"initialState","value":0},{"name":"sequentialOrder","value":false},{"name":"firstAndLast","value":false},{"name":"contentLayout","value":0}]}' > /dev/null 2>&1 || true
fi

# Configure Sonarr
if [ -n "$SONARR_KEY" ]; then
    echo "[*] Configuring Sonarr..."
    curl -s -X POST "http://localhost:8989/api/v3/rootfolder" -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" -d '{"path":"/tv"}' > /dev/null 2>&1 || true
    curl -s -X POST "http://localhost:8989/api/v3/downloadclient" -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" -d '{"name":"qBittorrent","enable":true,"protocol":"torrent","priority":1,"implementation":"QBittorrent","configContract":"QBittorrentSettings","fields":[{"name":"host","value":"qbittorrent"},{"name":"port","value":8080},{"name":"useSsl","value":false},{"name":"urlBase","value":""},{"name":"username","value":""},{"name":"password","value":""},{"name":"tvCategory","value":"sonarr"},{"name":"tvImportedCategory","value":""},{"name":"recentTvPriority","value":0},{"name":"olderTvPriority","value":0},{"name":"initialState","value":0},{"name":"sequentialOrder","value":false},{"name":"firstAndLast","value":false},{"name":"contentLayout","value":0}]}' > /dev/null 2>&1 || true
fi

# Configure Prowlarr
if [ -n "$PROWLARR_KEY" ]; then
    echo "[*] Configuring Prowlarr..."
    curl -s -X POST "http://localhost:9696/api/v1/indexerProxy" -H "Content-Type: application/json" -H "X-Api-Key: $PROWLARR_KEY" -d '{"name":"FlareSolverr","fields":[{"name":"host","value":"http://flaresolverr:8191"},{"name":"requestTimeout","value":60}],"implementationName":"FlareSolverr","implementation":"FlareSolverr","configContract":"FlareSolverrSettings","tags":[1]}' > /dev/null 2>&1 || true
fi

echo "[*] Configuration complete!"
