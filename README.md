# Media Server Setup

One-command deployment of a complete media server with:
- **Jellyfin** - Stream your media
- **Radarr** - Movie management
- **Sonarr** - TV show management
- **Bazarr** - Subtitle downloads
- **qBittorrent** - Download client
- **Prowlarr** - Indexer management
- **FlareSolverr** - Cloudflare bypass

## Requirements

- Fresh Ubuntu/Debian VPS
- Domain with DNS A records pointing to your server:
  - `yourdomain.com`
  - `www.yourdomain.com`
  - `jellyfin.yourdomain.com`
  - `radarr.yourdomain.com`
  - `sonarr.yourdomain.com`
  - `bazarr.yourdomain.com`
  - `qbit.yourdomain.com`
  - `prowlarr.yourdomain.com`

## Quick Start

```bash
# Clone the repo
git clone https://github.com/YOURUSER/media-server-setup
cd media-server-setup

# Run setup (replace with your domain and email)
sudo ./setup.sh yourdomain.com your@email.com
```

## What the setup does

1. Installs Docker, Nginx, Certbot
2. Creates data directories at `/media`
3. Starts all containers
4. Configures Nginx reverse proxy
5. Obtains SSL certificates (auto-renewal enabled)
6. Connects all services together

## Post-Setup

1. Go to `https://jellyfin.yourdomain.com`
2. Create your admin account
3. Add libraries:
   - Movies: `/data/movies`
   - TV Shows: `/data/tvshows`
4. Optionally create a "Guest" user for open access

## Directory Structure

```
/media/
├── configs/          # Service configurations
│   ├── jellyfin/
│   ├── radarr/
│   ├── sonarr/
│   ├── bazarr/
│   ├── qbittorrent/
│   └── prowlarr/
├── radarr/movies/    # Movie files
├── sonarr/tv/        # TV show files
└── qbittorrent/downloads/  # Active downloads
```

## Services

| Service | Port | URL |
|---------|------|-----|
| Dashboard | 8888 | https://yourdomain.com |
| Jellyfin | 8096 | https://jellyfin.yourdomain.com |
| Radarr | 7878 | https://radarr.yourdomain.com |
| Sonarr | 8989 | https://sonarr.yourdomain.com |
| Bazarr | 6767 | https://bazarr.yourdomain.com |
| qBittorrent | 8080 | https://qbit.yourdomain.com |
| Prowlarr | 9696 | https://prowlarr.yourdomain.com |
