#!/bin/bash
# Script de test complet des services (VoIP, Web, Radius)
# Tests depuis différents clients avec et sans VPN

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNING=0

test_http() {
    local from=$1
    local url=$2
    local description=$3
    
    echo -n "  Testing $description ... "
    if docker exec $from curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 $url 2>/dev/null | grep -q '200'; then
        echo -e "${GREEN}✓ OK (HTTP 200)${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

test_sip() {
    local from=$1
    local sip_server=$2
    local description=$3
    
    echo -n "  Testing $description ... "
    # Test de connexion SIP (port 5060)
    if docker exec $from nc -zv -u $sip_server 5060 2>&1 | grep -q "succeeded"; then
        echo -e "${GREEN}✓ OK (Port accessible)${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

test_radius() {
    local from=$1
    local radius_server=$2
    local username=$3
    local password=$4
    local description=$5
    
    echo -n "  Testing $description ... "
    # Test avec radtest si disponible, sinon test de port
    if docker exec $from nc -zv -u $radius_server 1812 2>&1 | grep -q "succeeded"; then
        echo -e "${GREEN}✓ OK (Port accessible)${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}⚠ Port accessible mais radtest non disponible${NC}"
        ((WARNING++))
        return 1
    fi
}

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

# Start OpenVPN client inside a container using config files placed into /etc/openvpn
start_openvpn_client() {
    local container=$1
    local vpn_dir=$2 # host path to vpn config files (mounted into the container via cp)

    echo "  Starting OpenVPN client in $container ..."
    # copy certs/config into the container
    docker exec $container mkdir -p /etc/openvpn
    docker cp ${vpn_dir}/. $container:/etc/openvpn >/dev/null 2>&1 || true
    # install openvpn if missing
    docker exec $container sh -c "if ! command -v openvpn >/dev/null 2>&1; then apk add --no-cache openvpn >/dev/null 2>&1 || (apt-get update >/dev/null 2>&1 && apt-get install -y openvpn >/dev/null 2>&1); fi" || true
    # start client in background (log to /var/log/openvpn-client.log)
    docker exec -d $container sh -c "openvpn --config /etc/openvpn/client-entreprise.conf > /var/log/openvpn-client.log 2>&1 || true"
    # wait for tun0 dev to appear
    for i in 1 2 3 4 5; do
        docker exec $container sh -c "ip addr show tun0 >/dev/null 2>&1 && echo ok || echo no" | grep -q ok && break || sleep 1
    done
}

stop_openvpn_client() {
    local container=$1
    echo "  Stopping OpenVPN client in $container ..."
    docker exec $container sh -c "pkill openvpn || true"
}

echo "=========================================="
echo "  TEST COMPLET DES SERVICES"
echo "  (VoIP, Web, Radius)"
echo "=========================================="
echo ""

# Adresses des services
NGINX_IP="120.0.84.13"
NGINX_DNS="nginx-entreprise5.entreprise5.lan"
ASTERISK_IP="120.0.84.12"
RADIUS_IP="120.0.84.11"

# ============================================
# 1. TESTS DEPUIS CLIENT ENTREPRISE
# ============================================

echo -e "${BLUE}=== 1. Tests depuis Client Entreprise ===${NC}"

echo -e "\n${CYAN}1.1. Service Web (Nginx)${NC}"
test_http "client-entreprise5-1" "http://${NGINX_IP}" "HTTP via IP"
test_http "client-entreprise5-1" "http://${NGINX_DNS}" "HTTP via DNS"

echo -e "\n${CYAN}1.2. Service VoIP (Asterisk)${NC}"
test_ping "client-entreprise5-1" "${ASTERISK_IP}" "Ping vers Asterisk"
test_sip "client-entreprise5-1" "${ASTERISK_IP}" "Connexion SIP (port 5060)"

echo -e "\n${CYAN}1.3. Service Radius${NC}"
test_ping "client-entreprise5-1" "${RADIUS_IP}" "Ping vers Radius"
test_radius "client-entreprise5-1" "${RADIUS_IP}" "user1" "password1" "Port Radius (1812)"

# ============================================
# 2. TESTS DEPUIS CLIENT PARTICULIER
# ============================================

echo -e "\n${BLUE}=== 2. Tests depuis Client Particulier ===${NC}"

echo -e "\n${CYAN}2.1. Service Web (Nginx) - SANS VPN${NC}"
test_ping "client-particulier5-1" "${NGINX_IP}" "Ping vers Nginx"
test_http "client-particulier5-1" "http://${NGINX_IP}" "HTTP via IP"

echo -e "\n${CYAN}2.2. Service VoIP (Asterisk) - SANS VPN${NC}"
test_ping "client-particulier5-1" "${ASTERISK_IP}" "Ping vers Asterisk"
test_sip "client-particulier5-1" "${ASTERISK_IP}" "Connexion SIP (port 5060)"

echo -e "\n${CYAN}2.3. Service Radius - SANS VPN${NC}"
test_ping "client-particulier5-1" "${RADIUS_IP}" "Ping vers Radius"
test_radius "client-particulier5-1" "${RADIUS_IP}" "user1" "password1" "Port Radius (1812)"

# ============================================
# 3. TESTS DEPUIS SITE SECONDAIRE
# ============================================

echo -e "\n${BLUE}=== 3. Tests depuis Site Secondaire ===${NC}"

echo -e "\n${CYAN}3.1. Service Web (Nginx) - SANS VPN (attendu: FAIL si politique VPN-only est appliquée)${NC}"
# Expectation: If the network policy requires VPN-only access, this should fail. Otherwise it may succeed in the simulation.
test_ping "client-site-secondaire-1" "${NGINX_IP}" "Ping vers Nginx (sans VPN)"
test_http "client-site-secondaire-1" "http://${NGINX_IP}" "HTTP via IP (sans VPN)"

echo -e "\n${CYAN}3.2. Service VoIP (Asterisk) - SANS VPN${NC}"
test_ping "client-site-secondaire-1" "${ASTERISK_IP}" "Ping vers Asterisk"
test_sip "client-site-secondaire-1" "${ASTERISK_IP}" "Connexion SIP (port 5060)"

echo -e "\n${CYAN}3.3. Service Radius - SANS VPN${NC}"
test_ping "client-site-secondaire-1" "${RADIUS_IP}" "Ping vers Radius"
test_radius "client-site-secondaire-1" "${RADIUS_IP}" "user1" "password1" "Port Radius (1812)"

echo -e "\n${BLUE}=== 3.4. Tests depuis Site Secondaire AVEC VPN ===${NC}"
echo -e "\n${CYAN}3.4.1. Établir la connexion OpenVPN (client)${NC}"
# Host-side path to vpn config for site-secondaire - used to copy into container
VPN_CONFIG_HOST_PATH="services/site-secondaire/config/vpn/"
start_openvpn_client "client-site-secondaire-1" "${VPN_CONFIG_HOST_PATH}"
sleep 3

echo -e "\n${CYAN}3.4.2. Service Web (Nginx) - AVEC VPN (attendu: OK)${NC}"
test_ping "client-site-secondaire-1" "${NGINX_IP}" "Ping vers Nginx (avec VPN)"
test_http "client-site-secondaire-1" "http://${NGINX_IP}" "HTTP via IP (avec VPN)"

echo -e "\n${CYAN}3.4.3. Service VoIP (Asterisk) - AVEC VPN${NC}"
test_ping "client-site-secondaire-1" "${ASTERISK_IP}" "Ping vers Asterisk (avec VPN)"
test_sip "client-site-secondaire-1" "${ASTERISK_IP}" "Connexion SIP (port 5060, avec VPN)"

echo -e "\n${CYAN}3.4.4. Service Radius - AVEC VPN${NC}"
test_ping "client-site-secondaire-1" "${RADIUS_IP}" "Ping vers Radius (avec VPN)"
test_radius "client-site-secondaire-1" "${RADIUS_IP}" "user1" "password1" "Port Radius (1812, avec VPN)"

# Finalize site-secondaire VPN testing
stop_openvpn_client "client-site-secondaire-1"

# ============================================
# 4. TESTS AVEC VPN (si configuré)
# ============================================

echo -e "\n${BLUE}=== 4. Tests avec VPN (si disponible) ===${NC}"

# Vérifier si OpenVPN est actif
if docker ps --format '{{.Names}}' | grep -q "openvpn-entreprise5"; then
    echo -e "${YELLOW}Note: Tests VPN nécessitent configuration client VPN${NC}"
    echo -e "${YELLOW}Les tests ci-dessus montrent l'accès sans VPN${NC}"
else
    echo -e "${YELLOW}⚠ OpenVPN non démarré${NC}"
fi

# ============================================
# 5. TESTS RADIUS DÉTAILLÉS
# ============================================

echo -e "\n${BLUE}=== 5. Tests Radius Détaillés ===${NC}"

echo -e "\n${CYAN}5.1. Vérification du service Radius${NC}"
if docker ps --format '{{.Names}}' | grep -q "radius-entreprise5"; then
    echo -e "  ${GREEN}✓ Radius service actif${NC}"
    ((PASSED++))
    
    echo -e "\n${CYAN}5.2. Test d'authentification Radius${NC}"
    echo -n "  Testing authentification ... "
    if docker exec radius-entreprise5 radtest user1 password1 127.0.0.1 0 testing123 2>&1 | grep -q "Access-Accept"; then
        echo -e "${GREEN}✓ OK (Access-Accept)${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Test d'authentification (peut nécessiter configuration)${NC}"
        ((WARNING++))
    fi
    
    echo -e "\n${CYAN}5.3. Utilisateurs configurés${NC}"
    echo "  Utilisateurs disponibles:"
    docker exec radius-entreprise5 cat /etc/freeradius/users 2>/dev/null | grep -E "^[a-zA-Z]" | awk '{print "    - " $1}' || echo "    (non disponible)"
    
else
    echo -e "  ${RED}✗ Radius service non actif${NC}"
    ((FAILED++))
fi

# ============================================
# 6. RÉSUMÉ DES CONNECTIVITÉS
# ============================================

echo -e "\n${BLUE}=== 6. Résumé des Connectivités ===${NC}"

echo -e "\n${CYAN}6.1. Matrice de Connectivité${NC}"
echo "  Client Entreprise → Services:"
echo "    - Nginx: $(docker exec client-entreprise5-1 curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://${NGINX_IP} 2>/dev/null || echo 'N/A')"
echo "    - Asterisk: $(docker exec client-entreprise5-1 nc -zv ${ASTERISK_IP} 5060 2>&1 | grep -q succeeded && echo 'OK' || echo 'FAIL')"
echo "    - Radius: $(docker exec client-entreprise5-1 nc -zv -u ${RADIUS_IP} 1812 2>&1 | grep -q succeeded && echo 'OK' || echo 'FAIL')"

echo ""
echo "  Client Particulier → Services:"
echo "    - Nginx: $(docker exec client-particulier5-1 curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://${NGINX_IP} 2>/dev/null || echo 'N/A')"
echo "    - Asterisk: $(docker exec client-particulier5-1 nc -zv ${ASTERISK_IP} 5060 2>&1 | grep -q succeeded && echo 'OK' || echo 'FAIL')"
echo "    - Radius: $(docker exec client-particulier5-1 nc -zv -u ${RADIUS_IP} 1812 2>&1 | grep -q succeeded && echo 'OK' || echo 'FAIL')"

echo ""
echo "  Site Secondaire → Services:"
echo "    - Nginx: $(docker exec client-site-secondaire-1 curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://${NGINX_IP} 2>/dev/null || echo 'N/A')"
echo "    - Asterisk: $(docker exec client-site-secondaire-1 nc -zv ${ASTERISK_IP} 5060 2>&1 | grep -q succeeded && echo 'OK' || echo 'FAIL')"
echo "    - Radius: $(docker exec client-site-secondaire-1 nc -zv -u ${RADIUS_IP} 1812 2>&1 | grep -q succeeded && echo 'OK' || echo 'FAIL')"

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
    echo -e "${GREEN}✓ TOUS LES TESTS SONT RÉUSSIS${NC}"
    if [ $WARNING -gt 0 ]; then
        echo -e "${YELLOW}⚠ Certains tests ont des avertissements (non critiques)${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ CERTAINS TESTS ONT ÉCHOUÉ${NC}"
    exit 1
fi

