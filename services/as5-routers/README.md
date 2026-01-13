# Routeurs AS5

## Description
Ce dossier contient la configuration des routeurs du Système Autonome 5 (AS5).

## Composants

### as5-border
- **Rôle** : Routeur de bordure AS5
- **Fonctions** :
  - Routage OSPF (interne AS5)
  - Routage BGP (externe vers AS1/Internet)
  - NAT/Masquerade pour le trafic sortant
  - QoS (Quality of Service) pour prioriser le trafic entreprise
- **Interfaces** :
  - `eth0` : Backbone AS5 (120.0.80.1/24)
  - `eth1` : Lien vers Internet (120.0.81.1/24)
  - `eth2` : Lien vers Entreprise (120.0.82.1/24)
  - `eth3` : Lien vers Particulier (120.0.83.1/24)

### as5-internal
- **Rôle** : Routeur interne AS5
- **Fonctions** :
  - Routage OSPF (interne AS5)
  - Routage BGP iBGP avec as5-border
  - Connexion aux services AS5
- **Interfaces** :
  - `eth0` : Backbone AS5 (120.0.80.2/24)
  - `eth1` : Services AS5 (120.0.85.1/24)

## Configuration

### Fichiers
- `docker-compose.yml` : Définition des conteneurs routeurs
- `config/as5-border.conf` : Configuration FRR pour le routeur de bordure
- `config/as5-internal.conf` : Configuration FRR pour le routeur interne
- `scripts/nat-border.sh` : Script de configuration NAT/Masquerade
- `scripts/qos-border.sh` : Script de configuration QoS

## Protocoles

### OSPF
- **Area** : 0
- **Réseaux annoncés** :
  - 120.0.80.0/24 (Backbone)
  - 120.0.81.0/24 (Lien Internet)
  - 120.0.82.0/24 (Lien Entreprise)
  - 120.0.83.0/24 (Lien Particulier)
  - 120.0.85.0/24 (Services)

### BGP
- **AS5-Border** :
  - eBGP vers AS1 (Internet Router) : 120.0.81.2
  - iBGP vers AS5-Internal : 120.0.80.2
  - Route annoncée : 120.0.80.0/20

## Commandes Utiles

```bash
# Vérifier les routes OSPF
docker exec as5-border vtysh -c "show ip route ospf"

# Vérifier les voisins BGP
docker exec as5-border vtysh -c "show ip bgp summary"

# Vérifier les routes
docker exec as5-border vtysh -c "show ip route"

# Accéder à la console FRR
docker exec -it as5-border vtysh
```

## Maintenance

Pour modifier la configuration :
1. Éditer les fichiers dans `config/`
2. Redémarrer le conteneur : `docker compose restart as5-border`

