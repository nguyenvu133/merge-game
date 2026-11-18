# Fix hardcoded machine paths so the project builds from any clone (GitHub).
import io
import os

OLD = r'C:\New folder\Hangrong\merge-game'
HERE = 'os.path.dirname(os.path.abspath(__file__))'

# test_web.ps1 — project root from script location
p = 'test_web.ps1'
s = io.open(p, encoding='utf-8').read()
s = s.replace("$proj = '" + OLD + "'", "$proj = Split-Path -Parent $MyInvocation.MyCommand.Path")
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('test_web.ps1 fixed:', OLD not in s)

# python converters — default paths relative to the script
for p in ['kine2skel.py', 'spine4.py', 'make_audio.py']:
    s = io.open(p, encoding='utf-8').read()
    n = s.replace(OLD, HERE)
    if 'import os' not in n:
        n = n.replace('import sys', 'import sys\nimport os', 1)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(n)
    print(p, 'fixed:', OLD not in n)
