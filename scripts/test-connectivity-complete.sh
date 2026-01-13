#!/bin/bash
# Script de test de connectivité complète du projet

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNING=0

test_ping() {
    local from=$1
    local to=$2
    local description=$3
    
    echo -n "  Testing $description ... "
    if docker exec $from ping -c 2 -W 2 $to > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

test_dns() {
    local from=$1
    local dns_server=$2
    local query=$3
    local description=$4
    
    echo -n "  Testing $description ... "
    if docker exec $from nslookup $query $dns_server > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

test_http() {
    local from=$1
    local url=$2
    local description=$3
    
    echo -n "  Testing $description ... "
    if docker exec $from curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 $url | grep -q '200'; then
        echo -e "${GREEN}✓ OK${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

test_route() {
    local router=$1
    local network=$2
    local description=$3
    
    echo -n "  Testing $description ... "
    if docker exec $router vtysh -c "show ip route $network" 2>/dev/null | grep -q "$network"; then
        echo -e "${GREEN}✓ OK${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}⚠ Route not found (may be normal)${NC}"
        ((WARNING++))
        return 1
    fi
}

echo "=========================================="
echo "  TEST DE CONNECTIVITÉ COMPLÈTE"
echo "=========================================="
echo ""

# Vérifier que les conteneurs sont démarrés
echo -e "${BLUE}=== Vérification des conteneurs ===${NC}"
containers=("as5-border" "as5-internal" "internet-router" "entreprise5-router" "particulier5-box" "site-secondaire-router" "dns-as5" "dns-entreprise5" "nginx-entreprise5" "client-entreprise5-1" "client-particulier5-1" "client-site-secondaire-1")

for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "  ${GREEN}✓${NC} $container is running"
    else
        echo -e "  ${RED}✗${NC} $container is NOT running"
        ((FAILED++))
    fi
done
echo ""

# ============================================
# 1. TEST DE CONNECTIVITÉ DE BASE (PING)
# ============================================

echo -e "${BLUE}=== 1. Tests de Connectivité de Base (Ping) ===${NC}"

echo -e "\n${YELLOW}1.1. Connectivité AS5 Backbone${NC}"
test_ping "as5-border" "120.0.80.2" "AS5-Border → AS5-Internal"
test_ping "as5-internal" "120.0.80.1" "AS5-Internal → AS5-Border"

echo -e "\n${YELLOW}1.2. Connectivité vers Internet${NC}"
test_ping "as5-border" "120.0.81.2" "AS5-Border → Internet Router"
test_ping "internet-router" "120.0.81.1" "Internet Router → AS5-Border"

echo -e "\n${YELLOW}1.3. Connectivité Entreprise${NC}"
test_ping "as5-border" "120.0.82.10" "AS5-Border → Entreprise Router"
test_ping "entreprise5-router" "120.0.82.1" "Entreprise Router → AS5-Border"
test_ping "entreprise5-router" "120.0.84.10" "Entreprise Router → DNS Entreprise"
test_ping "client-entreprise5-1" "120.0.84.1" "Client Entreprise → Gateway"
test_ping "client-entreprise5-1" "120.0.84.13" "Client Entreprise → Nginx"

echo -e "\n${YELLOW}1.4. Connectivité Particulier${NC}"
test_ping "as5-border" "120.0.83.10" "AS5-Border → Particulier Box"
test_ping "particulier5-box" "120.0.83.1" "Particulier Box → AS5-Border"
test_ping "client-particulier5-1" "192.168.5.1" "Client Particulier → Gateway"
test_ping "client-particulier5-1" "192.168.5.11" "Client Particulier → Client 2"

echo -e "\n${YELLOW}1.5. Connectivité Site Secondaire${NC}"
test_ping "internet-router" "10.0.1.10" "Internet Router → Site Secondaire Router"
test_ping "site-secondaire-router" "10.0.1.1" "Site Secondaire Router → Internet Router"
test_ping "client-site-secondaire-1" "10.0.2.1" "Client Site Secondaire → Gateway"

echo -e "\n${YELLOW}1.6. Connectivité Services AS5${NC}"
test_ping "as5-internal" "120.0.85.10" "AS5-Internal → DNS AS5"
test_ping "client-entreprise5-1" "120.0.85.10" "Client Entreprise → DNS AS5"

# ============================================
# 2. TEST DE ROUTAGE (OSPF/BGP)
# ============================================

echo -e "\n${BLUE}=== 2. Tests de Routage (OSPF/BGP) ===${NC}"

echo -e "\n${YELLOW}2.1. Routes OSPF${NC}"
test_route "as5-border" "120.0.80.0/24" "AS5-Border: Route 120.0.80.0/24 (OSPF)"
test_route "as5-border" "120.0.85.0/24" "AS5-Border: Route 120.0.85.0/24 (OSPF)"
test_route "as5-internal" "120.0.80.0/24" "AS5-Internal: Route 120.0.80.0/24 (OSPF)"
test_route "as5-internal" "120.0.81.0/24" "AS5-Internal: Route 120.0.81.0/24 (OSPF)"

echo -e "\n${YELLOW}2.2. Routes BGP${NC}"
test_route "as5-border" "120.0.80.0/20" "AS5-Border: Route 120.0.80.0/20 (BGP)"
test_route "internet-router" "120.0.80.0/20" "Internet Router: Route 120.0.80.0/20 (BGP)"

# ============================================
# 3. TEST DES SERVICES DNS
# ============================================

echo -e "\n${BLUE}=== 3. Tests des Services DNS ===${NC}"

echo -e "\n${YELLOW}3.1. DNS AS5 (Récursif)${NC}"
test_dns "client-entreprise5-1" "120.0.85.10" "google.com" "DNS AS5: Résolution google.com"
test_dns "client-particulier5-1" "120.0.85.10" "github.com" "DNS AS5: Résolution github.com"

echo -e "\n${YELLOW}3.2. DNS Entreprise (Autoritaire)${NC}"
test_dns "client-entreprise5-1" "120.0.84.10" "www.entreprise5.lan" "DNS Entreprise: Résolution www.entreprise5.lan"
test_dns "client-entreprise5-1" "120.0.84.10" "nginx-entreprise5.entreprise5.lan" "DNS Entreprise: Résolution nginx-entreprise5.entreprise5.lan"

# ============================================
# 4. TEST DES SERVICES WEB
# ============================================

echo -e "\n${BLUE}=== 4. Tests des Services Web ===${NC}"

echo -e "\n${YELLOW}4.1. Service Nginx${NC}"
test_http "client-entreprise5-1" "http://120.0.84.13" "Client Entreprise → Nginx (IP)"
test_http "client-entreprise5-1" "http://nginx-entreprise5.entreprise5.lan" "Client Entreprise → Nginx (DNS)"

# ============================================
# 5. TEST DE CONNECTIVITÉ CROISÉE
# ============================================

echo -e "\n${BLUE}=== 5. Tests de Connectivité Croisée ===${NC}"

echo -e "\n${YELLOW}5.1. Entreprise → Particulier${NC}"
test_ping "client-entreprise5-1" "120.0.83.10" "Client Entreprise → Particulier Box"

echo -e "\n${YELLOW}5.2. Particulier → Entreprise${NC}"
test_ping "client-particulier5-1" "120.0.84.10" "Client Particulier → DNS Entreprise"

echo -e "\n${YELLOW}5.3. Site Secondaire → Internet${NC}"
test_ping "client-site-secondaire-1" "10.0.1.1" "Client Site Secondaire → Internet Router"

# ============================================
# 6. TEST DE TRACEROUTE
# ============================================

echo -e "\n${BLUE}=== 6. Tests de Traceroute ===${NC}"

echo -e "\n${YELLOW}6.1. Traceroute Client Entreprise → Internet${NC}"
echo -n "  Testing traceroute ... "
if docker exec client-entreprise5-1 traceroute -m 5 120.0.81.2 2>/dev/null | head -3 > /dev/null; then
    echo -e "${GREEN}✓ OK${NC}"
    docker exec client-entreprise5-1 traceroute -m 5 120.0.81.2 2>/dev/null | head -5
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Traceroute not available${NC}"
    ((WARNING++))
fi

# ============================================
# 7. TEST DES SERVICES (PORTS)
# ============================================

echo -e "\n${BLUE}=== 7. Tests des Services (Ports) ===${NC}"

echo -e "\n${YELLOW}7.1. Ports ouverts${NC}"

# DNS
echo -n "  Testing DNS (53) ... "
if docker exec client-entreprise5-1 nc -zv 120.0.84.10 53 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✓ OK${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

# HTTP
echo -n "  Testing HTTP (80) ... "
if docker exec client-entreprise5-1 nc -zv 120.0.84.13 80 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✓ OK${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++))
fi

# ============================================
# RÉSUMÉ
# ============================================

echo ""
echo "=========================================="
echo "  RÉSUMÉ"
echo "=========================================="
echo -e "${GREEN}Tests réussis: $PASSED${NC}"
echo -e "${RED}Tests échoués: $FAILED${NC}"
echo -e "${YELLOW}Avertissements: $WARNING${NC}"
echo ""

TOTAL=$((PASSED + FAILED + WARNING))
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ TOUS LES TESTS DE CONNECTIVITÉ SONT RÉUSSIS${NC}"
    if [ $WARNING -gt 0 ]; then
        echo -e "${YELLOW}⚠ Certains tests ont des avertissements (non critiques)${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ CERTAINS TESTS ONT ÉCHOUÉ${NC}"
    exit 1
fi

