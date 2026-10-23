$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$logFile = Join-Path $env:TEMP 'cccc_serve.log'
function Log($msg) { Add-Content -Path $logFile -Value ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg) }
Log "Server starting. PSScriptRoot=$root"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8765/')
$listener.Start()
Log "Listener started"

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
    } catch {
        Log "GetContext error: $_"
        break
    }
    $req = $ctx.Request
    $res = $ctx.Response
    $urlPath = $req.Url.AbsolutePath
    if ($urlPath -eq '/' -or $urlPath -eq '') { $urlPath = '/index.html' }
    $rel = $urlPath.TrimStart('/')
    $filePath = Join-Path $root $rel
    if (Test-Path -LiteralPath $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        switch ($ext) {
            '.html' { $res.ContentType = 'text/html; charset=utf-8' }
            '.css'  { $res.ContentType = 'text/css; charset=utf-8' }
            '.js'   { $res.ContentType = 'application/javascript; charset=utf-8' }
            '.jpg'  { $res.ContentType = 'image/jpeg' }
            '.jpeg' { $res.ContentType = 'image/jpeg' }
            '.png'  { $res.ContentType = 'image/png' }
            '.svg'  { $res.ContentType = 'image/svg+xml' }
            '.gif'  { $res.ContentType = 'image/gif' }
            default { $res.ContentType = 'application/octet-stream' }
        }
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        Log "OK $urlPath -> $filePath ($($bytes.Length) bytes)"
    } else {
        $res.StatusCode = 404
        $body = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
        $res.ContentLength64 = $body.Length
        $res.OutputStream.Write($body, 0, $body.Length)
        Log "404 $urlPath -> $filePath"
    }
    $res.Close()
}
Log "Server stopped"
