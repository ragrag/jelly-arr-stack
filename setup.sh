#!/bin/bash
set -e

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

print_status() { echo -e "${GREEN}[*]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[x]${NC} $1"; }

# Parse arguments
TEST_MODE=false
if [ "$1" = "--test" ]; then
    TEST_MODE=true
    shift
fi

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./setup.sh [--test] <domain> <email>"
    echo ""
    echo "Options:"
    echo "  --test    Run in test mode (skip SSL, use self-signed certs)"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh mrlucky.vip admin@mrlucky.vip"
    echo "  ./setup.sh --test localhost test@test.com"
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
mkdir -p $DATA_PATH/{configs/{jellyfin,radarr,sonarr,bazarr,qbittorrent,prowlarr},jellyfin/cache,radarr/movies,sonarr/tv,qbittorrent/downloads}

# Step 3: Create .env file
print_status "Creating environment file..."
cat > "$SCRIPT_DIR/.env" << EOF
DATA_PATH=$DATA_PATH
TZ=Europe/Berlin
DOMAIN=$DOMAIN
EOF

# Step 4: Setup dashboard
print_status "Setting up dashboard..."
mkdir -p "$SCRIPT_DIR/dashboard"
sed "s/{{DOMAIN}}/$DOMAIN/g" "$SCRIPT_DIR/dashboard/index.html.template" > "$SCRIPT_DIR/dashboard/index.html"

# Step 5: Start containers
print_status "Starting Docker containers..."
cd "$SCRIPT_DIR"
docker compose up -d

# Step 6: Wait for services to initialize
print_status "Waiting for services to initialize (60s)..."
sleep 60

# Step 7: Configure Nginx
print_status "Configuring Nginx..."
sed "s/{{DOMAIN}}/$DOMAIN/g" "$SCRIPT_DIR/nginx/media-server.conf.template" > /etc/nginx/sites-available/media-server
ln -sf /etc/nginx/sites-available/media-server /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Step 8: SSL Certificates
if [ "$TEST_MODE" = true ]; then
    print_warning "TEST MODE: Skipping SSL certificates"
    print_warning "Services available via HTTP only"
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

# Step 9: Configure qBittorrent
print_status "Configuring qBittorrent..."
sleep 5
docker compose restart qbittorrent
sleep 10

mkdir -p $DATA_PATH/configs/qbittorrent/qBittorrent
cat > $DATA_PATH/configs/qbittorrent/qBittorrent/qBittorrent.conf << EOF
[Preferences]
WebUI\Address=*
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\AuthSubnetWhitelist=0.0.0.0/0
WebUI\LocalHostAuth=false
WebUI\Port=8080
WebUI\ServerDomains=*
WebUI\Username=admin
WebUI\CSRFProtection=false
WebUI\ClickjackingProtection=false
WebUI\HostHeaderValidation=false
EOF
docker compose restart qbittorrent

# Step 10: Run configuration script
print_status "Running service configuration..."
bash "$SCRIPT_DIR/scripts/configure-services.sh" "$DOMAIN"

# Print summary
print_status "======================================"
print_status "Setup Complete!"
print_status "======================================"
echo ""

if [ "$TEST_MODE" = true ]; then
    echo "TEST MODE - HTTP URLs:"
    echo "Dashboard:   http://localhost:8888"
    echo "Jellyfin:    http://localhost:8096"
    echo "Radarr:      http://localhost:7878"
    echo "Sonarr:      http://localhost:8989"
    echo "Bazarr:      http://localhost:6767"
    echo "qBittorrent: http://localhost:8080"
    echo "Prowlarr:    http://localhost:9696"
else
    echo "Dashboard:   https://$DOMAIN"
    echo "Jellyfin:    https://jellyfin.$DOMAIN"
    echo "Radarr:      https://radarr.$DOMAIN"
    echo "Sonarr:      https://sonarr.$DOMAIN"
    echo "Bazarr:      https://bazarr.$DOMAIN"
    echo "qBittorrent: https://qbit.$DOMAIN"
    echo "Prowlarr:    https://prowlarr.$DOMAIN"
fi

echo ""
print_warning "Next steps:"
echo "1. Open Jellyfin and create admin user"
echo "2. Add movies/TV libraries pointing to /data/movies and /data/tvshows"
echo "3. Run: ./scripts/configure-services.sh $DOMAIN (after Jellyfin setup)"
echo ""
