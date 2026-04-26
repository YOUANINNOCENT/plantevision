import requests, json
base='http://127.0.0.1:8000'
import os
key = os.getenv('OPENAI_API_KEY','').strip()
try:
    r1 = requests.post(base + '/admin/openai_key', json={'key': key}, timeout=30)
    print('POST /admin/openai_key', r1.status_code)
    try:
        print(r1.json())
    except:
        print(r1.text[:1000])
except Exception as e:
    print('error post key', e)

try:
    r2 = requests.post(base + '/admin/ai_mode', json={'mode':'remote'}, timeout=30)
    print('POST /admin/ai_mode', r2.status_code)
    try:
        print(r2.json())
    except:
        print(r2.text[:1000])
except Exception as e:
    print('error set ai_mode', e)
