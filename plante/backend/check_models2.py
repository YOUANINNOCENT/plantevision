import requests
import os
key = os.getenv("OPENAI_API_KEY", "").strip()
url = 'https://generativelanguage.googleapis.com/v1/models'
r = requests.get(url, headers={'x-goog-api-key': key}, timeout=60)
print('STATUS', r.status_code)
print(r.text[:4000])
