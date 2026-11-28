# =====================================================================
# unprotect.ps1 - Descifra un archivo .enc para comprobar que se puede recuperar
# Uso:  .\herramientas\unprotect.ps1 -Archivo .\protegido\users.csv.enc
# El resultado queda en restaurado\ (excluida del repositorio). Bórralo al terminar.
# =====================================================================
param(
    [Parameter(Mandatory)]
    [string]$Archivo,
    [string]$Destino = (Join-Path (Split-Path $PSScriptRoot -Parent) "restaurado"),
    [string]$Llave   = (Join-Path $HOME "datahunt-llaves/datahunt.key")
)
$ErrorActionPreference = "Stop"

$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Archivo))
if ($bytes.Length -lt 28) {
    Write-Host "El archivo es demasiado corto para estar cifrado." -ForegroundColor Red
    exit 1
}

# Separa las partes: nonce (12) + etiqueta (16) + datos cifrados
$nonce    = $bytes[0..11]
$etiqueta = $bytes[12..27]
$cifrado  = [byte[]]::new($bytes.Length - 28)
[Array]::Copy($bytes, 28, $cifrado, 0, $cifrado.Length)
$plano    = [byte[]]::new($cifrado.Length)

$cifrador = [System.Security.Cryptography.ChaCha20Poly1305]::new([System.IO.File]::ReadAllBytes($Llave))
try {
    $cifrador.Decrypt([byte[]]$nonce, $cifrado, [byte[]]$etiqueta, $plano)
}
catch [System.Security.Cryptography.CryptographicException] {
    Write-Host "No se pudo descifrar: el archivo fue alterado o la llave no es la correcta." -ForegroundColor Red
    exit 1
}
finally {
    $cifrador.Dispose()
}

New-Item -ItemType Directory -Path $Destino -Force | Out-Null
$salida = Join-Path $Destino ((Split-Path $Archivo -Leaf) -replace "\.enc$", "")
[System.IO.File]::WriteAllBytes($salida, $plano)
Write-Host "Descifrado en $salida" -ForegroundColor Green