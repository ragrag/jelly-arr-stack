# Media Server Setup

One-command deployment of a complete media server with zero manual configuration.

## Quick Start

```bash
git clone https://github.com/ragrag/jelly-arr-stack.git
cd jelly-arr-stack
sudo ./setup.sh yourdomain.com your@email.com
```

## Post-Setup (2 minutes)

1. Go to `https://jellyfin.yourdomain.com`
2. Complete Jellyfin setup wizard:
   - Create admin user
   - Add Movies library: `/data/movies`
   - Add TV Shows library: `/data/tvshows`

That is it! Everything else is pre-configured.

## What is Pre-Configured

- ✅ 3 Torrent indexers (1337x, EZTV, LimeTorrents with Cloudflare bypass)
- ✅ qBittorrent connected to Radarr & Sonarr
- ✅ Root folders for movies and TV
- ✅ Subtitle providers with auto-download
- ✅ Bazarr linked to Radarr & Sonarr
- ✅ SSL certificates with auto-renewal
- ✅ Netflix-style dashboard

## Usage

1. **Add a movie:** Radarr → Search → Add
2. **Add a TV show:** Sonarr → Search → Add
3. **Watch:** Content appears in Jellyfin automatically
4. **Subtitles:** Downloaded automatically by Bazarr

## Services

- Dashboard: https://yourdomain.com
- Jellyfin: https://jellyfin.yourdomain.com
- Radarr: https://radarr.yourdomain.com
- Sonarr: https://sonarr.yourdomain.com
- Bazarr: https://bazarr.yourdomain.com
- qBittorrent: https://qbit.yourdomain.com
- Prowlarr: https://prowlarr.yourdomain.com
