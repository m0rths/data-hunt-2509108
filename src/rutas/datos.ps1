# =====================================================================
# src\datos.ps1 - Archivos CSV que simulan la base de datos
# =====================================================================

# Los datos viven en la carpeta datos\, que .gitignore excluye del repositorio
$CarpetaDatos    = Join-Path $Raiz "datos"
$ArchivoUsuarios = Join-Path $CarpetaDatos "users.csv"
$ArchivoAccesos  = Join-Path $CarpetaDatos "access_log.csv"
New-Item -ItemType Directory -Path $CarpetaDatos -Force | Out-Null

# Fecha y hora actual en un formato fácil de leer y de ordenar
function Ahora {
    (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

# Lee todos los registros de un CSV (si no existe, regresa una lista vacía)
function Leer-Csv([string]$ruta) {
    if (Test-Path $ruta) { return @(Import-Csv -Path $ruta -Encoding UTF8) }
    return @()
}

# Agrega un registro al final de un CSV (lo crea si no existe)
function Agregar-Csv([string]$ruta, $registro) {
    [PSCustomObject]$registro | Export-Csv -Path $ruta -Append -Encoding UTF8
}
