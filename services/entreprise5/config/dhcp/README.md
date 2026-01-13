# Serveur DHCP - Entreprise 5

## 📋 Description

Serveur DHCP pour le réseau entreprise (120.0.84.0/24).

## 🔧 Configuration

### Fichier de configuration
- `dhcpd.conf` : Configuration principale du serveur DHCP

### Paramètres

- **Réseau** : 120.0.84.0/24
- **Plage DHCP** : 120.0.84.100 - 120.0.84.200
- **Gateway** : 120.0.84.1 (Entreprise Router)
- **DNS** : 120.0.84.10 (DNS Entreprise), 120.0.85.10 (DNS AS5)
- **Domaine** : entreprise5.lan
- **Lease time** : 3600s (1h) par défaut, 7200s (2h) maximum

## 🚀 Utilisation

Le serveur DHCP démarre automatiquement avec le service entreprise.

### Vérifier le statut

```bash
docker logs dhcp-entreprise5
```

### Voir les baux DHCP

```bash
docker exec dhcp-entreprise5 cat /var/lib/dhcp/dhcpd.leases
```

## 📝 Notes

- Les clients existants ont des IP statiques configurées via Docker
- Pour utiliser DHCP, retirer l'IP statique de la configuration Docker
- Les réservations d'adresses sont disponibles dans `dhcpd.conf` (commentées)

## 🔄 Migration vers DHCP

Pour migrer un client vers DHCP :

1. Retirer `ipv4_address` de la configuration Docker
2. Redémarrer le client
3. Le client recevra automatiquement une adresse de la plage DHCP

