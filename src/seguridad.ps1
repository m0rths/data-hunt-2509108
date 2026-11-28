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
