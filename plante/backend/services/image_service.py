import os
import json
import base64
import traceback
import requests
from services import config as svc_config

OPENAI_IMAGES_URL = "https://api.openai.com/v1/images"
GOOGLE_IMAGES_BASE = "https://generativelanguage.googleapis.com"


def generate_image(prompt: str, size: str = "1024x1024") -> str:
    """Génère une image à partir d'un prompt. Retourne une chaîne base64 (sans header).

    Essaie OpenAI Images si la clé est de type Bearer / OpenAI, sinon tente
    l'API image de Google (image-bison) si la clé ressemble à une clé Google (AQ.|AIza).
    """
    api_key = getattr(svc_config, "openai_api_key", None) or os.environ.get("OPENAI_API_KEY")
    if not api_key:
        # Try Unsplash key first (if provided separately)
        unsplash_key = getattr(svc_config, "unsplash_key", None) or os.environ.get("UNSPLASH_KEY")
        if not unsplash_key:
            raise RuntimeError("Aucune clé API fournie pour la génération d'images")
        # If only Unsplash is provided, use it to fetch a random photo matching the prompt
        try:
            # Use Unsplash random photo endpoint
            print(f"[image_service] Using Unsplash fallback with key prefix={unsplash_key[:4]}...")
            url = "https://api.unsplash.com/photos/random"
            params = {"query": prompt, "orientation": "portrait"}
            headers = {"Accept-Version": "v1", "Authorization": f"Client-ID {unsplash_key}"}
            r = requests.get(url, headers=headers, params=params, timeout=30)
            r.raise_for_status()
            j = r.json()
            # choose the best available URL
            img_url = None
            urls = j.get("urls") or {}
            for key in ("raw", "full", "regular", "small"):
                if urls.get(key):
                    img_url = urls.get(key)
                    break
            if not img_url:
                raise RuntimeError(f"Impossible d'obtenir l'URL image depuis Unsplash: {j}")
            print(f"[image_service] Downloading image from Unsplash URL (truncated): {img_url[:200]}")
            r2 = requests.get(img_url, timeout=60)
            r2.raise_for_status()
            data = r2.content
            return base64.b64encode(data).decode()
        except Exception as e:
            raise RuntimeError(f"Erreur Unsplash fallback: {e}")

    # Heuristique: clé Google commence par 'AQ.' ou 'AIza'
    if api_key.startswith("AQ.") or api_key.startswith("AIza"):
        # Preferer l'utilisation du SDK officiel `google-genai` si disponible.
        try:
            from google import genai
            from google.genai import types
        except Exception:
            genai = None

        if genai is not None:
            try:
                client = genai.Client(api_key=api_key)
            except Exception as e:
                raise RuntimeError(f"Impossible d'initialiser le client google-genai: {e}\n{traceback.format_exc()}")

            # modèle orienté image; ajuster si indisponible
            preferred_models = [
                "gemini-3.1-flash-image-preview",
                "gemini-3.1-image-preview",
                "gemini-3.0-image-preview",
            ]
            last_exc = None
            for model in preferred_models:
                try:
                    print(f"[image_service] Trying google-genai SDK model={model}")
                    contents = [
                        types.Content(
                            role="user",
                            parts=[types.Part.from_text(text=prompt)],
                        )
                    ]
                    config = types.GenerateContentConfig(
                        image_config=types.ImageConfig(image_size="1K"),
                        response_modalities=["IMAGE"],
                    )

                    for chunk in client.models.generate_content_stream(
                        model=model,
                        contents=contents,
                        config=config,
                    ):
                        if not getattr(chunk, "parts", None):
                            continue
                        for p in chunk.parts:
                            inline = getattr(p, "inline_data", None)
                            if inline and getattr(inline, "data", None):
                                data = inline.data
                                if isinstance(data, (bytes, bytearray)):
                                    return base64.b64encode(data).decode()
                                # if SDK returns base64 string already
                                if isinstance(data, str):
                                    try:
                                        # verify it's base64
                                        base64.b64decode(data)
                                        return data
                                    except Exception:
                                        continue
                    # if we reach here, try next model
                except Exception as e:
                    last_exc = e
                    print(f"[image_service] google-genai SDK model {model} failed: {e}")
                    print(traceback.format_exc())
                    continue
            raise RuntimeError(f"Échec génération image via google-genai: {last_exc}")

        # fallback HTTP REST approach (as implemented précédemment)
        url = f"{GOOGLE_IMAGES_BASE}/v1/images:generate"
        headers = {"x-goog-api-key": api_key, "Content-Type": "application/json"}
        body = {
            "model": "image-bison-001",
            "prompt": {"text": prompt},
            "imageConfig": {"size": size}
        }
        # Diagnostic print (masquer la clé partiellement)
        try:
            masked_key = api_key[:4] + "..." if api_key else None
            print(f"[image_service] Google REST call to {url}")
            print(f"[image_service] headers: x-goog-api-key={masked_key}, Content-Type=application/json")
            print(f"[image_service] body (truncated): {json.dumps(body)[:1000]}")
            r = requests.post(url, headers=headers, json=body, timeout=60)
            print(f"[image_service] Google REST response status: {r.status_code}")
            try:
                print(f"[image_service] Google REST response body (truncated): {r.text[:2000]}")
            except Exception:
                pass
            r.raise_for_status()
            j = r.json()
        except requests.HTTPError as e:
            status = None
            try:
                status = r.status_code
            except Exception:
                pass
            if status == 404:
                raise RuntimeError(
                    "L'API de génération d'images Google n'est pas disponible pour cette clé (404). "
                    "Activez l'API images pour votre projet Google Cloud ou fournissez une clé OpenAI (DALL·E) via /admin/openai_key."
                )
            # include response text if available
            resp_text = None
            try:
                resp_text = r.text
            except Exception:
                resp_text = str(e)
            raise RuntimeError(f"Erreur Google Images REST: status={status}, resp={resp_text}")
        # Try multiple shapes: some responses put image in 'images' list with 'image' base64
        img_b64 = None
        if isinstance(j, dict):
            imgs = j.get("images") or j.get("artifacts") or []
            if imgs and isinstance(imgs, list):
                first = imgs[0]
                img_b64 = first.get("image") or first.get("b64_bytes") or first.get("b64")
        if not img_b64:
            cand = j.get("candidates") if isinstance(j, dict) else None
            if cand and isinstance(cand, list) and cand[0].get("image"):
                img_b64 = cand[0].get("image")
        if not img_b64:
            raise RuntimeError(f"Impossible d'extraire l'image depuis la réponse Google: {j}")
        return img_b64

    # Otherwise, use OpenAI Images API
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    body = {"prompt": prompt, "size": size, "n": 1, "response_format": "b64_json"}
    print(f"[image_service] OpenAI Images call to {OPENAI_IMAGES_URL}")
    try:
        print(f"[image_service] OpenAI headers: Authorization=Bearer {api_key[:4]}...")
    except Exception:
        pass
    print(f"[image_service] OpenAI body (truncated): {json.dumps(body)[:1000]}")
    r = requests.post(f"{OPENAI_IMAGES_URL}", headers=headers, json=body, timeout=60)
    print(f"[image_service] OpenAI response status: {r.status_code}")
    try:
        print(f"[image_service] OpenAI response body (truncated): {r.text[:2000]}")
    except Exception:
        pass
    r.raise_for_status()
    j = r.json()
    # OpenAI returns data[0].b64_json
    try:
        img_b64 = j["data"][0]["b64_json"]
    except Exception:
        raise RuntimeError(f"Impossible d'extraire l'image depuis la réponse OpenAI: {j}")
    return img_b64
