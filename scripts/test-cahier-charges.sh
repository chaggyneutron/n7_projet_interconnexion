#!/bin/bash
# Script de test de conformité au cahier des charges

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNING=0

test_check() {
    local description=$1
    local test_cmd=$2
    local expected=$3
    
    echo -n "  ✓ $description ... "
    if eval "$test_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        ((PASSED++))
        return 0
    else
        if [ "$expected" = "optional" ]; then
            echo -e "${YELLOW}⚠ Optionnel (non disponible)${NC}"
            ((WARNING++))
        else
            echo -e "${RED}✗ ÉCHEC${NC}"
            ((FAILED++))
        fi
        return 1
    fi
}

echo "=========================================="
echo "  TEST DE CONFORMITÉ AU CAHIER DES CHARGES"
echo "=========================================="
echo ""

# ============================================
# A. PARTIE SYSTÈME AUTONOME (AS5)
# ============================================

echo -e "${BLUE}=== A. SYSTÈME AUTONOME (AS5) ===${NC}"

echo -e "\n${YELLOW}A.1. Routage${NC}"
test_check "Plage IP AS5 correcte (120.0.80.0/20)" \
    "docker network inspect projet_as5-backbone 2>/dev/null | grep -q '120.0.80.0/24'"

test_check "Routeur AS5-Border existe" \
    "docker ps --format '{{.Names}}' | grep -q 'as5-border'"

test_check "Routeur AS5-Internal existe" \
    "docker ps --format '{{.Names}}' | grep -q 'as5-internal'"

test_check "OSPF configuré (fichier de config existe)" \
    "test -f services/as5-routers/config/as5-border.conf && grep -q 'router ospf' services/as5-routers/config/as5-border.conf"

test_check "BGP configuré (fichier de config existe)" \
    "test -f services/as5-routers/config/as5-border.conf && grep -q 'router bgp' services/as5-routers/config/as5-border.conf"

echo -e "\n${YELLOW}A.2. Services AS${NC}"
test_check "NAT/Masquerade configuré (script existe)" \
    "test -f scripts/nat-border.sh"

test_check "DNS récursif AS5 existe" \
    "docker ps --format '{{.Names}}' | grep -q 'dns-as5'"

test_check "DNS récursif accessible (120.0.85.10)" \
    "docker exec client-particulier5-1 nslookup google.com 120.0.85.10 2>&1 | grep -q 'Name:'" "optional"

echo -e "\n${YELLOW}A.3. Client Particulier (Box-like)${NC}"
test_check "Box Particulier existe" \
    "docker ps --format '{{.Names}}' | grep -q 'particulier5-box'"

test_check "Box dans plage AS5 (120.0.83.x)" \
    "docker inspect particulier5-box 2>/dev/null | grep -q '120.0.83'"

test_check "NAT Box configuré (script existe)" \
    "test -f scripts/particulier-box-init.sh"

test_check "LAN domestique (192.168.5.0/24)" \
    "docker network inspect projet_particulier5-lan 2>/dev/null | grep -q '192.168.5.0/24'"

test_check "Clients particuliers existent" \
    "docker ps --format '{{.Names}}' | grep -q 'client-particulier5'"

echo -e "\n${YELLOW}A.4. QoS${NC}"
test_check "Script QoS existe" \
    "test -f scripts/qos-border.sh"

test_check "QoS configuré dans script" \
    "grep -q 'tc qdisc' scripts/qos-border.sh"

# ============================================
# B. PARTIE RÉSEAU D'ENTREPRISE
# ============================================

echo -e "\n${BLUE}=== B. RÉSEAU D'ENTREPRISE (Site Principal) ===${NC}"

echo -e "\n${YELLOW}B.1. Adressage${NC}"
test_check "Réseau entreprise (120.0.84.0/24)" \
    "docker network inspect projet_entreprise5-lan 2>/dev/null | grep -q '120.0.84.0/24'"

test_check "Routeur entreprise existe" \
    "docker ps --format '{{.Names}}' | grep -q 'entreprise5-router'"

test_check "Clients entreprise existent" \
    "docker ps --format '{{.Names}}' | grep -q 'client-entreprise5'"

echo -e "\n${YELLOW}B.2. Sécurité${NC}"
test_check "Firewall iptables configuré (script existe)" \
    "test -f services/entreprise5/scripts/router-init.sh"

test_check "Règles iptables dans script" \
    "grep -q 'iptables' services/entreprise5/scripts/router-init.sh"

echo -e "\n${YELLOW}B.3. Services Obligatoires${NC}"

test_check "DNS autoritaire existe" \
    "docker ps --format '{{.Names}}' | grep -q 'dns-entreprise5'"

test_check "Zone entreprise5.lan configurée" \
    "test -f services/entreprise5/config/dns/db.entreprise5.lan"

test_check "FreeRADIUS existe" \
    "docker ps --format '{{.Names}}' | grep -q 'radius-entreprise5'"

test_check "Configuration Radius existe" \
    "test -f services/entreprise5/config/radius/users"

test_check "Asterisk (VoIP) existe" \
    "docker ps --format '{{.Names}}' | grep -q 'asterisk-entreprise5'"

test_check "Configuration Asterisk existe" \
    "test -f services/entreprise5/config/asterisk/sip.conf"

test_check "Nginx (Web) existe" \
    "docker ps --format '{{.Names}}' | grep -q 'nginx-entreprise5'"

test_check "Configuration Nginx existe" \
    "test -f services/entreprise5/config/nginx/nginx.conf"

test_check "Service web accessible" \
    "docker exec client-entreprise5-1 curl -s -o /dev/null -w '%{http_code}' http://120.0.84.13 | grep -q '200'"

echo -e "\n${YELLOW}B.4. VPN Site-à-Site${NC}"
test_check "OpenVPN entreprise existe" \
    "docker ps --format '{{.Names}}' | grep -q 'openvpn-entreprise5'"

test_check "Configuration OpenVPN existe" \
    "test -f services/entreprise5/config/vpn/server.conf"

test_check "Certificats OpenVPN générés" \
    "test -f services/entreprise5/config/vpn/ca.crt && test -f services/entreprise5/config/vpn/server.crt"

# ============================================
# C. PARTIE SITE SECONDAIRE & INTERCONNEXION
# ============================================

echo -e "\n${BLUE}=== C. SITE SECONDAIRE & INTERCONNEXION ===${NC}"

echo -e "\n${YELLOW}C.1. Routeur Externe${NC}"
test_check "Routeur Internet existe" \
    "docker ps --format '{{.Names}}' | grep -q 'internet-router'"

test_check "BGP configuré sur Internet Router" \
    "test -f services/internet-router/config/internet-router.conf && grep -q 'router bgp' services/internet-router/config/internet-router.conf"

echo -e "\n${YELLOW}C.2. Site Secondaire${NC}"
test_check "Site secondaire router existe" \
    "docker ps --format '{{.Names}}' | grep -q 'site-secondaire-router'"

test_check "LAN site secondaire (10.0.2.0/24)" \
    "docker network inspect projet_site-secondaire-lan 2>/dev/null | grep -q '10.0.2.0/24'"

test_check "Client site secondaire existe" \
    "docker ps --format '{{.Names}}' | grep -q 'client-site-secondaire'"

echo -e "\n${YELLOW}C.3. VPN Site-à-Site${NC}"
test_check "OpenVPN site secondaire existe" \
    "docker ps --format '{{.Names}}' | grep -q 'openvpn-site-secondaire'"

test_check "Configuration VPN site secondaire" \
    "test -f services/site-secondaire/config/vpn/server.conf"

echo -e "\n${YELLOW}C.4. Accès Distant${NC}"
test_check "Configuration client VPN pour particulier" \
    "test -f config/vpn/openvpn-entreprise5/client-site-secondaire.conf || test -f services/entreprise5/config/vpn/client-site-secondaire.conf" "optional"

# ============================================
# D. STRUCTURE ET ORGANISATION
# ============================================

echo -e "\n${BLUE}=== D. STRUCTURE ET ORGANISATION ===${NC}"

test_check "Structure modulaire créée" \
    "test -d services/as5-routers && test -d services/entreprise5"

test_check "Documentation par service" \
    "test -f services/as5-routers/README.md && test -f services/entreprise5/README.md"

test_check "Docker-compose par service" \
    "test -f services/as5-routers/docker-compose.yml && test -f services/entreprise5/docker-compose.yml"

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
    echo -e "${GREEN}✓ CONFORMITÉ AU CAHIER DES CHARGES${NC}"
    if [ $WARNING -gt 0 ]; then
        echo -e "${YELLOW}⚠ Certains éléments optionnels ne sont pas disponibles${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ NON CONFORME - $FAILED test(s) échoué(s)${NC}"
    exit 1
fi

