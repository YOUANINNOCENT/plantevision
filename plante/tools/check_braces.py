import os
from pathlib import Path

ROOT = Path('.').resolve()
EXTS = ['.ps1', '.py', '.dart', '.js', '.ts', '.java', '.c', '.cpp', '.cs']

issues = []
for p in ROOT.rglob('*'):
    if p.is_file() and p.suffix.lower() in EXTS:
        try:
            s = p.read_text(encoding='utf-8')
        except Exception:
            try:
                s = p.read_text(encoding='latin-1')
            except Exception:
                continue
        # check braces and parens
        for sym in [('{','}'),('(',')')]:
            open_sym, close_sym = sym
            cum = 0
            first_neg = None
            line_no = 0
            for i,line in enumerate(s.splitlines(),1):
                for ch in line:
                    if ch == open_sym:
                        cum += 1
                    elif ch == close_sym:
                        cum -= 1
                if cum < 0 and first_neg is None:
                    first_neg = i
                line_no = i
            if cum != 0 or first_neg is not None:
                issues.append((p.relative_to(ROOT), open_sym, close_sym, cum, first_neg))

if not issues:
    print('OK - No imbalance found for inspected file types')
else:
    for p, o, c, cum, first_neg in issues:
        print(f'{p} -> {o}{c} imbalance: final_count={cum} first_negative_line={first_neg}')
    raise SystemExit(2)
