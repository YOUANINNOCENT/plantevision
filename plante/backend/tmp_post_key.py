import requests, json
base='http://192.168.0.102:8000'
import os
key = os.getenv('OPENAI_API_KEY','').strip()
print('Posting key to /admin/openai_key')
try:
    r1 = requests.post(base + '/admin/openai_key', json={'key': key}, timeout=30)
    print('openai_key status', r1.status_code)
    try:
        print('openai_key resp', r1.json())
    except:
        print('openai_key body', r1.text[:1000])
except Exception as e:
    print('openai_key error', e)

print('Setting ai_mode to remote')
try:
    r2 = requests.post(base + '/admin/ai_mode', json={'mode':'remote'}, timeout=30)
    print('ai_mode status', r2.status_code)
    try:
        print('ai_mode resp', r2.json())
    except:
        print('ai_mode body', r2.text[:1000])
except Exception as e:
    print('ai_mode error', e)

print('Checking admin/ai_mode GET')
try:
    r3 = requests.get(base + '/admin/ai_mode', timeout=10)
    print('GET ai_mode', r3.status_code)
    try:
        print('GET ai_mode body', r3.json())
    except:
        print('GET ai_mode text', r3.text[:1000])
except Exception as e:
    print('GET ai_mode error', e)

print('Calling /ask')
try:
    r4 = requests.post(base + '/ask', json={'message':'Bonjour, test accès IA'}, timeout=60)
    print('ask status', r4.status_code)
    try:
        print('ask resp', r4.json())
    except Exception:
        print('ask body', r4.text[:1000])
except Exception as e:
    print('ask error', e)
