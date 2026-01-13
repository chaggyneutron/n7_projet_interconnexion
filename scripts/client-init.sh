#!/bin/sh
# Script d'initialisation pour les clients

# Configuration DNS (utiliser le DNS de l'AS5 ou de l'entreprise selon le contexte)
# Pour les clients entreprise, utiliser le DNS entreprise
# Pour les clients particulier, utiliser le DNS AS5

# Récupérer l'adresse IP du conteneur
IP=$(hostname -i | awk '{print $1}')

# Si c'est un client entreprise (120.0.84.x)
if echo "$IP" | grep -q "^120\.0\.84\."; then
    echo "nameserver 120.0.84.10" > /etc/resolv.conf
    echo "nameserver 120.0.85.10" >> /etc/resolv.conf
    # Route par le routeur entreprise
    ip route replace default via 120.0.84.1 dev eth0
    echo "Client entreprise configuré avec DNS entreprise"
# Si c'est un client particulier (192.168.5.x)
elif echo "$IP" | grep -q "^192\.168\.5\."; then
    echo "nameserver 120.0.85.10" > /etc/resolv.conf
    # Route par la box particulier
    ip route replace default via 192.168.5.1 dev eth0
    echo "Client particulier configuré avec DNS AS5"
# Si c'est un client site secondaire (10.0.2.x)
elif echo "$IP" | grep -q "^10\.0\.2\."; then
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    # Route par le routeur site secondaire
    ip route replace default via 10.0.2.1 dev eth0
    echo "Client site secondaire configuré"
fi

echo "Client initialisé: IP=$IP"

