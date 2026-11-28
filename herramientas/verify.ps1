# =====================================================================
# verify.ps1 - Comprueba con SHA-256 que los archivos cifrados no se alteraron
# Uso:  .\herramientas\verify.ps1
#       .\herramientas\verify.ps1 -Carpeta \\servidor\atencion\datahunt
# =====================================================================
param(
    [string]$Carpeta = (Join-Path (Split-Path $PSScriptRoot -Parent) "protegido")
)

$alterados = 0
foreach ($archivoHash in Get-ChildItem -Path $Carpeta -Filter *.sha256) {
    # Cada .sha256 contiene:  <hash>  <nombre del archivo>
    $esperado, $nombre = (Get-Content -Path $archivoHash.FullName -Raw).Trim() -split "\s+", 2
    $ruta = Join-Path $Carpeta $nombre

    if (-not (Test-Path $ruta)) {
        Write-Host "FALTA      $nombre" -ForegroundColor Red
        $alterados++
        continue
    }
    $actual = (Get-FileHash -Path $ruta -Algorithm SHA256).Hash.ToLower()
    if ($actual -eq $esperado) {
        Write-Host "ÍNTEGRO    $nombre" -ForegroundColor Green
    }
    else {
        Write-Host "ALTERADO   $nombre" -ForegroundColor Red
        Write-Host "  esperado: $esperado"
        Write-Host "  actual:   $actual"
        $alterados++
    }
}

if ($alterados -gt 0) { exit 1 }