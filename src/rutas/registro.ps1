# =====================================================================
# src\rutas\registro.ps1 - Alta de clientes
# VERSIÓN LÍNEA BASE: contiene fallas intencionales marcadas como HALLAZGO
# =====================================================================

function Formulario-Registro([string]$mensaje = "") {
    $html = ""
    if ($mensaje) { $html += "<p class='mensaje'>$(Escapar $mensaje)</p>" }

    # HALLAZGO H-07: el formulario no muestra aviso de privacidad ni pide consentimiento
    $html += "<form method='post' action='/registro'>"
    $html += "<label>Correo electrónico <input type='email' name='email' required></label>"
    $html += "<label>Contraseña <input type='password' name='password' required minlength='8'></label>"
    foreach ($campo in $Campos) {
        $html += "<label>$(Escapar $campo.Etiqueta) <input type='$($campo.Tipo)' name='$($campo.Nombre)' required></label>"
    }
    $html += "<button>Crear cuenta</button></form>"
    return $html
}

$Rutas["/registro"] = {
    param($ctx)
    $peticion = $ctx.Request

    # GET: muestra el formulario vacío
    if ($peticion.HttpMethod -ne "POST") {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro))
        return
    }

    # POST: procesa los datos enviados
    $form = Leer-Formulario $ctx

    # HALLAZGO H-03: los datos del cliente se imprimen en la consola del servidor
    $texto = ($form.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " | "
    Write-Host "[DEBUG] Registro recibido: $texto" -ForegroundColor Yellow

    if (-not $form["email"] -or -not $form["password"]) {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro "El correo y la contraseña son obligatorios."))
        return
    }
    if (Leer-Csv $ArchivoUsuarios | Where-Object { $_.email -eq $form["email"] }) {
        Enviar $ctx (Nueva-Pagina "Crear cuenta" (Formulario-Registro "Ese correo ya está registrado."))
        return
    }

    $registro = [ordered]@{}
    $registro["email"] = $form["email"]
    # HALLAZGO H-01: la contraseña se guarda en texto plano
    $registro["password"] = $form["password"]
    foreach ($campo in $Campos) {
        $registro[$campo.Nombre] = $form[$campo.Nombre]
    }

    # HALLAZGO H-05: datos que el cliente nunca escribió y que ningún aviso declara
    $registro["ip"]        = $peticion.RemoteEndPoint.Address.ToString()
    $registro["navegador"] = $peticion.UserAgent
    $registro["idioma"]    = $peticion.Headers["Accept-Language"]
    $registro["fecha_registro"] = Ahora

    # HALLAZGO H-06: el archivo users.csv se guarda sin cifrar
    Agregar-Csv $ArchivoUsuarios $registro

    Enviar $ctx (Nueva-Pagina "Cuenta creada" "<p>Tu cuenta se creó correctamente. Ya puedes <a href='/login'>iniciar sesión</a>.</p>")
}