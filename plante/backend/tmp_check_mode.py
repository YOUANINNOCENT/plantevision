import requests
r = requests.get('http://192.168.0.102:8000/admin/ai_mode', timeout=5)
print(r.status_code, r.text)
