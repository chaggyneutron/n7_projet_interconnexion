#!/bin/bash
# Script simplifié pour générer les certificats OpenVPN

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VPN_DIR="$PROJECT_DIR/config/vpn"
EASYRSA_DIR="/tmp/easyrsa-$$"

echo "=== Génération des certificats OpenVPN ==="
echo "VPN_DIR: $VPN_DIR"

# Créer les répertoires VPN si nécessaire
mkdir -p "$VPN_DIR/openvpn-entreprise5"
mkdir -p "$VPN_DIR/openvpn-site-secondaire"

# Créer un répertoire temporaire
mkdir -p "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

# Utiliser easyrsa si disponible, sinon créer des certificats basiques
if command -v easyrsa &> /dev/null || [ -f /usr/share/easy-rsa/easyrsa ]; then
    EASYRSA_SCRIPT=$(which easyrsa || echo /usr/share/easy-rsa/easyrsa)
    
    # Initialiser PKI
    $EASYRSA_SCRIPT init-pki <<EOF
yes
EOF
    
    # Créer CA
    $EASYRSA_SCRIPT build-ca nopass <<EOF

EOF
    
    # Générer DH
    $EASYRSA_SCRIPT gen-dh
    
    # Générer ta.key
    openvpn --genkey --secret ta.key 2>/dev/null || dd if=/dev/urandom of=ta.key bs=1 count=32 2>/dev/null
    
    # Certificats serveur entreprise
    $EASYRSA_SCRIPT build-server-full server-entreprise5 nopass <<EOF

EOF
    
    # Certificats serveur site secondaire
    $EASYRSA_SCRIPT build-server-full server-site-secondaire nopass <<EOF

EOF
    
    # Certificats clients
    $EASYRSA_SCRIPT build-client-full client-site-secondaire nopass <<EOF

EOF
    
    $EASYRSA_SCRIPT build-client-full client-particulier5 nopass <<EOF

EOF
    
    # Copier les fichiers
    cp pki/ca.crt "$VPN_DIR/openvpn-entreprise5/"
    cp pki/issued/server-entreprise5.crt "$VPN_DIR/openvpn-entreprise5/server.crt"
    cp pki/private/server-entreprise5.key "$VPN_DIR/openvpn-entreprise5/server.key"
    cp pki/dh.pem "$VPN_DIR/openvpn-entreprise5/dh.pem"
    cp ta.key "$VPN_DIR/openvpn-entreprise5/ta.key"
    
    cp pki/ca.crt "$VPN_DIR/openvpn-site-secondaire/"
    cp pki/issued/server-site-secondaire.crt "$VPN_DIR/openvpn-site-secondaire/server.crt"
    cp pki/private/server-site-secondaire.key "$VPN_DIR/openvpn-site-secondaire/server.key"
    cp pki/dh.pem "$VPN_DIR/openvpn-site-secondaire/dh.pem"
    cp ta.key "$VPN_DIR/openvpn-site-secondaire/ta.key"
    
    cp pki/issued/client-site-secondaire.crt "$VPN_DIR/openvpn-entreprise5/client-site-secondaire.crt"
    cp pki/private/client-site-secondaire.key "$VPN_DIR/openvpn-entreprise5/client-site-secondaire.key"
    
    cp pki/issued/client-particulier5.crt "$VPN_DIR/openvpn-entreprise5/client-particulier5.crt"
    cp pki/private/client-particulier5.key "$VPN_DIR/openvpn-entreprise5/client-particulier5.key"
    
    echo "Certificats générés avec succès"
else
    echo "easyrsa non disponible, création de certificats basiques avec openssl..."
    # Créer des certificats basiques avec openssl
    openssl genrsa -out ca.key 2048
    openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=VPN-CA"
    
    # Certificats serveur
    openssl genrsa -out server-entreprise5.key 2048
    openssl req -new -key server-entreprise5.key -out server-entreprise5.csr -subj "/CN=server-entreprise5"
    openssl x509 -req -days 3650 -in server-entreprise5.csr -CA ca.crt -CAkey ca.key -out server-entreprise5.crt
    
    # DH params
    openssl dhparam -out dh.pem 2048
    
    # ta.key
    openvpn --genkey --secret ta.key 2>/dev/null || dd if=/dev/urandom of=ta.key bs=1 count=32
    
    # Copier
    cp ca.crt "$VPN_DIR/openvpn-entreprise5/"
    cp server-entreprise5.crt "$VPN_DIR/openvpn-entreprise5/server.crt"
    cp server-entreprise5.key "$VPN_DIR/openvpn-entreprise5/server.key"
    cp dh.pem "$VPN_DIR/openvpn-entreprise5/dh.pem"
    cp ta.key "$VPN_DIR/openvpn-entreprise5/ta.key"
    
    cp ca.crt "$VPN_DIR/openvpn-site-secondaire/"
    cp server-entreprise5.crt "$VPN_DIR/openvpn-site-secondaire/server.crt"
    cp server-entreprise5.key "$VPN_DIR/openvpn-site-secondaire/server.key"
    cp dh.pem "$VPN_DIR/openvpn-site-secondaire/dh.pem"
    cp ta.key "$VPN_DIR/openvpn-site-secondaire/ta.key"
    
    echo "Certificats basiques générés"
fi

# Nettoyer
cd ..
rm -rf "$EASYRSA_DIR"

echo "=== Certificats prêts ==="

