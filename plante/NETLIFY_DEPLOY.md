# Déployer le frontend Flutter Web sur Netlify

Ce projet est composé d'un backend (FastAPI sur Render) et d'un frontend
(Flutter Web sur Netlify). Cette documentation couvre uniquement Netlify ;
voir `DEPLOYMENT.md` pour Render.

## 1. Prérequis

- Backend Render déjà déployé et accessible (vérifie avec `/health`).
- Repo GitHub à jour (push fait depuis ton PC).
- Compte Netlify gratuit : https://app.netlify.com (signup avec GitHub).

## 2. Variables Netlify à configurer

Sur https://app.netlify.com → ton site → **Site settings** → **Environment variables** :

| Clé | Valeur |
|---|---|
| `BACKEND_URL` | `https://plante-backend-XXXX.onrender.com` (ton URL Render) |
| `GROQ_API_KEY` | `gsk_XXXXXXXXXXXXXXXXXXXXXXXXX` (ta clé Groq) |
| `FLUTTER_VERSION` | `3.24.5` (ou la version utilisée localement) |

## 3. Étape par étape sur Netlify

### A. Créer le site

1. https://app.netlify.com/start → **Import from Git** → **GitHub**
2. Autorise Netlify à voir ton repo `plantevision`
3. Choisis le repo

### B. Configurer le build

Netlify détecte `netlify.toml` automatiquement. Sinon, mets manuellement :

| Champ | Valeur |
|---|---|
| **Base directory** | `plante` |
| **Build command** | `bash netlify-build.sh` |
| **Publish directory** | `plante/build/web` |
| **Branch to deploy** | `main` |

### C. Définir les variables d'environnement

Avant le premier build, va sur **Site settings → Environment variables** et
ajoute les 3 variables du tableau ci-dessus.

### D. Lancer le déploiement

Sur la page du site Netlify → bouton **Deploy site**. Le premier build prend
~5-10 minutes (téléchargement du SDK Flutter + build release).

Si le build échoue : onglet **Deploys** → clique sur le déploiement échoué →
section **Deploy log** → copie-colle l'erreur.

### E. Récupérer ton URL

Quand le build est vert, tu auras une URL du type :
```
https://votre-nom-aleatoire.netlify.app
```

Tu peux la personnaliser dans **Site settings → Site information →
Change site name**.

## 4. Updates ultérieurs

Chaque `git push` sur la branche `main` déclenche automatiquement un
re-déploiement Netlify (~5 min).

## 5. Limitations

- **Tier gratuit Netlify** : 100 GB de bande passante/mois, 300 minutes de
  build/mois. Largement suffisant pour un projet de démo.
- **Camera/GPS** : sur Web, l'API caméra demande HTTPS (ce que Netlify
  fournit). Le scanner de plantes fonctionnera donc.
- **Backend Render free** : se met en veille après 15 min d'inactivité.
  Premier appel après veille = 30-60 s de latence. À mentionner aux testeurs.
