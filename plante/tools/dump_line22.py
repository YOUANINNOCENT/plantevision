line_no=22
with open('backend/run_backend.ps1','rb') as f:
    lines=f.read().splitlines()
ln=lines[line_no-1]
print('Line',line_no,':',ln.decode('utf-8','replace'))
print('Hex codes:')
for i,b in enumerate(ln,1):
    ch = chr(b)
    # escape non-printables
    esc = ch if 32 <= b <= 126 else f'\\x{b:02x}'
    print(f'{i:02}: {b:02x} {esc}')
