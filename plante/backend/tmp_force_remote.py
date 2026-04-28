import requests, json
import os
base='http://192.168.0.102:8000'
print('GET /admin/ai_mode')
try:
    r = requests.get(base + '/admin/ai_mode', timeout=10)
    print(r.status_code, r.text)
except Exception as e:
    print('err get', e)

# ensure key stored in process (read from environment)
key = os.getenv('OPENAI_API_KEY','').strip()
try:
    r = requests.post(base + '/admin/openai_key', json={'key': key}, timeout=10)
    print('POST openai_key', r.status_code, r.text)
except Exception as e:
    print('err post key', e)

try:
    r = requests.post(base + '/admin/ai_mode', json={'mode':'remote'}, timeout=10)
    print('POST ai_mode', r.status_code, r.text)
except Exception as e:
    print('err set mode', e)

# send long prompt
long_prompt = '''Bonjour, je voudrais une réponse détaillée et technique en français sur la plante Mentha × piperita (menthe poivrée).

Donnez :
1) Une description botanique complète (morphologie, feuilles, fleurs, racines, cycle de vie).
2) Son habitat naturel et conditions de culture optimales.
3) Principaux constituants chimiques (là où l'on trouve le menthol, en quelles parties et proportions approximatives).
4) Usages traditionnels et modernes (culinaires, médicinaux, cosmétiques), incluant dosages usuels pour infusion et décoction.
5) Précautions et contre‑indications (interactions médicamenteuses connues, sujets à risque, effets secondaires possibles).
6) Méthodes de conservation et de préparation (infusion, décoction, huile essentielle extraction sommaire), avec temps/quantités indicatifs.

Répondez avec des sous-titres numériques correspondant aux points ci‑dessus. Soyez précis mais concis — ciblez environ 600-900 mots pour consommer des tokens de sortie.
'''
try:
    r = requests.post(base + '/ask', json={'message': long_prompt}, timeout=120)
    print('/ask', r.status_code)
    try:
        j = r.json()
        print(json.dumps(j, ensure_ascii=False)[:4000])
    except Exception:
        print('non-json', r.text[:2000])
except Exception as e:
    print('err ask', e)
