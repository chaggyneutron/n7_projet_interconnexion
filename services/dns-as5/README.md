# DNS AS5 - Serveur DNS Récursif

## Description
Ce dossier contient la configuration du serveur DNS récursif de l'AS5, qui fournit la résolution DNS pour tous les clients de l'AS.

## Composant

### dns-as5
- **Rôle** : Serveur DNS récursif
- **Adresse** : 120.0.85.10
- **Port** : 53/udp, 53/tcp
- **Type** : Récursif avec forwarders

## Configuration

### Fichiers
- `docker-compose.yml` : Définition du conteneur
- `config/named.conf` : Configuration Bind9
- `config/named.conf.options` : Options communes

## Fonctionnalités

- **Récursion** : Activée pour les clients AS5
- **Forwarders** : 8.8.8.8, 8.8.4.4 (Google DNS)
- **Accessible depuis** : 120.0.80.0/20, 192.168.5.0/24

## Commandes Utiles

```bash
# Tester la résolution DNS
docker exec client-particulier5-1 nslookup google.com 120.0.85.10

# Vérifier les logs
docker compose logs dns-as5
```

