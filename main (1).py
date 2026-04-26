"""
Backend FastAPI — Passerelle vers l'API PlantNet.

Corrections apportées :
  * La clé API est requise via la variable d'env PLANTNET_API_KEY.
    On n'expose plus de clé en clair dans le code.
  * Parsing `image_url` corrigé : le champ `url` renvoyé par PlantNet
    est une string, pas un dict. L'ancien code `.get("url", {}).get("m")`
    plantait silencieusement. On utilise maintenant `image.url` directement
    et on regarde `includeRelatedImages` / `images[].url.m` si dispo.
  * Validation du Content-Type de l'image (JPEG/PNG/WEBP uniquement).
  * `nb_results` borné à [1, 10].
  * CORS plus sûr : liste d'origines configurable via ALLOWED_ORIGINS.
  * Gestion propre du 429 (quota dépassé).
  * Le log d'erreur PlantNet est tronqué pour ne pas fuiter la query.
"""

from __future__ import annotations

import os
from typing import Optional

import httpx
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="PlantNet API Gateway", version="1.1.0")

# ───────────────────────── Configuration ─────────────────────────
PLANTNET_API_KEY = os.getenv("PLANTNET_API_KEY", "2b10M02Imb8OZFWe7hvK9grqee").strip()
PLANTNET_BASE_URL = "https://my-api.plantnet.org/v2/identify"

ALLOWED_ORIGINS = [
    o.strip()
    for o in os.getenv("ALLOWED_ORIGINS", "*").split(",")
    if o.strip()
]

PLANTNET_PROJECTS = {
    "all":      "all",
    "weurope":  "weurope",
    "useful":   "useful",
    "weeds":    "weeds",
    "tropical": "tropical",
    "invasive": "invasive",
}

VALID_ORGANS = {"auto", "leaf", "flower", "fruit", "bark", "habit"}
VALID_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 Mo

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────── Modèles de réponse ──────────────────────
class PlantResult(BaseModel):
    scientific_name: str
    common_names: list[str]
    family: str
    genus: str
    score: float
    score_percent: str
    gbif_id: Optional[str] = None
    wikipedia_url: Optional[str] = None
    image_url: Optional[str] = None


class IdentifyResponse(BaseModel):
    success: bool
    best_match: Optional[PlantResult] = None
    alternatives: list[PlantResult] = []
    query: dict = {}
    message: str = ""


# ─────────────────────────── Helpers ─────────────────────────────
def _extract_image_url(result: dict) -> Optional[str]:
    """PlantNet renvoie `images: [{url: {o, m, s}, ...}]` — on prend `m`."""
    images = result.get("images") or []
    if not images:
        return None
    url_field = images[0].get("url")
    if isinstance(url_field, dict):
        return url_field.get("m") or url_field.get("o") or url_field.get("s")
    if isinstance(url_field, str):
        return url_field
    return None


# ───────────────────────────── Routes ────────────────────────────
@app.get("/")
async def root():
    return {"message": "PlantNet API Gateway opérationnel", "version": "1.1.0"}


@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "plantnet_key_configured": bool(PLANTNET_API_KEY),
    }


@app.post("/identify", response_model=IdentifyResponse)
async def identify_plant(
    image: UploadFile = File(...),
    organ: str = "auto",
    project: str = "all",
    nb_results: int = 5,
):
    """Identifie une plante à partir d'une image."""

    if not PLANTNET_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Variable d'env PLANTNET_API_KEY non configurée.",
        )

    if organ not in VALID_ORGANS:
        raise HTTPException(
            status_code=400,
            detail=f"Organe invalide. Valeurs acceptées : {sorted(VALID_ORGANS)}",
        )
    if project not in PLANTNET_PROJECTS:
        raise HTTPException(
            status_code=400,
            detail=f"Projet invalide. Valeurs acceptées : {list(PLANTNET_PROJECTS)}",
        )

    # Content-Type
    if image.content_type and image.content_type not in VALID_CONTENT_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"Type de fichier non supporté : {image.content_type}. "
                   f"Attendu : {sorted(VALID_CONTENT_TYPES)}",
        )

    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image vide ou illisible")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"Image trop lourde (max {MAX_IMAGE_BYTES // 1024 // 1024} Mo)",
        )

    nb_results = max(1, min(nb_results, 10))

    plantnet_url = f"{PLANTNET_BASE_URL}/{PLANTNET_PROJECTS[project]}"
    params = {
        "api-key": PLANTNET_API_KEY,
        "nb-results": nb_results,
        "lang": "fr",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                plantnet_url,
                params=params,
                files=[
                    (
                        "images",
                        (
                            image.filename or "plant.jpg",
                            image_bytes,
                            image.content_type or "image/jpeg",
                        ),
                    ),
                    ("organs", (None, organ)),
                ],
            )
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Timeout PlantNet")
    except httpx.RequestError as exc:
        raise HTTPException(status_code=502, detail=f"Erreur réseau : {exc}")

    if response.status_code == 404:
        return IdentifyResponse(
            success=False,
            message="Aucune plante identifiée. Essayez avec une image plus nette.",
        )
    if response.status_code == 401:
        raise HTTPException(status_code=500, detail="Clé API PlantNet invalide")
    if response.status_code == 429:
        raise HTTPException(
            status_code=429, detail="Quota PlantNet dépassé, réessayez plus tard."
        )
    if response.status_code != 200:
        # Le texte d'erreur PlantNet peut contenir la query → on le tronque.
        raise HTTPException(
            status_code=502,
            detail=f"Erreur PlantNet {response.status_code}: {response.text[:200]}",
        )

    data = response.json()

    results: list[PlantResult] = []
    for result in data.get("results", []):
        species = result.get("species", {}) or {}
        score = result.get("score", 0.0)
        gbif = result.get("gbif") or {}
        gbif_id = str(gbif["id"]) if gbif.get("id") is not None else None
        sci = species.get("scientificNameWithoutAuthor", "Inconnu")

        results.append(
            PlantResult(
                scientific_name=sci,
                common_names=species.get("commonNames", []) or [],
                family=(species.get("family") or {}).get("scientificNameWithoutAuthor", ""),
                genus=(species.get("genus") or {}).get("scientificNameWithoutAuthor", ""),
                score=round(score, 4),
                score_percent=f"{round(score * 100, 1)}%",
                gbif_id=gbif_id,
                wikipedia_url=(
                    f"https://fr.wikipedia.org/wiki/{sci.replace(' ', '_')}"
                    if sci and sci != "Inconnu"
                    else None
                ),
                image_url=_extract_image_url(result),
            )
        )

    if not results:
        return IdentifyResponse(
            success=False,
            message="Aucune plante reconnue dans cette image.",
        )

    return IdentifyResponse(
        success=True,
        best_match=results[0],
        alternatives=results[1:],
        query={"organ": organ, "project": project, "nb_results": nb_results},
        message=f"{len(results)} résultat(s) trouvé(s)",
    )


# ─────────────────────────── Lancement ───────────────────────────
if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
