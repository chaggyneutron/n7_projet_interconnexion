#!/bin/bash
# Script pour arrêter tous les conteneurs du projet

set -e

echo "=========================================="
echo "  ARRÊT DE TOUS LES CONTENEURS"
echo "=========================================="
echo ""

# Compter les conteneurs actifs
ACTIVE=$(docker ps -q | wc -l)

if [ $ACTIVE -eq 0 ]; then
    echo "Aucun conteneur actif."
    exit 0
fi

echo "Conteneurs actifs: $ACTIVE"
echo ""

# Arrêter tous les conteneurs
echo "Arrêt des conteneurs..."
docker stop $(docker ps -q)

echo ""
echo "✅ Tous les conteneurs ont été arrêtés."
echo ""

# Afficher le statut
echo "Statut:"
docker ps -a --format "  {{.Names}}: {{.Status}}" | head -10

echo ""
echo "Pour redémarrer: ./start-all.sh"
echo "Pour nettoyer: docker container prune"


