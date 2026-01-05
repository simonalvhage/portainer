#!/bin/bash
# ===========================================
# Homelab Restore Script
# ===========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_directory>"
    echo "Example: $0 /mnt/backup/homelab/20240115_120000"
    exit 1
fi

BACKUP_PATH="$1"

if [ ! -d "$BACKUP_PATH" ]; then
    echo -e "${RED}Backup directory not found: $BACKUP_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}=== Homelab Restore ===${NC}"
echo "Restoring from: $BACKUP_PATH"
echo ""
echo -e "${RED}WARNING: This will overwrite existing data!${NC}"
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Restore Docker volumes
echo -e "\n${YELLOW}Restoring Docker volumes...${NC}"
for archive in "$BACKUP_PATH/volumes"/*.tar.gz; do
    if [ -f "$archive" ]; then
        vol=$(basename "$archive" .tar.gz)
        echo "  → $vol"
        
        # Skapa volym om den inte finns
        docker volume create "$vol" 2>/dev/null || true
        
        # Återställ data
        docker run --rm \
            -v "$vol":/target \
            -v "$archive":/backup.tar.gz:ro \
            alpine sh -c "rm -rf /target/* && tar xzf /backup.tar.gz -C /target"
    fi
done

# Restore config directories
echo -e "\n${YELLOW}Restoring config directories...${NC}"
for archive in "$BACKUP_PATH/configs"/*.tar.gz; do
    if [ -f "$archive" ]; then
        name=$(basename "$archive" .tar.gz)
        echo "  → $name"
        
        # Bestäm destination baserat på namn
        case "$name" in
            *jellyfin*)
                dest="/opt/docker/jellyfin"
                ;;
            *qbittorrent*)
                dest="/opt/docker/qbittorrent"
                ;;
            *gluetun*)
                dest="/opt/docker"
                ;;
            *makemkv*)
                dest="/opt"
                ;;
            *)
                echo "    Unknown config, skipping"
                continue
                ;;
        esac
        
        mkdir -p "$dest"
        tar xzf "$archive" -C "$dest"
    fi
done

echo -e "\n${GREEN}=== Restore Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. Review restored data"
echo "2. Restart containers: docker restart \$(docker ps -q)"
echo "3. Or redeploy stacks in Portainer"
