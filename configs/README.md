# Pre-configured Templates

These config files and databases contain pre-configured settings:

## Prowlarr
- **Indexers**: 1337x, EZTV, LimeTorrents (with FlareSolverr)
- **Apps**: Radarr & Sonarr linked

## Radarr  
- **Download Client**: qBittorrent
- **Root Folder**: /movies
- **Indexer**: Linked to Prowlarr

## Sonarr
- **Download Client**: qBittorrent  
- **Root Folder**: /tv
- **Indexer**: Linked to Prowlarr

## qBittorrent
- Authentication disabled for internal network
- Download path: /downloads

## API Keys (for internal connections)
- Prowlarr: 309a2f534f4343fda7ac5aee6cbb5170
- Radarr: fa91a1d159044102a5c416e4a9ca3024
- Sonarr: 97e8d80bdf7742c2bb7948ba60f78262

These keys are used for inter-service communication and are safe to keep.
