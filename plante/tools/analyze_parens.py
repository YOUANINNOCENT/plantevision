from pathlib import Path
import logging

logger = logging.getLogger(__name__)

p = Path('backend/run_backend.ps1')
text = p.read_bytes().decode('utf-8','replace')
logger.info('Counts -> (:%d ) :%d  { :%d  } :%d', text.count('('), text.count(')'), text.count('{'), text.count('}'))
lines = text.splitlines()
# check parentheses
cum=0
first_neg=None
for i,l in enumerate(lines,1):
    for ch in l:
        if ch=='(':
            cum+=1
        elif ch==')':
            cum-=1
    if cum<0 and first_neg is None:
        first_neg=(i,l)

if first_neg:
    logger.info('\nParentheses go negative at line %s', first_neg[0])
    logger.info('%s', first_neg[1])
else:
    logger.info('\nNo negative cumulative parentheses detected during parse')
if cum!=0:
    logger.info('\nFinal cumulative parentheses count: %s', cum)
    logger.info('\nContext (last 60 lines):')
    start=max(1,len(lines)-60)
    for idx in range(start, len(lines)+1):
        logger.info('%03d: %s', idx, lines[idx-1])
else:
    logger.info('\nParentheses balanced overall')

# check braces
cum_b=0
first_neg_b=None
for i,l in enumerate(lines,1):
    for ch in l:
        if ch=='{': cum_b+=1
        elif ch=='}': cum_b-=1
    if cum_b<0 and first_neg_b is None:
        first_neg_b=(i,l)
if first_neg_b:
    logger.info('\nBraces go negative at line %s', first_neg_b[0])
    logger.info('%s', first_neg_b[1])
else:
    logger.info('\nNo negative braces during parse')
if cum_b!=0:
    logger.info('\nFinal cumulative braces count: %s', cum_b)
