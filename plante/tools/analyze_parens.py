from pathlib import Path
p = Path('backend/run_backend.ps1')
text = p.read_bytes().decode('utf-8','replace')
print('Counts -> (:', text.count('('), ') :', text.count(')'), ' { :', text.count('{'), ' } :', text.count('}'))
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
    print('\nParentheses go negative at line', first_neg[0])
    print(first_neg[1])
else:
    print('\nNo negative cumulative parentheses detected during parse')
if cum!=0:
    print('\nFinal cumulative parentheses count:', cum)
    print('\nContext (last 60 lines):')
    start=max(1,len(lines)-60)
    for idx in range(start, len(lines)+1):
        print(f"{idx:03}: {lines[idx-1]}")
else:
    print('\nParentheses balanced overall')

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
    print('\nBraces go negative at line', first_neg_b[0])
    print(first_neg_b[1])
else:
    print('\nNo negative braces during parse')
if cum_b!=0:
    print('\nFinal cumulative braces count:', cum_b)
