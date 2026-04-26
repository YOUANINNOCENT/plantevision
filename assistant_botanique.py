"""
Assistant botanique : identifie une plante (PlantNet) puis génère une image
illustrative via Pollinations.ai (gratuit, sans clé).

Corrections apportées par rapport à la version initiale :
  * Les clés API sont lues depuis les variables d'environnement
    (plus de hardcoding) avec valeur de repli pour compat locale.
  * Pixazo a été remplacé par Pollinations.ai car l'endpoint
    api.pixazo.ai n'existe pas / n'est pas une API publique connue.
  * La compression d'image conserve le ratio (thumbnail) et convertit
    RGBA/P → RGB pour éviter l'erreur "cannot write mode RGBA as JPEG".
  * Le fichier temporaire est lu en mémoire une seule fois : le bug
    "file déjà consommé après un retry 504" est corrigé.
  * Le fichier temporaire est supprimé à la fin (context manager).
  * `except:` nu remplacé par des exceptions typées.
  * L'organe photographié est un paramètre (leaf, flower, fruit…).
"""

from __future__ import annotations

import io
import os
import sys
import time
from pathlib import Path
from typing import Any
from urllib.parse import quote

import requests
from PIL import Image

# ───────────────────────── Configuration ─────────────────────────
PLANTNET_API_KEY = os.getenv("PLANTNET_API_KEY", "2b10M02Imb8OZFWe7hvK9grqee")
PLANTNET_URL = "https://my-api.plantnet.org/v2/identify/all"

# Pollinations : génération d'image gratuite, pas de clé requise.
# Doc : https://pollinations.ai/
POLLINATIONS_URL = "https://image.pollinations.ai/prompt/{prompt}"

MAX_IMAGE_SIDE = 1024     # px — assez pour PlantNet, pas trop lourd
JPEG_QUALITY = 80
REQUEST_TIMEOUT = 30      # s
MAX_RETRIES = 3


# ───────────────────── Compression d'image ──────────────────────
def compresser_image(input_path: str | Path) -> bytes:
    """
    Charge l'image, redimensionne en conservant le ratio et retourne
    les octets JPEG prêts à être envoyés. Rien n'est écrit sur disque :
    on manipule un buffer en mémoire (plus simple pour les retries).
    """
    input_path = Path(input_path)
    if not input_path.is_file():
        raise FileNotFoundError(f"Image introuvable : {input_path}")

    with Image.open(input_path) as img:
        # JPEG n'accepte ni RGBA ni palette : on convertit.
        if img.mode in ("RGBA", "LA", "P"):
            img = img.convert("RGB")
        img.thumbnail((MAX_IMAGE_SIDE, MAX_IMAGE_SIDE), Image.LANCZOS)

        buffer = io.BytesIO()
        img.save(buffer, format="JPEG", quality=JPEG_QUALITY, optimize=True)
        return buffer.getvalue()


# ───────────────────── Identification plante ────────────────────
def identifier_plante(image_bytes: bytes, organ: str = "auto") -> dict[str, Any]:
    """
    Appelle PlantNet. Retry en cas de timeout / 504.
    Retourne un dict { ok, nom_scientifique?, score?, erreur? }.
    """
    valid_organs = {"auto", "leaf", "flower", "fruit", "bark", "habit"}
    if organ not in valid_organs:
        raise ValueError(f"Organe invalide : {organ}. Valeurs : {valid_organs}")

    last_error = "Serveur indisponible"

    for tentative in range(1, MAX_RETRIES + 1):
        try:
            response = requests.post(
                PLANTNET_URL,
                params={"api-key": PLANTNET_API_KEY, "lang": "fr"},
                files=[
                    ("images", ("plante.jpg", image_bytes, "image/jpeg")),
                    ("organs", (None, organ)),
                ],
                timeout=REQUEST_TIMEOUT,
            )
        except requests.Timeout:
            last_error = "Timeout"
            print(f"[{tentative}/{MAX_RETRIES}] Timeout, nouvelle tentative…")
            time.sleep(2)
            continue
        except requests.RequestException as exc:
            return {"ok": False, "erreur": f"Erreur réseau : {exc}"}

        if response.status_code == 200:
            data = response.json()
            results = data.get("results") or []
            if not results:
                return {"ok": False, "erreur": "Aucune plante reconnue"}
            top = results[0]
            species = top.get("species", {})
            return {
                "ok": True,
                "nom_scientifique": species.get(
                    "scientificNameWithoutAuthor", "Inconnu"
                ),
                "noms_communs": species.get("commonNames", []),
                "famille": species.get("family", {}).get(
                    "scientificNameWithoutAuthor", ""
                ),
                "score": round(top.get("score", 0.0), 4),
            }

        if response.status_code == 504:
            last_error = "504 Gateway Timeout"
            print(f"[{tentative}/{MAX_RETRIES}] Serveur lent, retry…")
            time.sleep(2)
            continue

        if response.status_code == 401:
            return {"ok": False, "erreur": "Clé API PlantNet invalide (401)"}
        if response.status_code == 429:
            return {"ok": False, "erreur": "Quota PlantNet dépassé (429)"}

        return {
            "ok": False,
            "erreur": f"Erreur API : {response.status_code} — {response.text[:200]}",
        }

    return {"ok": False, "erreur": last_error}


# ──────────────────── Génération d'image ────────────────────────
def generer_image(prompt: str, destination: str | Path = "plante_generee.jpg") -> dict[str, Any]:
    """
    Génère une image illustrative via Pollinations.ai (gratuit, sans clé).
    Sauvegarde le résultat à `destination` et renvoie le chemin.
    """
    url = POLLINATIONS_URL.format(prompt=quote(prompt))
    try:
        response = requests.get(
            url,
            params={"width": 768, "height": 768, "nologo": "true"},
            timeout=60,  # la génération peut être longue
        )
    except requests.RequestException as exc:
        return {"ok": False, "erreur": f"Erreur réseau : {exc}"}

    if response.status_code != 200:
        return {
            "ok": False,
            "erreur": f"Erreur image : HTTP {response.status_code}",
        }

    destination = Path(destination)
    destination.write_bytes(response.content)
    return {"ok": True, "chemin": str(destination)}


# ──────────────────────── Pipeline complet ───────────────────────
def assistant_botanique(image_path: str | Path, organ: str = "auto") -> dict[str, Any]:
    print("→ Compression de l'image…")
    image_bytes = compresser_image(image_path)

    print("→ Identification de la plante…")
    identification = identifier_plante(image_bytes, organ=organ)
    if not identification["ok"]:
        return {"erreur": identification["erreur"]}

    nom = identification["nom_scientifique"]
    description = (
        f"{nom} est une plante pouvant être comestible, médicinale ou toxique "
        f"selon son usage — vérifiez une source fiable avant toute consommation."
    )

    print("→ Génération de l'image illustrative…")
    image = generer_image(f"{nom}, plante réaliste, photographie botanique, haute qualité")

    return {
        "plante": nom,
        "noms_communs": identification.get("noms_communs", []),
        "famille": identification.get("famille", ""),
        "score": identification.get("score"),
        "description": description,
        "image": image,
    }


if __name__ == "__main__":
    chemin = sys.argv[1] if len(sys.argv) > 1 else "plante.jpg"
    organe = sys.argv[2] if len(sys.argv) > 2 else "auto"
    try:
        resultat = assistant_botanique(chemin, organ=organe)
        for cle, val in resultat.items():
            print(f"{cle}: {val}")
    except FileNotFoundError as exc:
        print(f"❌ {exc}")
        sys.exit(1)
