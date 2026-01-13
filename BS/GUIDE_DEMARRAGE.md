# Guide de Démarrage - Structure Modulaire

## 🎯 Vue d'Ensemble

Le projet est maintenant organisé de manière **modulaire et hiérarchique** pour faciliter le travail en équipe. Chaque service a son propre dossier avec sa configuration et sa documentation.

## 📁 Structure des Services

### 1. Routeurs AS5 (`services/as5-routers/`)
- **as5-border** : Routeur de bordure (OSPF + BGP)
- **as5-internal** : Routeur interne
- **Documentation** : `services/as5-routers/README.md`

### 2. Routeur Internet (`services/internet-router/`)
- **internet-router** : Routeur AS1/Internet
- **Documentation** : `services/internet-router/README.md`

### 3. DNS AS5 (`services/dns-as5/`)
- **dns-as5** : Serveur DNS récursif
- **Documentation** : `services/dns-as5/README.md`

### 4. Entreprise 5 (`services/entreprise5/`)
- Routeur, DNS, FreeRADIUS, Asterisk, Nginx, OpenVPN, Clients
- **Documentation** : `services/entreprise5/README.md`

### 5. Particulier 5 (`services/particulier5/`)
- Box et clients particuliers
- **Documentation** : `services/particulier5/README.md`

### 6. Site Secondaire (`services/site-secondaire/`)
- Routeur, clients, OpenVPN
- **Documentation** : `services/site-secondaire/README.md`

## 🚀 Démarrage Rapide

### Option 1 : Script Automatique (Recommandé)

```bash
./start-all.sh
```

### Option 2 : Manuel (Étape par Étape)

```bash
# 1. Créer les réseaux
docker compose up -d --no-start

# 2. Lancer les services dans l'ordre
docker compose -f services/as5-routers/docker-compose.yml up -d
docker compose -f services/internet-router/docker-compose.yml up -d
docker compose -f services/dns-as5/docker-compose.yml up -d
docker compose -f services/entreprise5/docker-compose.yml up -d
docker compose -f services/particulier5/docker-compose.yml up -d
docker compose -f services/site-secondaire/docker-compose.yml up -d
```

### Option 3 : Service par Service

```bash
# Lancer uniquement l'entreprise5
cd services/entreprise5
docker compose up -d

# Vérifier l'état
docker compose ps
```

## 🛠️ Commandes Utiles

### Vérifier l'état d'un service

```bash
# Service spécifique
docker compose -f services/entreprise5/docker-compose.yml ps

# Tous les services
docker compose ps
```

### Redémarrer un service

```bash
docker compose -f services/entreprise5/docker-compose.yml restart
```

### Voir les logs

```bash
docker compose -f services/entreprise5/docker-compose.yml logs -f
```

### Arrêter un service

```bash
docker compose -f services/entreprise5/docker-compose.yml down
```

## 👥 Travail en Équipe

### Attribution Recommandée

- **Membre 1** : `services/as5-routers/` (Routage)
- **Membre 2** : `services/entreprise5/` (Services entreprise)
- **Membre 3** : `services/particulier5/` + `services/site-secondaire/`
- **Membre 4** : `services/dns-as5/` + Tests globaux

### Workflow Git

```bash
# Travailler sur un service
cd services/entreprise5
# ... modifications ...
git add services/entreprise5/
git commit -m "feat(entreprise5): amélioration DNS"
```

## 📚 Documentation

- **Structure** : `README_STRUCTURE.md`
- **Architecture** : `ARCHITECTURE.md`
- **Service spécifique** : `services/<service>/README.md`

## ⚠️ Notes Importantes

1. **Ordre de démarrage** : Les routeurs doivent démarrer avant les services
2. **Réseaux** : Créés par `docker-compose.yml` principal
3. **Certificats VPN** : Générer avant de lancer OpenVPN (voir `services/entreprise5/README.md`)

## 🔍 Dépannage

### Service ne démarre pas

```bash
# Vérifier les logs
docker compose -f services/<service>/docker-compose.yml logs

# Vérifier les réseaux
docker network ls
```

### Conflit de réseau

```bash
# Nettoyer
docker compose down
docker network prune -f
```

---

**Pour plus de détails** : Voir `README_STRUCTURE.md` et les README de chaque service.

