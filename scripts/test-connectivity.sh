#!/bin/bash
# Script de test de connectivité pour valider l'infrastructure

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Tests de Connectivité - Projet AS5"
echo "=========================================="
echo ""

# Fonction de test
test_ping() {
    local container=$1
    local target=$2
    local description=$3
    
    echo -n "Test: $description ... "
    if docker exec -it "$container" ping -c 2 -W 2 "$target" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ ÉCHEC${NC}"
        return 1
    fi
}

test_dns() {
    local container=$1
    local domain=$2
    local description=$3
    
    echo -n "Test DNS: $description ... "
    if docker exec -it "$container" nslookup "$domain" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ ÉCHEC${NC}"
        return 1
    fi
}

test_http() {
    local container=$1
    local url=$2
    local description=$3
    
    echo -n "Test HTTP: $description ... "
    if docker exec -it "$container" curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ ÉCHEC${NC}"
        return 1
    fi
}

# Vérifier que les conteneurs sont démarrés
echo "Vérification des conteneurs..."
if ! docker ps | grep -q "as5-border"; then
    echo -e "${RED}Erreur: Les conteneurs ne sont pas démarrés. Lancez 'docker-compose up -d'${NC}"
    exit 1
fi
echo -e "${GREEN}Conteneurs démarrés${NC}"
echo ""

# Tests de ping
echo "=== Tests de Ping ==="
test_ping "client-entreprise5-1" "120.0.84.1" "Client entreprise → Routeur entreprise"
test_ping "client-entreprise5-1" "120.0.82.1" "Client entreprise → AS5-Border"
test_ping "client-entreprise5-1" "120.0.80.1" "Client entreprise → AS5-Border (backbone)"
test_ping "client-entreprise5-1" "120.0.85.10" "Client entreprise → DNS AS5"
test_ping "client-particulier5-1" "192.168.5.1" "Client particulier → Box particulier"
test_ping "client-particulier5-1" "120.0.83.1" "Client particulier → AS5-Border"
echo ""

# Tests DNS
echo "=== Tests DNS ==="
test_dns "client-entreprise5-1" "dns-entreprise5.entreprise5.lan" "Résolution DNS entreprise (autoritaire)"
test_dns "client-entreprise5-1" "www.entreprise5.lan" "Résolution DNS www.entreprise5.lan"
test_dns "client-entreprise5-1" "asterisk-entreprise5.entreprise5.lan" "Résolution DNS asterisk"
test_dns "client-particulier5-1" "google.com" "Résolution DNS récursif (AS5)"
echo ""

# Tests HTTP
echo "=== Tests HTTP ==="
test_http "client-entreprise5-1" "http://nginx-entreprise5.entreprise5.lan" "Service web Nginx"
echo ""

# Tests de routage FRR
echo "=== Tests Routage FRR ==="
echo -n "Test: Routes OSPF ... "
if docker exec -it as5-border vtysh -c "show ip route ospf" | grep -q "O"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${YELLOW}⚠ Aucune route OSPF trouvée${NC}"
fi

echo -n "Test: Neighbors BGP ... "
if docker exec -it as5-border vtysh -c "show ip bgp summary" | grep -q "Established"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${YELLOW}⚠ BGP non établi (normal si Internet Router n'est pas configuré)${NC}"
fi
echo ""

# Tests de services
echo "=== Tests Services ==="
echo -n "Test: FreeRADIUS ... "
if docker exec -it radius-entreprise5 ps aux | grep -q "freeradius"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi

echo -n "Test: Asterisk ... "
if docker exec -it asterisk-entreprise5 ps aux | grep -q "asterisk"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi

echo -n "Test: Nginx ... "
if docker exec -it nginx-entreprise5 ps aux | grep -q "nginx"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi
echo ""

echo "=========================================="
echo "Tests terminés"
echo "=========================================="

