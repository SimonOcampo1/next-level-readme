# Renderiza banner.html a PNG.
#
#   pwsh -File make-banner.ps1 -Src docs\banner.html [-OutDir docs]
#
# Salida:  banner.png  1600x533 (3:1)  -> header del README
#          social.png  1280x640 (2:1)  -> Settings > Social preview del repo
#
# ponytail: Chromium headless ya instalado en vez de puppeteer/playwright — cero dependencias nuevas.
# Dos trampas reales de Chromium headless en Windows, ambas resueltas acá:
#   1. --screenshot con espacios en la ruta se parsea partido y no escribe nada, sin error.
#      Por eso se captura a %TEMP% y recién despues se mueve al destino.
#   2. Los GUI apps no se bloquean al ejecutarse desde una shell: hace falta Start-Process -Wait.

param(
  [Parameter(Mandatory=$true)][string]$Src,
  [string]$OutDir
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Src)) { throw "No existe: $Src" }
$Src = (Resolve-Path $Src).Path
if (-not $OutDir) { $OutDir = Split-Path $Src -Parent }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

# Brave queda deliberadamente fuera: en headless se cuelga sin escribir nada ni salir.
# Edge viene con Windows, asi que siempre hay al menos uno.
$browser = @(
  "C:\Program Files\Google\Chrome\Application\chrome.exe",
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw "No se encontro Chrome ni Edge" }

# El HTML se deja donde esta (asi siguen resolviendo sus rutas relativas: hero, fuentes locales);
# lo unico que se muda al temp es el destino del screenshot.
$url  = "file:///" + ($Src -replace '\\','/' -replace ' ','%20')
$tmp  = Join-Path $env:TEMP ("banner-" + [guid]::NewGuid().ToString("N").Substring(0,8))
$prof = Join-Path $tmp "profile"
New-Item -ItemType Directory -Force $tmp | Out-Null

function Shot($name, $w, $h) {
  $shot = Join-Path $tmp $name
  $a = @(
    "--headless=new", "--disable-gpu", "--hide-scrollbars",
    "--no-first-run", "--no-default-browser-check",
    "--user-data-dir=$prof",
    "--virtual-time-budget=10000",   # espera a que bajen las Google Fonts
    "--window-size=$w,$h",
    "--screenshot=$shot",
    $url
  )
  $p = Start-Process -FilePath $browser -ArgumentList $a -Wait -PassThru -NoNewWindow
  if (-not (Test-Path $shot)) { throw "Fallo el render de $name (browser exit $($p.ExitCode))" }
  Move-Item $shot (Join-Path $OutDir $name) -Force
  "  {0}\{1}  {2}x{3}  ({4:N0} KB)" -f $OutDir, $name, $w, $h, ((Get-Item (Join-Path $OutDir $name)).Length / 1KB)
}

try {
  Shot "banner.png" 1600 533
  Shot "social.png" 1280 640
} finally {
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
