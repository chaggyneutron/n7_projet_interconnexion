#!/bin/bash
# Script pour lancer tous les services du projet

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Démarrage de l'infrastructure AS5 ===${NC}"
echo ""

# Créer les réseaux
echo "1. Création des réseaux..."
docker compose up -d --no-start 2>&1 | grep -E "(Creating|Created)" || true
echo ""

# Services dans l'ordre de dépendance
SERVICES=(
    "services/as5-routers"
    "services/internet-router"
    "services/dns-as5"
    "services/entreprise5"
    "services/particulier5"
    "services/site-secondaire"
)

for service in "${SERVICES[@]}"; do
    echo -e "${YELLOW}2. Démarrage de $service...${NC}"
    docker compose -f "$service/docker-compose.yml" up -d
    sleep 2
done

echo ""
echo -e "${GREEN}=== Infrastructure démarrée ===${NC}"
echo ""
echo "Vérification de l'état :"
docker compose ps --format "table {{.Name}}\t{{.Status}}" | head -20

