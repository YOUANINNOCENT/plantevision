import requests, json
base='http://192.168.0.102:8000'
import os
key = os.getenv('OPENAI_API_KEY','').strip()
print('Posting key...')
r1 = requests.post(base + '/admin/openai_key', json={'key': key}, timeout=10)
print('post key', r1.status_code, r1.text)
print('Set ai_mode remote...')
r2 = requests.post(base + '/admin/ai_mode', json={'mode':'remote'}, timeout=10)
print('set mode', r2.status_code, r2.text)
print('GET ai_mode')
r3 = requests.get(base + '/admin/ai_mode', timeout=10)
print('get', r3.status_code, r3.text)

long_prompt = 'Explique en détail la biosynthèse du menthol dans Mentha × piperita, décris les voies métaboliques impliquées, enzymes clefs, localisation cellulaire et organique, et facteurs environnementaux qui influencent la production de menthol.'
r4 = requests.post(base + '/ask', json={'message': long_prompt}, timeout=120)
print('/ask', r4.status_code)
try:
    print(r4.json())
except Exception:
    print('non-json', r4.text[:2000])
