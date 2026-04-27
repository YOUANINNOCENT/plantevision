from pathlib import Path
ROOT = Path('.').resolve()
EXTS = ['.ps1', '.psm1', '.psh', '.psd1', '.ps1xml']

def check_file(p: Path):
    try:
        s = p.read_text(encoding='utf-8')
    except Exception:
        try:
            s = p.read_text(encoding='latin-1')
        except Exception:
            return None
    total = s.count('"')
    # also check line-level
    bad_lines = []
    for i,l in enumerate(s.splitlines(),1):
        if l.count('"') % 2 == 1:
            bad_lines.append(i)
    return total, bad_lines

issues = []
for p in ROOT.rglob('*'):
    if p.is_file() and p.suffix.lower() in EXTS:
        res = check_file(p)
        if res is None:
            continue
        total, bad_lines = res
        if total % 2 == 1 or bad_lines:
            issues.append((p.relative_to(ROOT), total, bad_lines))

if not issues:
    print('No unbalanced double quotes found in PowerShell files')
else:
    for p,total,bad in issues:
        print(f"{p} -> total_quotes={total} bad_lines={bad}")
    raise SystemExit(2)
