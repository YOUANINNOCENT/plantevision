import os
import requests
import base64
import json
import time
from typing import Optional

PLANTID_API_KEY = os.environ.get('PLANTID_API_KEY', '')
API_URL = 'https://api.plant.id/v3/identification'


def call_plantid(image_b64: str) -> dict:
    if not PLANTID_API_KEY:
        raise RuntimeError('PLANTID_API_KEY not configured')
    resp = requests.post(
        API_URL,
        params={'details': 'common_names,taxonomy,description,best_watering,best_light_condition,best_soil_type', 'language': 'fr'},
        headers={'Api-Key': PLANTID_API_KEY, 'Content-Type': 'application/json'},
        json={'images': [image_b64]},
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()


def format_result(data: dict) -> str:
    try:
        result = data.get('result', {})
        classification = result.get('classification', {})
        suggestions = classification.get('suggestions', [])
        if not suggestions:
            is_plant = result.get('is_plant', {}).get('binary', False)
            if not is_plant:
                return '❌ Aucune plante détectée dans l\'image.'
            return '⚠️ Plante détectée mais impossible de l\'identifier précisément.'
        top = suggestions[0]
        nom_sci = top.get('name', 'Inconnu')
        proba = round(top.get('probability', 0) * 100, 1)
        details = top.get('details', {})
        noms_communs = details.get('common_names') or []
        nom_commun = ', '.join(noms_communs[:3]) if noms_communs else 'Non disponible'
        taxo = details.get('taxonomy', {})
        famille = taxo.get('family', '—')
        genre = taxo.get('genus', '—')
        desc_obj = details.get('description', {})
        description = desc_obj.get('value', '') if isinstance(desc_obj, dict) else ''
        if description and len(description) > 300:
            description = description[:300] + '...'

        def soin(cle):
            obj = details.get(cle, {})
            return obj.get('value', '') if isinstance(obj, dict) else ''

        arrosage = soin('best_watering')
        lumiere = soin('best_light_condition')
        sol = soin('best_soil_type')

        lines = [
            f"🌿 Plante identifiée : {nom_sci} ({proba}% de confiance)",
            f"📛 Noms communs     : {nom_commun}",
            f"🔬 Famille          : {famille} | Genre : {genre}",
        ]
        if description:
            lines += ['', '📖 Description :', description]
        soins = []
        if arrosage: soins.append(f"  💧 Arrosage : {arrosage}")
        if lumiere: soins.append(f"  ☀️  Lumière  : {lumiere}")
        if sol: soins.append(f"  🪴 Sol      : {sol}")
        if soins:
            lines += ['', "🌱 Conseils d'entretien :"] + soins
        if len(suggestions) > 1:
            autres = [f"  - {s['name']} ({round(s['probability']*100,1)}%)" for s in suggestions[1:4]]
            lines += ['', '🔎 Autres possibilités :'] + autres
        return '\n'.join(lines)
    except Exception as e:
        return f"Erreur de formatage : {e}\n\nRéponse brute :\n{json.dumps(data, indent=2)}"


def save_base64_image(image_b64: str, upload_dir) -> Optional[str]:
    try:
        data = base64.b64decode(image_b64)
        filename = f"capture_{int(time.time()*1000)}.jpg"
        path = upload_dir / filename
        with path.open('wb') as f:
            f.write(data)
        return str(path)
    except Exception:
        return None
