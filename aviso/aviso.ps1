# =====================================================================
# src\rutas\aviso.ps1 - Aviso de privacidad integral y simplificado
# =====================================================================

$CarpetaAviso = Join-Path $Raiz "aviso"

# Lee un aviso de la carpeta aviso\ y reemplaza los valores de config.ps1
function Leer-Aviso([string]$nombre) {
    $texto = Get-Content -Path (Join-Path $CarpetaAviso "$nombre.html") -Raw -Encoding UTF8
    $texto = $texto.Replace("{ORGANIZACION}", (Escapar $Organizacion))
    $texto = $texto.Replace("{CONTACTO}", (Escapar $ContactoPrivacidad))
    return $texto
}

# Tabla con cada dato que trata la app y su finalidad.
# Se arma con $Campos de config.ps1: si agregas un campo, el aviso se actualiza solo.
function Tabla-Finalidades {
    $filas = @()
    $filas += [PSCustomObject]@{ Dato = "Correo electrónico"; Finalidad = "Identificar tu cuenta y enviarte avisos sobre el servicio" }
    $filas += [PSCustomObject]@{ Dato = "Contraseña"; Finalidad = "Proteger el acceso a tu cuenta" }
    foreach ($campo in $Campos) {
        $filas += [PSCustomObject]@{ Dato = $campo.Etiqueta; Finalidad = $campo.Finalidad }
    }
    $filas += [PSCustomObject]@{ Dato = "Región de residencia"; Finalidad = "Saber qué ley de protección de datos aplica a tu información" }
    $filas += [PSCustomObject]@{ Dato = "Fecha y versión del aviso que aceptaste"; Finalidad = "Demostrar que diste tu consentimiento" }
    $filas += [PSCustomObject]@{ Dato = "Dirección IP, navegador y fecha de cada inicio de sesión (se obtienen automáticamente)"; Finalidad = "Seguridad: detectar accesos no autorizados a tu cuenta" }
    return Tabla-Html $filas
}

$Rutas["/aviso"] = {
    param($ctx)
    $contenido  = "<p><strong>Versión $(Escapar $AvisoVersion)</strong></p>"
    $contenido += Leer-Aviso "integral"
    $contenido += "<h2>Datos que tratamos y para qué</h2>" + (Tabla-Finalidades)
    Enviar $ctx (Nueva-Pagina "Aviso de privacidad integral" $contenido)
}