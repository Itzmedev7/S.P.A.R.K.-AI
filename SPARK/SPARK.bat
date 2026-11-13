@echo off & title S.P.A.R.K. & set "SPARK_ROOT=%~dp0" & powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Raw) -replace '(?s)^.*?#PS[#]','')" & if errorlevel 1 (echo. & echo Something went wrong. & pause) & exit /b
#PS#
$root = "$env:SPARK_ROOT".TrimEnd([char]92)
if (-not $root) { $root = (Get-Location).Path }
if (-not (Test-Path (Join-Path $root 'index.html'))) { Write-Host 'index.html not found next to SPARK.bat'; Read-Host 'Press Enter'; exit }
$mime = @{ '.html'='text/html'; '.js'='text/javascript'; '.css'='text/css'; '.json'='application/json'; '.png'='image/png'; '.jpg'='image/jpeg'; '.svg'='image/svg+xml'; '.ico'='image/x-icon'; '.webmanifest'='application/manifest+json'; '.woff2'='font/woff2' }
$l = $null
foreach ($p in 8080..8099) {
  try { $l = New-Object System.Net.HttpListener; $l.Prefixes.Add("http://localhost:$p/"); $l.Start(); $port = $p; break } catch { $l = $null }
}
if (-not $l) { Write-Host 'No free port found.'; Read-Host 'Press Enter'; exit }
Write-Host "S.P.A.R.K. running at http://localhost:$port  (close this window to stop)"
Start-Process "http://localhost:$port"
while ($l.IsListening) {
  $c = $l.GetContext()
  $path = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath).TrimStart('/')
  if (-not $path) { $path = 'index.html' }
  $file = [IO.Path]::GetFullPath((Join-Path $root $path))
  if ($file.StartsWith($root) -and (Test-Path $file -PathType Leaf)) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $c.Response.ContentType = $(if ($mime[$ext]) { $mime[$ext] } else { 'application/octet-stream' })
    $c.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else { $c.Response.StatusCode = 404 }
  $c.Response.Close()
}
