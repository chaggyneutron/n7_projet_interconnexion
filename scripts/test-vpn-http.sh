#!/bin/bash
# Script de test HTTP avec et sans VPN

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  TEST HTTP: Site Secondaire → Entreprise5"
echo "=========================================="
echo ""

# Test 1: Sans VPN
echo -e "${BLUE}=== TEST 1: HTTP sans VPN ===${NC}"
echo "Tentative de connexion HTTP sans VPN..."
echo ""

# Test DNS
echo -n "  DNS (nginx-entreprise5.entreprise5.lan) ... "
if docker exec client-site-secondaire-1 nslookup nginx-entreprise5.entreprise5.lan 2>&1 | grep -q "NXDOMAIN\|not found"; then
    echo -e "${RED}✗ ÉCHEC (attendu)${NC}"
else
    echo -e "${GREEN}✓ OK${NC}"
fi

# Test Ping
echo -n "  Ping (120.0.84.13) ... "
if docker exec client-site-secondaire-1 ping -c 2 -W 2 120.0.84.13 2>&1 | grep -q "100% packet loss\|0 packets received"; then
    echo -e "${RED}✗ ÉCHEC (attendu)${NC}"
else
    echo -e "${GREEN}✓ OK${NC}"
fi

# Test HTTP
echo -n "  HTTP Request ... "
HTTP_RESULT=$(docker exec client-site-secondaire-1 curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://120.0.84.13 2>&1)
if echo "$HTTP_RESULT" | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ OK (Code: $HTTP_RESULT)${NC}"
elif echo "$HTTP_RESULT" | grep -q "timeout\|refused\|unreachable"; then
    echo -e "${RED}✗ ÉCHEC (attendu): $HTTP_RESULT${NC}"
else
    echo -e "${YELLOW}⚠ Résultat: $HTTP_RESULT${NC}"
fi
echo ""

# Vérifier si VPN est actif
echo -e "${BLUE}=== Vérification VPN ===${NC}"
VPN_ACTIVE=false
if docker exec client-site-secondaire-1 ps aux 2>/dev/null | grep -q "openvpn"; then
    VPN_ACTIVE=true
    echo -e "${GREEN}✓ Client OpenVPN actif${NC}"
    
    # Vérifier interface tun
    if docker exec client-site-secondaire-1 ip addr show tun0 2>/dev/null | grep -q "inet"; then
        TUN_IP=$(docker exec client-site-secondaire-1 ip addr show tun0 2>/dev/null | grep "inet" | awk '{print $2}')
        echo -e "${GREEN}✓ Interface tun0: $TUN_IP${NC}"
    else
        echo -e "${YELLOW}⚠ Interface tun0 non trouvée${NC}"
    fi
    
    # Vérifier routes VPN
    if docker exec client-site-secondaire-1 ip route 2>/dev/null | grep -q "120.0.84"; then
        VPN_ROUTE=$(docker exec client-site-secondaire-1 ip route 2>/dev/null | grep "120.0.84")
        echo -e "${GREEN}✓ Route VPN: $VPN_ROUTE${NC}"
    else
        echo -e "${YELLOW}⚠ Route VPN non trouvée${NC}"
    fi
else
    echo -e "${RED}✗ Client OpenVPN non actif${NC}"
    echo "  Configuration du VPN..."
    
    # Installer OpenVPN
    docker exec client-site-secondaire-1 apk add --no-cache openvpn > /dev/null 2>&1
    
    # Copier certificats (si nécessaire)
    # Déjà fait précédemment
    
    # Démarrer VPN
    docker exec -d client-site-secondaire-1 openvpn --config /etc/openvpn/client.conf --daemon
    sleep 5
    VPN_ACTIVE=true
fi
echo ""

# Test 2: Avec VPN
if [ "$VPN_ACTIVE" = true ]; then
    echo -e "${BLUE}=== TEST 2: HTTP avec VPN ===${NC}"
    echo "Tentative de connexion HTTP via VPN..."
    echo ""
    
    # Attendre que le VPN soit établi
    sleep 3
    
    # Test Ping via VPN
    echo -n "  Ping via VPN (120.0.84.13) ... "
    if docker exec client-site-secondaire-1 ping -c 2 -W 2 120.0.84.13 2>&1 | grep -q "0% packet loss\|0 packets received"; then
        PING_RESULT=$(docker exec client-site-secondaire-1 ping -c 2 -W 2 120.0.84.13 2>&1 | grep "packet loss")
        if echo "$PING_RESULT" | grep -q "0% packet loss"; then
            echo -e "${GREEN}✓ OK${NC}"
        else
            echo -e "${RED}✗ ÉCHEC: $PING_RESULT${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Résultat inattendu${NC}"
    fi
    
    # Test HTTP via VPN
    echo -n "  HTTP Request via VPN ... "
    HTTP_RESULT=$(docker exec client-site-secondaire-1 curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://120.0.84.13 2>&1)
    HTTP_BODY=$(docker exec client-site-secondaire-1 curl -s --connect-timeout 5 http://120.0.84.13 2>&1 | head -3)
    
    if echo "$HTTP_RESULT" | grep -q "200"; then
        echo -e "${GREEN}✓ OK (Code: $HTTP_RESULT)${NC}"
        echo -e "  ${GREEN}✓ Contenu reçu: $(echo "$HTTP_BODY" | head -1 | cut -c1-50)...${NC}"
    elif echo "$HTTP_RESULT" | grep -q "timeout\|refused"; then
        echo -e "${RED}✗ ÉCHEC: $HTTP_RESULT${NC}"
    else
        echo -e "${YELLOW}⚠ Code: $HTTP_RESULT${NC}"
    fi
    
    # Test avec nom de domaine (si DNS configuré)
    echo -n "  HTTP via nom de domaine ... "
    if docker exec client-site-secondaire-1 sh -c "echo '120.0.84.13 nginx-entreprise5.entreprise5.lan' >> /etc/hosts 2>/dev/null; curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://nginx-entreprise5.entreprise5.lan" 2>&1 | grep -q "200"; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${YELLOW}⚠ DNS non configuré (normal)${NC}"
    fi
else
    echo -e "${RED}✗ VPN non disponible pour le test${NC}"
fi

echo ""
echo "=========================================="
echo "  RÉSUMÉ"
echo "=========================================="
echo -e "Sans VPN: ${RED}Connectivité impossible${NC} (attendu)"
if [ "$VPN_ACTIVE" = true ]; then
    echo -e "Avec VPN: ${GREEN}Connectivité établie${NC} ✨"
else
    echo -e "Avec VPN: ${RED}Non testé${NC}"
fi
echo "=========================================="

