# =====================================================================
# src\rutas\registro.ps1 - Alta de clientes
# FASE 7: contraseñas con hash y consola sin datos personales
# =====================================================================

function Formulario-Registro([string]$mensaje = "") {
    $html = ""
    if ($mensaje) { $html += "<p class='mensaje'>$(Escapar $mensaje)</p>" }

    $html += "<form method='post' action='/registro'>"
    $html += "<label>Correo electrónico <input type='email' name='email' required></label>"
    $html += "<label>Contraseña <input type='password' name='password' required minlength='8'></label>"
    foreach ($campo in $Campos) {
        $html += "<label>$(Escapar $campo.Etiqueta) <input type='$($campo.Tipo)' name='$($campo.Nombre)' required></label>"
    }

    # Región de residencia: define qué ley aplica (LFPDPPP, GDPR o CCPA)
    $html += "<label>Región de residencia <select name='region' required><option value=''>Selecciona...</option>"
    foreach ($region in $Regiones.Keys) {
        $html += "<option>$(Escapar $region)</option>"
    }
    $html += "</select></label>"

    # CORREGIDO H-07: aviso simplificado antes del envío y consentimiento sin marcar
    $html += "<div class='aviso'><h3>Aviso de privacidad simplificado</h3>"
    $html += (Leer-Aviso "simplificado") + (Tabla-Finalidades) + "</div>"
    $html += "<label><input type='checkbox' name='consentimiento' value='acepto'> "
    $html += "Leí el aviso de privacidad (versión $(Escapar $AvisoVersion)) y acepto el tratamiento de mis datos para las finalidades indicadas.</label>"

    $html += "<button>Crear cuenta</button></form>"
    return $html
}

$Rutas["/registro"] = {
    param($ctx)

    if ($ctx.Request.HttpMethod -ne "POST") {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro))
        return
    }

    $form = Leer-Formulario $ctx

    # CORREGIDO H-03: la consola solo muestra el evento, nunca los datos del cliente
    Write-Host "  Solicitud de registro recibida"

    # El servidor valida de nuevo: el navegador se puede saltar los "required"
    if (-not $form["email"] -or -not $form["password"]) {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro "El correo y la contraseña son obligatorios."))
        return
    }
    if (-not $Regiones.Contains($form["region"])) {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro "Selecciona tu región de residencia."))
        return
    }
    # CORREGIDO H-07: sin consentimiento no se guarda ningún dato
    if ($form["consentimiento"] -ne "acepto") {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro "Para crear tu cuenta debes aceptar el aviso de privacidad."))
        return
    }
    if (Leer-Csv $ArchivoUsuarios | Where-Object { $_.email -eq $form["email"] }) {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro "Ese correo ya está registrado."))
        return
    }

    $registro = [ordered]@{}
    $registro["email"] = $form["email"]
    # CORREGIDO H-01: se guarda un hash con sal, nunca la contraseña
    $registro["password_hash"] = Nuevo-HashContrasena $form["password"]
    foreach ($campo in $Campos) {
        $registro[$campo.Nombre] = $form[$campo.Nombre]
    }
    $registro["region"]        = $form["region"]
    $registro["ley_aplicable"] = $Regiones[$form["region"]]

    # Evidencia del consentimiento: cuándo y qué versión del aviso aceptó
    $registro["consentimiento_fecha"] = Ahora
    $registro["aviso_version"]        = $AvisoVersion
    $registro["fecha_registro"]       = Ahora

    # CORREGIDO H-05: ya no se guardan IP, navegador ni idioma en users.csv (minimización).
    # La IP y el navegador solo quedan en la bitácora de accesos, y el aviso lo declara.

    # HALLAZGO H-06: el archivo users.csv se guarda sin cifrar
    Agregar-Csv $ArchivoUsuarios $registro

    Enviar $ctx (Nueva-Pagina "Cuenta creada" "<p>Tu cuenta se creó correctamente. Ya puedes <a href='/login'>iniciar sesión</a>.</p>")
}
