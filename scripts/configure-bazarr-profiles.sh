#!/bin/bash
set -e

echo "[*] Configuring Bazarr subtitle profiles..."

# Wait for Bazarr
for i in {1..30}; do
    if curl -s http://localhost:6767/api/system/status -H "X-API-KEY: 8992f957724ffc7f17d89d12919e900a" > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

BAZARR_KEY="8992f957724ffc7f17d89d12919e900a"

# Check if default profile exists
PROFILES=$(curl -s "http://localhost:6767/api/profiles" -H "X-API-KEY: $BAZARR_KEY" 2>/dev/null || echo "[]")
PROFILE_EXISTS=$(echo "$PROFILES" | python3 -c "import sys,json; print(len(json.load(sys.stdin)) > 0)" 2>/dev/null || echo "False")

if [ "$PROFILE_EXISTS" = "False" ]; then
    echo "Creating default subtitle profile..."
    curl -s -X POST "http://localhost:6767/api/profiles" \
        -H "X-API-KEY: $BAZARR_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Default\",\"cutoff\":null,\"items\":[{\"language\":\"en\",\"forced\":false,\"hi\":false},{\"language\":\"en\",\"forced\":false,\"hi\":true}],\"mustContain\":[],\"mustNotContain\":[]}" > /dev/null 2>&1
    echo "  ✓ Default profile created (English with HI option)"
else
    echo "  ✓ Profiles already exist"
fi

echo "[*] Bazarr profiles configured!"
