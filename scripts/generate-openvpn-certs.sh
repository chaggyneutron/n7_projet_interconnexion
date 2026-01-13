#!/bin/bash
# Script de génération des certificats OpenVPN
# À exécuter une fois pour générer les certificats nécessaires

set -e

EASYRSA_DIR="/tmp/easyrsa"
VPN_DIRS=("config/vpn/openvpn-entreprise5" "config/vpn/openvpn-site-secondaire")

echo "=== Génération des certificats OpenVPN ==="

# Installer easy-rsa si nécessaire
if ! command -v easyrsa &> /dev/null; then
    echo "Installation de easy-rsa..."
    if [ -f /etc/debian_version ]; then
        apt-get update && apt-get install -y easy-rsa
    else
        echo "Veuillez installer easy-rsa manuellement"
        exit 1
    fi
fi

# Créer le répertoire easyrsa
mkdir -p "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

# Initialiser PKI
if [ ! -d "pki" ]; then
    easyrsa init-pki
    easyrsa build-ca nopass
    easyrsa gen-dh
    openvpn --genkey --secret ta.key
fi

# Générer certificat serveur pour entreprise5
easyrsa build-server-full server-entreprise5 nopass
cp pki/ca.crt ../config/vpn/openvpn-entreprise5/ca.crt
cp pki/issued/server-entreprise5.crt ../config/vpn/openvpn-entreprise5/server.crt
cp pki/private/server-entreprise5.key ../config/vpn/openvpn-entreprise5/server.key
cp pki/dh.pem ../config/vpn/openvpn-entreprise5/dh.pem
cp ta.key ../config/vpn/openvpn-entreprise5/ta.key

# Générer certificat serveur pour site-secondaire
easyrsa build-server-full server-site-secondaire nopass
cp pki/ca.crt ../config/vpn/openvpn-site-secondaire/ca.crt
cp pki/issued/server-site-secondaire.crt ../config/vpn/openvpn-site-secondaire/server.crt
cp pki/private/server-site-secondaire.key ../config/vpn/openvpn-site-secondaire/server.key
cp pki/dh.pem ../config/vpn/openvpn-site-secondaire/dh.pem
cp ta.key ../config/vpn/openvpn-site-secondaire/ta.key

# Générer certificat client pour site-secondaire
easyrsa build-client-full client-site-secondaire nopass
cp pki/issued/client-site-secondaire.crt ../config/vpn/openvpn-entreprise5/client-site-secondaire.crt
cp pki/private/client-site-secondaire.key ../config/vpn/openvpn-entreprise5/client-site-secondaire.key

# Générer certificat client pour particulier
easyrsa build-client-full client-particulier5 nopass
cp pki/issued/client-particulier5.crt ../config/vpn/openvpn-entreprise5/client-particulier5.crt
cp pki/private/client-particulier5.key ../config/vpn/openvpn-entreprise5/client-particulier5.key

echo "=== Certificats générés avec succès ==="
echo "Les certificats sont dans config/vpn/openvpn-entreprise5/ et config/vpn/openvpn-site-secondaire/"

