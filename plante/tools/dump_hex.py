from pathlib import Path
import logging

logger = logging.getLogger(__name__)

p = Path('backend/run_backend.ps1')
b = p.read_bytes()
logger.info('File length: %d', len(b))
for i, line in enumerate(b.splitlines(), 1):
    hexs = ' '.join(f'{ch:02x}' for ch in line)
    logger.info('%03d: %s    | %s', i, hexs, line.decode(errors='replace'))
