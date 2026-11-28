# =====================================================================
# src\seguridad.ps1 - Hash de contraseñas con PBKDF2
# =====================================================================

# Iteraciones de PBKDF2-SHA256 (valor recomendado por OWASP).
# Más iteraciones = más lento para un atacante que prueba millones de contraseñas.
$IteracionesPbkdf2 = 600000

# Convierte una contraseña en un hash con sal.
# Resultado:  pbkdf2-sha256:600000:<sal en Base64>:<hash en Base64>
function Nuevo-HashContrasena([string]$contrasena) {
    $sal  = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)   # sal aleatoria de 16 bytes
    $hash = [System.Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2(
        [System.Text.Encoding]::UTF8.GetBytes($contrasena),
        $sal,
        $IteracionesPbkdf2,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        32)
    return "pbkdf2-sha256:$($IteracionesPbkdf2):$([Convert]::ToBase64String($sal)):$([Convert]::ToBase64String($hash))"
}

# Comprueba si una contraseña corresponde a un hash guardado
function Probar-Contrasena([string]$contrasena, [string]$guardado) {
    $partes = $guardado -split ":"
    if ($partes.Count -ne 4 -or $partes[0] -ne "pbkdf2-sha256") { return $false }

    $iteraciones = [int]$partes[1]
    $sal         = [Convert]::FromBase64String($partes[2])
    $esperado    = [Convert]::FromBase64String($partes[3])
    $calculado   = [System.Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2(
        [System.Text.Encoding]::UTF8.GetBytes($contrasena),
        $sal,
        $iteraciones,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        $esperado.Length)

    # Comparación en tiempo constante: no revela cuántos bytes coincidieron
    return [System.Security.Cryptography.CryptographicOperations]::FixedTimeEquals($calculado, $esperado)
}

# --- Sesiones, roles y enmascaramiento (Fase 8) ----------------------

# Empleados que pueden entrar a /admin. Se dan de alta con herramientas\crear-empleado.ps1
$ArchivoEmpleados = Join-Path $CarpetaDatos "empleados.csv"

# Roles que pueden ver /admin (ajústalos a la matriz de roles del Reto 5)
$RolesAdmin = @("admin", "dpo")

# Sesiones activas en memoria: token -> correo, rol y hora de expiración
$Sesiones      = @{}
$MinutosSesion = 15

# Crea una sesión y le manda al navegador una cookie con un token aleatorio
function Nueva-Sesion($ctx, [string]$email, [string]$rol) {
    $token = [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
    $Sesiones[$token] = @{ email = $email; rol = $rol; expira = (Get-Date).AddMinutes($MinutosSesion) }
    # HttpOnly: JavaScript no puede leer la cookie. SameSite=Strict: otros sitios no la envían.
    # Con HTTPS también se agregaría Secure (ver hallazgo H-04).
    $ctx.Response.AppendHeader("Set-Cookie", "sesion=$token; Path=/; HttpOnly; SameSite=Strict")
}

# Regresa la sesión del navegador, o $null si no tiene una válida
function Obtener-Sesion($ctx) {
    $cookie = $ctx.Request.Cookies["sesion"]
    if (-not $cookie) { return $null }
    $sesion = $Sesiones[$cookie.Value]
    if (-not $sesion) { return $null }
    if ($sesion.expira -lt (Get-Date)) {
        $Sesiones.Remove($cookie.Value)
        return $null
    }
    $sesion.expira = (Get-Date).AddMinutes($MinutosSesion)   # se renueva con cada uso
    return $sesion
}

# Borra la sesión del servidor y la cookie del navegador
function Cerrar-Sesion($ctx) {
    $cookie = $ctx.Request.Cookies["sesion"]
    if ($cookie) { $Sesiones.Remove($cookie.Value) }
    $ctx.Response.AppendHeader("Set-Cookie", "sesion=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0")
}

# Enmascaramiento: muestra solo lo indispensable de cada dato
function Enmascarar-Correo([string]$correo) {
    $partes = $correo -split "@", 2
    if ($partes.Count -ne 2 -or $partes[0].Length -eq 0) { return "***" }
    return $partes[0].Substring(0, 1) + "***@" + $partes[1]
}

function Enmascarar-Texto([string]$texto) {
    if ($texto.Length -le 2) { return "***" }
    return $texto.Substring(0, 2) + "***"
}

function Enmascarar-Ip([string]$ip) {
    $partes = $ip -split "\."
    if ($partes.Count -eq 4) { return "$($partes[0]).$($partes[1]).$($partes[2]).x" }
    return "***"
}