"""Configuration runtime simple pour les services.

Contient un flag `ai_mode`:
- 'auto' (par défaut): utilise OpenAI si `OPENAI_API_KEY` est définie, sinon fallback local.
- 'local': force le fallback local (utile pour dev sans clé).
- 'remote': force l'appel à l'API distante (nécessite clé sinon erreur).

Ce fichier est volontairement minimal et non sécurisé; pour la prod utilisez
une configuration plus robuste et des contrôles d'accès.
"""

import os

ai_mode: str = "auto"
system_prompt: str | None = None
# Optionally store an OpenAI key in memory (set via admin endpoint). Do NOT commit keys to disk.
# Initialize from environment so the key set in `backend/.env` is picked up at import time.
openai_api_key: str | None = os.environ.get("OPENAI_API_KEY") or None
# Optional Unsplash API key (used as a fallback for image generation)
unsplash_key: str | None = os.environ.get("UNSPLASH_KEY") or None
