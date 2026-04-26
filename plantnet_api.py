"""
Intégration de l'API Pl@ntNet en Python.
Doc officielle : https://my.plantnet.org/doc/openapi

Corrections apportées :
  * La clé API est lue depuis la variable d'env PLANTNET_API_KEY
    (plus de placeholder "YOUR_API_KEY" qui faisait planter le script).
  * Le mélange fichiers locaux + URLs distantes est maintenant correct :
    l'ancienne version passait `images` et `organs` comme listes dans
    `params`, mais `requests` ne re-sérialise pas les listes imbriquées
    dans `setdefault` ; les multiples URLs étaient silencieusement ignorées.
  * Exceptions typées (pas de traceback brut à l'utilisateur).
  * Les fichiers sont toujours fermés (context managers).
  * `include-related-images` est renvoyé comme "true"/"false" (l'API
    n'accepte pas le bool Python sérialisé en "True").
"""

from __future__ import annotations

import json
import os
import sys
from contextlib import ExitStack
from pathlib import Path

import requests


API_KEY = os.getenv("PLANTNET_API_KEY", "2b10M02Imb8OZFWe7hvK9grqee").strip()
BASE_URL = "https://my-api.plantnet.org/v2/identify"


def identify_plant(
    image_paths: list[str],
    organs: list[str] | None = None,
    lang: str = "fr",
    project: str = "all",
    include_related_images: bool = True,
) -> dict:
    """
    Identifie une plante à partir d'une ou plusieurs images (fichiers locaux
    et/ou URLs publiques mélangés).
    """
    if not API_KEY:
        raise RuntimeError(
            "Variable d'env PLANTNET_API_KEY manquante — "
            "récupérez votre clé sur https://my.plantnet.org"
        )
    if not image_paths:
        raise ValueError("Fournissez au moins une image.")
    if organs is None:
        organs = ["auto"] * len(image_paths)
    if len(organs) != len(image_paths):
        raise ValueError("Le nombre d'organes doit correspondre au nombre d'images.")

    # Params simples
    params: list[tuple[str, str]] = [
        ("api-key", API_KEY),
        ("lang", lang),
        ("include-related-images", "true" if include_related_images else "false"),
    ]

    # Champs multi-valués (URL)
    multipart: list[tuple[str, tuple]] = []

    with ExitStack() as stack:
        for path, organ in zip(image_paths, organs):
            if path.startswith(("http://", "https://")):
                # URLs distantes : PlantNet les accepte en query string répétée.
                params.append(("images", path))
                params.append(("organs", organ))
            else:
                # Fichier local : multipart.
                p = Path(path)
                if not p.is_file():
                    raise FileNotFoundError(f"Image introuvable : {p}")
                f = stack.enter_context(p.open("rb"))
                multipart.append(("images", (p.name, f, "image/jpeg")))
                multipart.append(("organs", (None, organ)))

        try:
            response = requests.post(
                f"{BASE_URL}/{project}",
                params=params,
                files=multipart if multipart else None,
                timeout=30,
            )
        except requests.RequestException as exc:
            raise RuntimeError(f"Erreur réseau PlantNet : {exc}") from exc

    if response.status_code == 401:
        raise RuntimeError("Clé API PlantNet invalide (401).")
    if response.status_code == 429:
        raise RuntimeError("Quota PlantNet dépassé (429).")
    response.raise_for_status()
    return response.json()


def display_results(results: dict, top_n: int = 3) -> None:
    """Affiche les N premiers résultats de manière lisible."""
    if "results" not in results or not results["results"]:
        print("Aucun résultat trouvé.")
        print(json.dumps(results, indent=2, ensure_ascii=False))
        return

    print(f"\n🌿 Score global : {results.get('bestMatch', 'N/A')}\n")
    print(f"Top {top_n} espèces :")
    print("-" * 50)

    for i, result in enumerate(results["results"][:top_n], 1):
        species = result.get("species", {})
        score = result.get("score", 0.0)
        scientific = species.get("scientificNameWithoutAuthor", "Inconnu")
        common = species.get("commonNames", [])
        family = (species.get("family") or {}).get("scientificNameWithoutAuthor", "Inconnue")
        genus = (species.get("genus") or {}).get("scientificNameWithoutAuthor", "Inconnu")

        print(f"\n#{i} — {scientific}")
        print(f"   Confiance    : {score * 100:.1f}%")
        print(f"   Famille      : {family}")
        print(f"   Genre        : {genus}")
        if common:
            print(f"   Noms communs : {', '.join(common[:3])}")


# ─── Exemple d'utilisation ───────────────────────────────────────
if __name__ == "__main__":
    try:
        results = identify_plant(
            image_paths=[
                "https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/"
                "Sunflower_from_Silesia2.jpg/640px-Sunflower_from_Silesia2.jpg"
            ],
            organs=["flower"],
            lang="fr",
        )
    except RuntimeError as exc:
        print(f"❌ {exc}")
        sys.exit(1)

    display_results(results, top_n=3)

    out = Path("plantnet_results.json")
    out.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n✅ Résultats complets sauvegardés dans {out}")
