# Structure Hiérarchique du Projet

## 📁 Organisation Modulaire

Le projet est organisé de manière hiérarchique pour faciliter le travail en équipe. Chaque service/composant a son propre dossier avec sa configuration et sa documentation.

```
projet/
├── docker-compose.yml          # Réseaux principaux (référence)
├── README.md                   # Documentation principale
├── README_STRUCTURE.md         # Ce fichier
│
├── services/                   # Services modulaires
│   ├── as5-routers/            # Routeurs AS5
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   └── config/
│   │       ├── as5-border.conf
│   │       └── as5-internal.conf
│   │
│   ├── internet-router/        # Routeur Internet/AS1
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   └── config/
│   │       └── internet-router.conf
│   │
│   ├── entreprise5/            # Site Principal Entreprise
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   ├── config/
│   │   │   ├── dns/            # DNS autoritaire
│   │   │   ├── radius/         # FreeRADIUS
│   │   │   ├── asterisk/       # VoIP
│   │   │   ├── nginx/          # Web
│   │   │   └── vpn/            # OpenVPN
│   │   └── scripts/
│   │       └── router-init.sh
│   │
│   ├── particulier5/           # Box Particulier
│   │   ├── README.md
│   │   └── docker-compose.yml
│   │
│   ├── site-secondaire/        # Site Secondaire
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   ├── config/
│   │   │   └── vpn/
│   │   └── scripts/
│   │
│   └── dns-as5/                # DNS Récursif AS5
│       ├── README.md
│       ├── docker-compose.yml
│       └── config/
│
├── scripts/                    # Scripts partagés
│   ├── nat-border.sh
│   ├── qos-border.sh
│   ├── client-init.sh
│   └── ...
│
└── config/                     # Configurations originales (référence)
    ├── router/
    ├── dns/
    ├── vpn/
    └── ...
```

## 🚀 Utilisation

### Lancer tous les services

```bash
# 1. Créer les réseaux
docker compose up -d --no-start

# 2. Lancer chaque service
docker compose -f services/as5-routers/docker-compose.yml up -d
docker compose -f services/internet-router/docker-compose.yml up -d
docker compose -f services/dns-as5/docker-compose.yml up -d
docker compose -f services/entreprise5/docker-compose.yml up -d
docker compose -f services/particulier5/docker-compose.yml up -d
docker compose -f services/site-secondaire/docker-compose.yml up -d
```

### Lancer un service spécifique

```bash
# Exemple : Entreprise5 uniquement
cd services/entreprise5
docker compose up -d
```

### Script de lancement global

Un script `start-all.sh` peut être créé pour lancer tout automatiquement.

## 👥 Travail en Équipe

### Attribution des Services

Chaque membre de l'équipe peut travailler sur un service spécifique :

- **Membre 1** : `services/as5-routers/` (Routage OSPF/BGP)
- **Membre 2** : `services/entreprise5/` (Services entreprise)
- **Membre 3** : `services/particulier5/` + `services/site-secondaire/`
- **Membre 4** : `services/dns-as5/` + Tests

### Workflow

1. **Modifier un service** : Éditer les fichiers dans `services/<service>/`
2. **Tester localement** : `docker compose -f services/<service>/docker-compose.yml up -d`
3. **Commit** : Chaque service peut être commité indépendamment
4. **Intégration** : Tester l'ensemble avec le script global

## 📝 Documentation

Chaque dossier `services/<service>/` contient :
- **README.md** : Documentation du service
- **docker-compose.yml** : Configuration Docker
- **config/** : Fichiers de configuration
- **scripts/** : Scripts d'initialisation (si nécessaire)

## 🔧 Avantages de cette Structure

1. **Modularité** : Chaque service est indépendant
2. **Clarté** : Facile de comprendre l'organisation
3. **Collaboration** : Plusieurs personnes peuvent travailler en parallèle
4. **Maintenance** : Modifications isolées par service
5. **Tests** : Tests unitaires par service possible
6. **Documentation** : Documentation proche du code

## 📚 Pour Aller Plus Loin

- Voir `README.md` pour la documentation complète
- Voir `ARCHITECTURE.md` pour l'architecture détaillée
- Voir chaque `services/<service>/README.md` pour les détails du service

