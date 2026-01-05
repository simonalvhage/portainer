# Simon's Homelab

Docker-baserad homelab setup med Portainer på Ubuntu/Debian.

## Översikt

| Stack | Port | Beskrivning |
|-------|------|-------------|
| n8n | 5678 | Workflow automation |
| Jellyfin | 8096 | Media server |
| qBittorrent | 8080 | Torrent client (via VPN) |
| Gluetun | - | VPN container (PIA) |
| Jenkins | 8081 | CI/CD |
| MakeMKV | 5800 | DVD/Blu-ray ripping |
| Speedtest | 8765 | Internet speed tracking |
| Eufy Security | 3000 | Eufy camera bridge för Home Assistant |

## Förutsättningar

- Docker & Docker Compose
- Portainer (valfritt men rekommenderat)
- NFS-mount för media (om separat NAS)

## Snabbstart

### 1. Klona repo

```bash
git clone https://github.com/yourusername/homelab.git
cd homelab
```

### 2. Konfigurera environment

```bash
cp .env.example .env
nano .env  # Fyll i dina credentials
```

### 3. Skapa mappar och volymer

```bash
# Skapa config-mappar
sudo mkdir -p /opt/docker/{gluetun,jellyfin/config,qbittorrent/config2,makemkv/config}

# Skapa media-mappar (justera efter ditt setup)
sudo mkdir -p /mnt/media/{movies,tv,dvd_ripped}

# Skapa Docker-volymer
docker volume create n8n_n8n_data
docker volume create jenkins_home
docker volume create eufy_data
docker volume create speedtest-config
```

### 4. Deploya stacks

**Med Portainer:**
1. Stacks → Add stack
2. Klistra in innehållet från respektive `docker-compose.yml`
3. Lägg till environment-variabler från `.env`
4. Deploy

**Med Docker Compose:**
```bash
cd stacks/n8n && docker compose up -d
cd ../gluetun-qbittorrent && docker compose up -d
# osv...
```

## Stack-detaljer

### n8n
Workflow automation med webhook-stöd.

- **Port:** 5678
- **Data:** `n8n_n8n_data` volume
- **Extern åtkomst:** Kräver reverse proxy (Cloudflare Tunnel rekommenderas)

### Gluetun + qBittorrent
qBittorrent routas genom Gluetun VPN-container.

- **VPN:** Private Internet Access (PIA)
- **qBittorrent WebUI:** localhost:8080
- **Media-mappar:** `/mnt/media/movies`, `/mnt/media/tv`

### Jellyfin
Media server med hardware transcoding-stöd.

- **Port:** 8096 (network_mode: host)
- **Config:** `/opt/docker/jellyfin/config`
- **Media:** `/mnt/media/movies`, `/mnt/media/tv`, `/mnt/media/dvd_ripped`

### Eufy Security
WebSocket bridge för Eufy-kameror till Home Assistant.

- **Port:** 3000
- **Kräver:** Sekundärt Eufy-konto (huvudkontot loggas ut)
- **Home Assistant:** Installera Eufy Security via HACS

### MakeMKV
DVD/Blu-ray ripping via webbgränssnitt.

- **WebUI:** localhost:5800
- **Output:** `/mnt/media/dvd_ripped`
- **Device:** `/dev/sr0` (DVD-enhet)

### Speedtest Tracker
Automatisk hastighetsmätning var 3:e timme.

- **Port:** 8765
- **Schema:** `0 */3 * * *` (var 3:e timme)

## Backup

### Volymer att säkerhetskopiera

```bash
# Lista volymer
docker volume ls

# Backup-script
./scripts/backup.sh
```

Viktiga volymer:
- `n8n_n8n_data` - Workflows och credentials
- `jenkins_home` - Jobs och config
- `eufy_data` - Eufy session data
- `/opt/docker/jellyfin/config` - Jellyfin bibliotek
- `/opt/docker/qbittorrent/config2` - qBittorrent inställningar

### Restore

```bash
# Återställ volym
docker volume create <volume_name>
sudo cp -r /path/to/backup/* /var/lib/docker/volumes/<volume_name>/_data/
```

## Felsökning

### qBittorrent visar inte WebUI
Kontrollera att Gluetun är igång och VPN är uppkopplat:
```bash
docker logs gluetun | grep -i "vpn"
```

### Eufy loggar ut mig från appen
Skapa ett sekundärt Eufy-konto och dela ditt hem med det. Använd sekundärkontot i Docker.

### Jellyfin buffrar
- Kontrollera nätverket mellan Jellyfin och NAS
- Sänk streaming-kvaliteten
- Aktivera hardware transcoding om möjligt

## Licens

MIT
