# Knockout Training Center — Servidor local
# Uso: .\serve.ps1 5502

$root = "C:\Users\siegp\OneDrive\Documentos\Claude\Gym Knockout"
$port = if ($args[0]) { $args[0] } else { 5502 }
$prefix = "http://localhost:$port/"

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css"
  ".js"   = "application/javascript"
  ".json" = "application/json"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".webp" = "image/webp"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
  ".woff2"= "font/woff2"
  ".mp4"  = "video/mp4"
  ".webm" = "video/webm"
}

$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add($prefix)
$http.Start()

Write-Host ""
Write-Host "  Knockout Training Center · servidor local" -ForegroundColor Red
Write-Host "  ──────────────────────────────────────────"
Write-Host "  Abre: http://localhost:$port" -ForegroundColor Cyan
Write-Host "  Ctrl+C para detener." -ForegroundColor DarkGray
Write-Host ""

while ($http.IsListening) {
  $ctx = $http.GetContext()
  $raw = $ctx.Request.RawUrl.Split('?')[0].TrimEnd('/')

  $file = $null

  if ([string]::IsNullOrEmpty($raw) -or $raw -eq '/') {
    $file = Join-Path $root "index.html"
  } else {
    $rel   = $raw.TrimStart('/')
    $exact = Join-Path $root $rel

    if (Test-Path $exact -PathType Leaf) {
      $file = $exact
    } elseif (Test-Path ($exact + ".html") -PathType Leaf) {
      $file = $exact + ".html"
    } elseif (Test-Path (Join-Path $exact "index.html") -PathType Leaf) {
      $file = Join-Path $exact "index.html"
    }
  }

  if ($file -and (Test-Path $file -PathType Leaf)) {
    $ext  = [System.IO.Path]::GetExtension($file).ToLower()
    $ct   = if ($mime[$ext]) { $mime[$ext] } else { "application/octet-stream" }
    $data = [System.IO.File]::ReadAllBytes($file)
    $ctx.Response.ContentType     = $ct
    $ctx.Response.ContentLength64 = $data.Length
    $ctx.Response.OutputStream.Write($data, 0, $data.Length)
    Write-Host "  200  $raw" -ForegroundColor Green
  } else {
    $ctx.Response.StatusCode = 404
    $body = [System.Text.Encoding]::UTF8.GetBytes("404 - No encontrado: $raw")
    $ctx.Response.OutputStream.Write($body, 0, $body.Length)
    Write-Host "  404  $raw" -ForegroundColor Red
  }

  $ctx.Response.Close()
}
