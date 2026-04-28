import requests, json, base64
import logging

logger = logging.getLogger(__name__)
base='http://192.168.0.102:8000'
# ensure the Gemini key is stored (it already is, but repost to be safe)
import os
# key (read from env when needed)
key = os.getenv('OPENAI_API_KEY','').strip()
# requests.post(base + '/admin/openai_key', json={'key': key}, timeout=30)
logger.info('Calling /generate_image...')
r = requests.post(base + '/generate_image', json={'prompt':'Une feuille de menthe sur fond blanc, photographie réaliste','size':'512x512'}, timeout=180)
logger.info('STATUS %s', r.status_code)
logger.debug('%s', r.text[:4000])
try:
    j = r.json()
    logger.info('JSON keys %s', list(j.keys()))
except Exception as e:
    logger.exception('No JSON')
