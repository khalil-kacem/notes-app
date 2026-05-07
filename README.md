# Notes App
# Notes-App — Chaîne DevOps Complète

Application web full-stack de gestion de notes, industrialisée avec une chaîne DevOps moderne couvrant CI/CD, GitOps, DevSecOps et Monitoring.

[![CI Pipeline](https://github.com/khalil-kacem/notes-app/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/khalil-kacem/notes-app/actions/workflows/ci.yml)
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-khalil8-blue?logo=docker)](https://hub.docker.com/u/khalil8)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Minikube-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?logo=argo)](https://argo-cd.readthedocs.io/)
[![Grafana](https://img.shields.io/badge/Monitoring-Grafana-F46800?logo=grafana)](http://localhost:3000)

---

## Table des matières

- [Description](#description)
- [Architecture](#architecture)
- [Stack technique](#stack-technique)
- [Prérequis](#prérequis)
- [Installation locale](#installation-locale)
- [Docker](#docker)
- [Pipeline CI/CD](#pipeline-cicd)
- [Déploiement Kubernetes](#déploiement-kubernetes)
- [GitOps avec ArgoCD](#gitops-avec-argocd)
- [DevSecOps](#devsecops)
- [Monitoring](#monitoring)
- [Structure du projet](#structure-du-projet)
- [Auteur](#auteur)

---

## Description

Notes-App est une application web composée de deux services :

| Service | Rôle | Port |
|---------|------|------|
| **Backend** | API REST Node.js/Express — gestion des notes, métriques Prometheus | 3000 |
| **Frontend** | Interface statique servie par Nginx | 80 |

Endpoints disponibles :
- `GET /health` — Vérification de santé
- `GET /metrics` — Métriques Prometheus (`http_requests_total`, `process_resident_memory_bytes`, etc.)
- `GET /api/notes` — Liste des notes

---

## Architecture
┌─────────────┐     ┌─────────────────────────────┐     ┌─────────────┐
│  GitHub     │────→│  GitHub Actions (CI/CD)     │────→│  Docker Hub │
│  (Code)     │     │  • Tests + Lint              │     │  (Images)   │
└─────────────┘     │  • Scan sécurité (Trivy)     │     └─────────────┘
│  • Build & Push Docker         │            ↓
└─────────────────────────────┘     ┌─────────────┐
│  ArgoCD     │
│  (GitOps)   │
└──────┬──────┘
↓
┌─────────────────────────────────────────────────┐
│              Kubernetes (Minikube)                │
│  ┌─────────────┐  ┌─────────────┐              │
│  │   Backend   │  │   Frontend  │              │
│  │  2 replicas │  │  1 replica  │              │
│  └─────────────┘  └─────────────┘              │
│  ┌─────────────────────────────────────┐        │
│  │  Prometheus + Grafana (Monitoring)  │        │
│  └─────────────────────────────────────┘        │
└─────────────────────────────────────────────────┘

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Backend | Node.js 22, Express, prom-client, helmet, express-rate-limit |
| Frontend | HTML5, CSS3, Nginx (Alpine) |
| Conteneurisation | Docker, Docker Hub |
| Orchestration | Kubernetes (Minikube), Kustomize |
| GitOps | ArgoCD |
| CI/CD | GitHub Actions |
| Sécurité | SonarQube, Trivy, TruffleHog, npm audit, Helmet |
| Monitoring | Prometheus, Grafana |
| Qualité | Jest, ESLint |

---

## Prérequis

- [Node.js 22](https://nodejs.org/)
- [Docker](https://docs.docker.com/get-docker/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- [Helm](https://helm.sh/docs/intro/install/)
- [GitHub CLI](https://cli.github.com/) (`gh`)

---

## Installation locale

### 1. Cloner le dépôt

git clone https://github.com/khalil-kacem/notes-app.git
cd notes-app

2. Backend
cd backend
npm install
npm test        # Lance les tests Jest
npm run lint    # Vérifie le code avec ESLint
npm start       # Démarre le serveur sur http://localhost:3000

4. Frontend
Le frontend est statique — ouvrir frontend/index.html dans un navigateur, ou :
cd frontend
docker build -t notes-frontend .
docker run -p 8080:80 notes-frontend
# → http://localhost:8080
Docker
Construire les images localement

# Backend
docker build -t khalil8/notes-backend:latest .

# Frontend
docker build -t khalil8/notes-frontend:latest ./frontend
Pousser sur Docker Hub
docker login
docker push khalil8/notes-backend:latest
docker push khalil8/notes-frontend:latest
Pipeline CI/CD
Le pipeline s'exécute automatiquement à chaque push sur n'importe quelle branche, et sur les pull requests vers main et dev.
Jobs du pipeline

Job	Description	Dépendances
test-backend	Tests Jest + ESLint	—
validate-frontend	Vérification fichiers frontend	—
validate-k8s	Validation Kustomize + YAML	—
sonarqube	Analyse qualité du code	test + validate
security-scan-code	npm audit + TruffleHog	—
security-scan-deps	Trivy filesystem scan	—
build-docker	Build images sans push	tests + security
security-scan-backend	Trivy image scan backend (CRITICAL)	build-docker
security-scan-frontend	Trivy image scan frontend (CRITICAL)	build-docker
push-docker	Push images sur Docker Hub	build + sonarqube
deploy-gitops	Déploiement ArgoCD sur Minikube	push-docker
Secrets requis (GitHub Settings → Secrets)

Secret	Description
DOCKER_USERNAME	Identifiant Docker Hub
DOCKER_PASSWORD	Mot de passe Docker Hub
SONAR_TOKEN	Token SonarQube
SONAR_HOST_URL	URL du serveur SonarQube
GH_TOKEN	Token GitHub (pour gh pr merge)

Déploiement Kubernetes
Démarrer Minikube

minikube start --driver=docker --memory=4096 --cpus=2
Appliquer les manifests (dev)

kubectl apply -k k8s/overlays/dev/
Vérifier le déploiement

kubectl get pods -n notes-app
kubectl get svc -n notes-app
kubectl get pods -n monitoring
Accéder aux services

# Backend
kubectl port-forward svc/dev-backend -n notes-app 3000:80 &
curl http://localhost:3000/health
curl http://localhost:3000/metrics

# Frontend
minikube service dev-frontend -n notes-app --url
GitOps avec ArgoCD
Installation d'ArgoCD

kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd --namespace argocd
Accéder à l'interface

kubectl port-forward svc/argocd-server -n argocd 8080:443
# → https://localhost:8080
# Login: admin / Mot de passe: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
Applications configurées

Application	Branche	Environnement
notes-app-dev	dev	Développement
notes-app-prod	main	Production
Fichiers de configuration : ./k8s/argocd/
DevSecOps
La sécurité est intégrée à toutes les étapes du pipeline (approche shift-left).
Outils de sécurité

Outil	Phase	Rôle
ESLint	CI	Qualité du code
SonarQube	CI	Analyse statique, dette technique
npm audit	CI	Vulnérabilités packages Node.js
TruffleHog	CI	Détection de secrets (clés API, mots de passe)
Trivy (FS)	CI	Scan vulnérabilités fichiers et dépendances
Trivy (Image)	CI	Scan CRITICAL/HIGH dans images Docker
Helmet	Runtime	Headers HTTP sécurisés (CSP, HSTS, X-Frame)
Rate Limiting	Runtime	Protection contre les attaques par force brute
Politique de sécurité
Le pipeline échoue automatiquement si Trivy détecte des vulnérabilités CRITICAL
Les images Docker tournent avec un utilisateur non-root
Les fichiers système sont en lecture seule (readOnlyRootFilesystem: true)
Monitoring
Architecture de monitoring

Composant	Namespace	Rôle
Prometheus	monitoring	Collecte des métriques (scrape toutes les 15s)
Grafana	monitoring	Visualisation des métriques
Métriques exposées

Métrique	Type	Description
http_requests_total	Counter	Nombre de requêtes HTTP par méthode, path et status
http_request_duration_seconds	Histogram	Latence des requêtes (buckets: 0.1s à 10s)
process_cpu_user_seconds_total	Gauge	Temps CPU consommé
process_resident_memory_bytes	Gauge	Mémoire résidente utilisée
Accès local

# Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090
# → http://localhost:9090 → Status → Targets

# Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000
# → http://localhost:3000
# Login: admin / admin
# Dashboard: Notes App Dashboard
Dashboard Grafana
Le dashboard préconfiguré affiche :
HTTP Request Rate — Requêtes par seconde
CPU Usage — Utilisation processeur
Memory Usage — Consommation mémoire
Structure du projet

notes-app/
├── .github/
│   └── workflows/
│       └── ci.yml                  # Pipeline CI/CD GitHub Actions
├── backend/
│   ├── src/
│   │   ├── index.js               # Serveur Express + métriques Prometheus
│   │   └── index.test.js          # Tests unitaires Jest
│   ├── package.json               # Dépendances Node.js
│   └── Dockerfile                 # Image Docker backend
├── frontend/
│   ├── index.html                 # Page web
│   ├── style.css                  # Styles
│   ├── app.js                     # Logique frontend
│   └── Dockerfile                 # Image Docker frontend
├── k8s/
│   ├── argocd/                    # Applications ArgoCD (dev + prod)
│   │   ├── namespace.yaml
│   │   ├── application-dev.yaml
│   │   └── application-prod.yaml
│   ├── base/                      # Manifests Kubernetes de base
│   │   ├── backend-deployment.yaml
│   │   ├── backend-service.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── frontend-service.yaml
│   │   ├── kustomization.yaml
│   │   └── monitoring/            # Prometheus + Grafana
│   │       ├── namespace.yaml
│   │       ├── prometheus-*.yaml
│   │       └── grafana-*.yaml
│   └── overlays/                  # Configurations par environnement
│       ├── dev/
│       │   └── kustomization.yaml # Préfixe "dev-", namespace notes-app
│       └── prod/
│           └── kustomization.yaml # Préfixe "prod-", namespace notes-app-prod
├── .trivyignore                   # Exclusions de vulnérabilités Trivy
├── Dockerfile                     # Image backend (racine)
└── README.md                      # Ce fichier
Branches et flux de travail
Stratégie Git Flow simplifiée :

feat/*  →  dev  →  main
   ↑         ↑        ↑
 feature   intégration  production
Branche	Description

main	Production stable
dev	Intégration des features
feat/docker	Dockerisation
feat/ci-pipeline	Pipeline CI GitHub Actions
feat/k8s-manifests	Manifests Kubernetes
feat/argocd	Configuration GitOps
feat/devsecops	Intégration sécurité
feat/monitoring	Prometheus + Grafana
