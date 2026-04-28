import requests, base64, json
base='http://192.168.0.102:8000'
# store key
import os
k = os.getenv('OPENAI_API_KEY','').strip()
r1 = requests.post(base + '/admin/openai_key', json={'key': k}, timeout=30)
print('store key status', r1.status_code, r1.text)
# set ai_mode remote
r2 = requests.post(base + '/admin/ai_mode', json={'mode':'remote'}, timeout=30)
print('set mode', r2.status_code, r2.text)
# call generate_image
r = requests.post(base + '/generate_image', json={'prompt':'Une feuille de menthe sur fond blanc, photographie réaliste','size':'512x512'}, timeout=120)
print('generate status', r.status_code)
print(r.text[:2000])
try:
    j=r.json()
    img=j.get('image_b64')
    if img:
        data=base64.b64decode(img)
        open('sortie.png','wb').write(data)
        print('Saved sortie.png bytes:', len(data))
except Exception as e:
    print('JSON/save error', e)
