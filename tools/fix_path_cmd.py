import io

for p in ['build_web.ps1', 'build_desktop.ps1']:
    s = io.open(p, encoding='utf-8').read()
    old = "$env:Path = 'C:\\v;C:\\mingw64\\bin;' + $env:Path"
    new = """# velo toolchain: use it from PATH when available, else the default install dir
if (-not (Get-Command velo -ErrorAction SilentlyContinue)) {
    if (Test-Path 'C:\\v') { $env:Path = 'C:\\v;C:\\mingw64\\bin;' + $env:Path }
}"""
    assert old in s, p + ' old not found'
    s = s.replace(old, new)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print(p, 'updated')
