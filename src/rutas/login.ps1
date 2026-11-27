# =====================================================================
# src\rutas\login.ps1 - Inicio de sesión y bitácora de accesos
# VERSIÓN LÍNEA BASE: contiene fallas intencionales marcadas como HALLAZGO
# =====================================================================

function Formulario-Login([string]$mensaje = "") {
    $html = ""
    if ($mensaje) { $html += "<p class='mensaje'>$(Escapar $mensaje)</p>" }
    $html += "<form method='post' action='/login'>"
    $html += "<label>Correo electrónico <input type='email' name='email' required></label>"
    $html += "<label>Contraseña <input type='password' name='password' required></label>"
    $html += "<button>Entrar</button></form>"
    return $html
}

# Guarda un evento en la bitácora de accesos (access_log.csv)
function Registrar-Acceso($ctx, [string]$email, [string]$evento, [bool]$exito) {
    Agregar-Csv $ArchivoAccesos ([ordered]@{
        fecha     = Ahora
        email     = $email
        evento    = $evento
        exito     = [int]$exito
        ip        = $ctx.Request.RemoteEndPoint.Address.ToString()
        navegador = $ctx.Request.UserAgent
    })
}

$Rutas["/login"] = {
    param($ctx)

    if ($ctx.Request.HttpMethod -ne "POST") {
        Enviar $ctx (Nueva-Pagina "Iniciar sesión" (Formulario-Login))
        return
    }

    $form = Leer-Formulario $ctx

    # HALLAZGO H-03: la contraseña aparece en la consola del servidor
    Write-Host "[DEBUG] Inicio de sesión: email=$($form['email']) password=$($form['password'])" -ForegroundColor Yellow

    # HALLAZGO H-01: compara contraseñas guardadas en texto plano
    $usuario = Leer-Csv $ArchivoUsuarios | Where-Object { $_.email -eq $form["email"] -and $_.password -eq $form["password"] }

    # Cada intento queda en la bitácora, exitoso o no
    Registrar-Acceso $ctx $form["email"] "login" ([bool]$usuario)

    if ($usuario) {
        Enviar $ctx (Nueva-Pagina "Bienvenido" "<p>Iniciaste sesión como $(Escapar $form['email']).</p>")
    }
    else {
        Enviar $ctx (Nueva-Pagina "Iniciar sesión" (Formulario-Login "Correo o contraseña incorrectos."))
    }
}