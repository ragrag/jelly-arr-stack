#!/bin/bash
set -e

echo "[*] Configuring Jellyfin libraries..."
echo "Waiting for Jellyfin to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8096/health > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

TOKEN=$(curl -s -X POST "http://localhost:8096/Users/AuthenticateByName" -H "Content-Type: application/json" -H "X-Emby-Authorization: MediaBrowser Client=\"setup\", Device=\"server\", DeviceId=\"setup123\", Version=\"1.0\"" -d "{\"Username\":\"root\",\"Pw\":\"Replay1988\"}" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get(\"AccessToken\", \"\"))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "[!] Jellyfin needs initial setup - create admin user first"
    exit 0
fi

echo "Got authentication token"

LIBRARIES=$(curl -s "http://localhost:8096/Library/VirtualFolders" -H "X-Emby-Token: $TOKEN")
MOVIE_EXISTS=$(echo "$LIBRARIES" | python3 -c "import sys,json; print(any(l.get(\"CollectionType\") == \"movies\" for l in json.load(sys.stdin)))" 2>/dev/null || echo "False")
TV_EXISTS=$(echo "$LIBRARIES" | python3 -c "import sys,json; print(any(l.get(\"CollectionType\") == \"tvshows\" for l in json.load(sys.stdin)))" 2>/dev/null || echo "False")

if [ "$MOVIE_EXISTS" = "False" ]; then
    echo "Adding Movies library..."
    curl -s -X POST "http://localhost:8096/Library/VirtualFolders?collectionType=movies&refreshLibrary=false&name=Movies" -H "X-Emby-Token: $TOKEN" -H "Content-Type: application/json" -d "{\"LibraryOptions\":{\"PathInfos\":[{\"Path\":\"/data/movies\"}],\"EnableInternetProviders\":true,\"AllowEmbeddedSubtitles\":\"AllowAll\"}}" > /dev/null 2>&1
    echo "  ✓ Movies library added"
else
    echo "  ✓ Movies library already exists"
fi

if [ "$TV_EXISTS" = "False" ]; then
    echo "Adding TV Shows library..."
    curl -s -X POST "http://localhost:8096/Library/VirtualFolders?collectionType=tvshows&refreshLibrary=false&name=TV%20Shows" -H "X-Emby-Token: $TOKEN" -H "Content-Type: application/json" -d "{\"LibraryOptions\":{\"PathInfos\":[{\"Path\":\"/data/tvshows\"}],\"EnableInternetProviders\":true,\"AllowEmbeddedSubtitles\":\"AllowAll\"}}" > /dev/null 2>&1
    echo "  ✓ TV Shows library added"
else
    echo "  ✓ TV Shows library already exists"
fi

echo "[*] Jellyfin libraries configured!"
