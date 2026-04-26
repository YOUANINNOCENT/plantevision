import requests
base='http://127.0.0.1:8000'
import os
key = os.getenv('OPENAI_API_KEY','').strip()
try:
    r1 = requests.post(base + '/admin/openai_key', json={'key': key}, timeout=10)
    print('POST key', r1.status_code)
    try:
        print(r1.json())
    except:
        print(r1.text[:1000])
except Exception as e:
    print('error post key', e)

try:
    r2 = requests.get(base + '/admin/ai_mode', timeout=10)
    print('GET ai_mode', r2.status_code)
    try:
        print(r2.json())
    except:
        print(r2.text[:1000])
except Exception as e:
    print('error get ai_mode', e)

try:
    r3 = requests.post(base + '/ask', json={'message':'Bonjour, test accès IA'}, timeout=60)
    print('/ask', r3.status_code)
    try:
        print(r3.json())
    except:
        print(r3.text[:1000])
except Exception as e:
    print('error ask', e)
