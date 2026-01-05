#!/bin/bash
# ===========================================
# Homelab Backup Script
# ===========================================

set -e

BACKUP_DIR="${BACKUP_DIR:-/mnt/backup/homelab}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"

# Färger
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Homelab Backup ===${NC}"
echo "Backup destination: $BACKUP_PATH"

# Skapa backup-mapp
mkdir -p "$BACKUP_PATH/volumes"
mkdir -p "$BACKUP_PATH/configs"

# Docker volymer att backa upp
VOLUMES=(
    "n8n_n8n_data"
    "jenkins_home"
    "eufy_data"
    "speedtest-config"
)

# Config-mappar att backa upp
CONFIGS=(
    "/opt/docker/jellyfin/config"
    "/opt/docker/qbittorrent/config2"
    "/opt/docker/gluetun"
    "/opt/makemkv/config"
)

# Backup Docker volumes
echo -e "\n${YELLOW}Backing up Docker volumes...${NC}"
for vol in "${VOLUMES[@]}"; do
    if docker volume inspect "$vol" > /dev/null 2>&1; then
        echo "  → $vol"
        docker run --rm \
            -v "$vol":/source:ro \
            -v "$BACKUP_PATH/volumes":/backup \
            alpine tar czf "/backup/${vol}.tar.gz" -C /source .
    else
        echo -e "  ${RED}✗ $vol (not found)${NC}"
    fi
done

# Backup config directories
echo -e "\n${YELLOW}Backing up config directories...${NC}"
for cfg in "${CONFIGS[@]}"; do
    if [ -d "$cfg" ]; then
        name=$(basename "$cfg")
        parent=$(basename $(dirname "$cfg"))
        echo "  → $cfg"
        tar czf "$BACKUP_PATH/configs/${parent}_${name}.tar.gz" -C "$(dirname $cfg)" "$name"
    else
        echo -e "  ${RED}✗ $cfg (not found)${NC}"
    fi
done

# Backup stack files från Portainer
echo -e "\n${YELLOW}Backing up Portainer stacks...${NC}"
if [ -d "/var/lib/docker/volumes/portainer_data/_data/compose" ]; then
    cp -r /var/lib/docker/volumes/portainer_data/_data/compose "$BACKUP_PATH/portainer_stacks"
    echo "  → Portainer stacks saved"
fi

# Sammanfattning
echo -e "\n${GREEN}=== Backup Complete ===${NC}"
du -sh "$BACKUP_PATH"
echo ""
echo "Files:"
find "$BACKUP_PATH" -type f -name "*.tar.gz" -exec du -h {} \;

# Cleanup old backups (keep last 7)
echo -e "\n${YELLOW}Cleaning up old backups (keeping last 7)...${NC}"
cd "$BACKUP_DIR"
ls -dt */ | tail -n +8 | xargs -r rm -rf
echo "Done!"
