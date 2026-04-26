import requests, json
import logging
import os

logger = logging.getLogger(__name__)

# Do not hardcode API keys. Read from environment.
key = os.getenv("OPENAI_API_KEY", "").strip()
url = 'https://generativelanguage.googleapis.com/v1/models'
logger.info('GET %s', url)
try:
    r = requests.get(url, headers={'x-goog-api-key': key}, timeout=60)
    logger.info('STATUS %s', r.status_code)
    text = r.text
    logger.debug('BODY (truncated 4000 chars):\n%s', text[:4000])
    try:
        j = r.json()
        models = j.get('models') or j.get('model', j)
        if isinstance(models, list):
            logger.info('\nFound %d models:', len(models))
            for m in models:
                name = m.get('name') or m.get('model') or m.get('id')
                display = m.get('displayName') or m.get('title') or ''
                methods = m.get('supportedMethods') or m.get('availableMethods') or m.get('methods') or []
                logger.info('- %s | %s | methods: %s', name, display, methods)
        else:
            logger.info('\nmodels field not a list; keys: %s', list(j.keys()))
    except Exception as e:
        logger.exception('JSON parse error')
except Exception as e:
    logger.exception('REQUEST ERROR')
