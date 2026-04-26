import logging

logger = logging.getLogger(__name__)

line_no=22
with open('backend/run_backend.ps1','rb') as f:
    lines=f.read().splitlines()
ln=lines[line_no-1]
logger.info('Line %s: %s', line_no, ln.decode('utf-8','replace'))
logger.info('Hex codes:')
for i,b in enumerate(ln,1):
    ch = chr(b)
    # escape non-printables
    esc = ch if 32 <= b <= 126 else f'\\x{b:02x}'
    logger.info('%02d: %02x %s', i, b, esc)
