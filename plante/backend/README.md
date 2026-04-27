Mini API FastAPI pour le projet "plante"

Installation (recommandé dans un virtualenv) :

```bash
python -m venv .venv
source .venv/bin/activate   # ou .\.venv\Scripts\activate sur Windows
pip install -r backend/requirements.txt
```

Lancer le serveur (développement) :

```bash
uvicorn backend.main:app --reload
```

Endpoints disponibles :
- `GET /health` : check
- `POST /upload` : upload d'image; champs form : `file` (image) et `user_id` (int)
- `GET /analyses/{user_id}` : liste des analyses pour l'utilisateur

Le backend charge dynamiquement `models.py` et `backend/services/db_service.py` et crée la base de données si nécessaire.
