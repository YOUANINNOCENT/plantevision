import requests, json
base='http://192.168.0.102:8000'
import os
key = os.getenv('OPENAI_API_KEY','').strip()
print('POST openai_key')
try:
    r = requests.post(base + '/admin/openai_key', json={'key': key}, timeout=10)
    print('posted key', r.status_code)
except Exception as e:
    print('post key error', e)

print('SET ai_mode remote')
try:
    r2 = requests.post(base + '/admin/ai_mode', json={'mode':'remote'}, timeout=10)
    print('set mode', r2.status_code, r2.text)
except Exception as e:
    print('set mode error', e)

long_prompt = '''Bonjour, rédigez une réponse technique et détaillée en français (environ 600-900 mots) sur Mentha × piperita (menthe poivrée) couvrant:
1) description botanique (morphologie, feuilles, fleurs, racines, cycle de vie)
2) habitat naturel et conditions de culture
3) principaux constituants chimiques et localisation (menthol, etc.)
4) usages traditionnels et modernes (culinaires, médicinaux, cosmétiques) avec dosages usuels pour infusion/décoction
5) précautions, interactions, contre-indications
6) méthodes de conservation et préparation (temps/quantités indicatifs)
Répondez avec des sections numérotées.
'''
print('CALL /ask')
try:
    r3 = requests.post(base + '/ask', json={'message': long_prompt}, timeout=180)
    print('/ask status', r3.status_code)
    try:
        j = r3.json()
        print(json.dumps(j, ensure_ascii=False)[:8000])
    except Exception:
        print('non-json', r3.text[:8000])
except Exception as e:
    print('ask error', e)
