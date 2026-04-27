import json
from pathlib import Path
import shutil
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Body, Request
from fastapi.responses import JSONResponse, FileResponse
import asyncio

# AI service
from services import ai_service
from services import image_service
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import time
import os
import traceback
from typing import List, Optional, cast
from sqlalchemy import func
from dotenv import load_dotenv

# ✅ IMPORTS PROPRES
from services import db_service, plant_service

# ✅ CONFIG API
# Load .env early so services can read PLANTNET/PLANTID keys
load_dotenv()

PLANTID_API_KEY = os.getenv('PLANTID_API_KEY', "").strip()
API_URL = os.getenv('PLANTID_API_URL', "https://api.plant.id/v3/identification").strip()

# Initialiser la base de données
db_service.initialize_database()

# FastAPI app
app = FastAPI(title="Plante API")

# CORS (développement) — adapter en production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dossier upload
BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


# Admin endpoints to control AI mode at runtime (dev convenience)
@app.get("/admin/ai_mode")
async def get_ai_mode():
    try:
        from services import config as svc_config

        # Consider an OpenAI/Gemini key present either in process config or in env
        has_key = bool(getattr(svc_config, "openai_api_key", None) or os.environ.get("OPENAI_API_KEY"))
        return {"ai_mode": svc_config.ai_mode, "has_openai_key": has_key}
    except Exception:
        return {"ai_mode": "unknown", "has_openai_key": False}


class AiModeBody(BaseModel):
    mode: str


@app.post("/admin/ai_mode")
async def set_ai_mode(body: AiModeBody):
    from services import config as svc_config

    mode = (body.mode or "").strip().lower()
    if mode not in ("auto", "local", "remote"):
        raise HTTPException(status_code=400, detail="mode must be one of: auto, local, remote")
    svc_config.ai_mode = mode
    return {"ai_mode": svc_config.ai_mode}


class AiKeyBody(BaseModel):
    key: str


@app.post("/admin/openai_key")
async def set_openai_key(body: AiKeyBody):
    """Set an OpenAI key in memory for the running process (dev only).

    WARNING: this stores the key in process memory only. Do not use in
    production without proper security/ACL.
    """
    from services import config as svc_config

    key = (body.key or "").strip()
    if not key:
        raise HTTPException(status_code=400, detail="key is required")
    svc_config.openai_api_key = key
    # also set process environment so child calls and reloads can see it
    try:
        os.environ["OPENAI_API_KEY"] = key
    except Exception:
        pass
    return {"status": "ok", "stored": bool(svc_config.openai_api_key)}


class UnsplashKeyBody(BaseModel):
    key: str


@app.post("/admin/unsplash_key")
async def set_unsplash_key(body: UnsplashKeyBody):
    """Store an Unsplash API key in memory for testing (dev only)."""
    from services import config as svc_config

    key = (body.key or "").strip()
    if not key:
        raise HTTPException(status_code=400, detail="key is required")
    # store in svc_config and env to be visible to other parts
    try:
        svc_config.unsplash_key = key
    except Exception:
        pass
    try:
        os.environ["UNSPLASH_KEY"] = key
    except Exception:
        pass
    return {"status": "ok", "stored": True}


class PlantIdKeyBody(BaseModel):
    key: str


@app.post("/admin/plantid_key")
async def set_plantid_key(body: PlantIdKeyBody):
    """Store a Plant.id API key in environment for the running process (dev only)."""
    key = (body.key or "").strip()
    if not key:
        raise HTTPException(status_code=400, detail="key is required")
    try:
        os.environ["PLANTID_API_KEY"] = key
    except Exception:
        pass
    return {"status": "ok", "stored": True}



# =========================
# ✅ ROUTE TEST
# =========================
@app.get("/health")
async def health():
    return {"status": "ok"}


# =========================
# 🔧 UTILITAIRE
# =========================
def _analysis_to_dict(a):
    return {
        "id": a.id,
        "user_id": a.user_id,
        "plant_id": a.plant_id,
        "image_path": str(a.image_path) if getattr(a, "image_path", None) else None,
        "result": a.result,
        "created_at": a.created_at.isoformat()
        if getattr(a, "created_at", None)
        else None,
    }


def _to_int(x):
    """Robustly convert an ORM id-like value to int for JSON/DB calls.

    This tries to return an int when possible and falls back to str->int.
    It's defensive against static type checkers that may view ORM attributes
    as Column[...] objects.
    """
    try:
        if isinstance(x, int):
            return x
        return int(x)
    except Exception:
        try:
            return int(str(x))
        except Exception:
            # give up and return 0 as a safe fallback
            return 0


# =========================
# 📤 UPLOAD IMAGE
# =========================
@app.post("/upload")
async def upload_image(file: UploadFile = File(...), user_id: int = Form(...)):

    # Some UploadFile implementations may have no content_type set
    content_type = file.content_type or ""
    if not content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are accepted")

    # Ensure filename is a string (UploadFile.filename can be None in some types)
    filename = file.filename or f"upload_{int(time.time() * 1000)}.jpg"
    dest = UPLOAD_DIR / filename

    i = 1
    while dest.exists():
        dest = UPLOAD_DIR / f"{dest.stem}_{i}{dest.suffix}"
        i += 1

    with dest.open("wb") as f:
        shutil.copyfileobj(file.file, f)

    analysis = db_service.create_analysis(
        user_id=user_id, image_path=str(dest), plant_id=None, result=None
    )

    return {"status": "ok", "analysis": _analysis_to_dict(analysis)}


# =========================
# 📊 LISTE ANALYSES
# =========================
@app.get("/analyses/{user_id}")
async def list_analyses(user_id: int):
    analyses = db_service.list_analyses_for_user(user_id=user_id)
    return {"results": [_analysis_to_dict(a) for a in analyses]}


# =========================
# 👤 USERS
# =========================


@app.get("/users/{user_id}")
async def get_user_endpoint(user_id: int):
    u = db_service.get_user(user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    # basic stats
    analyses = db_service.list_analyses_for_user(user_id=user_id)
    scans_total = len(analyses)
    # placeholder for rare plants / precision — compute basic values if possible
    rare_plants = 0
    try:
        plant_ids = {a.plant_id for a in analyses if getattr(a, 'plant_id', None)}
        rare_plants = len(plant_ids)
    except Exception:
        rare_plants = 0

    return {
        "id": _to_int(getattr(u, 'id')),
        "email": getattr(u, 'email', None),
        "full_name": getattr(u, 'full_name', None),
        "is_active": getattr(u, 'is_active', True),
        "scans_total": scans_total,
        "rare_plants": rare_plants,
        "is_premium": False,
    }


# =========================
# 🖼️ IMAGE ANALYSE
# =========================
@app.get("/analyses/{analysis_id}/image")
async def get_analysis_image(analysis_id: int):
    analysis = db_service.get_analysis_by_id(analysis_id)

    if not analysis:
        raise HTTPException(status_code=404, detail="Not found")

    image_path = getattr(analysis, "image_path", None)
    if not image_path:
        raise HTTPException(status_code=404, detail="No image for this analysis")

    # static type checkers see SQLAlchemy Columns as Column[str]; cast to str for FileResponse
    path_str = cast(str, image_path)
    return FileResponse(path_str)


# =========================
# ❌ DELETE ANALYSE
# =========================
@app.delete("/analyses/{analysis_id}")
async def delete_analysis(analysis_id: int):
    db_service.delete_analysis(analysis_id)
    return {"status": "deleted"}


# =========================
# 🤖 IDENTIFICATION PLANTE
# =========================
@app.post("/identify")
async def identify(images: List[str] = Body(...), user_id: Optional[int] = Body(0)):

    if not images:
        raise HTTPException(status_code=400, detail="No images")

    image_b64 = images[0]

    # Sauvegarde image
    image_path = plant_service.save_base64_image(image_b64, UPLOAD_DIR)

    # Appel API externe (PlantNet-like) via wrapper with retries
    data = plant_service.call_plant_api(image_b64)
    # If call_plant_api returns an error dict, map to HTTP statuses
    if isinstance(data, dict) and data.get("error"):
        err = data.get("error", "Erreur API")
        if "Clé API invalide" in err:
            raise HTTPException(status_code=401, detail=err)
        if "Accès refusé" in err:
            raise HTTPException(status_code=403, detail=err)
        if "Trop de requêtes" in err:
            raise HTTPException(status_code=429, detail=err)
        if "Timeout" in err:
            raise HTTPException(status_code=504, detail="Le serveur ne répond pas (timeout)")
        if "Serveur API indisponible" in err:
            raise HTTPException(status_code=502, detail=err)
        # default
        raise HTTPException(status_code=502, detail=err)

    # Format result if possible (fallback to raw JSON)
    try:
        result_text = plant_service.format_result(data)
    except Exception:
        result_text = json.dumps(data)

    # Extraire nom plante
    plant_name = None
    try:
        plant_name = data["result"]["classification"]["suggestions"][0]["name"]
    except Exception:
        # ignore parsing errors and keep plant_name as None
        pass

    # Sauvegarde DB
    uid: int = user_id if user_id is not None else 0
    analysis = db_service.create_analysis(
        user_id=uid, image_path=image_path, plant_id=plant_name, result=json.dumps(data)
    )

    return {
        "status": "ok",
        "result": result_text,
        "analysis": _analysis_to_dict(analysis),
    }


@app.post("/identify_plantnet")
async def identify_plantnet(images: List[str] = Body(...), user_id: Optional[int] = Body(0)):
    """Identify via PlantNet API. Returns clear errors for 401/403/timeout."""
    if not images:
        raise HTTPException(status_code=400, detail="No images")

    image_b64 = images[0]

    # Sauvegarde image
    image_path = plant_service.save_base64_image(image_b64, UPLOAD_DIR)

    # Appel PlantNet
    try:
        data = plant_service.call_plantnet_api(image_b64)
    except RuntimeError as e:
        msg = str(e)
        # map common messages to HTTP statuses for client clarity
        if "Clé API invalide" in msg:
            raise HTTPException(status_code=401, detail=msg)
        if "Accès refusé" in msg:
            raise HTTPException(status_code=403, detail=msg)
        if "Timeout" in msg:
            raise HTTPException(status_code=504, detail="Le serveur PlantNet ne répond pas (timeout)")
        # generic 502 for other service errors
        raise HTTPException(status_code=502, detail=f"PlantNet error: {msg}")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"PlantNet unexpected error: {e}")

    # Sauvegarde DB
    uid: int = user_id if user_id is not None else 0
    analysis = db_service.create_analysis(
        user_id=uid, image_path=image_path, plant_id=None, result=json.dumps(data)
    )

    return {"status": "ok", "result": data, "analysis": _analysis_to_dict(analysis)}


# =========================
# 💬 ASK ENDPOINTS (développement)
# =========================


class AskRequest(BaseModel):
    message: str
    conversation_id: Optional[int] = None
    user_id: Optional[int] = 0


@app.get("/ask")
async def ask_get(request: Request):
    client = request.client.host if request.client else "unknown"
    print(f"[ASK GET] from {client}")
    return {
        "status": "ok",
        "message": 'POST /ask with JSON {"message":"..."} to get a reply',
    }


@app.post("/ask")
async def ask_post(request: Request, payload: AskRequest = Body(...)):
    client = request.client.host if request.client else "unknown"
    print(f"[ASK POST] from {client} payload={payload.dict()}")
    q = (payload.message or "").strip()
    if not q:
        raise HTTPException(status_code=400, detail="message is required")

    try:
        # store user message into a conversation (create if needed)
        conv_id = payload.conversation_id or None
        uid = int(payload.user_id or 0)
        if not conv_id:
            conv = db_service.create_conversation(user_id=uid, title=(q[:120] if q else None))
            conv_id = _to_int(getattr(conv, "id"))
        # add user message
        try:
            db_service.add_message(_to_int(conv_id), "user", q)
        except Exception:
            # non-fatal: continue even if message storage fails
            traceback.print_exc()

        # appeler la fonction bloquante dans un thread pour éviter de bloquer l'event loop
        result = await asyncio.to_thread(ai_service.get_ai_answer, q)
        # `get_ai_answer` retourne désormais (text, tokens)
        if isinstance(result, tuple) and len(result) == 2:
            answer_text, tokens_used = result
        else:
            answer_text = result
            tokens_used = 0

        # store assistant reply
        try:
            db_service.add_message(_to_int(conv_id), "assistant", answer_text or "")
        except Exception:
            traceback.print_exc()
    except Exception as e:
        print(f"[ASK ERROR] {e}")
        traceback.print_exc()
        raise HTTPException(status_code=502, detail=str(e))

    return JSONResponse({"status": "ok", "answer": answer_text, "tokens_used": tokens_used, "conversation_id": conv_id})


class ImageRequest(BaseModel):
    prompt: str
    size: Optional[str] = "1024x1024"


@app.post("/generate_image")
async def generate_image(request: Request, payload: ImageRequest = Body(...)):
    q = (payload.prompt or "").strip()
    if not q:
        raise HTTPException(status_code=400, detail="prompt is required")
    try:
        size = payload.size or "1024x1024"
        img_b64 = await asyncio.to_thread(image_service.generate_image, q, size)
    except Exception as e:
        print(f"[IMAGE ERROR] {e}")
        traceback.print_exc()
        raise HTTPException(status_code=502, detail=str(e))

    # return base64 string (client can prepend data:image/png;base64,)
    return JSONResponse({"status": "ok", "image_b64": img_b64})


# =========================
# 🗂️ Conversations / Messages
# =========================


class ConversationCreate(BaseModel):
    user_id: Optional[int] = 0
    title: Optional[str] = None


class MessageCreate(BaseModel):
    role: str
    content: str


@app.post("/conversations")
async def create_conversation_endpoint(payload: ConversationCreate = Body(...)):
    conv = db_service.create_conversation(user_id=payload.user_id or 0, title=payload.title)
    return {"status": "ok", "conversation": {"id": _to_int(getattr(conv, 'id')), "user_id": conv.user_id, "title": conv.title, "created_at": conv.created_at.isoformat()}}


@app.get("/conversations/{user_id}")
async def list_conversations(user_id: int):
    convs = db_service.list_conversations_for_user(user_id=user_id)
    out = []
    for c in convs:
        # try to grab last message summary
        last = None
        try:
            msgs = db_service.list_messages_for_conversation(_to_int(getattr(c, 'id')), limit=1, offset=max(0, 0))
            if msgs:
                m = msgs[-1]
                # ensure content is a plain string before len/slicing to satisfy static checkers
                raw = getattr(m, 'content', '') or ''
                content = str(raw)
                summary = (content[:200] + '...') if len(content) > 200 else content
                last = {"role": m.role, "content": summary, "created_at": m.created_at.isoformat()}
        except Exception:
            last = None
        out.append({"id": _to_int(getattr(c, 'id')), "user_id": c.user_id, "title": c.title, "created_at": c.created_at.isoformat(), "last_message": last})
    return {"results": out}


@app.get("/conversations/{conv_id}/messages")
async def get_conversation_messages(conv_id: int):
    msgs = db_service.list_messages_for_conversation(conv_id)
    out = []
    for m in msgs:
        out.append({"id": _to_int(getattr(m, 'id')), "role": m.role, "content": m.content, "created_at": m.created_at.isoformat()})
    return {"results": out}


@app.post("/conversations/{conv_id}/messages")
async def post_conversation_message(conv_id: int, payload: MessageCreate = Body(...)):
    msg = db_service.add_message(conv_id, payload.role or "user", payload.content or "")
    return {"status": "ok", "message": {"id": _to_int(getattr(msg, 'id')), "role": msg.role, "content": msg.content, "created_at": msg.created_at.isoformat()}}


# =========================
# 🌿 PLANTS
# =========================


@app.get("/plants")
async def list_plants_endpoint(category: Optional[str] = None):
    # accept category (e.g. 'comestible' or 'médicinale') to filter
    plants = db_service.list_plants(category=category)
    out = []
    for p in plants:
        out.append({
            "id": _to_int(getattr(p, 'id')),
            "scientific_name": getattr(p, 'scientific_name', None),
            "common_name": getattr(p, 'common_name', None),
            "category": getattr(p, 'category', None),
            "description": getattr(p, 'description', None),
        })
    return {"results": out}


# =========================
# 🍽️ MENU CONFIGURATION
# =========================


@app.get("/menu")
async def get_menu():
    """Return a structured menu configuration used by the frontend.

    The menu is intentionally simple: a set of static entries plus
    dynamic category entries derived from plants present in the DB.
    Each menu item contains: id, label, icon (material icon name),
    route (frontend route or special action), order and optional
    permission (e.g. 'premium').
    """
    try:
        plants = db_service.list_plants()
    except Exception:
        plants = []

    # collect categories (preserve insertion order)
    seen = []
    for p in plants:
        try:
            c = (getattr(p, 'category', '') or '').strip()
            if c and c not in seen:
                seen.append(c)
        except Exception:
            continue

    menu = []
    # static primary items
    menu.append({"id": "home", "label": "ACCUEIL", "icon": "home", "route": "/", "order": 10})
    menu.append({"id": "profile", "label": "PROFIL", "icon": "person", "route": "/profile", "order": 20})
    menu.append({"id": "history", "label": "HISTORIQUE", "icon": "history", "route": "/history", "order": 30})
    menu.append({"id": "dashboard", "label": "TABLEAU DE BORD", "icon": "dashboard", "route": "/dashboard", "order": 40})

    # dynamic categories
    base_order = 100
    for i, c in enumerate(seen):
        menu.append({
            "id": "cat_${i}",
            "label": c.capitalize(),
            "icon": "local_florist",
            "route": "/plants?category=${c}",
            "order": base_order + i,
        })

    # footer items
    menu.append({"id": "settings", "label": "PARAMÈTRES", "icon": "settings", "route": "/settings", "order": 1000})
    menu.append({"id": "help", "label": "AIDE", "icon": "help", "route": "/help", "order": 1010})

    # sort by order and return
    try:
        menu_sorted = sorted(menu, key=lambda x: x.get("order", 9999))
    except Exception:
        menu_sorted = menu

    return {"items": menu_sorted}


if __name__ == "__main__":
    # Run uvicorn when invoked as a script (prevents reloader spawn issues)
    try:
        import uvicorn

        uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
    except Exception as e:
        print(f"Failed to start uvicorn via __main__: {e}")


@app.get("/dashboard")
async def get_dashboard():
    """Return simple dashboard data used by the Flutter frontend.

    Format:
    {
      "stats": { "total_scans": int, "percent_toxic": "12.4%", "species_count": int },
      "donut": { "comestible": "65%", "medicinal": "20%", "toxic": "15%", "dominant": "Comestible" },
      "alerts": [ {"title":"...","subtitle":"...","actionLabel":"Voir","color":"<decimal int>","time":"HIER"}, ... ]
    }
    The endpoint is tolerant: if the DB or tables are missing it returns empty/default values.
    """
    try:
        try:
            # import models/session robustly (same pattern as db_service)
            from models import get_session, Analysis, Plant
        except Exception:
            from backend.models import get_session, Analysis, Plant

        with get_session() as session:
            total_scans = int(session.query(func.count(Analysis.id)).scalar() or 0)
            species_count = int(
                session.query(func.count(func.distinct(Analysis.plant_id))).filter(Analysis.plant_id != None).scalar() or 0
            )

            # counts per category (join Analysis->Plant)
            q = (
                session.query(func.lower(func.coalesce(Plant.category, '')), func.count(Analysis.id))
                .join(Plant, Plant.id == Analysis.plant_id)
                .group_by(func.lower(func.coalesce(Plant.category, '')))
                .all()
            )
            counts = { (c or ''): int(n) for c, n in q }

            com = counts.get('comestible', 0)
            med = counts.get('médicinale', counts.get('medicinal', 0))
            tox = counts.get('toxique', counts.get('toxique', 0))

            # donut percentages relative to category-known analyses
            cat_total = com + med + tox
            def pct(n, base=total_scans):
                try:
                    return f"{(n * 100.0 / base):.1f}%" if base and base > 0 else '—'
                except Exception:
                    return '—'

            percent_toxic = pct(tox, total_scans)

            donut = {
                'comestible': pct(com, cat_total),
                'medicinal': pct(med, cat_total),
                'toxic': pct(tox, cat_total),
                'dominant': '—',
            }

            # determine dominant
            if cat_total > 0:
                dom = max(('comestible', 'medicinal', 'toxic'), key=lambda k: {'comestible': com, 'medicinal': med, 'toxic': tox}.get(k, 0))
                names = {'comestible': 'Comestible', 'medicinal': 'Médicinales', 'toxic': 'Toxiques'}
                donut['dominant'] = names.get(dom, dom)

            # simple alert rules
            alerts = []
            try:
                if total_scans > 0 and tox * 100.0 / max(1, total_scans) > 10.0:
                    alerts.append({
                        'title': 'Taux de plantes toxiques élevé',
                        'subtitle': f'{percent_toxic} des analyses récentes sont signalées toxiques.',
                        'actionLabel': 'Vérifier',
                        'color': str(0xFFba1a1a),
                        'time': 'AUJOURD\'HUI',
                    })
                if species_count > 50:
                    alerts.append({
                        'title': 'Grande diversité détectée',
                        'subtitle': f'{species_count} espèces identifiées récemment.',
                        'actionLabel': 'Explorer',
                        'color': str(0xFF2e7d32),
                        'time': 'HIER',
                    })
            except Exception:
                alerts = []

            return {
                'stats': {'total_scans': total_scans, 'percent_toxic': percent_toxic, 'species_count': species_count},
                'donut': donut,
                'alerts': alerts,
            }
    except Exception as e:
        print(f"/dashboard error: {e}")
        traceback.print_exc()
        return {'stats': {}, 'donut': {}, 'alerts': []}


@app.get("/plants/{plant_id}")
async def get_plant_endpoint(plant_id: int):
    p = db_service.get_plant_by_id(plant_id)
    if not p:
        raise HTTPException(status_code=404, detail="Not found")
    return {
        "id": _to_int(getattr(p, 'id')),
        "scientific_name": p.scientific_name,
        "common_name": p.common_name,
        "description": p.description,
    }


# =========================
# 🚀 LANCEMENT
# =========================
if __name__ == "__main__":
    import uvicorn

    # Expose the server on all interfaces so emulators/devices can reach it
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
