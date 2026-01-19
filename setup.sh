#!/bin/bash
set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

print_status() { echo -e "${GREEN}[*]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Parse arguments
TEST_MODE=false
if [ "$1" = "--test" ]; then
    TEST_MODE=true
    shift
fi

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./setup.sh [--test] <domain> <email>"
    echo ""
    echo "Options:"
    echo "  --test    Run in test mode (skip SSL)"
    echo ""
    echo "Example:"
    echo "  ./setup.sh mrlucky.vip admin@mrlucky.vip"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
DATA_PATH="/media"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$TEST_MODE" = true ]; then
    print_warning "Running in TEST MODE - SSL will be skipped"
fi

print_status "Starting Media Server Setup for $DOMAIN"

# Step 1: Install dependencies
print_status "Installing dependencies..."
apt-get update -qq
apt-get install -y -qq docker.io docker-compose-v2 nginx curl > /dev/null

if [ "$TEST_MODE" = false ]; then
    apt-get install -y -qq snapd > /dev/null
    snap install core > /dev/null 2>&1 || true
    snap refresh core > /dev/null 2>&1 || true
    snap install --classic certbot > /dev/null 2>&1 || true
    ln -sf /snap/bin/certbot /usr/bin/certbot
fi

systemctl enable docker
systemctl start docker

print_status "Dependencies installed"

# Step 2: Create directories
print_status "Creating directories..."
mkdir -p $DATA_PATH/{configs/{jellyfin,radarr,sonarr,bazarr,qbittorrent/qBittorrent,prowlarr},jellyfin/cache,radarr/movies,sonarr/tv,qbittorrent/downloads}

# Step 3: Copy pre-configured templates (THE KEY STEP!)
print_status "Copying pre-configured service templates..."
cp "$SCRIPT_DIR/configs/prowlarr/config.xml" "$DATA_PATH/configs/prowlarr/"
cp "$SCRIPT_DIR/configs/prowlarr/prowlarr.db" "$DATA_PATH/configs/prowlarr/"
cp "$SCRIPT_DIR/configs/radarr/config.xml" "$DATA_PATH/configs/radarr/"
cp "$SCRIPT_DIR/configs/radarr/radarr.db" "$DATA_PATH/configs/radarr/"
cp "$SCRIPT_DIR/configs/sonarr/config.xml" "$DATA_PATH/configs/sonarr/"
cp "$SCRIPT_DIR/configs/sonarr/sonarr.db" "$DATA_PATH/configs/sonarr/"
cp "$SCRIPT_DIR/configs/qbittorrent/qBittorrent.conf" "$DATA_PATH/configs/qbittorrent/qBittorrent/"

print_status "Pre-configured templates copied!"

# Step 4: Create .env file
cat > "$SCRIPT_DIR/.env" << EOF
DATA_PATH=$DATA_PATH
TZ=Europe/Berlin
DOMAIN=$DOMAIN
EOF

# Step 5: Setup dashboard
print_status "Setting up dashboard..."
mkdir -p "$SCRIPT_DIR/dashboard"
sed "s/{{DOMAIN}}/$DOMAIN/g" "$SCRIPT_DIR/dashboard/index.html.template" > "$SCRIPT_DIR/dashboard/index.html"

# Step 6: Start containers
print_status "Starting Docker containers..."
cd "$SCRIPT_DIR"
docker compose up -d

# Step 7: Wait for services
print_status "Waiting for services to initialize (30s)..."
sleep 30

# Step 8: Configure Nginx
print_status "Configuring Nginx..."
sed "s/{{DOMAIN}}/$DOMAIN/g" "$SCRIPT_DIR/nginx/media-server.conf.template" > /etc/nginx/sites-available/media-server
ln -sf /etc/nginx/sites-available/media-server /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Step 9: SSL
if [ "$TEST_MODE" = true ]; then
    print_warning "TEST MODE: Skipping SSL certificates"
else
    print_status "Obtaining SSL certificates..."
    certbot --nginx \
        -d $DOMAIN \
        -d jellyfin.$DOMAIN \
        -d radarr.$DOMAIN \
        -d sonarr.$DOMAIN \
        -d bazarr.$DOMAIN \
        -d qbit.$DOMAIN \
        -d prowlarr.$DOMAIN \
        --non-interactive \
        --agree-tos \
        --email $EMAIL \
        --redirect
fi

# Done!
print_status "======================================"
print_status "Setup Complete!"
print_status "======================================"
echo ""

if [ "$TEST_MODE" = true ]; then
    echo "TEST MODE - HTTP URLs:"
    echo "  Dashboard:   http://localhost:8888"
    echo "  Jellyfin:    http://localhost:8096"
    echo "  Radarr:      http://localhost:7878"
    echo "  Sonarr:      http://localhost:8989"
    echo "  Prowlarr:    http://localhost:9696"
else
    echo "Your media server is ready!"
    echo ""
    echo "  Dashboard:   https://$DOMAIN"
    echo "  Jellyfin:    https://jellyfin.$DOMAIN"
    echo "  Radarr:      https://radarr.$DOMAIN"
    echo "  Sonarr:      https://sonarr.$DOMAIN"
    echo "  Prowlarr:    https://prowlarr.$DOMAIN"
fi

echo ""
echo "Everything is pre-configured:"
echo "  - Indexers: 1337x, EZTV, LimeTorrents (with FlareSolverr)"
echo "  - Download client: qBittorrent"
echo "  - Root folders: /movies, /tv"
echo ""
print_status "Just add movies/shows and they will download automatically!"
