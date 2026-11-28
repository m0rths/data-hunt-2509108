# =====================================================================
# crear-empleado.ps1 - Da de alta una cuenta de empleado con su rol
# Uso:  .\herramientas\crear-empleado.ps1 -Rol admin
#       .\herramientas\crear-empleado.ps1 -Rol dpo
#       .\herramientas\crear-empleado.ps1 -Rol operador
# =====================================================================
param(
    [ValidateSet("admin", "dpo", "operador")]
    [string]$Rol = "admin"
)
$ErrorActionPreference = "Stop"

# Carga la configuración y las funciones de la app
$Raiz = Split-Path $PSScriptRoot -Parent
. (Join-Path $Raiz "config.ps1")
. (Join-Path $Raiz "src/datos.ps1")
. (Join-Path $Raiz "src/seguridad.ps1")

$email = Read-Host "Correo del empleado"
$segura = Read-Host "Contraseña (mínimo 12 caracteres)" -AsSecureString
$contrasena = ConvertFrom-SecureString $segura -AsPlainText

if ($contrasena.Length -lt 12) {
    Write-Host "La contraseña debe tener al menos 12 caracteres." -ForegroundColor Red
    exit 1
}
if (Leer-Csv $ArchivoEmpleados | Where-Object { $_.email -eq $email }) {
    Write-Host "Ya existe un empleado con ese correo." -ForegroundColor Red
    exit 1
}

Agregar-Csv $ArchivoEmpleados ([ordered]@{
    email         = $email
    password_hash = Nuevo-HashContrasena $contrasena
    rol           = $Rol
    fecha_alta    = Ahora
})
Write-Host "Empleado creado: $email (rol: $Rol)" -ForegroundColor Green