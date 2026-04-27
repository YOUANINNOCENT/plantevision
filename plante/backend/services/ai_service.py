import os
import json
import time
import requests
from typing import Any, Dict, Optional, Union
from services import config as svc_config

OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"


def get_ai_answer(message: str, system_prompt: str | None = None) -> tuple[str, int]:
    """Appel synchrone à l'API OpenAI Chat completions.

    Retourne le texte de la réponse. Lance une exception en cas d'erreur.
    Nécessite la variable d'environnement `OPENAI_API_KEY`.
    """
    # Respecter le mode configuré
    mode = getattr(svc_config, "ai_mode", "auto")
    # Prefer in-memory key if provided by admin, else environment variable
    api_key = getattr(svc_config, "openai_api_key", None) or os.environ.get("OPENAI_API_KEY")

    def _mask(k: str | None) -> str:
        if not k:
            return "(none)"
        if len(k) <= 8:
            return k
        return f"{k[:4]}...{k[-4:]}"

    # Force local fallback
    if mode == "local":
        api_key = None

    # Force remote mode but clée absente => erreur
    if mode == "remote" and not api_key:
        raise RuntimeError("AI mode 'remote' requis mais OPENAI_API_KEY est absente")

    if not api_key:
        # fallback: réponse locale simple, non-echo, pour développement hors-ligne
        m = (message or "").strip().lower()
        # salutations
        if any(w in m for w in ["bonjour", "salut", "coucou", "hello"]):
            return ("Bonjour ! Je suis votre assistant botanique hors-ligne — comment puis-je vous aider ?", 0)
        if "comment tu vas" in m or "ça va" in m or "ca va" in m:
            return ("Je vais bien, merci — prêt à vous aider avec des informations sur les plantes.", 0)
        # identifier une plante
        if any(w in m for w in ["identifier", "quelle plante", "c'est quelle plante", "quelle est cette plante"]):
            return (
                "Pour identifier une plante, envoyez une photo nette de la feuille et de la fleur si possible. "
                "Donnez aussi le lieu et la saison. Je proposerai des suggestions probables.",
                0,
            )
        # préparations (infusion / décoction)
        if any(w in m for w in ["décoction", "decoction", "infusion", "préparer", "préparation"]):
            return (
                "Infusion: verser eau chaude sur les parties tendres (feuilles, fleurs) et laisser 5–10 min. "
                "Décoction: faire bouillir les parties dures (racines, écorces) 10–30 min selon la matière.",
                0,
            )
        # sécurité / comestible
        if any(w in m for w in ["comestible", "manger", "toxique", "poison"]):
            return (
                "N'allez pas consommer une plante sans certitude. Recherchez des sources fiables ou demandez l'avis d'un expert. "
                "La même espèce peut comporter des variétés toxiques.",
                0,
            )

        # question générique: fournir piste utile
        return (
            "Je n'ai pas accès à l'API distante ici. Je peux aider pour l'identification, les préparations (infusion/décoction) "
            "et les précautions. Posez une question précise. "
            "Pour activer les réponses IA complètes, fournissez une clé (OpenAI ou Gemini) en définissant la variable d'environnement "
            "OPENAI_API_KEY ou en utilisant l'endpoint d'administration POST /admin/openai_key.",
            0,
        )

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    system = system_prompt or "You are a helpful botanical assistant. Answer concisely in French."

    # Allow overriding max tokens via environment for testing
    try:
        # Increase default max tokens to allow longer replies; can be overridden
        # by setting the environment variable OPENAI_MAX_TOKENS.
        max_tokens_val = int(os.environ.get("OPENAI_MAX_TOKENS") or 2048)
    except Exception:
        max_tokens_val = 2048

    payload = {
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": message},
        ],
        "max_tokens": max_tokens_val,
        "temperature": 0.2,
    }

    # If the key looks like a Google/Gemini API key (starts with 'AIza' or 'AQ.'), call Gemini
    if api_key and (api_key.startswith("AIza") or api_key.startswith("AQ.")):
        print(f"[AI-SERVICE] Using Gemini key { _mask(api_key) } - calling Gemini API")
        try:
            j = _call_google_generative(message, api_key, None, max_tokens_val)
            # Some Gemini responses may already be raw text; handle both dict and str
            if isinstance(j, str):
                return j, 0
            text = _extract_gemini_text(j)
            # try to extract token usage from Gemini response variants
            tokens = None
            try:
                if isinstance(j, dict):
                    meta = j.get("metadata") or {}
                    tu = meta.get("tokenUsage") or meta.get("token_usage") or {}
                    tokens = tu.get("totalTokens") or tu.get("total_tokens")
                    if tokens is None:
                        tokens = j.get("totalTokens") or j.get("total_tokens")
                    if tokens is None:
                        c = (j.get("candidates") or [])
                        if c and isinstance(c[0], dict):
                            cm = c[0].get("metadata") or {}
                            tokens = cm.get("tokenUsage") or cm.get("token_usage") or cm.get("totalTokens")
            except Exception:
                tokens = None
            return text, int(tokens or 0)
        except Exception as e:
            print(f"[AI-SERVICE][ERROR] Gemini call failed: {e}")
            raise

    print(f"[AI-SERVICE] Using OpenAI path with key {_mask(api_key)}")
    print(f"[AI-SERVICE] POST {OPENAI_API_URL} payload={json.dumps(payload)[:1000]}")
    # Retryable POST with exponential backoff for transient 5xx errors or connection issues
    attempts = 3
    resp = None
    for attempt in range(attempts):
        try:
            resp = requests.post(OPENAI_API_URL, headers=headers, data=json.dumps(payload), timeout=30)
            print(f"[AI-SERVICE] OpenAI HTTP {resp.status_code} - resp_len={len(resp.content or b'')}")

            # Server error: retry a few times
            if 500 <= resp.status_code < 600:
                body = resp.text if hasattr(resp, 'text') else '<no body>'
                print(f"[AI-SERVICE][WARN] OpenAI transient HTTP {resp.status_code}: {body}")
                if attempt < attempts - 1:
                    sleep = 1 * (2 ** attempt)
                    print(f"[AI-SERVICE] Retrying in {sleep}s...")
                    time.sleep(sleep)
                    continue
                # persistent server error -> return controlled message to caller
                return (f"Erreur de connexion au service IA (HTTP {resp.status_code}). Veuillez réessayer plus tard.", 0)

            # Client error (bad request / auth) -> return informative message
            if 400 <= resp.status_code < 500:
                body = resp.text if hasattr(resp, 'text') else '<no body>'
                print(f"[AI-SERVICE][ERROR] OpenAI returned HTTP {resp.status_code}: {body}")
                if resp.status_code == 401 or resp.status_code == 403:
                    return ("Clé API invalide ou accès refusé pour le service IA.", 0)
                return (f"Erreur API ({resp.status_code}) du service IA. Voir les logs serveur.", 0)

            # success (2xx) -> proceed
            break

        except requests.RequestException as e:
            print(f"[AI-SERVICE][WARN] OpenAI request failed ({type(e).__name__}): {e}")
            if attempt < attempts - 1:
                sleep = 1 * (2 ** attempt)
                print(f"[AI-SERVICE] Retrying in {sleep}s...")
                time.sleep(sleep)
                continue
            return ("Erreur de connexion au service IA (réseau). Veuillez vérifier votre connexion et réessayer.", 0)

    # At this point resp should be a successful Response
    try:
        j = resp.json()
    except Exception as e:
        body = getattr(resp, 'text', '<no body>')
        print(f"[AI-SERVICE][ERROR] Failed to decode OpenAI JSON: {e} - body={body}")
        return ("Réponse invalide reçue du service IA.", 0)

    # extraire le contenu et l'usage tokens
    try:
        content = j["choices"][0]["message"]["content"].strip()
        usage = j.get("usage") or {}
        total = usage.get("total_tokens") or usage.get("totalTokens") or 0
        return content, int(total or 0)
    except Exception as e:
        raise RuntimeError(f"Impossible de parser la réponse IA: {e} - {j}")


def _call_google_generative(message: str, api_key: str, model: str | None = None, max_output_tokens: int = 1024) -> Union[Dict[str, Any], str]:
    """Appel à l'API Generative Language (Gemini).

    Utilise l'endpoint REST `v1/models/{model}:generateContent` avec l'entête
    `x-goog-api-key`. Si `model` est None ou introuvable, on tente de lister
    les modèles disponibles et d'en choisir un adapté.
    """
    headers = {"Content-Type": "application/json", "x-goog-api-key": api_key}
    base = "https://generativelanguage.googleapis.com"

    def _format_model(m: str) -> str:
        if m.startswith("models/"):
            return m
        return f"models/{m}"

    # helper to perform a generateContent call for a fully-qualified model name
    def _gen_call(full_model_name: str) -> Dict[str, Any]:
        url = f"{base}/v1/{full_model_name}:generateContent"
        body = {
            "contents": [
                {"role": "user", "parts": [{"text": message}]}
            ],
            "generationConfig": {"temperature": 0.2, "maxOutputTokens": max_output_tokens},
        }
        print(f"[AI-SERVICE] Gemini POST {url} headers_preview={{'x-goog-api-key': '***'}} body_preview={json.dumps(body)[:1000]}")
        # Retry on transient 5xx errors
        attempts = 3
        r = None
        for attempt in range(attempts):
            try:
                r = requests.post(url, headers=headers, json=body, timeout=30)
                print(f"[AI-SERVICE] Gemini HTTP {r.status_code} response_len={len(r.content or b'')}")
                r.raise_for_status()
                try:
                    data = r.json()
                    if not isinstance(data, dict):
                        raise RuntimeError(f"Unexpected Gemini JSON type: {type(data).__name__}")
                    return data
                except Exception as e:
                    print(f"[AI-SERVICE][ERROR] Failed to parse Gemini JSON: {e} - body={r.text}")
                    raise
            except requests.HTTPError as e:
                status = r.status_code if r is not None else None
                # retry on server errors
                if status and 500 <= status < 600 and attempt < attempts - 1:
                    sleep = 1 * (2 ** attempt)
                    print(f"[AI-SERVICE] Gemini transient HTTP {status}, retrying in {sleep}s...")
                    time.sleep(sleep)
                    continue
                print(f"[AI-SERVICE][ERROR] Gemini HTTP error: {e}")
                raise
            except Exception as e:
                if attempt < attempts - 1:
                    sleep = 1 * (2 ** attempt)
                    print(f"[AI-SERVICE] Gemini request failed ({type(e).__name__}), retrying in {sleep}s...")
                    time.sleep(sleep)
                    continue
                print(f"[AI-SERVICE][ERROR] Gemini request failed final: {e}")
                raise
        # If we exit the retry loop without returning, raise an explicit error
        raise RuntimeError(f"Gemini request failed for model {full_model_name} after {attempts} attempts")

    # If a model was supplied, try it first
    tried_models = []
    if model:
        full = _format_model(model)
        tried_models.append(full)
        try:
            j = _gen_call(full)
            # extract generated text
            return _extract_gemini_text(j)
        except requests.HTTPError as e:
            # if 404 or model-not-found, we will fallback to listing models
            print(f"[AI-SERVICE] Gemini model {full} call failed: {e}")

    # List available models and pick a suitable top candidate (gemini-*)
    try:
        list_url = f"{base}/v1/models"
        print(f"[AI-SERVICE] Listing Gemini models {list_url}")
        r = requests.get(list_url, headers=headers, timeout=20)
        print(f"[AI-SERVICE] Models list HTTP {r.status_code}")
        r.raise_for_status()
        mj = r.json()
        models = [m.get("name") for m in mj.get("models", []) if m.get("name")]
    except Exception as e:
        print(f"[AI-SERVICE][ERROR] Failed to list Gemini models: {e}")
        models = []

    # choose first gemini-* model if present
    chosen = None
    for m in models:
        if m and "gemini" in m.lower():
            chosen = m
            break
    if not chosen and models:
        chosen = models[0]

    if not chosen:
        raise RuntimeError("Aucun modèle Gemini disponible pour la clé fournie (liste vide)")

    if chosen in tried_models:
        raise RuntimeError(f"Modèle déjà essayé et introuvable: {chosen}")

    try:
        j = _gen_call(chosen)
        return _extract_gemini_text(j)
    except Exception as e:
        print(f"[AI-SERVICE][ERROR] Final Gemini call failed for {chosen}: {e}")
        raise


def _extract_gemini_text(j: Optional[Dict[str, Any]]) -> str:
    """Extraire le texte à partir d'une réponse GenerateContentResponse.

    Valide que `j` est un dictionnaire et lève une erreur claire sinon.
    """
    if not isinstance(j, dict):
        raise RuntimeError(f"Invalid Gemini response type: {type(j).__name__} - expected dict")
    try:
        candidates = j.get("candidates") or []
        if not candidates:
            raise RuntimeError(f"No candidates in Gemini response: {j}")

        # Choose the candidate with the most combined parts text to avoid short/truncated candidates
        def candidate_length(cand: dict) -> int:
            cont = cand.get("content") or {}
            parts = cont.get("parts") or []
            total = 0
            for p in parts:
                if isinstance(p, dict) and p.get("text"):
                    total += len(p.get("text") or "")
                elif isinstance(p, str):
                    total += len(p)
            if total == 0 and isinstance(cont, dict) and cont.get("text"):
                total = len(cont.get("text") or "")
            return total

        best = max(candidates, key=candidate_length)
        content = best.get("content") or {}
        parts = content.get("parts") or []

        texts = []
        for p in parts:
            if isinstance(p, dict):
                t = p.get("text")
                if isinstance(t, str) and t.strip():
                    texts.append(t.strip())
            elif isinstance(p, str) and p.strip():
                texts.append(p.strip())

        # fallback: some responses put text directly under content.text
        if not texts and isinstance(content, dict) and content.get("text"):
            txt = content.get("text")
            if isinstance(txt, str) and txt.strip():
                texts.append(txt.strip())

        if texts:
            # join with blank line to improve readability
            return "\n\n".join(texts).strip()

        raise RuntimeError(f"Cannot extract usable text from Gemini response: {j}")
    except Exception as e:
        raise RuntimeError(f"Impossible de parser la réponse Gemini: {e} - {j}")
