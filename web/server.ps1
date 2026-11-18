# =====================================================================
# server.ps1 — a tiny local web server for the game, using ONLY
# PowerShell + .NET (no Python, no Node, works fully offline).
# Serves the build/webgl folder on http://localhost:8090/build/webgl/
# =====================================================================
param([int]$Port = 8090)
$ErrorActionPreference = 'Stop'

$root = Join-Path $PSScriptRoot '..'
$root = [IO.Path]::GetFullPath($root)
if (-not (Test-Path (Join-Path $root 'build\webgl\index.html'))) {
    Write-Host "ERROR: build/webgl not found. Run build_web.ps1 first."
    exit 1
}

$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'text/javascript; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.gif'  = 'image/gif'
    '.svg'  = 'image/svg+xml'
    '.webp' = 'image/webp'
    '.wav'  = 'audio/wav'
    '.mp3'  = 'audio/mpeg'
    '.ogg'  = 'audio/ogg'
    '.ico'  = 'image/x-icon'
    '.wasm' = 'application/wasm'
    '.meta' = 'text/plain; charset=utf-8'
    '.kine' = 'application/octet-stream'
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
} catch {
    Write-Host "ERROR: cannot listen on $prefix ($($_.Exception.Message))"
    Write-Host 'Maybe the port is busy - close the other server, or edit Port in server.ps1.'
    exit 1
}

Write-Host "Server running: http://localhost:$Port/build/webgl/"
Write-Host "Press Ctrl+C to stop."
Write-Host ''

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        try {
            $req = $ctx.Request
            $res = $ctx.Response
            $url = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
            # map /build/webgl/... -> <root>/webgl/...
            $rel = $url.TrimStart('/')
            if (-not $rel.StartsWith('build\') -and -not $rel.StartsWith('build/')) {
                $rel = 'build/' + $rel.TrimStart('/')
            }
            $file = [IO.Path]::GetFullPath((Join-Path $root ($rel -replace '/', '\')))
            if (-not $file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                $res.StatusCode = 403
                $res.Close()
                continue
            }
            if (Test-Path $file -PathType Container) {
                $file = Join-Path $file 'index.html'
            }
            if (Test-Path $file) {
                $ext = [IO.Path]::GetExtension($file).ToLower()
                if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] }
                else { $res.ContentType = 'application/octet-stream' }
                $bytes = [IO.File]::ReadAllBytes($file)
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $res.StatusCode = 404
            }
        } catch {
            try { $ctx.Response.StatusCode = 500 } catch {}
        } finally {
            try { $ctx.Response.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
}
