#!/bin/bash
# Script de test complet de l'infrastructure

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  TESTS COMPLETS - PROJET AS5"
echo "=========================================="
echo ""

# Fonction de test
test_cmd() {
    local container=$1
    local cmd=$2
    local description=$3
    
    echo -n "Test: $description ... "
    if docker exec $container sh -c "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ ÉCHEC${NC}"
        return 1
    fi
}

# 1. Tests de connectivité de base
echo -e "${BLUE}=== 1. Tests de Connectivité ===${NC}"
test_cmd "client-entreprise5-1" "ping -c 2 -W 2 120.0.84.1" "Client entreprise → Routeur entreprise"
test_cmd "client-entreprise5-1" "ping -c 2 -W 2 120.0.84.10" "Client entreprise → DNS entreprise"
test_cmd "client-entreprise5-1" "ping -c 2 -W 2 120.0.84.13" "Client entreprise → Nginx"
test_cmd "client-particulier5-1" "ping -c 2 -W 2 192.168.5.1" "Client particulier → Box particulier"
echo ""

# 2. Tests DNS
echo -e "${BLUE}=== 2. Tests DNS ===${NC}"
test_cmd "client-entreprise5-1" "nslookup dns-entreprise5.entreprise5.lan 120.0.84.10" "DNS entreprise (autoritaire)"
test_cmd "client-entreprise5-1" "nslookup www.entreprise5.lan 120.0.84.10" "Résolution www.entreprise5.lan"
test_cmd "client-particulier5-1" "nslookup google.com 120.0.85.10" "DNS récursif AS5"
echo ""

# 3. Tests HTTP
echo -e "${BLUE}=== 3. Tests HTTP ===${NC}"
test_cmd "client-entreprise5-1" "curl -s -o /dev/null -w '%{http_code}' http://nginx-entreprise5.entreprise5.lan | grep -q '200'" "Service web Nginx"
echo ""

# 4. Tests Services
echo -e "${BLUE}=== 4. Tests Services ===${NC}"
echo -n "Test: FreeRADIUS actif ... "
if docker exec radius-entreprise5 ps aux | grep -q "freeradius"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi

echo -n "Test: Asterisk actif ... "
if docker exec asterisk-entreprise5 ps aux | grep -q "asterisk"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi

echo -n "Test: Nginx actif ... "
if docker exec nginx-entreprise5 ps aux | grep -q "nginx"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi
echo ""

# 5. Tests OpenVPN
echo -e "${BLUE}=== 5. Tests OpenVPN ===${NC}"
echo -n "Test: OpenVPN Entreprise actif ... "
if docker exec openvpn-entreprise5 ps aux | grep -q "openvpn"; then
    echo -e "${GREEN}✓ OK${NC}"
    docker exec openvpn-entreprise5 ps aux | grep openvpn | head -1 | awk '{print "  Port: "$0}'
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi

echo -n "Test: OpenVPN Site Secondaire actif ... "
if docker exec openvpn-site-secondaire ps aux | grep -q "openvpn"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ÉCHEC${NC}"
fi

echo -n "Test: Port OpenVPN Entreprise (1194) ... "
if docker exec openvpn-entreprise5 netstat -uln 2>/dev/null | grep -q ":1194 " || docker exec openvpn-entreprise5 ss -uln 2>/dev/null | grep -q ":1194 "; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${YELLOW}⚠ Vérification manuelle nécessaire${NC}"
fi
echo ""

# 6. Tests Routage (si routeurs démarrés)
echo -e "${BLUE}=== 6. Tests Routage ===${NC}"
if docker ps | grep -q "as5-border"; then
    echo -n "Test: Routes OSPF ... "
    if docker exec as5-border vtysh -c "show ip route ospf" 2>/dev/null | grep -q "O"; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${YELLOW}⚠ Aucune route OSPF${NC}"
    fi
    
    echo -n "Test: BGP neighbors ... "
    if docker exec as5-border vtysh -c "show ip bgp summary" 2>/dev/null | grep -q "Established"; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${YELLOW}⚠ BGP non établi${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Routeurs non démarrés (conflits réseau)${NC}"
fi
echo ""

# Résumé
echo "=========================================="
echo "  RÉSUMÉ"
echo "=========================================="
echo -e "${GREEN}Services opérationnels:${NC}"
docker compose ps --format "{{.Name}}: {{.Status}}" | grep "Up" | wc -l | xargs echo "  -"
echo ""
echo -e "${YELLOW}Pour tester le VPN manuellement:${NC}"
echo "  1. Connecter un client au serveur OpenVPN"
echo "  2. Vérifier la connectivité via le tunnel"
echo ""
echo "=========================================="

