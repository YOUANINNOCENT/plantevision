# Déployer le backend sur Render

Résumé rapide
- Nous utilisons un service Docker pour exécuter le backend FastAPI (Uvicorn). Le fichier `render.yaml` et le `Dockerfile` sont fournis.

Étapes à suivre

1. Révoquez / rotater toutes les clés compromises avant de déployer (GCP, GEMINI, MODELSLAB, etc.).

2. Mettre le dépôt sur GitHub (branche `main`) — déjà fait.

3. Sur Render (https://dashboard.render.com) :
   - Connectez votre compte GitHub si nécessaire.
   - Créez un nouveau **Web Service** en important le repo `YOUANINNOCENT/plantevision`.
   - Render détectera `render.yaml` et utilisera la configuration : service `plante-backend` (Docker) avec `root` = `plante/backend`.

4. Secrets / variables d'environnement (NE PAS mettre les clés dans le repo) :
   - Dans le tableau de bord Render > votre service > `Environment` ajoutez :
     - `PLANTNET_API_KEY` = (votre clé PlantNet)
     - `GEMINI_API_KEY` = (votre clé Gemini / Google)
     - `MODELSLAB_API_KEY` = (votre clé ModelsLab)
     - `DATABASE_URL` = (URL de production si besoin)
     - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `SMTP_FROM_NAME` si vous activez l'e-mail

5. Vérifier les paramètres de build / démarrage :
   - Le service utilise le `Dockerfile` situé dans `plante/backend` (via `root` dans `render.yaml`).
   - La commande de démarrage fournie dans le `Dockerfile` lance Uvicorn sur `${PORT}`.

6. Déployer
   - Activez le déploiement automatique (`Auto Deploy`) ou lancez un déploiement manuel depuis l'UI.
   - Surveillez les logs de build et d'application pour vérifier que l'app démarre correctement.

7. Tests post-déploiement
   - Appeler `GET /health` ou une route simple si existante, sinon `GET /` ou `GET /analyses/1` selon votre API.
   - Vérifier que les intégrations (PlantNet, image generation) fonctionnent avec les clés stockées dans Render.

Notes et recommandations
- N'ajoutez jamais `.env` dans le repo. Utilisez `.env.example` pour documenter les variables d'environnement.
- Si vous avez besoin d'une base de données relationnelle, créez un service PostgreSQL/MySQL sur Render ou utilisez un provider externe, et mettez la `DATABASE_URL` en secret.
- Pour stocker les fichiers uploadés (images), utilisez un stockage externe (S3, Backblaze, Cloud Storage). Ne versionnez pas les dossiers `uploads/`.

Si vous voulez, je peux :
- A : Créer automatiquement la PR contenant `render.yaml`, `Dockerfile` et la documentation (je peux faire la PR et lier).  
- B : Lancer un test de build local Docker pour vérifier l'image (nécessite Docker installé sur votre machine).
