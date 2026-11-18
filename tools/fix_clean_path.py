import io

for p in ['build_web.ps1', 'build_desktop.ps1']:
    s = io.open(p, encoding='utf-8').read()
    old = "$clean = 'C:\\velo\\mergeweb'"
    new = """# clean build dir: prefer the default C:\\velo (fast local disk); any machine without
# it (e.g. a fresh GitHub clone) falls back to a per-user temp dir
$veloRoot = if (Test-Path 'C:\\velo') { 'C:\\velo' } else { Join-Path $env:TEMP 'velo' }
$clean = Join-Path $veloRoot 'mergeweb'"""
    assert old in s, p + ' clean not found'
    s = s.replace(old, new)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print(p, 'clean path updated')
