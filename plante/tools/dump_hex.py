from pathlib import Path
p = Path('backend/run_backend.ps1')
b = p.read_bytes()
print('File length:', len(b))
for i, line in enumerate(b.splitlines(), 1):
    hexs = ' '.join(f'{ch:02x}' for ch in line)
    print(f'{i:03}: {hexs}    | {line.decode(errors="replace")}')
