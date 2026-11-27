# =====================================================================
# src\rutas\login.ps1 - Inicio de sesión y bitácora de accesos
# FASE 7: contraseñas con hash y consola sin datos personales
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

    # CORREGIDO H-03: la consola ya no muestra el correo ni la contraseña
    Write-Host "  Intento de inicio de sesión"

    # CORREGIDO H-01: se compara contra el hash guardado
    $usuario = Leer-Csv $ArchivoUsuarios | Where-Object { $_.email -eq $form["email"] } | Select-Object -First 1
    $correcto = $false
    if ($usuario) { $correcto = Probar-Contrasena $form["password"] $usuario.password_hash }

    # Cada intento queda en la bitácora, exitoso o no (nunca la contraseña)
    Registrar-Acceso $ctx $form["email"] "login" $correcto

    if ($correcto) {
        Enviar $ctx (Nueva-Pagina "Bienvenido" "<p>Iniciaste sesión como $(Escapar $form['email']).</p>")
    }
    else {
        # El mensaje no dice si falló el correo o la contraseña
        Enviar $ctx (Nueva-Pagina "Iniciar sesión" (Formulario-Login "Correo o contraseña incorrectos."))
    }
}