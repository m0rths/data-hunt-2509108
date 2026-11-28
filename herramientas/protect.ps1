# =====================================================================
# protect.ps1 - Cifra los CSV con ChaCha20-Poly1305 y calcula su SHA-256
# Uso:  .\herramientas\protect.ps1
# Resultado (en la carpeta protegido\):
#   users.csv.enc         -> archivo cifrado
#   users.csv.enc.sha256  -> hash para verificar que no se alteró al moverlo
# =====================================================================
param(
    [string]$Origen  = (Join-Path (Split-Path $PSScriptRoot -Parent) "datos"),
    [string]$Destino = (Join-Path (Split-Path $PSScriptRoot -Parent) "protegido"),
    # La llave vive FUERA del repositorio, en tu carpeta de usuario
    [string]$Llave   = (Join-Path $HOME "datahunt-llaves/datahunt.key")
)
$ErrorActionPreference = "Stop"

if (-not [System.Security.Cryptography.ChaCha20Poly1305]::IsSupported) {
    Write-Host "Este equipo no admite ChaCha20-Poly1305. Avisa a tu profesor." -ForegroundColor Red
    exit 1
}

# 1. Obtiene la llave de 256 bits, o la crea la primera vez
if (-not (Test-Path $Llave)) {
    New-Item -ItemType Directory -Path (Split-Path $Llave -Parent) -Force | Out-Null
    [System.IO.File]::WriteAllBytes($Llave, [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
    if ($IsWindows) {
        # Solo tu usuario puede leer la llave
        icacls $Llave /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null
    }
    Write-Host "Llave nueva creada en $Llave" -ForegroundColor Yellow
    Write-Host "Si la pierdes, no podrás descifrar los archivos. Nunca la subas al repositorio." -ForegroundColor Yellow
}
$bytesLlave = [System.IO.File]::ReadAllBytes($Llave)
$cifrador   = [System.Security.Cryptography.ChaCha20Poly1305]::new($bytesLlave)

New-Item -ItemType Directory -Path $Destino -Force | Out-Null

# 2. Cifra cada CSV de la carpeta de origen
foreach ($archivo in Get-ChildItem -Path $Origen -Filter *.csv) {
    $plano   = [System.IO.File]::ReadAllBytes($archivo.FullName)
    $nonce   = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)   # nunca se repite
    $cifrado = [byte[]]::new($plano.Length)
    $etiqueta = [byte[]]::new(16)                                                   # detecta alteraciones
    $cifrador.Encrypt($nonce, $plano, $cifrado, $etiqueta)

    # Formato del archivo: nonce (12 bytes) + etiqueta (16 bytes) + datos cifrados
    $salida = Join-Path $Destino "$($archivo.Name).enc"
    [System.IO.File]::WriteAllBytes($salida, [byte[]]($nonce + $etiqueta + $cifrado))

    # 3. Calcula el SHA-256 del archivo cifrado y lo guarda junto a él
    $hash = (Get-FileHash -Path $salida -Algorithm SHA256).Hash.ToLower()
    Set-Content -Path "$salida.sha256" -Value "$hash  $($archivo.Name).enc" -Encoding ascii

    Write-Host ("Cifrado: {0,-20} -> {1}.enc   SHA-256: {2}..." -f $archivo.Name, $archivo.Name, $hash.Substring(0, 16)) -ForegroundColor Green
}
$cifrador.Dispose()