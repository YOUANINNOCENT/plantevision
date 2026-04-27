# Déploiement — Vision (Plante)

Ce document détaille les étapes pour publier le projet sur **GitHub** et déployer
le backend FastAPI sur **Render**. L'app Flutter mobile reste sur ton PC (tu la
compiles avec `flutter run` ou tu génères un APK).

---

## A. Pousser le projet sur GitHub

### Pré-requis
- Un compte GitHub.
- [Git for Windows](https://git-scm.com/download/win) installé.
- L'invite PowerShell ouverte dans `C:\Users\innoc\OneDrive\Documents\simplon\plante`.

### Étapes

1. **Vérifie qu'aucun secret ne va être committé** :
   ```powershell
   git status
   ```
   Tu ne dois **pas** voir `backend/.env` dans la liste des fichiers à committer
   (il est protégé par `.gitignore`). S'il apparaît : arrête immédiatement et
   préviens-moi, on règle.

2. **Initialise le dépôt local** (si pas déjà fait) :
   ```powershell
   git init
   git add .
   git commit -m "Initial commit — Vision app"
   ```

3. **Crée un nouveau repo sur GitHub** : https://github.com/new
   - Nom suggéré : `plante-vision`
   - Visibilité : `Private` (recommandé tant que tu n'as pas révoqué les clés
     API présentes dans l'historique des messages)
   - **Ne coche pas** "Initialize with README" (le repo doit être vide)

4. **Lie le repo distant et pousse** :
   ```powershell
   git branch -M main
   git remote add origin https://github.com/TON_USERNAME/plante-vision.git
   git push -u origin main
   ```

   Si Git te demande tes identifiants, utilise un **token d'accès personnel**
   (Personal Access Token) au lieu de ton mot de passe :
   https://github.com/settings/tokens → Generate new token (classic) → coche
   `repo` → copie le token et utilise-le comme mot de passe.

5. **Vérifie sur GitHub** que ton repo affiche bien tous les fichiers, **mais
   pas** `backend/.env`.

---

## B. Déployer le backend sur Render

### Pré-requis
- Un compte Render : https://dashboard.render.com (gratuit, signup avec GitHub).
- Le projet poussé sur GitHub (étape A terminée).

### Étape 1 — Créer le service via Blueprint

Le fichier `render.yaml` à la racine du projet décrit déjà toute la config :
service web FastAPI + base PostgreSQL gratuite + variables d'environnement.

1. Sur Render → bouton **New +** → **Blueprint**.
2. Connecte ton compte GitHub si ce n'est pas déjà fait, puis sélectionne le
   repo `plante-vision`.
3. Render détecte automatiquement `render.yaml` et te propose de créer :
   - Un service web `plante-backend` (FastAPI sur uvicorn)
   - Une base `plante-db` (PostgreSQL 1 Go gratuit)
4. Clique **Apply**. Render lance le build (3–5 minutes).

### Étape 2 — Renseigner les secrets dans l'UI

Dans le dashboard Render, ouvre le service `plante-backend` → onglet
**Environment**. Ajoute (ou édite) ces variables avec tes vraies valeurs :

| Variable           | Valeur à mettre                                    |
|--------------------|----------------------------------------------------|
| `PLANTNET_API_KEY` | Ta clé PlantNet                                    |
| `GEMINI_API_KEY`   | Ta clé Google Gemini                               |
| `MODELSLAB_API_KEY`| (optionnel) Ta clé ModelsLab                       |
| `SMTP_USER`        | Ton email Gmail                                    |
| `SMTP_PASSWORD`    | Ton App Password Gmail (16 caractères)             |
| `SMTP_FROM`        | Le même email que SMTP_USER                        |

Clique **Save Changes** — Render redéploie automatiquement.

### Étape 3 — Récupérer l'URL publique

Sur la page de ton service `plante-backend`, en haut, tu vois l'URL publique :
```
https://plante-backend-xxxx.onrender.com
```

Teste-la dans le navigateur :
```
https://plante-backend-xxxx.onrender.com/health
```
Tu dois voir `{"status":"ok"}` ou similaire.

### Étape 4 — Pointer l'app Flutter sur le backend Render

Édite `lib/config.dart` :

```dart
const String backendBaseUrl = 'https://plante-backend-xxxx.onrender.com';
const String backendLocalIp = 'plante-backend-xxxx.onrender.com';
```

Puis `flutter run` (hot restart majuscule `R`). Plus besoin d'IP locale,
ton app peut désormais marcher depuis n'importe où dans le monde.

---

## ⚠️ Limitations du plan gratuit Render

- **Mise en veille après 15 min d'inactivité** : la première requête après une
  période de calme prend 30–60 s à répondre (le temps que le service redémarre).
  Pour un projet de démo, c'est acceptable.
- **750 h/mois de service web gratuit** (largement suffisant si un seul service).
- **Disque non persistant** : les fichiers dans `backend/uploads/` (images
  scannées) sont perdus à chaque redéploiement. La base PostgreSQL persiste, en
  revanche, donc les analyses (texte, plant_name, GPS) restent.
- **PostgreSQL gratuite expire après 90 jours** d'inactivité ou plafond
  1 Go atteint. À surveiller.

---

## 🔧 Mises à jour ultérieures

Pour pousser une nouvelle version :

```powershell
git add .
git commit -m "Description des changements"
git push
```

Render détecte automatiquement le push et redéploie le backend (3 min). Aucune
action manuelle requise sur Render.

Pour l'app Flutter, recompile-la et redistribue l'APK aux utilisateurs.

---

## 🔑 Clé Groq (chat botaniste IA, côté client Flutter)

La clé Groq alimente le chat. Elle est utilisée côté client. Pour ne PAS
la committer dans le code source :

**Lance Flutter avec `--dart-define`** :

```powershell
flutter run --dart-define=GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxx
```

Ou pour générer un APK release :
```powershell
flutter build apk --dart-define=GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxx
```

Sans `--dart-define`, le chat afficherait une erreur 401 Groq. C'est normal :
la clé doit venir du build, pas du code source.

**À terme**, le mieux serait de proxifier les appels Groq via le backend
FastAPI (la clé reste côté serveur, jamais côté client). C'est un chantier
ouvert si tu veux le faire un jour.

---

## 🚨 Sécurité

Avant de rendre ton repo public sur GitHub :

1. **Révoque les clés API** présentes dans l'historique de la conversation
   (PlantNet, Gemini, ModelsLab, Gmail App Password, Groq) — elles ont peut-être
   été visibles à un moment.
2. **Régénère** des nouvelles clés et mets-les uniquement dans Render
   Environment (jamais dans le code, jamais dans `.env` committé).
3. Si tu veux **purger l'historique Git** d'un fichier sensible :
   https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
