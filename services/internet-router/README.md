# Routeur Internet (AS1)

## Description
Ce dossier contient la configuration du routeur Internet/AS externe qui simule la connexion à Internet ou à un autre AS.

## Composant

### internet-router
- **Rôle** : Routeur Internet/AS1
- **Fonctions** :
  - Routage BGP vers AS5
  - Connexion au backbone Internet
  - Connexion au site secondaire
- **Interfaces** :
  - `eth0` : Lien vers AS5 (120.0.81.2/24)
  - `eth1` : Backbone Internet (10.0.0.1/24)
  - `eth2` : Lien vers Site Secondaire (10.0.1.1/24)

## Configuration

### Fichiers
- `docker-compose.yml` : Définition du conteneur
- `config/internet-router.conf` : Configuration FRR

## Protocoles

### BGP
- **AS** : 1
- **Neighbors** :
  - AS5-Border (AS 5) : 120.0.81.1
- **Réseaux annoncés** :
  - 10.0.0.0/24 (Backbone Internet)
  - 10.0.1.0/24 (Lien Site Secondaire)

## Commandes Utiles

```bash
# Vérifier les voisins BGP
docker exec internet-router vtysh -c "show ip bgp summary"

# Vérifier les routes
docker exec internet-router vtysh -c "show ip route"
```

